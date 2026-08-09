library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/breathing_sound_provider.dart';
import 'package:breath_state/services/biofeedback/adaptive_breathing_controller.dart';
import 'package:breath_state/services/biofeedback/realtime_hrv_engine.dart';
import 'package:breath_state/services/biofeedback/signal_quality_index.dart';
import 'package:breath_state/services/background/background_session_service.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:breath_state/services/hrv_analysis/hrv_psychophysiological_indices.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/services/webxr/webxr_bridge.dart';
import 'package:breath_state/services/webxr/vr_gamification.dart';
import 'package:breath_state/services/webxr/vr_resonance_sweep.dart';
import 'package:breath_state/services/webxr/webxr_messages.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/breathing_sound_toggle.dart';

class VrBiofeedbackScreen extends StatefulWidget {
  const VrBiofeedbackScreen({super.key});

  @override
  State<VrBiofeedbackScreen> createState() => _VrBiofeedbackScreenState();
}

class _VrBiofeedbackScreenState extends State<VrBiofeedbackScreen> {
  static const List<int> _durationOptionsMinutes = [3, 5, 10, 15];
  static const Duration _bridgeTick = Duration(milliseconds: 500);
  static const Duration _snapshotInterval = Duration(seconds: 5);

  RealtimeHrvEngine? _engine;
  AdaptiveBreathingController? _breathController;
  RfAssessmentController? _rfController;
  GoDirectRfRespirationSource? _rfRespirationSource;
  WebXRBridge? _bridge;
  late final BreathingSoundProvider _soundGuide;
  final VrGamificationTracker _gamification = VrGamificationTracker();
  final RfReleaseAudit _rfReleaseAudit = RfReleaseAudit.capture(
    VrResonanceSweepProtocol.config,
  );

  StreamSubscription<WebXRCommand>? _commandSub;
  StreamSubscription<int>? _hrSub;
  StreamSubscription<RealtimeHrvSnapshot>? _snapshotSub;
  StreamSubscription<AdaptiveBreathingState>? _breathSub;
  StreamSubscription<RfAssessmentSnapshot>? _rfAssessmentSub;
  Timer? _bridgeTimer;
  Future<void> _audioOperation = Future<void>.value();
  String? _audioPhase;
  int? _audioCycleIndex;
  bool _audioSessionActive = false;
  bool _disposing = false;

  bool _isStarting = false;
  bool _isActive = false;
  bool _isPaused = false;
  bool _isStopping = false;
  bool _vrLaunched = false;
  bool _ownsBackgroundSession = false;
  String _displayMode = 'patient';
  bool _seatedMode = true;
  bool _reducedMotion = false;
  bool _reducedParticles = false;
  bool _highContrastGuide = true;
  bool _largerText = false;
  String? _error;
  String _lastCommand = 'None';
  String _protocol = VrBreathingProtocol.resonanceBreathing;
  int _rrFedCount = 0;

  int _heartRate = 0;
  double _rmssd = 0;
  double _sdnn = 0;
  double _coherence = 0;
  double _stressIndex = 150;
  double _currentBreathRate = 6.0;
  String _signalQuality = 'waiting';
  int _dataSent = 0;
  double _treeVitalityScore = 50;
  int _ambientTier = 1;
  int _bestBuildingStreakSec = 0;
  int _bestPeakStreakSec = 0;
  int _bestBreathSyncStreakSec = 0;
  RfAssessmentSnapshot? _rfSnapshot;

  Duration _targetDuration = const Duration(minutes: 5);
  String _elapsed = '00:00';
  String _remaining = '05:00';
  String _phaseLabel = 'Ready';
  double _phaseProgress = 0;
  double _cycleProgress = 0;
  int _phaseSecondsRemaining = 0;
  int _inhaleMs = 5000;
  int _exhaleMs = 5000;

  int _bestHighStreakSec = 0;
  int _heartRateSum = 0;
  int _heartRateSamples = 0;
  int? _minHeartRate;
  int? _maxHeartRate;
  final List<int> _sessionHrReadings = [];
  DateTime? _sessionStartedAt;
  DateTime? _sessionEndedAt;
  VrTreeProgress _treeProgress = VrTreeProgress.initial();
  VrSessionResult? _lastSessionResult;
  RfAssessmentResult? _lastSweepResult;

  final Stopwatch _sessionClock = Stopwatch();

  @override
  void initState() {
    super.initState();
    _soundGuide = context.read<BreathingSoundProvider>();
    final bridge = WebXRBridge();
    if (bridge.isSupported) {
      _bridge = bridge;
      _setupBridge();
      _bridgeTimer = Timer.periodic(_bridgeTick, (_) => _tickBridgeState());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentBreathRate = _initialResonanceRate();
          _setBreathDurationsForRate(_currentBreathRate);
        });
        _sendSessionState();
        _sendBreathPhase();
      });
    } else {
      bridge.dispose();
    }
  }

  @override
  void dispose() {
    _disposing = true;
    _stopVrBreathingAudio();
    _bridgeTimer?.cancel();
    _commandSub?.cancel();
    unawaited(_stop(sendResult: false));
    if (_ownsBackgroundSession) {
      _ownsBackgroundSession = false;
      unawaited(BackgroundSessionService.stop());
    }
    _bridge?.dispose();
    super.dispose();
  }

  void _setupBridge() {
    _bridge!.open();
    _commandSub = _bridge!.commands.listen(_handleVrCommand);
  }

  void _handleVrCommand(WebXRCommand command) {
    if (!mounted) return;
    setState(() => _lastCommand = command.name);

    switch (command.name) {
      case WebXRCommandName.start:
        unawaited(_start());
        break;
      case WebXRCommandName.pause:
        _pause();
        break;
      case WebXRCommandName.resume:
        _resume();
        break;
      case WebXRCommandName.stop:
        unawaited(_stop());
        break;
      case WebXRCommandName.setDuration:
        final minutes = command.payload['minutes'];
        if (minutes is num && !_isActive) {
          _setDuration(Duration(minutes: minutes.round().clamp(1, 60)));
        }
        break;
      case WebXRCommandName.setProtocol:
        _setProtocol(command.payload['protocol'] ?? command.payload['mode']);
        break;
      case WebXRCommandName.setComfortOptions:
        _applyComfortOptions(command.payload);
        _sendSessionState();
        _sendTreeProgress();
        break;
      case WebXRCommandName.recenter:
        _sendSessionState();
        break;
      default:
        _sendError('Unsupported VR command: ${command.name}');
    }
  }

  void _applyComfortOptions(Map<String, Object?> payload) {
    bool boolFromPayload(String key, bool current) {
      final value = payload[key];
      return value is bool ? value : current;
    }

    final mode = payload['displayMode'] ?? payload['mode'];
    setState(() {
      if (mode == 'patient' || mode == 'clinician') {
        _displayMode = mode.toString();
      }
      _seatedMode = boolFromPayload('seatedMode', _seatedMode);
      _reducedMotion = boolFromPayload('reducedMotion', _reducedMotion);
      _reducedParticles = boolFromPayload(
        'reducedParticles',
        _reducedParticles,
      );
      _highContrastGuide = boolFromPayload(
        'highContrastGuide',
        _highContrastGuide,
      );
      _largerText = boolFromPayload('largerText', _largerText);
    });
  }

  void _setProtocol(Object? value) {
    if (_isActive || _isStarting) return;

    final nextProtocol = VrBreathingProtocol.normalize(value);
    if (nextProtocol == VrBreathingProtocol.resonanceSweep &&
        !_rfReleaseAudit.assessmentsAllowed) {
      final message =
          _rfReleaseAudit.protocolConformance.passed
              ? 'Precise RF is disabled in this build.'
              : 'Precise RF protocol integrity validation failed.';
      setState(() => _error = message);
      _sendError(message);
      return;
    }
    final nextDuration =
        nextProtocol == VrBreathingProtocol.resonanceSweep
            ? VrResonanceSweepProtocol.defaultDuration
            : _targetDuration;
    final nextRate =
        nextProtocol == VrBreathingProtocol.resonanceSweep
            ? VrResonanceSweepProtocol.config.startBpm
            : _initialResonanceRate();

    setState(() {
      _protocol = nextProtocol;
      _targetDuration = nextDuration;
      _currentBreathRate = nextRate;
      _remaining = _formatDuration(nextDuration);
      _resetSweepState();
      if (_isSweepProtocol) {
        _setSweepBreathDurationsForRate(nextRate);
      } else {
        _setBreathDurationsForRate(nextRate);
      }
    });
    _sendSessionState();
    _sendBreathPhase();
  }

  Future<void> _start() async {
    if (!(_bridge?.isSupported ?? false) || _isStarting || _isActive) return;
    if (_isSweepProtocol && !_rfReleaseAudit.assessmentsAllowed) {
      _setStartError(
        _rfReleaseAudit.protocolConformance.passed
            ? 'Precise RF is disabled in this build.'
            : 'Precise RF protocol integrity validation failed.',
      );
      return;
    }

    final patient = context.read<PatientProvider>().activePatient;
    if (patient == null) {
      _setStartError('Select or create a patient before starting VR.');
      return;
    }

    final polarProvider = context.read<PolarConnectProvider>();
    final goDirectProvider = context.read<GoDirectProvider>();
    final unified = polarProvider.getPolarConnect();
    if (unified == null) {
      _setStartError('Connect a Polar device in Settings first.');
      return;
    }

    setState(() {
      _isStarting = true;
      _error = null;
      _phaseLabel = 'Preparing';
    });
    _sendSessionState();

    final progress = await _loadVrTreeProgress(patient.id);
    if (!mounted) return;
    _treeProgress = progress;
    _gamification.reset(startingVitality: progress.treeVitality);

    await WakelockPlus.enable();

    if (_isSweepProtocol) {
      _targetDuration = VrResonanceSweepProtocol.defaultDuration;
    }

    final initialRate =
        _isSweepProtocol
            ? VrResonanceSweepProtocol.config.startBpm
            : _initialResonanceRate();
    _currentBreathRate = initialRate;
    if (_isSweepProtocol) {
      _setSweepBreathDurationsForRate(initialRate);
    } else {
      _setBreathDurationsForRate(initialRate);
    }
    _resetSweepState();

    if (_isSweepProtocol) {
      _rfRespirationSource = GoDirectRfRespirationSource(goDirectProvider);
      _rfController = RfAssessmentController(
        polarSource: UnifiedPolarRfAcquisitionSource(unified),
        respirationSource: _rfRespirationSource,
      );
      _rfSnapshot = _rfController!.snapshot;
      _rfAssessmentSub = _rfController!.snapshots.listen(
        _onRfAssessmentSnapshot,
      );
      await _rfController!.initializePreflight();
      if (!mounted) return;
      final preflight = _rfController!.snapshot;
      if (preflight.state != RfAssessmentControllerState.readyMeasured &&
          preflight.state != RfAssessmentControllerState.readyEstimated) {
        await _teardownSessionResources(stopPolar: true);
        _setStartError(
          preflight.message ?? 'RF sensor preflight did not pass.',
        );
        return;
      }
      await _rfController!.startAssessment(mode: preflight.mode);
    } else {
      _engine =
          RealtimeHrvEngine(windowDurationSec: 60, updateIntervalMs: 5000)
            ..setBreathingRateBpm(initialRate)
            ..start();
      _breathController = AdaptiveBreathingController(
        hrvEngine: _engine!,
        initialRateBpm: initialRate,
      )..start();

      try {
        final hrStream = await unified.getHeartRate();
        final broadcastHR = hrStream.asBroadcastStream();
        _rrFedCount = 0;

        _hrSub = broadcastHR.listen(
          (hr) {
            if (!mounted) return;
            final rr = unified.sessionRrIntervals;
            while (_rrFedCount < rr.length) {
              final rrMs = rr[_rrFedCount].toDouble();
              _engine?.addRR(rrMs);
              _rrFedCount++;
            }
            _recordHeartRate(hr);
            setState(() => _heartRate = hr);
          },
          onError: (Object error) {
            _sendError('Polar stream stopped: ${_friendlyError(error)}');
            if (mounted) {
              setState(
                () => _error = 'Polar stream stopped: ${_friendlyError(error)}',
              );
            }
          },
        );
      } catch (e) {
        await _teardownSessionResources(stopPolar: true);
        _setStartError('Failed to start HR stream: ${_friendlyError(e)}');
        return;
      }

      _snapshotSub = _engine!.snapshots.listen(_onHrvSnapshot);
      _breathSub = _breathController?.stateStream.listen(_onBreathingState);
    }

    _sessionStartedAt = DateTime.now();
    _sessionEndedAt = null;
    _sessionClock
      ..reset()
      ..start();
    _bestHighStreakSec = 0;
    _bestBuildingStreakSec = 0;
    _bestPeakStreakSec = 0;
    _bestBreathSyncStreakSec = 0;
    _heartRateSum = 0;
    _heartRateSamples = 0;
    _minHeartRate = null;
    _maxHeartRate = null;
    _sessionHrReadings.clear();

    setState(() {
      _isStarting = false;
      _isActive = true;
      _isPaused = false;
      _isStopping = false;
      _lastSessionResult = null;
      _lastSweepResult = null;
      _treeVitalityScore = progress.treeVitality;
      _ambientTier = progress.unlockedAmbientTier;
      _phaseLabel = 'Inhale';
      _elapsed = _formatDuration(Duration.zero);
      _remaining = _formatDuration(_targetDuration);
      _dataSent = _bridge?.messagesSent ?? 0;
    });

    _sendSessionState();
    _sendBreathPhase();
    _sendTreeProgress();
    _syncVrBreathingAudio(force: true);
  }

  void _setStartError(String message) {
    unawaited(WakelockPlus.disable());
    setState(() {
      _isStarting = false;
      _isActive = false;
      _isPaused = false;
      _error = message;
      _phaseLabel = 'Ready';
    });
    _sendError(message);
    _sendSessionState();
  }

  void _pause() {
    if (!_isActive || _isPaused) return;
    if (_isSweepProtocol) {
      _sendError(
        'Precise RF cannot be paused. The assessment was aborted and must restart.',
      );
      unawaited(_rfController?.abort(RfAbortReason.vrPaused));
      return;
    }
    _sessionClock.stop();
    setState(() {
      _isPaused = true;
      _phaseLabel = 'Paused';
    });
    _stopVrBreathingAudio();
    _sendSessionState();
    _sendBreathPhase();
  }

  void _resume() {
    if (!_isActive || !_isPaused) return;
    if (_isSweepProtocol) return;
    _sessionClock.start();
    setState(() {
      _isPaused = false;
    });
    _updatePhaseFromClock();
    _sendSessionState();
    _sendBreathPhase();
  }

  Future<void> _stop({bool sendResult = true}) async {
    if (_isStopping || (!_isActive && !_isStarting)) return;
    _isStopping = true;

    final patientProvider = context.read<PatientProvider>();
    final patient = patientProvider.activePatient;
    _sessionEndedAt = DateTime.now();
    _sessionClock.stop();
    _stopVrBreathingAudio();

    VrSessionResult? result;
    RfAssessmentResult? sweepResult;
    double? savedSweepFrequency;
    var progress = _treeProgress;
    if (sendResult && _isActive) {
      if (_isSweepProtocol) {
        sweepResult = _rfSnapshot?.result;
        final rate = sweepResult?.rfBpm;
        if (sweepResult?.mode == RfAcquisitionMode.measured &&
            sweepResult?.status == RfResultStatus.completed &&
            _rfReleaseAudit.patientApplicationAllowed &&
            rate != null &&
            rate.isFinite &&
            rate > 0) {
          savedSweepFrequency = rate;
        }
      }
      result = _buildSessionResult();
      progress = _treeProgress.applySession(result);
      final persistenceSucceeded = await _persistVrSessionSummary(
        patient: patient,
        result: result,
        progress: progress,
        sweepResult: sweepResult,
        savedSweepFrequency: savedSweepFrequency,
      );
      if (!persistenceSucceeded) {
        savedSweepFrequency = null;
      }
      final resultPayload = _sessionResultPayload(
        result: result,
        progress: progress,
        sweepResult: sweepResult,
        savedSweepFrequency: savedSweepFrequency,
      );
      _bridge?.sendMessage(
        WebXRMessage.build(
          WebXRMessageType.sessionResult,
          session: _sessionPayload(),
          tree: _treeProgressPayload(
            progressOverride: progress,
            result: result,
          ),
          result: resultPayload,
        ),
      );
      if (persistenceSucceeded && savedSweepFrequency != null && mounted) {
        ResonanceFrequency.userResonanceFreq = savedSweepFrequency;
        await patientProvider.refreshPatients();
      }
    }

    await _teardownSessionResources(stopPolar: true);
    await WakelockPlus.disable();

    if (!mounted) return;
    setState(() {
      _isStarting = false;
      _isActive = false;
      _isPaused = false;
      _isStopping = false;
      _phaseLabel = 'Ready';
      _phaseProgress = 0;
      _cycleProgress = 0;
      _phaseSecondsRemaining = 0;
      _dataSent = _bridge?.messagesSent ?? 0;
      _treeProgress = progress;
      _ambientTier = progress.unlockedAmbientTier;
      if (result != null) {
        _lastSessionResult = result;
        _lastSweepResult = sweepResult;
        _treeVitalityScore = progress.treeVitality;
      }
    });
    _sendSessionState();
    _sendTreeProgress();
  }

  Future<void> _teardownSessionResources({required bool stopPolar}) async {
    await _hrSub?.cancel();
    _hrSub = null;
    await _snapshotSub?.cancel();
    _snapshotSub = null;
    await _breathSub?.cancel();
    _breathSub = null;
    await _rfAssessmentSub?.cancel();
    _rfAssessmentSub = null;

    _engine?.stop();
    _engine?.dispose();
    _engine = null;

    _breathController?.stop();
    _breathController?.dispose();
    _breathController = null;
    await _rfController?.dispose();
    _rfController = null;
    await _rfRespirationSource?.dispose();
    _rfRespirationSource = null;

    if (stopPolar && mounted) {
      final unified = context.read<PolarConnectProvider>().getPolarConnect();
      if (unified != null) {
        try {
          await unified.stopRecording();
        } catch (_) {}
      }
    }
  }

  void _onHrvSnapshot(RealtimeHrvSnapshot snapshot) {
    if (!mounted) return;

    final stressIndex = _computeStressIndex(snapshot);
    final coherence = snapshot.coherence.clamp(0.0, 100.0).toDouble();
    final signalQuality = _signalQualityLabel(snapshot);
    _gamification.addBiofeedbackSample(
      coherence: coherence,
      sampleInterval: _snapshotInterval,
      targetBpm: _currentBreathRate,
      coherencePeakFrequencyHz: snapshot.coherencePeakFrequencyHz,
      signalQuality: signalQuality,
    );

    setState(() {
      _heartRate = snapshot.instantHR.round();
      _rmssd = snapshot.timeDomain?.rmssd ?? 0;
      _sdnn = snapshot.timeDomain?.sdnn ?? 0;
      _coherence = coherence;
      _stressIndex = stressIndex;
      _signalQuality = signalQuality;
      _bestBuildingStreakSec = _gamification.bestBuildingCoherenceStreakSeconds;
      _bestHighStreakSec = _gamification.bestHighCoherenceStreakSeconds;
      _bestPeakStreakSec = _gamification.bestPeakCoherenceStreakSeconds;
      _bestBreathSyncStreakSec = _gamification.bestBreathSyncStreakSeconds;
      _treeVitalityScore = _gamification.treeVitalityScore;
      _ambientTier = math.max(
        _treeProgress.unlockedAmbientTier,
        _treeProgressForLivePayloadTier(),
      );
    });

    _bridge?.sendMessage(
      WebXRMessage.build(
        WebXRMessageType.biofeedbackSnapshot,
        session: _sessionPayload(),
        metrics: _metricsPayload(),
        breath: _breathPayload(),
        tree: _treeProgressPayload(),
      ),
    );
    _sendTreeProgress();
    setState(() => _dataSent = _bridge?.messagesSent ?? 0);
  }

  void _onRfAssessmentSnapshot(RfAssessmentSnapshot snapshot) {
    if (!mounted) return;
    final cycle = VrResonanceSweepProtocol.config.cycleAtElapsedMs(
      snapshot.elapsedMs,
    );
    final cycleProgress =
        snapshot.phase == RfBreathPhase.inhale
            ? snapshot.phaseProgress * 0.5
            : 0.5 + snapshot.phaseProgress * 0.5;
    final phaseRemainingMs = cycle.inhaleMs * (1 - snapshot.phaseProgress);

    setState(() {
      _rfSnapshot = snapshot;
      _currentBreathRate = snapshot.scheduledBpm;
      _setSweepBreathDurationsForRate(snapshot.scheduledBpm);
      _phaseLabel =
          snapshot.phase == RfBreathPhase.inhale ? 'Inhale' : 'Exhale';
      _phaseProgress = snapshot.phaseProgress;
      _cycleProgress = cycleProgress;
      _phaseSecondsRemaining = (phaseRemainingMs / 1000).ceil().clamp(0, 99);
      _elapsed = _formatDuration(
        Duration(milliseconds: snapshot.elapsedMs.round()),
      );
      _remaining = _formatDuration(
        Duration(milliseconds: snapshot.remainingMs.round()),
      );
    });
    _sendSessionState();
    _sendBreathPhase();
    _syncRfBreathingAudio(snapshot);

    if (snapshot.state == RfAssessmentControllerState.completed &&
        _isActive &&
        !_isStopping) {
      unawaited(_stop());
    } else if ((snapshot.state == RfAssessmentControllerState.invalid ||
            snapshot.state == RfAssessmentControllerState.aborted) &&
        _isActive &&
        !_isStopping) {
      final message = snapshot.message ?? 'Precise RF assessment ended.';
      setState(() => _error = message);
      _sendError(message);
      unawaited(_stop(sendResult: false));
    }
  }

  void _onBreathingState(AdaptiveBreathingState state) {
    if (!mounted) return;
    _engine?.setBreathingRateBpm(state.currentRateBpm);
    setState(() {
      _currentBreathRate = state.currentRateBpm;
      _inhaleMs = state.inhaleMs;
      _exhaleMs = state.exhaleMs;
    });
    _sendSessionState();
  }

  void _tickBridgeState() {
    if (!mounted) return;
    if (_isActive &&
        !_isPaused &&
        !_isSweepProtocol &&
        _sessionClock.elapsed >= _targetDuration) {
      unawaited(_stop());
      return;
    }

    if (!_isSweepProtocol) {
      _updatePhaseFromClock();
    }
    _sendBreathPhase();
    _sendTreeProgress();

    final dataSent = _bridge?.messagesSent ?? 0;
    if (dataSent != _dataSent) {
      setState(() => _dataSent = dataSent);
    }
  }

  void _updatePhaseFromClock() {
    final elapsed = _sessionClock.elapsed;
    final remaining = _targetDuration - elapsed;
    final clampedRemaining = remaining.isNegative ? Duration.zero : remaining;

    if (!_isActive) {
      setState(() {
        _elapsed = _formatDuration(Duration.zero);
        _remaining = _formatDuration(_targetDuration);
        _phaseLabel = 'Ready';
        _phaseProgress = 0;
        _cycleProgress = 0;
        _phaseSecondsRemaining = 0;
      });
      return;
    }

    if (_isPaused) {
      setState(() {
        _elapsed = _formatDuration(elapsed);
        _remaining = _formatDuration(clampedRemaining);
        _phaseLabel = 'Paused';
      });
      return;
    }

    final cycleMs = math.max(_inhaleMs + _exhaleMs, 1000);
    final cyclePosition = elapsed.inMilliseconds % cycleMs;
    final inhaleMs = math.max(_inhaleMs, 1);
    final exhaleMs = math.max(_exhaleMs, 1);

    late final String label;
    late final double phaseProgress;
    late final int phaseRemainingMs;
    if (cyclePosition < inhaleMs) {
      label = 'Inhale';
      phaseProgress = cyclePosition / inhaleMs;
      phaseRemainingMs = inhaleMs - cyclePosition;
    } else {
      label = 'Exhale';
      final exhalePosition = cyclePosition - inhaleMs;
      phaseProgress = exhalePosition / exhaleMs;
      phaseRemainingMs = exhaleMs - exhalePosition;
    }

    setState(() {
      _elapsed = _formatDuration(elapsed);
      _remaining = _formatDuration(clampedRemaining);
      _phaseLabel = label;
      _phaseProgress = phaseProgress.clamp(0.0, 1.0).toDouble();
      _cycleProgress = (cyclePosition / cycleMs).clamp(0.0, 1.0).toDouble();
      _phaseSecondsRemaining = (phaseRemainingMs / 1000).ceil().clamp(0, 99);
    });
    _syncVrBreathingAudio(cycleIndex: elapsed.inMilliseconds ~/ cycleMs);
  }

  void _syncRfBreathingAudio(RfAssessmentSnapshot snapshot) {
    if (!_isActive ||
        _isPaused ||
        _disposing ||
        snapshot.state != RfAssessmentControllerState.running) {
      return;
    }
    final phase = snapshot.phase == RfBreathPhase.inhale ? 'inhale' : 'exhale';
    final phaseDurationMs =
        snapshot.phase == RfBreathPhase.inhale ? _inhaleMs : _exhaleMs;
    final remainingMs = math.max(
      1,
      (phaseDurationMs * (1 - snapshot.phaseProgress.clamp(0.0, 1.0))).round(),
    );
    _queueVrBreathingCue(
      phase: phase,
      cycleIndex: snapshot.cycleIndex,
      sustainFor: Duration(milliseconds: remainingMs),
    );
  }

  void _syncVrBreathingAudio({bool force = false, int? cycleIndex}) {
    if (!_isActive || _isPaused || _disposing) return;
    final phase = _phaseLabel.toLowerCase();
    if (phase != 'inhale' && phase != 'exhale') return;
    final safeCycleIndex =
        cycleIndex ??
        _sessionClock.elapsedMilliseconds ~/
            math.max(_inhaleMs + _exhaleMs, 1000);
    final phaseDurationMs = phase == 'inhale' ? _inhaleMs : _exhaleMs;
    final remainingMs = math.max(
      1,
      (phaseDurationMs * (1 - _phaseProgress.clamp(0.0, 1.0))).round(),
    );
    _queueVrBreathingCue(
      phase: phase,
      cycleIndex: safeCycleIndex,
      sustainFor: Duration(milliseconds: remainingMs),
      force: force,
    );
  }

  void _queueVrBreathingCue({
    required String phase,
    required int cycleIndex,
    required Duration sustainFor,
    bool force = false,
  }) {
    final startingSession = !_audioSessionActive;
    if (!force &&
        !startingSession &&
        phase == _audioPhase &&
        cycleIndex == _audioCycleIndex) {
      return;
    }
    _audioSessionActive = true;
    _audioPhase = phase;
    _audioCycleIndex = cycleIndex;
    unawaited(
      _enqueueVrAudio(() async {
        if (startingSession) await _soundGuide.beginSession();
        await _soundGuide.cue(
          phase == 'inhale' ? BreathingCue.inhale : BreathingCue.exhale,
          sustainFor: sustainFor,
        );
      }),
    );
  }

  void _stopVrBreathingAudio() {
    if (!_audioSessionActive) return;
    _audioSessionActive = false;
    _audioPhase = null;
    _audioCycleIndex = null;
    unawaited(_enqueueVrAudio(_soundGuide.endSession));
  }

  Future<void> _replayCurrentBreathingCue() {
    if (!_isActive || _isPaused) {
      return _soundGuide.cue(BreathingCue.inhale);
    }
    _syncVrBreathingAudio(force: true);
    return _audioOperation;
  }

  Future<void> _enqueueVrAudio(Future<void> Function() operation) {
    final next = _audioOperation.then(
      (_) => operation(),
      onError: (_) => operation(),
    );
    _audioOperation = next;
    return next;
  }

  void _setDuration(Duration duration) {
    final nextDuration =
        _isSweepProtocol ? VrResonanceSweepProtocol.defaultDuration : duration;
    setState(() {
      _targetDuration = nextDuration;
      _remaining = _formatDuration(nextDuration);
    });
    _sendSessionState();
  }

  double _initialResonanceRate() {
    final patient = context.read<PatientProvider>().activePatient;
    final resonanceRate =
        patient?.resonanceFrequency ?? ResonanceFrequency.userResonanceFreq;
    return resonanceRate > 0 ? resonanceRate : 6.0;
  }

  void _setBreathDurationsForRate(double rateBpm) {
    final cycleMs = (60000 / rateBpm).round();
    _inhaleMs = (cycleMs / 2).round();
    _exhaleMs = cycleMs - _inhaleMs;
  }

  void _setSweepBreathDurationsForRate(double rateBpm) {
    final durations = VrResonanceSweepProtocol.durationsForRate(rateBpm);
    _inhaleMs = durations.inhaleMs;
    _exhaleMs = durations.exhaleMs;
  }

  bool get _isSweepProtocol => _protocol == VrBreathingProtocol.resonanceSweep;

  void _resetSweepState() {
    _rfSnapshot = null;
  }

  double _computeStressIndex(RealtimeHrvSnapshot snapshot) {
    if (snapshot.windowRRs.length < 10) return _stressIndex;
    try {
      final psychResult = PsychophysiologicalAnalyzer.compute(
        rrIntervalsMs: snapshot.windowRRs,
        rmssd: snapshot.timeDomain?.rmssd ?? 40,
        meanNN: snapshot.timeDomain?.meanNN ?? 800,
      );
      return psychResult.stressIndex.value ?? _stressIndex;
    } catch (_) {
      return _stressIndex;
    }
  }

  String _signalQualityLabel(RealtimeHrvSnapshot snapshot) {
    if (snapshot.sqiResults.isEmpty) return 'waiting';
    switch (snapshot.sqiResults.last.level) {
      case SqiLevel.good:
        return 'good';
      case SqiLevel.warning:
        return 'warning';
      case SqiLevel.bad:
        return 'bad';
    }
  }

  void _sendSessionState() {
    _bridge?.sendMessage(
      WebXRMessage.build(
        WebXRMessageType.sessionState,
        session: _sessionPayload(),
        metrics: _metricsPayload(),
        breath: _breathPayload(),
        tree: _treeProgressPayload(),
      ),
    );
  }

  void _sendBreathPhase() {
    _bridge?.sendMessage(
      WebXRMessage.build(
        WebXRMessageType.breathPhase,
        session: _sessionPayload(),
        breath: _breathPayload(),
      ),
    );
  }

  void _sendTreeProgress() {
    _bridge?.sendMessage(
      WebXRMessage.build(
        WebXRMessageType.treeProgress,
        session: _sessionPayload(),
        metrics: _metricsPayload(),
        breath: _breathPayload(),
        tree: _treeProgressPayload(),
      ),
    );
  }

  void _sendError(String message) {
    _bridge?.sendMessage(
      WebXRMessage.build(
        WebXRMessageType.error,
        error: {'message': message},
        session: _sessionPayload(),
      ),
    );
  }

  Map<String, Object?> _sessionPayload() {
    final patient = context.read<PatientProvider>().activePatient;
    final elapsed = _sessionClock.elapsed;
    final remaining = _targetDuration - elapsed;
    return {
      'patientId': patient?.id,
      'patientName': patient?.name ?? 'Self',
      'mode': _displayMode,
      'displayMode': _displayMode,
      'comfortOptions': _comfortOptionsPayload(),
      'protocol': _protocol,
      'protocolLabel': VrBreathingProtocol.label(_protocol),
      if (_isSweepProtocol) 'resonanceSweep': _sweepPayload(),
      'durationSeconds': _targetDuration.inSeconds,
      'elapsedSeconds': elapsed.inSeconds,
      'remainingSeconds': remaining.isNegative ? 0 : remaining.inSeconds,
      'active': _isActive,
      'starting': _isStarting,
      'paused': _isPaused,
      'live': _isActive && !_isPaused,
      'demo': !_isActive,
      'vrLaunched': _vrLaunched,
      'startedAt': _sessionStartedAt?.toIso8601String(),
      'endedAt': _sessionEndedAt?.toIso8601String(),
    };
  }

  Map<String, Object?> _comfortOptionsPayload() {
    return {
      'seatedMode': _seatedMode,
      'reducedMotion': _reducedMotion,
      'reducedParticles': _reducedParticles,
      'highContrastGuide': _highContrastGuide,
      'largerText': _largerText,
    };
  }

  void _setDisplayMode(String mode) {
    if (mode != 'patient' && mode != 'clinician') return;
    setState(() => _displayMode = mode);
    _sendSessionState();
    _sendTreeProgress();
  }

  Map<String, Object?> _metricsPayload() {
    if (_isSweepProtocol) {
      return {
        'breathingRate': _currentBreathRate,
        'resonanceSweep': _sweepPayload(),
      };
    }
    return {
      'heartRate': _heartRate,
      'rmssd': _rmssd,
      'sdnn': _sdnn,
      'stressIndex': _stressIndex,
      'coherence': _coherence,
      'signalQuality': _signalQuality,
      'breathingRate': _currentBreathRate,
      'averageCoherence': _gamification.averageCoherence,
      'bestHighCoherenceStreakSeconds': _bestHighStreakSec,
      'bestBuildingCoherenceStreakSeconds': _bestBuildingStreakSec,
      'bestPeakCoherenceStreakSeconds': _bestPeakStreakSec,
      'bestBreathSyncStreakSeconds': _bestBreathSyncStreakSec,
      'treeVitalityScore': _treeVitalityScore,
      'unlockedAmbientTier': _ambientTier,
    };
  }

  Map<String, Object?> _breathPayload() {
    return {
      'phase': _phaseLabel.toLowerCase(),
      'phaseLabel': _phaseLabel,
      'phaseProgress': _phaseProgress,
      'cycleProgress': _cycleProgress,
      'secondsRemaining': _phaseSecondsRemaining,
      'inhaleMs': _inhaleMs,
      'exhaleMs': _exhaleMs,
      'holdMs': 0,
      'emptyHoldMs': 0,
      'targetBpm': _currentBreathRate,
    };
  }

  VrSessionResult _buildSessionResult() {
    return _gamification.buildResult(
      elapsed: _sessionClock.elapsed,
      targetDuration: _targetDuration,
      finalBreathingRate: _currentBreathRate,
    );
  }

  Map<String, Object?> _sessionResultPayload({
    required VrSessionResult result,
    required VrTreeProgress progress,
    RfAssessmentResult? sweepResult,
    double? savedSweepFrequency,
  }) {
    return {
      ...result.toPayload(progressAfterSession: progress),
      'protocol': _protocol,
      if (sweepResult != null)
        'resonanceSweep': {
          ...VrResonanceSweepProtocol.resultPayload(
            sweepResult,
            appliedPatientFrequencyBpm: savedSweepFrequency,
            estimateConfirmationRequired:
                _rfReleaseAudit.patientApplicationAllowed &&
                sweepResult.mode == RfAcquisitionMode.estimated &&
                savedSweepFrequency == null,
          ),
          'releaseValidation': _rfReleaseAudit.toJson(),
        },
    };
  }

  Map<String, Object?> _sweepPayload({
    RfAssessmentResult? result,
    double? savedSweepFrequency,
  }) {
    if (result != null) {
      return VrResonanceSweepProtocol.resultPayload(
        result,
        appliedPatientFrequencyBpm: savedSweepFrequency,
        estimateConfirmationRequired:
            _rfReleaseAudit.patientApplicationAllowed &&
            result.mode == RfAcquisitionMode.estimated &&
            savedSweepFrequency == null,
      );
    }
    final polarState =
        context.read<PolarConnectProvider>().isConnected
            ? 'ready'
            : 'disconnected';
    final beltState =
        context.read<GoDirectProvider>().isConnected
            ? (_rfSnapshot?.beltSignalDetected ?? false)
                ? 'ready'
                : 'connected'
            : 'disconnected';
    final snapshot = _rfSnapshot;
    if (snapshot == null) {
      return VrResonanceSweepProtocol.idlePayload(
        polarState: polarState,
        beltState: beltState,
        status: _isStarting ? 'preflight' : 'idle',
      );
    }
    return VrResonanceSweepProtocol.livePayload(
      snapshot: snapshot,
      active: _isActive,
      polarState: polarState,
      beltState: beltState,
    );
  }

  Map<String, Object?> _treeProgressPayload({
    VrTreeProgress? progressOverride,
    VrSessionResult? result,
  }) {
    final progress = progressOverride ?? _treeProgress;
    final live = _gamification.livePayload(
      elapsed: _sessionClock.elapsed,
      targetDuration: _targetDuration,
    );
    final liveTier = _treeProgressForLivePayloadTier();
    final effectiveTier = math.max(progress.unlockedAmbientTier, liveTier);
    return {
      ...live,
      'unlockedAmbientTier': effectiveTier,
      'unlockedVisuals': VrTreeProgress.visualLayersForTier(effectiveTier),
      'progress': progress.toPayload(),
      if (result != null) 'sessionResult': result.toPayload(),
    };
  }

  int _treeProgressForLivePayloadTier() {
    final live = _gamification.livePayload(
      elapsed: _sessionClock.elapsed,
      targetDuration: _targetDuration,
    );
    final tier = live['unlockedAmbientTier'];
    return tier is num ? tier.round().clamp(0, 4).toInt() : 0;
  }

  void _recordHeartRate(int hr) {
    if (hr <= 0) return;
    _heartRateSum += hr;
    _heartRateSamples++;
    _minHeartRate = _minHeartRate == null ? hr : math.min(_minHeartRate!, hr);
    _maxHeartRate = _maxHeartRate == null ? hr : math.max(_maxHeartRate!, hr);
    _sessionHrReadings.add(hr);
  }

  Future<VrTreeProgress> _loadVrTreeProgress(int patientId) async {
    try {
      final summaries = await AppDatabase().getSessionSummaries(patientId);
      for (final summary in summaries) {
        final raw = summary.extendedMetricsJson;
        if (raw == null || raw.isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final vrTree = decoded['vrTree'];
        if (vrTree is! Map) continue;
        final parsed = VrTreeProgress.tryParse(vrTree['progressAfterSession']);
        if (parsed != null) return parsed;
      }
    } catch (_) {}
    return VrTreeProgress.initial();
  }

  Future<bool> _persistVrSessionSummary({
    required Patient? patient,
    required VrSessionResult result,
    required VrTreeProgress progress,
    RfAssessmentResult? sweepResult,
    double? savedSweepFrequency,
  }) async {
    if (patient == null || _sessionStartedAt == null) return false;
    final resultPayload = _sessionResultPayload(
      result: result,
      progress: progress,
      sweepResult: sweepResult,
      savedSweepFrequency: savedSweepFrequency,
    );
    final extendedMetrics = jsonEncode({
      'vrTree': {
        'version': 1,
        'session': resultPayload,
        'progressAfterSession': progress.toPayload(),
      },
      if (sweepResult != null)
        'resonanceSweep': {
          ...VrResonanceSweepProtocol.resultPayload(
            sweepResult,
            appliedPatientFrequencyBpm: savedSweepFrequency,
            estimateConfirmationRequired:
                _rfReleaseAudit.patientApplicationAllowed &&
                sweepResult.mode == RfAcquisitionMode.estimated &&
                savedSweepFrequency == null,
          ),
          'releaseValidation': _rfReleaseAudit.toJson(),
        },
    });

    try {
      final database = AppDatabase();
      await database.transaction(() async {
        final summaryId = await database.insertSessionSummary(
          patientId: patient.id,
          sessionType: _isSweepProtocol ? 'vr_resonance_sweep' : 'vr_resonance',
          startedAt: _sessionStartedAt!.toIso8601String(),
          endedAt: (_sessionEndedAt ?? DateTime.now()).toIso8601String(),
          durationSeconds: result.durationSeconds,
          breathRate: result.finalBreathingRate.round(),
          breathSource:
              _isSweepProtocol
                  ? 'vr_resonance_frequency_sweep'
                  : 'vr_resonance_pacer',
          avgHeartRate:
              _heartRateSamples == 0 ? null : _heartRateSum / _heartRateSamples,
          minHeartRate: _minHeartRate,
          maxHeartRate: _maxHeartRate,
          rmssd: _rmssd > 0 ? _rmssd : null,
          sdnn: _sdnn > 0 ? _sdnn : null,
          hrReadingsJson:
              _sessionHrReadings.isEmpty
                  ? null
                  : jsonEncode(_sessionHrReadings),
          extendedMetricsJson: extendedMetrics,
        );
        final controller = _rfController;
        if (sweepResult != null && controller != null) {
          await RfAssessmentPersistenceService(database).persist(
            patientId: patient.id,
            surface: 'vr',
            startedAt: _sessionStartedAt!,
            endedAt: _sessionEndedAt ?? DateTime.now(),
            protocol: controller.protocol,
            result: sweepResult,
            rrSamples: controller.rrSamples,
            respirationSamples: controller.respirationSamples,
            completedCycles: controller.snapshot.cycleCount,
            appliedToPatient: savedSweepFrequency != null,
            estimateConfirmed: null,
            sessionSummaryId: summaryId,
            useTransaction: false,
            releaseAudit: _rfReleaseAudit,
          );
        }
      });
      return true;
    } catch (e) {
      _sendError('Could not save VR session summary: ${_friendlyError(e)}');
      return false;
    }
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '');
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = math.max(duration.inSeconds, 0);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _launchVr() async {
    final bridge = _bridge;
    if (bridge == null || !bridge.isSupported) return;
    var startedBackgroundSession = false;
    try {
      if (!kIsWeb && !_ownsBackgroundSession) {
        await BackgroundSessionService.start(
          reason: 'VR biofeedback is streaming to Meta Quest Browser',
          usesConnectedDevice: true,
        );
        _ownsBackgroundSession = true;
        startedBackgroundSession = true;
      }
      await bridge.launchVrWindow();
      if (!mounted) return;
      setState(() {
        _vrLaunched = true;
        _error = null;
      });
      _sendSessionState();
    } catch (error) {
      if (startedBackgroundSession) {
        _ownsBackgroundSession = false;
        await BackgroundSessionService.stop();
      }
      if (!mounted) return;
      setState(
        () =>
            _error =
                'Could not open Meta Quest Browser: ${_friendlyError(error)}',
      );
    }
  }

  Color _statusColor() {
    if (_error != null) return AppTheme.coralRose;
    if (_isActive && !_isPaused) return AppTheme.emerald;
    if (_isPaused) return Colors.amber;
    return AppTheme.softSage;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = Responsive.horizontalPadding(context);

    if (!(_bridge?.isSupported ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('VR Biofeedback')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_in_ar_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'VR Biofeedback is available in a WebXR browser.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the web build or install the Android app on a Meta Quest headset.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppTheme.darkBackgroundGradient
                  : AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                sliver: SliverToBoxAdapter(
                  child: ContentContainer(
                    child: _Header(
                      elapsed: _elapsed,
                      isActive: _isActive,
                      isPaused: _isPaused,
                      onBack: () async {
                        final navigator = Navigator.of(context);
                        if (_isActive || _isStarting) {
                          await _stop(sendResult: false);
                        }
                        if (mounted) navigator.pop();
                      },
                    ),
                  ),
                ),
              ),
              if (_error != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                  sliver: SliverToBoxAdapter(
                    child: ContentContainer(
                      child: _StatusBanner(
                        text: _error!,
                        color: AppTheme.coralRose,
                        icon: Icons.error_outline_rounded,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 0),
                sliver: SliverToBoxAdapter(
                  child: ContentContainer(
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _statusColor().withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.view_in_ar_rounded,
                                  color: _statusColor(),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'VR Resonance Session',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isActive
                                          ? _isPaused
                                              ? 'Session paused - VR can resume it'
                                              : 'Live and synchronized with VR'
                                          : 'Launch VR first or start from here',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              BreathingSoundToggle(
                                compact: true,
                                onCueSettingsChanged:
                                    _replayCurrentBreathingCue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _SessionControls(
                            isActive: _isActive,
                            isStarting: _isStarting,
                            isPaused: _isPaused,
                            vrLaunched: _vrLaunched,
                            targetDuration: _targetDuration,
                            durationOptionsMinutes: _durationOptionsMinutes,
                            protocol: _protocol,
                            currentRate: _currentBreathRate,
                            phaseLabel: _phaseLabel,
                            phaseSecondsRemaining: _phaseSecondsRemaining,
                            remaining: _remaining,
                            onProtocolChanged:
                                _isActive
                                    ? null
                                    : (protocol) => _setProtocol(protocol),
                            onDurationChanged:
                                _isActive || _isSweepProtocol
                                    ? null
                                    : (minutes) => _setDuration(
                                      Duration(minutes: minutes),
                                    ),
                            onStart: _start,
                            onPause: _pause,
                            onResume: _resume,
                            onStop: () => unawaited(_stop()),
                            onLaunchVr: _launchVr,
                          ),
                          const SizedBox(height: 16),
                          _VrComfortPanel(
                            displayMode: _displayMode,
                            onDisplayModeChanged: _setDisplayMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                sliver: SliverToBoxAdapter(
                  child: ContentContainer(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _statusColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isActive
                                    ? _isPaused
                                        ? 'Paused'
                                        : 'Streaming to WebXR'
                                    : 'WebXR bridge ready',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const Spacer(),
                              Text(
                                'Last VR command: $_lastCommand',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isSweepProtocol) ...[
                            Row(
                              children: [
                                _LiveMetric(
                                  label: 'Cycle',
                                  value:
                                      _rfSnapshot == null
                                          ? '--'
                                          : '${_rfSnapshot!.cycleIndex + 1}',
                                  unit: 'of 78',
                                  color: AppTheme.emerald,
                                ),
                                const SizedBox(width: 10),
                                _LiveMetric(
                                  label: 'Rate',
                                  value: _currentBreathRate.toStringAsFixed(2),
                                  unit: 'BPM',
                                  color: AppTheme.softSage,
                                ),
                                const SizedBox(width: 10),
                                _LiveMetric(
                                  label: 'Packets',
                                  value: '$_dataSent',
                                  unit: 'sent',
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_rfSnapshot?.mode == RfAcquisitionMode.measured ? 'Measured RF' : 'Estimated RF'} | '
                              'Polar ${_rfSnapshot?.polarReady == true ? 'ready' : 'checking'} | '
                              'GDX-RB ${_rfSnapshot?.beltSignalDetected == true ? 'ready' : 'not used'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                _LiveMetric(
                                  label: 'HR',
                                  value: _heartRate <= 0 ? '--' : '$_heartRate',
                                  unit: 'bpm',
                                  color: AppTheme.dustyRose,
                                ),
                                const SizedBox(width: 10),
                                _LiveMetric(
                                  label: 'Coherence',
                                  value:
                                      _coherence <= 0
                                          ? '--'
                                          : '${_coherence.round()}',
                                  unit: '%',
                                  color:
                                      _coherence >= 70
                                          ? AppTheme.emerald
                                          : _coherence >= 40
                                          ? Colors.amber
                                          : AppTheme.coralRose,
                                ),
                                const SizedBox(width: 10),
                                _LiveMetric(
                                  label: 'Rate',
                                  value: _currentBreathRate.toStringAsFixed(1),
                                  unit: 'BPM',
                                  color: AppTheme.softSage,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _LiveMetric(
                                  label: 'RMSSD',
                                  value:
                                      _rmssd <= 0
                                          ? '--'
                                          : _rmssd.toStringAsFixed(1),
                                  unit: 'ms',
                                  color: AppTheme.emerald,
                                ),
                                const SizedBox(width: 10),
                                _LiveMetric(
                                  label: 'SDNN',
                                  value:
                                      _sdnn <= 0
                                          ? '--'
                                          : _sdnn.toStringAsFixed(1),
                                  unit: 'ms',
                                  color: Colors.lightBlueAccent,
                                ),
                                const SizedBox(width: 10),
                                _LiveMetric(
                                  label: 'Packets',
                                  value: '$_dataSent',
                                  unit: 'sent',
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Signal quality: $_signalQuality | Tree vitality: ${_treeVitalityScore.round()}% | Tier $_ambientTier',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Best streaks: 40+ ${_bestBuildingStreakSec}s | 70+ ${_bestHighStreakSec}s | 85+ ${_bestPeakStreakSec}s | sync ${_bestBreathSyncStreakSec}s',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!_isActive && _lastSessionResult != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                  sliver: SliverToBoxAdapter(
                    child: ContentContainer(
                      child: _SessionResultCard(
                        result: _lastSessionResult!,
                        progress: _treeProgress,
                        sweepResult: _lastSweepResult,
                      ),
                    ),
                  ),
                ),
              if (!_isActive)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                  sliver: SliverToBoxAdapter(
                    child: ContentContainer(
                      child: Consumer<PolarConnectProvider>(
                        builder: (context, polar, _) {
                          if (polar.hasDevice) {
                            return const SizedBox.shrink();
                          }
                          return const _StatusBanner(
                            text:
                                'Connect a Polar device in Settings before starting a live VR session. The VR scene still opens in demo mode.',
                            color: Colors.amber,
                            icon: Icons.bluetooth_disabled_rounded,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: Responsive.bottomListPadding(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isActive;
  final bool isPaused;
  final String elapsed;
  final Future<void> Function() onBack;

  const _Header({
    required this.isActive,
    required this.isPaused,
    required this.elapsed,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => unawaited(onBack()),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VR Biofeedback',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (isActive)
                Text(
                  isPaused ? 'Paused - $elapsed' : 'Running - $elapsed',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPaused ? Colors.amber : AppTheme.emerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionResultCard extends StatelessWidget {
  final VrSessionResult result;
  final VrTreeProgress progress;
  final RfAssessmentResult? sweepResult;

  const _SessionResultCard({
    required this.result,
    required this.progress,
    this.sweepResult,
  });

  @override
  Widget build(BuildContext context) {
    final delta = result.vitalityDelta;
    final deltaText =
        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} vitality';
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.park_rounded,
                  color: AppTheme.emerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'VR Session Result',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'Tier ${progress.unlockedAmbientTier}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.emerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LiveMetric(
                label: 'Duration',
                value: _formatSeconds(result.durationSeconds),
                unit: '',
                color: AppTheme.softSage,
              ),
              const SizedBox(width: 10),
              _LiveMetric(
                label: 'Avg coherence',
                value: result.averageCoherence.round().toString(),
                unit: '%',
                color: AppTheme.emerald,
              ),
              const SizedBox(width: 10),
              _LiveMetric(
                label: 'Vitality',
                value: progress.treeVitality.round().toString(),
                unit: '%',
                color: delta >= 0 ? AppTheme.emerald : AppTheme.coralRose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Best 70+ streak: ${result.bestHighCoherenceStreakSeconds}s | Breath sync: ${result.bestBreathSyncStreakSeconds}s | $deltaText',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (sweepResult != null) ...[
            const SizedBox(height: 6),
            Text(
              'Precise RF: '
              '${sweepResult!.rfBpm?.toStringAsFixed(2) ?? 'invalid'} BPM | '
              '${sweepResult!.mode.name} | '
              '${sweepResult!.quality.passed ? 'quality passed' : 'quality warnings'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.clinicalTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            result.recommendation,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static String _formatSeconds(int seconds) {
    final duration = Duration(seconds: math.max(0, seconds));
    final minutes = duration.inMinutes;
    final remainder = duration.inSeconds.remainder(60);
    return minutes > 0 ? '${minutes}m' : '${remainder}s';
  }
}

class _VrComfortPanel extends StatelessWidget {
  final String displayMode;
  final ValueChanged<String> onDisplayModeChanged;

  const _VrComfortPanel({
    required this.displayMode,
    required this.onDisplayModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeValue = displayMode == 'clinician' ? 'clinician' : 'patient';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VR Display',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'patient',
              label: Text('Patient'),
              icon: Icon(Icons.self_improvement_rounded),
            ),
            ButtonSegment(
              value: 'clinician',
              label: Text('Clinician'),
              icon: Icon(Icons.monitor_heart_rounded),
            ),
          ],
          selected: {modeValue},
          onSelectionChanged: (values) => onDisplayModeChanged(values.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

class _SessionControls extends StatelessWidget {
  final bool isActive;
  final bool isStarting;
  final bool isPaused;
  final bool vrLaunched;
  final Duration targetDuration;
  final List<int> durationOptionsMinutes;
  final String protocol;
  final double currentRate;
  final String phaseLabel;
  final int phaseSecondsRemaining;
  final String remaining;
  final ValueChanged<String>? onProtocolChanged;
  final ValueChanged<int>? onDurationChanged;
  final Future<void> Function() onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onLaunchVr;

  const _SessionControls({
    required this.isActive,
    required this.isStarting,
    required this.isPaused,
    required this.vrLaunched,
    required this.targetDuration,
    required this.durationOptionsMinutes,
    required this.protocol,
    required this.currentRate,
    required this.phaseLabel,
    required this.phaseSecondsRemaining,
    required this.remaining,
    required this.onProtocolChanged,
    required this.onDurationChanged,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onLaunchVr,
  });

  @override
  Widget build(BuildContext context) {
    final durationMinutes = targetDuration.inMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: protocol,
                items: const [
                  DropdownMenuItem<String>(
                    value: VrBreathingProtocol.resonanceBreathing,
                    child: Text('Resonance'),
                  ),
                  DropdownMenuItem<String>(
                    value: VrBreathingProtocol.resonanceSweep,
                    child: Text('Precise RF (78 breaths)'),
                  ),
                ],
                onChanged:
                    onProtocolChanged == null
                        ? null
                        : (value) {
                          if (value != null) onProtocolChanged!(value);
                        },
                decoration: const InputDecoration(
                  labelText: 'Protocol',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                label: 'Target',
                value: '${currentRate.toStringAsFixed(1)} BPM',
                color: AppTheme.softSage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue:
                    durationOptionsMinutes.contains(durationMinutes)
                        ? durationMinutes
                        : durationOptionsMinutes.first,
                items:
                    durationOptionsMinutes
                        .map(
                          (minutes) => DropdownMenuItem<int>(
                            value: minutes,
                            child: Text('$minutes min'),
                          ),
                        )
                        .toList(),
                onChanged:
                    onDurationChanged == null
                        ? null
                        : (value) {
                          if (value != null) onDurationChanged!(value);
                        },
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                label: phaseLabel,
                value:
                    isActive && !isPaused
                        ? '${phaseSecondsRemaining}s'
                        : remaining,
                color: isPaused ? Colors.amber : AppTheme.clinicalTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    isActive || isStarting ? null : () => unawaited(onStart()),
                icon:
                    isStarting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.play_arrow_rounded),
                label: Text(isStarting ? 'Starting' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isActive ? (isPaused ? onResume : onPause) : null,
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(isPaused ? 'Resume' : 'Pause'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isActive || isStarting ? onStop : null,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.coralRose,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onLaunchVr,
                icon: const Icon(Icons.view_in_ar_rounded),
                label: Text(vrLaunched ? 'Re-open VR' : 'Launch VR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.softSage,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _StatusBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _LiveMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _LiveMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.5,
                ),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 10,
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
