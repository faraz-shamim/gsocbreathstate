// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:math' as math;

import 'package:breath_state/providers/breathing_sound_provider.dart';
import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/breathing_sound_toggle.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/guided_breathing.dart';
import 'package:breath_state/widgets/neural_breath_pacer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

                                                                   
   
                                                                            
                                                                         
                                                      
class RfAssessmentScreen extends StatefulWidget {
  final UnifiedPolarConnect polar;
  final int patientId;
  final Future<void>? preStartFuture;

  const RfAssessmentScreen({
    super.key,
    required this.polar,
    required this.patientId,
    this.preStartFuture,
  });

  @override
  State<RfAssessmentScreen> createState() => _RfAssessmentScreenState();
}

class _RfAssessmentScreenState extends State<RfAssessmentScreen> {
  late final GoDirectRfRespirationSource _respirationSource;
  late final RfAssessmentController _controller;
  late final RfAssessmentLifecycleObserver _lifecycleObserver;
  late final RfReleaseAudit _releaseAudit;
  late final BreathingSoundProvider _soundProvider;
  StreamSubscription<RfAssessmentSnapshot>? _snapshotSubscription;

  late RfAssessmentSnapshot _snapshot;
  Future<void> _audioOperation = Future<void>.value();
  RfBreathPhase? _audioPhase;
  int? _audioCycleIndex;
  bool _audioSessionActive = false;
  bool _disposing = false;
  bool _preparingPreviousRecording = false;
  bool _resultHandled = false;
  bool _applyingResult = false;
  bool _resultApplied = false;
  String? _applyMessage;
  DateTime? _assessmentStartedAt;

  @override
  void initState() {
    super.initState();
    _respirationSource = GoDirectRfRespirationSource(
      context.read<GoDirectProvider>(),
    );
    _controller = RfAssessmentController(
      polarSource: UnifiedPolarRfAcquisitionSource(widget.polar),
      respirationSource: _respirationSource,
    );
    _releaseAudit = RfReleaseAudit.capture(_controller.protocol);
    _snapshot = _controller.snapshot;
    _soundProvider = context.read<BreathingSoundProvider>();
    _lifecycleObserver = RfAssessmentLifecycleObserver(_controller)..attach();
    _snapshotSubscription = _controller.snapshots.listen(_onSnapshot);
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    final pending = widget.preStartFuture;
    if (pending != null) {
      setState(() => _preparingPreviousRecording = true);
      try {
        await pending;
      } catch (_) {
                                                                               
                                                        
      } finally {
        if (mounted) setState(() => _preparingPreviousRecording = false);
      }
    }
    if (!_releaseAudit.assessmentsAllowed) return;
    if (!mounted) return;
    await _controller.initializePreflight();
  }

  void _onSnapshot(RfAssessmentSnapshot snapshot) {
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
    _syncBreathingAudio(snapshot);

    if (snapshot.state == RfAssessmentControllerState.running) {
      unawaited(WakelockPlus.enable());
    } else if (snapshot.isTerminal) {
      unawaited(WakelockPlus.disable());
    }

    if (snapshot.state == RfAssessmentControllerState.completed &&
        !_resultHandled) {
      _resultHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_handleCompletedResult());
      });
    }
  }

  void _syncBreathingAudio(RfAssessmentSnapshot snapshot) {
    if (_disposing) return;
    if (snapshot.state == RfAssessmentControllerState.running) {
      final startingSession = !_audioSessionActive;
      final phaseChanged =
          startingSession ||
          snapshot.phase != _audioPhase ||
          snapshot.cycleIndex != _audioCycleIndex;
      if (!phaseChanged) return;

      _audioSessionActive = true;
      _audioPhase = snapshot.phase;
      _audioCycleIndex = snapshot.cycleIndex;
      unawaited(
        _enqueueAudio(() async {
          if (startingSession) {
            await _soundProvider.beginSession();
          }
          await _playBreathingCue(snapshot);
        }),
      );
      return;
    }

    if (_audioSessionActive) {
      _audioSessionActive = false;
      _audioPhase = null;
      _audioCycleIndex = null;
      unawaited(_enqueueAudio(_soundProvider.endSession));
    }
  }

  Future<void> _playBreathingCue(RfAssessmentSnapshot snapshot) {
    final cycle = _controller.protocol.cycleAtElapsedMs(snapshot.elapsedMs);
    final phaseDurationMs =
        snapshot.phase == RfBreathPhase.inhale
            ? cycle.inhaleMs
            : cycle.exhaleMs;
    final remainingMs = math.max(
      1,
      (phaseDurationMs * (1 - snapshot.phaseProgress.clamp(0.0, 1.0))).round(),
    );
    return _soundProvider.cue(
      snapshot.phase == RfBreathPhase.inhale
          ? BreathingCue.inhale
          : BreathingCue.exhale,
      sustainFor: Duration(milliseconds: remainingMs),
    );
  }

  Future<void> _replayCurrentBreathingCue() {
    if (_disposing) return Future<void>.value();
    if (_snapshot.state != RfAssessmentControllerState.running ||
        !_audioSessionActive) {
      return _soundProvider.cue(BreathingCue.inhale);
    }
    return _enqueueAudio(() => _playBreathingCue(_snapshot));
  }

  Future<void> _enqueueAudio(Future<void> Function() operation) {
    final next = _audioOperation.then(
      (_) => operation(),
      onError: (_) => operation(),
    );
    _audioOperation = next;
    return next;
  }

  Future<void> _handleCompletedResult() async {
    final result = _snapshot.result;
    if (result == null || result.rfBpm == null) return;
    if (result.mode == RfAcquisitionMode.measured) {
      await _persistResult(
        result,
        appliedToPatient: _releaseAudit.patientApplicationAllowed,
        estimateConfirmed: null,
      );
      return;
    }

    if (!_releaseAudit.patientApplicationAllowed) {
      await _persistResult(
        result,
        appliedToPatient: false,
        estimateConfirmed: null,
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Apply estimated RF?'),
                content: Text(
                  'This ${result.rfBpm!.toStringAsFixed(2)} BPM result used '
                  'pacer timing because no valid GDX-RB respiration signal '
                  'was available. Apply this estimate to the patient profile?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep without applying'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Apply estimate'),
                  ),
                ],
              ),
        ) ??
        false;
    if (mounted) {
      await _persistResult(
        result,
        appliedToPatient: confirmed,
        estimateConfirmed: confirmed,
      );
    }
  }

  Future<void> _persistResult(
    RfAssessmentResult result, {
    required bool appliedToPatient,
    required bool? estimateConfirmed,
  }) async {
    final rate = result.rfBpm;
    if (rate == null || !rate.isFinite || rate <= 0 || _applyingResult) return;
    setState(() {
      _applyingResult = true;
    });
    try {
      final database = AppDatabase();
      await RfAssessmentPersistenceService(database).persist(
        patientId: widget.patientId,
        surface: kIsWeb ? 'web' : 'native',
        startedAt: _assessmentStartedAt ?? DateTime.now(),
        endedAt: DateTime.now(),
        protocol: _controller.protocol,
        result: result,
        rrSamples: _controller.rrSamples,
        respirationSamples: _controller.respirationSamples,
        completedCycles: _snapshot.cycleCount,
        appliedToPatient: appliedToPatient,
        estimateConfirmed: estimateConfirmed,
        releaseAudit: _releaseAudit,
      );
      if (mounted && appliedToPatient) {
        ResonanceFrequency.userResonanceFreq = rate;
        await context.read<PatientProvider>().refreshPatients();
      }
      if (mounted) {
        setState(() {
          _resultApplied = appliedToPatient;
          _applyMessage =
              appliedToPatient
                  ? result.mode == RfAcquisitionMode.measured
                      ? 'Measured RF saved and applied automatically.'
                      : 'Estimated RF saved and applied with confirmation.'
                  : _releaseAudit.rolloutStage ==
                      PreciseRfRolloutStage.validation
                  ? '${result.mode == RfAcquisitionMode.measured ? 'Measured' : 'Estimated'} '
                      'RF saved in validation-only mode and not applied to the '
                      'patient profile.'
                  : 'Estimated RF saved but not applied to the patient profile.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _applyMessage = 'Could not save RF assessment: $error');
      }
    } finally {
      if (mounted) setState(() => _applyingResult = false);
    }
  }

  Future<void> _start() async {
    if (!_releaseAudit.assessmentsAllowed) return;
    _resultHandled = false;
    _resultApplied = false;
    _applyMessage = null;
    _assessmentStartedAt = DateTime.now();
    await _controller.startAssessment(mode: _snapshot.mode);
  }

  Future<void> _retry() async {
    _resultHandled = false;
    _resultApplied = false;
    _applyMessage = null;
    if (!_releaseAudit.assessmentsAllowed) return;
    await _controller.initializePreflight();
  }

  Future<void> _cancel() async {
    await _controller.abort(RfAbortReason.userCancelled);
  }

  @override
  void dispose() {
    _disposing = true;
    if (_audioSessionActive) {
      _audioSessionActive = false;
      unawaited(_enqueueAudio(_soundProvider.endSession));
    }
    _lifecycleObserver.dispose();
    unawaited(_snapshotSubscription?.cancel());
    unawaited(() async {
      await _controller.dispose();
      await _respirationSource.dispose();
    }());
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppTheme.darkBackgroundGradient
                  : AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(isDark),
              Expanded(
                child: switch (_snapshot.state) {
                  RfAssessmentControllerState.running => _buildRunning(isDark),
                  RfAssessmentControllerState.analyzing => _buildAnalyzing(),
                  RfAssessmentControllerState.completed => _buildResult(isDark),
                  RfAssessmentControllerState.invalid ||
                  RfAssessmentControllerState
                      .aborted => _buildTerminalProblem(isDark),
                  _ => _buildPreflight(isDark),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed:
                _snapshot.state == RfAssessmentControllerState.running
                    ? _cancel
                    : () => Navigator.of(context).pop(),
            tooltip:
                _snapshot.state == RfAssessmentControllerState.running
                    ? 'End assessment'
                    : 'Back',
            icon: Icon(
              _snapshot.state == RfAssessmentControllerState.running
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precise RF Assessment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Fisher–Lehrer 78-breath protocol',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (_snapshot.mode != null) _modeBadge(_snapshot.mode!),
          const SizedBox(width: 4),
          BreathingSoundToggle(
            compact: true,
            onCueSettingsChanged: _replayCurrentBreathingCue,
          ),
        ],
      ),
    );
  }

  Widget _buildPreflight(bool isDark) {
    final checking =
        _preparingPreviousRecording ||
        _snapshot.state == RfAssessmentControllerState.idle ||
        _snapshot.state == RfAssessmentControllerState.preflight;
    final measured =
        _snapshot.state == RfAssessmentControllerState.readyMeasured;
    final ready =
        _releaseAudit.assessmentsAllowed &&
        (measured ||
            _snapshot.state == RfAssessmentControllerState.readyEstimated);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  measured
                      ? Icons.science_rounded
                      : Icons.monitor_heart_rounded,
                  size: 46,
                  color: measured ? AppTheme.emerald : AppTheme.dustyRose,
                ),
                const SizedBox(height: 14),
                Text(
                  checking
                      ? 'Checking sensor signals…'
                      : measured
                      ? 'Measured RF is ready'
                      : 'Estimated RF is ready',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _preparingPreviousRecording
                      ? 'Finishing the current recording before preflight.'
                      : _snapshot.message ??
                          'Keep the Polar sensor connected and remain still.',
                  textAlign: TextAlign.center,
                ),
                if (checking) ...[
                  const SizedBox(height: 18),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _releaseAudit.assessmentsAllowed
                      ? Icons.verified_user_rounded
                      : Icons.block_rounded,
                  color:
                      _releaseAudit.assessmentsAllowed
                          ? AppTheme.emerald
                          : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Release gate: '
                        '${PreciseRfRolloutPolicy(_releaseAudit.rolloutStage).label}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !_releaseAudit.protocolConformance.passed
                            ? 'Protocol integrity check failed. This assessment '
                                'is blocked.'
                            : _releaseAudit.rolloutStage ==
                                PreciseRfRolloutStage.validation
                            ? 'Protocol integrity passed. Results are saved for '
                                'validation but cannot update the patient profile.'
                            : _releaseAudit.rolloutStage ==
                                PreciseRfRolloutStage.disabled
                            ? 'Precise RF is disabled in this build.'
                            : 'Protocol integrity passed '
                                '(${_releaseAudit.protocolConformance.configurationFingerprint}).',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _deviceRow(
            label: 'Polar RR',
            ready: _snapshot.polarReady,
            detail:
                _snapshot.polarReady
                    ? '${_snapshot.rrCount} interval(s) detected'
                    : 'Waiting for valid RR intervals',
          ),
          const SizedBox(height: 10),
          _deviceRow(
            label: 'GDX-RB respiration',
            ready: _snapshot.beltSignalDetected,
            detail:
                _snapshot.beltSignalDetected
                    ? 'Movement signal detected'
                    : _snapshot.beltConnected
                    ? 'Connected; no valid movement signal'
                    : 'Not connected — pacer timing will be used',
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              measured
                  ? 'Measured RF fits the final 60 seconds of the belt signal '
                      'and reports the observed breathing rate.'
                  : 'Estimated RF uses the exact scheduled pacer rate at the '
                      'cardiac maximum. You must confirm it before it is '
                      'applied to the patient profile.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'The assessment lasts 78 complete breaths (about 14:55), '
              'from 6.75 toward 4.25 breaths/min with equal inhale and '
              'exhale. It cannot be paused or resumed.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: ready ? _start : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                !_releaseAudit.assessmentsAllowed
                    ? 'Assessment unavailable'
                    : measured
                    ? 'Start measured RF'
                    : ready
                    ? 'Start estimated RF'
                    : 'Preparing assessment…',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunning(bool isDark) {
    final cycle = _controller.protocol.cycleAtElapsedMs(_snapshot.elapsedMs);
    final cycleProgress =
        _snapshot.phase == RfBreathPhase.inhale
            ? _snapshot.phaseProgress * cycle.inhaleFraction
            : cycle.inhaleFraction +
                _snapshot.phaseProgress * (1 - cycle.inhaleFraction);
    final phaseDurationMs =
        _snapshot.phase == RfBreathPhase.inhale
            ? cycle.inhaleMs
            : cycle.exhaleMs;
    final phaseSeconds =
        (phaseDurationMs * (1 - _snapshot.phaseProgress) / 1000).ceil();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Breath ${_snapshot.cycleIndex + 1} of '
                      '${_snapshot.cycleCount}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_snapshot.scheduledBpm.toStringAsFixed(2)} BPM',
                    style: TextStyle(
                      color: AppTheme.emerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    (_snapshot.cycleIndex + cycleProgress) /
                    _snapshot.cycleCount,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatMs(_snapshot.elapsedMs)),
                  Text('${_formatMs(_snapshot.remainingMs)} remaining'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: NeuralBreathPacer(
              phaseLabel:
                  _snapshot.phase == RfBreathPhase.inhale ? 'Inhale' : 'Exhale',
              phaseProgress: _snapshot.phaseProgress,
              cycleProgress: cycleProgress,
              secondsRemaining: phaseSeconds.clamp(0, 99),
              rateBpm: _snapshot.scheduledBpm,
              helperText: 'Follow the guide smoothly. Do not pause.',
              showMetricChips: false,
              showCoherenceOverlay: false,
              hasHoldPhase: false,
              inhaleFraction: 0.5,
              holdFraction: 0,
              exhaleFraction: 0.5,
              emptyHoldFraction: 0,
              fillParent: true,
              edgeToEdge: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
          child: Row(
            children: [
              Expanded(
                child: _statusChip(
                  'Polar',
                  '${_snapshot.rrCount} RR',
                  _snapshot.polarReady,
                ),
              ),
              if (_snapshot.mode == RfAcquisitionMode.measured) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _statusChip(
                    'Respiration',
                    '${_snapshot.respirationCount} samples',
                    _snapshot.beltSignalDetected,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzing() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text(
              'Analyzing the completed 78-breath assessment…',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(bool isDark) {
    final result = _snapshot.result!;
    final rf = result.rfBpm;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 50,
                  color: AppTheme.emerald,
                ),
                const SizedBox(height: 12),
                _modeBadge(result.mode),
                const SizedBox(height: 12),
                Text(
                  rf == null ? 'No valid RF' : '${rf.toStringAsFixed(2)} BPM',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emerald,
                  ),
                ),
                if (result.rfHz != null)
                  Text('${result.rfHz!.toStringAsFixed(3)} Hz'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _resultRow(
                  'Cardiac maximum',
                  result.peakToTroughAmplitude == null
                      ? 'Unavailable'
                      : '${result.peakToTroughAmplitude!.toStringAsFixed(1)} ms',
                ),
                _resultRow(
                  'Scheduled breathing',
                  result.scheduledBpmAtCenter == null
                      ? 'Unavailable'
                      : '${result.scheduledBpmAtCenter!.toStringAsFixed(2)} BPM',
                ),
                _resultRow(
                  'Measured breathing',
                  result.fittedRespirationBpm == null
                      ? 'Not measured'
                      : '${result.fittedRespirationBpm!.toStringAsFixed(2)} BPM',
                ),
                _resultRow(
                  'Ectopic corrections',
                  '${result.quality.ectopicCorrections}',
                ),
                _resultRow(
                  'Quality',
                  result.quality.passed ? 'Passed' : 'Review warnings',
                ),
              ],
            ),
          ),
          if (result.quality.flags.isNotEmpty) ...[
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(16),
              color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quality warnings',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...result.quality.flags.map(
                    (flag) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${_qualityFlagLabel(flag)}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_applyMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _applyMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _resultApplied ? AppTheme.emerald : Colors.amber,
              ),
            ),
          ],
          if (_applyingResult) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 22),
          if (rf != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openBreathing(rf),
                icon: const Icon(Icons.spa_rounded),
                label: const Text('Breathe at this RF'),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalProblem(bool isDark) {
    final aborted = _snapshot.state == RfAssessmentControllerState.aborted;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aborted ? Icons.restart_alt_rounded : Icons.warning_rounded,
                size: 48,
                color: Colors.amber,
              ),
              const SizedBox(height: 14),
              Text(
                aborted ? 'Assessment must restart' : 'Assessment unavailable',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _snapshot.message ?? 'Reconnect the sensors and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Run preflight again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceRow({
    required String label,
    required bool ready,
    required String detail,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: ready ? AppTheme.emerald : Colors.amber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value, bool ready) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: (ready ? AppTheme.emerald : Colors.amber).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _modeBadge(RfAcquisitionMode mode) {
    final measured = mode == RfAcquisitionMode.measured;
    final color = measured ? AppTheme.emerald : Colors.amber.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        measured ? 'MEASURED RF' : 'ESTIMATED RF',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _openBreathing(double rate) {
    final cycleMs = (60000 / rate).round();
    final inhaleMs = cycleMs ~/ 2;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => GuidedBreathing(
              sessionTitle: 'Resonance Breathing',
              inhaleDuration: Duration(milliseconds: inhaleMs),
              holdDuration: Duration.zero,
              exhaleDuration: Duration(milliseconds: cycleMs - inhaleMs),
              totalDuration: const Duration(minutes: 5),
              resonanceFrequency: rate,
            ),
      ),
    );
  }

  String _formatMs(double milliseconds) {
    final totalSeconds = math.max(0, (milliseconds / 1000).ceil());
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _qualityFlagLabel(RfQualityFlag flag) {
    final words = flag.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)!.toLowerCase()}',
    );
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }
}
