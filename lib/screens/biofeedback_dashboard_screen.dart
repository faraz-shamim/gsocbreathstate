library;

import 'dart:async';

import 'package:breath_state/providers/app_mode_provider.dart';
import 'package:breath_state/providers/breathing_sound_provider.dart';
import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/services/biofeedback/adaptive_breathing_controller.dart';
import 'package:breath_state/services/biofeedback/realtime_hrv_engine.dart';
import 'package:breath_state/services/biofeedback/sensor_synchronizer.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/adaptive_breathing_bubble.dart';
import 'package:breath_state/widgets/breathing_sound_toggle.dart';
import 'package:breath_state/widgets/clinical_primitives.dart';
import 'package:breath_state/widgets/dual_waveform_chart.dart';
import 'package:breath_state/widgets/realtime_hrv_gauges.dart';
import 'package:breath_state/widgets/result_card_primitives.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class BiofeedbackDashboardScreen extends StatefulWidget {
  const BiofeedbackDashboardScreen({super.key});

  @override
  State<BiofeedbackDashboardScreen> createState() =>
      _BiofeedbackDashboardScreenState();
}

class _BiofeedbackDashboardScreenState
    extends State<BiofeedbackDashboardScreen> {
  late final RealtimeHrvEngine _hrvEngine;
  late final Stream<double> _coherenceStream;
  late final BreathingSoundProvider _soundGuide;
  final SensorSynchronizer _sensorSynchronizer = SensorSynchronizer();
  AdaptiveBreathingController? _breathController;

  StreamSubscription<int>? _hrSub;
  StreamSubscription<double>? _beltSub;
  StreamSubscription<AdaptiveBreathingState>? _breathStateSub;

  final List<double> _respBuffer = [];
  static const int _maxRespSamples = 300;

  bool _isActive = false;
  bool _isStarting = false;
  bool _audioSessionActive = false;
  bool _hasBelt = false;
  String? _errorMessage;
  int _rrProcessedCount = 0;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _displayTimer;
  String _elapsedDisplay = '00:00';

  @override
  void initState() {
    super.initState();
    _soundGuide = context.read<BreathingSoundProvider>();
    _hrvEngine = RealtimeHrvEngine(
      windowDurationSec: 60,
      updateIntervalMs: 5000,
    );
    _coherenceStream = _hrvEngine.snapshots.map(
      (snapshot) => snapshot.coherence,
    );
  }

  @override
  void dispose() {
    unawaited(_stop());
    _hrvEngine.dispose();
    _breathController?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_isActive || _isStarting) return;
    final polarProvider = context.read<PolarConnectProvider>();
    final gdProvider = context.read<GoDirectProvider>();
    final patient = context.read<PatientProvider>().activePatient;
    if (!kIsWeb) WakelockPlus.enable();
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });
    await _soundGuide.prepareForSession();
    if (!mounted) {
      if (!kIsWeb) WakelockPlus.disable();
      return;
    }

    final unified = polarProvider.getPolarConnect();
    if (unified == null) {
      if (!kIsWeb) WakelockPlus.disable();
      setState(() {
        _isStarting = false;
        _errorMessage = 'Connect a Polar device first.';
      });
      return;
    }

    final double resonanceRate =
        patient?.resonanceFrequency ?? ResonanceFrequency.userResonanceFreq;
    final double initialRate = (resonanceRate > 0) ? resonanceRate : 6.0;

    try {
      final hrStream = await unified.getHeartRate();
      final broadcastHR = hrStream.asBroadcastStream();

      _rrProcessedCount = 0;
      _hrvEngine.reset();
      _sensorSynchronizer.clear();
      _hrvEngine.setBreathingRateBpm(initialRate);
      _hrvEngine.start();

      _breathController?.dispose();
      _breathController = AdaptiveBreathingController(
        hrvEngine: _hrvEngine,
        initialRateBpm: initialRate,
      );
      _breathController!.start();
      _breathStateSub = _breathController!.stateStream.listen((state) {
        _hrvEngine.setBreathingRateBpm(state.currentRateBpm);
      });

      _hrSub = broadcastHR.listen(
        (_) {
          final rrIntervals = unified.sessionRrIntervals;
          if (rrIntervals.length > _rrProcessedCount) {
            for (int i = _rrProcessedCount; i < rrIntervals.length; i++) {
              _hrvEngine.addRR(rrIntervals[i]);
              _sensorSynchronizer.addRrInterval(rrIntervals[i]);
            }
            _rrProcessedCount = rrIntervals.length;
            _hrvEngine.forceUpdate();
          }
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(
            () =>
                _errorMessage =
                    'Polar stream stopped: ${_friendlyError(error)}',
          );
        },
      );
    } catch (e) {
      await _hrSub?.cancel();
      _hrSub = null;
      _hrvEngine.stop();
      _breathController?.stop();
      try {
        await unified.stopRecording();
      } catch (_) {}
      if (!kIsWeb) WakelockPlus.disable();
      if (mounted) {
        setState(() {
          _isStarting = false;
          _isActive = false;
          _errorMessage = 'Failed to start Polar stream: ${_friendlyError(e)}';
        });
      }
      return;
    }

    if (gdProvider.isConnected) {
      try {
        await gdProvider.startMeasurements(sensorNumbers: [1], periodMs: 100);
        _hasBelt = true;
        _respBuffer.clear();
        _beltSub = gdProvider.respirationForceStream.listen((v) {
          _sensorSynchronizer.addRespiration(v);
          _respBuffer.add(v);
          if (_respBuffer.length > _maxRespSamples) {
            _respBuffer.removeRange(0, _respBuffer.length - _maxRespSamples);
          }
        });
      } catch (_) {
        _hasBelt = false;
      }
    }

    await _soundGuide.beginSession();
    _audioSessionActive = true;

    _stopwatch.reset();
    _stopwatch.start();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = _stopwatch.elapsed;
      setState(() {
        _elapsedDisplay =
            '${elapsed.inMinutes.toString().padLeft(2, '0')}:'
            '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });

    setState(() {
      _isActive = true;
      _isStarting = false;
      _errorMessage = null;
    });
  }

  Future<void> _stop() async {
    final gdProvider = context.read<GoDirectProvider>();
    final polarProvider = context.read<PolarConnectProvider>();

    _stopwatch.stop();
    _displayTimer?.cancel();

    _hrSub?.cancel();
    _hrSub = null;
    _beltSub?.cancel();
    _beltSub = null;
    _breathStateSub?.cancel();
    _breathStateSub = null;

    _hrvEngine.stop();
    _breathController?.stop();
    _rrProcessedCount = 0;

    if (_audioSessionActive) {
      _audioSessionActive = false;
      await _soundGuide.endSession();
    }

    if (_hasBelt && gdProvider.isStreaming) {
      await gdProvider.stopMeasurements();
    }
    _hasBelt = false;

    final unified = polarProvider.getPolarConnect();
    if (unified != null) {
      try {
        await unified.stopRecording();
      } catch (_) {}
    }

    if (!kIsWeb) WakelockPlus.disable();

    if (mounted) {
      setState(() {
        _isActive = false;
        _isStarting = false;
      });
    }
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '');
  }

  Color _coherenceColor(double? coherence) {
    if (coherence == null) return AppTheme.clinicalCyan;
    if (coherence >= 70) return AppTheme.signalGood;
    if (coherence >= 40) return AppTheme.signalWarn;
    return AppTheme.signalBad;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = Responsive.horizontalPadding(context);
    final isClinician = context.watch<AppModeProvider>().isClinician;

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
                    child: _SessionHeader(
                      isActive: _isActive,
                      isStarting: _isStarting,
                      isClinician: isClinician,
                      elapsedDisplay: _elapsedDisplay,
                      onBack: () {
                        if (_isActive) _stop();
                        Navigator.of(context).pop();
                      },
                      onToggle:
                          _isStarting
                              ? null
                              : () {
                                if (_isActive) {
                                  _stop();
                                } else {
                                  _start();
                                }
                              },
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                  sliver: SliverToBoxAdapter(
                    child: ContentContainer(
                      child: InsightBanner(
                        text: _errorMessage!,
                        color: AppTheme.signalBad,
                        isDark: isDark,
                        icon: Icons.error_outline_rounded,
                      ),
                    ),
                  ),
                ),
              if (_isActive && !isClinician)
                ..._patientSlivers(hPad)
              else if (_isActive)
                ..._clinicianSlivers(hPad)
              else
                ..._idleSlivers(hPad),
              SliverToBoxAdapter(
                child: SizedBox(height: Responsive.bottomListPadding(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _patientSlivers(double hPad) {
    return [
      if (_breathController != null)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
          sliver: SliverToBoxAdapter(
            child: ContentContainer(
              child: ClinicalPanel(
                padding: const EdgeInsets.all(16),
                radius: AppTheme.radiusXl,
                tint: AppTheme.clinicalTeal,
                elevated: true,
                child: AdaptiveBreathingBubble(
                  stateStream: _breathController!.stateStream,
                  coherenceStream: _coherenceStream,
                  initialInhaleMs: _breathController!.inhaleMs,
                  initialExhaleMs: _breathController!.exhaleMs,
                ),
              ),
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
        sliver: SliverToBoxAdapter(
          child: ContentContainer(
            child: StreamBuilder<RealtimeHrvSnapshot>(
              stream: _hrvEngine.snapshots,
              builder: (context, snapshot) {
                final coherence = snapshot.data?.coherence;
                return ClinicalPanel(
                  padding: const EdgeInsets.all(18),
                  tint: _coherenceColor(coherence),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coherence response',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              coherence == null
                                  ? 'Collecting a clean rolling window.'
                                  : coherence >= 70
                                  ? 'Stable phase-lock response.'
                                  : coherence >= 40
                                  ? 'Keep the rhythm gentle.'
                                  : 'Signal is still settling.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        coherence == null ? '--' : coherence.round().toString(),
                        style: AppTheme.monoNumeral(
                          color: _coherenceColor(coherence),
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
        sliver: SliverToBoxAdapter(
          child: ContentContainer(
            child: StreamBuilder<RealtimeHrvSnapshot>(
              stream: _hrvEngine.snapshots,
              builder: (context, snapshot) {
                final data = snapshot.data;
                return DualWaveformChart(
                  rrIntervals: data?.windowRRs ?? const [],
                  sqiResults: data?.sqiResults ?? const [],
                  respirationValues: List<double>.from(_respBuffer),
                  height: _hasBelt ? 254 : 212,
                );
              },
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _clinicianSlivers(double hPad) {
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
        sliver: SliverToBoxAdapter(
          child: ContentContainer(
            child: ClinicalPanel(
              padding: const EdgeInsets.all(16),
              tint: AppTheme.clinicalCyan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClinicalSectionHeader(
                    eyebrow: 'Clinician mode',
                    title: 'Instrumentation view',
                    trailing: SignalQualityLegend(
                      compact: MediaQuery.sizeOf(context).width < 420,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RR intervals, respiration, SQI bands, and adaptive controller state are shown for review without changing the underlying recording pipeline.',
                    style: Theme.of(context).textTheme.bodySmall,
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
            child: StreamBuilder<RealtimeHrvSnapshot>(
              stream: _hrvEngine.snapshots,
              builder: (context, snapshot) {
                final data = snapshot.data;
                return DualWaveformChart(
                  rrIntervals: data?.windowRRs ?? const [],
                  sqiResults: data?.sqiResults ?? const [],
                  respirationValues: List<double>.from(_respBuffer),
                  height: _hasBelt ? 286 : 228,
                );
              },
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
        sliver: SliverToBoxAdapter(
          child: ContentContainer(
            child: RealtimeHrvGauges(snapshotStream: _hrvEngine.snapshots),
          ),
        ),
      ),
      if (_breathController != null)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
          sliver: SliverToBoxAdapter(
            child: ContentContainer(
              child: ClinicalPanel(
                padding: const EdgeInsets.all(16),
                tint: AppTheme.clinicalTeal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ClinicalSectionHeader(
                      eyebrow: 'Adaptive controller',
                      title: 'Pacing guide',
                    ),
                    const SizedBox(height: 12),
                    AdaptiveBreathingBubble(
                      stateStream: _breathController!.stateStream,
                      coherenceStream: _coherenceStream,
                      initialInhaleMs: _breathController!.inhaleMs,
                      initialExhaleMs: _breathController!.exhaleMs,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _idleSlivers(double hPad) {
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 0),
        sliver: SliverToBoxAdapter(
          child: ContentContainer(
            child: ClinicalPanel(
              padding: const EdgeInsets.all(20),
              radius: AppTheme.radiusXl,
              tint: AppTheme.clinicalTeal,
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ClinicalSectionHeader(
                    eyebrow: 'Protocol cockpit',
                    title: 'Real-time biofeedback',
                    trailing: ClinicalStatusPill(
                      label: 'Idle',
                      color: AppTheme.clinicalCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start a Polar H10 session to monitor RR intervals, respiration, coherence, and adaptive pacing in one clinical workflow.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Consumer2<PolarConnectProvider, GoDirectProvider>(
                    builder: (context, polar, gdProvider, _) {
                      final polarConnected = polar.getPolarConnect() != null;
                      return Column(
                        children: [
                          _ReadinessRow(
                            label: 'Polar H10',
                            value: polarConnected ? 'Ready' : 'Required',
                            color:
                                polarConnected
                                    ? AppTheme.signalGood
                                    : AppTheme.signalBad,
                          ),
                          const SizedBox(height: 8),
                          _ReadinessRow(
                            label: 'Respiration belt',
                            value:
                                gdProvider.isConnected || gdProvider.isStreaming
                                    ? 'Resp belt on'
                                    : 'Resp belt off',
                            color:
                                gdProvider.isConnected || gdProvider.isStreaming
                                    ? AppTheme.signalGood
                                    : AppTheme.signalBad,
                          ),
                          const SizedBox(height: 8),
                          const _ReadinessRow(
                            label: 'Adaptive pacing',
                            value: '5-7 BPM',
                            color: AppTheme.clinicalTeal,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

class _SessionHeader extends StatelessWidget {
  final bool isActive;
  final bool isStarting;
  final bool isClinician;
  final String elapsedDisplay;
  final VoidCallback onBack;
  final VoidCallback? onToggle;

  const _SessionHeader({
    required this.isActive,
    required this.isStarting,
    required this.isClinician,
    required this.elapsedDisplay,
    required this.onBack,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicalPanel(
      padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClinician ? 'Clinician biofeedback' : 'Live biofeedback',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  isActive
                      ? 'Session running - $elapsedDisplay'
                      : 'Polar H10 required to start',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const BreathingSoundToggle(compact: true),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: onToggle,
            icon:
                isStarting
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(
                      isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    ),
            label: Text(
              isStarting
                  ? 'Starting'
                  : isActive
                  ? 'Stop'
                  : 'Start',
            ),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isActive ? AppTheme.signalBad : AppTheme.clinicalTeal,
              foregroundColor:
                  isActive ? AppTheme.pureWhite : AppTheme.graphite,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReadinessRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClinicalStatusPill(label: value, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
