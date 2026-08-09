import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/app_mode_provider.dart';
import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/screens/biofeedback_dashboard_screen.dart';
import 'package:breath_state/screens/quick_rf_assessment_screen.dart';
import 'package:breath_state/screens/rf_assessment_screen.dart';
import 'package:breath_state/screens/session_history_page.dart';
import 'package:breath_state/screens/vr_biofeedback_screen.dart';
import 'package:breath_state/services/background/background_session_service.dart';
import 'package:breath_state/services/breath_rate/belt_breath_rate.dart';
import 'package:breath_state/services/breath_rate/record.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/ecg_respiration/realtime_ecg_rpeak_detector.dart';
import 'package:breath_state/services/ecg_respiration/realtime_ecg_respiration_tracker.dart';
import 'package:breath_state/services/hrv_analysis/hrv_derived_breathing_rate.dart';
import 'package:breath_state/services/hrv_analysis/realtime_breath_rate_tracker.dart';
import 'package:breath_state/services/hrv_analysis/hrv_frequency_domain.dart';
import 'package:breath_state/services/hrv_analysis/hrv_rsa.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/animated_entrance.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:breath_state/widgets/hrv_frequency_result_card.dart';
import 'package:breath_state/widgets/hrv_result_card.dart';
import 'package:breath_state/widgets/hrv_rsa_result_card.dart';
import 'package:breath_state/widgets/psychophysiological_result_card.dart';
import 'package:breath_state/widgets/respiration_waveform_card.dart';
import 'package:breath_state/widgets/session_history_card.dart';
import 'package:breath_state/services/hrv_analysis/hrv_psychophysiological_indices.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  SoundRecorder? _recorder;
  Stream<int>? _hrStream;
  StreamSubscription<List<UnifiedEcgSample>>? _ecgSub;
  StreamSubscription<List<UnifiedAccSample>>? _accSub;
  late AnimationController _pulseController;
  final _ecgSweepController = _EcgSweepController();

  bool isRecordingHR = false;
  bool isRecordingBR = false;
  bool _isStartingRecording = false;
  int breathingRate = -2;
  double? _breathRateConfidence;
  bool _isEcgStreaming = false;
  String? _ecgStatus;
  bool _ecgHasSamples = false;
  bool _ecgStartRequested = false;
  int _ecgSampleIndex = 0;

  bool _beltActiveForSession = false;
  bool _polarOnlyBR = false;
  String _breathSource = 'Microphone';
  final List<double> _beltForceValues = [];
  StreamSubscription<double>? _beltSub;
  Timer? _beltBreathTimer;
  DateTime? _beltStartTime;
  bool _breathRatePersisted = false;
  Timer? _liveBreathRateTimer;
  RealtimeBreathRateTracker? _breathRateTracker;
  RealtimeEcgRespirationTracker? _ecgRespirationTracker;
  EcgBreathRateSnapshot? _lastEcgBreathSnapshot;
  RealtimeEcgRPeakDetector? _ecgRPeakDetector;
  int _lastRrFedIndex = 0;
  String? _lastLiveRrSource;
  double? _ecgDerivedBpm;
  double? _ecgDerivedLastRrMs;
  int _ecgRPeakCount = 0;

  final List<double> _breathingAmplitudes = [];
  double _breathingSamplingRateHz = 25.0;
  StreamSubscription<double>? _breathingAmplitudeSubscription;

  int? _currentSessionId;
  String? _currentSessionStartedAt;
  StreamSubscription<int>? _hrStorageSub;
  final List<int> _sessionHrReadings = [];

  List<SessionSummary> _sessionHistory = [];
  bool _historyLoaded = false;
  bool _isOpeningResonanceTrainer = false;

  bool get _usesWebWindowsUi =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _pulseController.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshHistory());
  }

  Future<void> _refreshHistory() async {
    final pid = _activePatientId;
    if (pid == null) {
      if (mounted)
        setState(() {
          _sessionHistory = [];
          _historyLoaded = true;
        });
      return;
    }
    try {
      final list = await AppDatabase().getSessionSummaries(pid);
      if (mounted)
        setState(() {
          _sessionHistory = list;
          _historyLoaded = true;
        });
    } catch (e) {
      developer.log('Error loading session history: $e');
      if (mounted) setState(() => _historyLoaded = true);
    }
  }

  Future<void> _saveSessionSummary({
    required int patientId,
    required String startedAt,
    String? endedAt,
    int? breathRateVal,
    String? breathSourceVal,
    HrvTimeDomainResult? hrvResult,
    HrvFrequencyDomainResult? freqResult,
    HrvRsaResult? rsaResult,
    PsychophysiologicalResult? psychResult,
  }) async {
    final start = DateTime.tryParse(startedAt);
    final end = endedAt != null ? DateTime.tryParse(endedAt) : DateTime.now();
    final durSec =
        (start != null && end != null) ? end.difference(start).inSeconds : 0;

    double? avgHr;
    int? minHr, maxHr;
    if (_sessionHrReadings.isNotEmpty) {
      final sum = _sessionHrReadings.fold<int>(0, (a, b) => a + b);
      avgHr = sum / _sessionHrReadings.length;
      minHr = _sessionHrReadings.reduce((a, b) => a < b ? a : b);
      maxHr = _sessionHrReadings.reduce((a, b) => a > b ? a : b);
    }

    String? hrJson;
    if (_sessionHrReadings.isNotEmpty) {
      hrJson = jsonEncode(_sessionHrReadings);
    }

    final extMap = <String, dynamic>{};
    if (hrvResult != null) {
      extMap['timeDomain'] = hrvResult.toMap();
    }
    if (freqResult != null) {
      extMap['freq'] = {
        ...freqResult.toNeuroKitMap(),
        'lfPower': freqResult.lf.absolutePower,
        'hfPower': freqResult.hf.absolutePower,
        'ulfPower': freqResult.ulf.absolutePower,
        'vlfPower': freqResult.vlf.absolutePower,
        'vhfPower': freqResult.vhf.absolutePower,
        'totalPower': freqResult.totalPower,
        'lfHfRatio':
            freqResult.lfHfRatio.isFinite ? freqResult.lfHfRatio : null,
        'ulfPeak': freqResult.ulf.peakFrequency,
        'vlfPeak': freqResult.vlf.peakFrequency,
        'lfPeak': freqResult.lf.peakFrequency,
        'hfPeak': freqResult.hf.peakFrequency,
        'vhfPeak': freqResult.vhf.peakFrequency,
        'method': freqResult.method.name,
        'interpolationRate': freqResult.interpolationRate,
        'durationWarning': freqResult.durationWarning,
        'allMetrics': _serializeMetricGroups(freqResult.allBandMetrics()),
      };
    }
    if (rsaResult != null) {
      extMap['rsa'] = {
        ...rsaResult.toNeuroKitMap(),
        'hrvBreathRate': rsaResult.hrvDerivedBreathRateBpm,
        'hrvBreathConfidence': rsaResult.hrvBreathRateConfidence,
        'hrvBreathPeakHz': rsaResult.hrvBreathRatePeakHz,
        'p2tMean': rsaResult.p2tMean,
        'p2tMeanLog': rsaResult.p2tMeanLog,
        'p2tSd': rsaResult.p2tSd,
        'p2tNoRsa': rsaResult.p2tNoRsa,
        'porgesBohrer': rsaResult.porgesBohrer,
        'gatesMean': rsaResult.gatesMean,
        'gatesMeanLog': rsaResult.gatesMeanLog,
        'gatesSd': rsaResult.gatesSd,
        'breathCycleCount': rsaResult.breathCycleCount,
        'respiratoryBreathRate': rsaResult.respiratoryBreathRateBpm,
        'warning': rsaResult.warning,
        'allMetrics': _serializeMetricGroups(rsaResult.allMetrics()),
      };
    }
    if (psychResult != null) {
      extMap['psych'] = {
        ...psychResult.toExportMap(),
        'stressIndex': psychResult.stressIndex.value,
        'stressLevel': psychResult.stressIndex.interpretation,
        'autonomicBalance': psychResult.autonomicBalance.value,
        'autonomicLevel': psychResult.autonomicBalance.interpretation,
        'parasympatheticTone': psychResult.parasympatheticTone.value,
        'parasympatheticLevel': psychResult.parasympatheticTone.interpretation,
        'relaxationScore': psychResult.relaxationScore.value,
        'relaxationLevel': psychResult.relaxationScore.interpretation,
        'mo': psychResult.mo,
        'amo': psychResult.amo,
        'mxdmn': psychResult.mxdmn,
        'meanHeartRateBpm': psychResult.meanHeartRateBpm,
        'rmssd': psychResult.rmssd,
        'hfPower': psychResult.hfPower,
        'lfHfRatio': psychResult.lfHfRatio,
        'warning': psychResult.warning,
        'allMetrics': _serializeMetricGroups(psychResult.allMetrics()),
      };
    }
    final extJson = extMap.isNotEmpty ? jsonEncode(extMap) : null;

    await AppDatabase().insertSessionSummary(
      patientId: patientId,
      startedAt: startedAt,
      endedAt: endedAt ?? DateTime.now().toIso8601String(),
      durationSeconds: durSec,
      breathRate: breathRateVal,
      breathSource: breathSourceVal,
      avgHeartRate: avgHr,
      minHeartRate: minHr,
      maxHeartRate: maxHr,
      rmssd: hrvResult?.rmssd,
      sdnn: hrvResult?.sdnn,
      meanNn: hrvResult?.meanNN,
      pnn50: hrvResult?.pnn50,
      hrReadingsJson: hrJson,
      extendedMetricsJson: extJson,
    );
  }

  Map<String, List<Map<String, dynamic>>> _serializeMetricGroups(
    Map<String, List<({String label, double? value, String unit})>> groups,
  ) {
    return groups.map(
      (group, metrics) => MapEntry(
        group,
        metrics
            .map(
              (metric) => {
                'label': metric.label,
                'value':
                    metric.value != null && metric.value!.isFinite
                        ? metric.value
                        : null,
                'unit': metric.unit,
              },
            )
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    _beltBreathTimer?.cancel();
    _liveBreathRateTimer?.cancel();
    _breathRateTracker?.dispose();
    _breathRateTracker = null;
    _ecgRespirationTracker?.dispose();
    _ecgRespirationTracker = null;
    _lastEcgBreathSnapshot = null;
    _ecgRPeakDetector = null;
    _ecgSub?.cancel();
    _accSub?.cancel();
    _ecgSweepController.dispose();
    _recorder?.dispose();
    _breathingAmplitudeSubscription?.cancel();
    _hrStorageSub?.cancel();
    _stopHRRecording();
    unawaited(BackgroundSessionService.forceStop());
    _pulseController.dispose();
    if (_currentSessionId != null) {
      AppDatabase().endSession(_currentSessionId!);
      _currentSessionId = null;
    }
    super.dispose();
  }

  int? get _activePatientId =>
      context.read<PatientProvider>().activePatient?.id;

  Future<void> _startRecording({
    required bool recordBR,
    required bool recordHR,
  }) async {
    if (_isStartingRecording) return;

    final patientId = _activePatientId;
    if (patientId == null) {
      _showNotConnectedDialog(message: 'No active patient selected.');
      return;
    }

    if (!kIsWeb) WakelockPlus.enable();
    setState(() => _isStartingRecording = true);

    try {
      final db = context.read<AppDatabase>();
      _currentSessionStartedAt = DateTime.now().toIso8601String();
      _currentSessionId = await db.createSession(
        patientId: patientId,
        sessionType: 'recording',
      );
      _sessionHrReadings.clear();
      _breathRatePersisted = false;
      _breathRateConfidence = null;
      _beltBreathTimer?.cancel();
      _beltBreathTimer = null;
      _ecgSweepController.reset();
      _ecgHasSamples = false;
      _ecgStatus = null;
      _isEcgStreaming = false;
      _ecgStartRequested = false;
      _ecgSampleIndex = 0;
      _ecgRPeakDetector = RealtimeEcgRPeakDetector();
      _ecgDerivedBpm = null;
      _ecgDerivedLastRrMs = null;
      _ecgRPeakCount = 0;
      _lastLiveRrSource = null;
      setState(() {
        breathingRate = -2;
        _breathRateConfidence = null;
      });

      final gdProvider = context.read<GoDirectProvider>();
      if (gdProvider.isConnected) {
        try {
          await gdProvider.startMeasurements(sensorNumbers: [1], periodMs: 100);
          _beltActiveForSession = true;
          _polarOnlyBR = false;
          _breathSource = 'Respiration Belt';
          _beltForceValues.clear();
          _beltStartTime = DateTime.now();
          _beltSub = gdProvider.respirationForceStream.listen((v) {
            _beltForceValues.add(v);
          });

          _breathingAmplitudes.clear();
          _breathingSamplingRateHz = 10.0;
          _breathingAmplitudeSubscription = gdProvider.respirationForceStream
              .listen((force) {
                _breathingAmplitudes.add(force);
              });
        } catch (e) {
          developer.log('Belt start failed, falling back: $e');
          _beltActiveForSession = false;
          if (recordHR && (!recordBR || _usesWebWindowsUi)) {
            _breathSource = 'Polar (HRV-derived)';
            _polarOnlyBR = true;
          } else {
            _polarOnlyBR = false;
            _breathSource = kIsWeb ? 'N/A' : 'Microphone';
          }
        }
      } else {
        _beltActiveForSession = false;
        if (recordHR && (!recordBR || _usesWebWindowsUi)) {
          _breathSource = 'Polar (HRV-derived)';
          _polarOnlyBR = true;
        } else {
          _polarOnlyBR = false;
          _breathSource = kIsWeb ? 'N/A' : 'Microphone';
        }
        _breathingAmplitudes.clear();
      }

      final bool polarIsActive = _polarOnlyBR;
      final bool usesMicrophone =
          recordBR && !kIsWeb && !polarIsActive && !_beltActiveForSession;
      final bool usesConnectedDevice =
          recordHR || _beltActiveForSession || _polarOnlyBR;

      if (usesMicrophone) {
        _recorder = SoundRecorder();
        await _recorder!.getPermission();
        await BackgroundSessionService.start(
          reason: 'Recording breath audio',
          usesConnectedDevice: usesConnectedDevice,
          usesMicrophone: true,
        );
        setState(() {
          breathingRate = -1;
          isRecordingBR = true;
        });
        _pulseController.repeat(reverse: true);
        _recorder!.startRecord().then((rate) async {
          if (mounted) {
            if (_breathRatePersisted ||
                _breathSource.contains('Polar') ||
                _breathSource.contains('Belt') ||
                _beltActiveForSession) {
              developer.log(
                'Mic finished but $_breathSource is active - ignoring mic result',
              );
              return;
            }

            int finalRate;
            String finalSource;
            if (_beltActiveForSession && _beltForceValues.length >= 30) {
              final result = estimateBreathRateFromForce(
                _beltForceValues,
                sampleRateHz: 10.0,
              );
              finalRate = result.bpm.round();
              finalSource = 'belt';
            } else {
              finalRate = rate;
              finalSource = 'microphone';
            }

            setState(() {
              breathingRate = finalRate;
              _breathSource =
                  finalSource == 'belt' ? 'Respiration Belt' : 'Microphone';
              _breathRateConfidence = null;
              isRecordingBR = false;
            });

            if (_currentSessionId != null) {
              _breathRatePersisted = true;
              await db.insertBreathRate(
                sessionId: _currentSessionId!,
                patientId: patientId,
                rate: finalRate,
                source: finalSource,
              );
            }

            _stopBelt();
            _checkStopEffect();
          }
        });
      } else if (_beltActiveForSession) {
        await BackgroundSessionService.start(
          reason: 'Recording respiration belt data',
          usesConnectedDevice: true,
        );
        setState(() {
          breathingRate = -1;
          isRecordingBR = true;
        });
        _pulseController.repeat(reverse: true);
        _beltBreathTimer = Timer(const Duration(seconds: 30), () {
          unawaited(_finishBeltBreathRate(db: db, patientId: patientId));
        });
      } else if (_polarOnlyBR) {
        await BackgroundSessionService.start(
          reason: 'Recording Polar HRV breathing data',
          usesConnectedDevice: true,
        );
        setState(() {
          breathingRate = -1;
          _breathSource = 'Polar (HRV-derived)';
          isRecordingBR = true;
        });
        _pulseController.repeat(reverse: true);
      }

      _startLiveBreathRateUpdates();

      if (recordHR) {
        if (!_beltActiveForSession && !_polarOnlyBR && !usesMicrophone) {
          await BackgroundSessionService.start(
            reason: 'Recording Polar heart data',
            usesConnectedDevice: true,
          );
        }

        final polarConnectProvider = context.read<PolarConnectProvider>();
        final unified = polarConnectProvider.getPolarConnect();
        if (unified == null) {
          if (mounted) _showNotConnectedDialog();
          throw StateError('No Polar connection is available.');
        } else {
          try {
            unified.resetEcgDerivedMetrics();
            final hrStream = await unified.getHeartRate();
            final broadcastStream = hrStream.asBroadcastStream();

            setState(() {
              _hrStream = broadcastStream;
              isRecordingHR = true;
              if (!unified.isWeb) {
                _ecgStatus = 'Waiting for HR signal before ECG...';
              }
            });

            void startEcgGraphOnce() {
              if (_ecgStartRequested) return;
              _ecgStartRequested = true;
              unawaited(
                Future<void>.delayed(
                  unified.isWeb
                      ? Duration.zero
                      : const Duration(milliseconds: 1500),
                  () async {
                    if (!mounted || !isRecordingHR) return;
                    await _startEcgGraph(unified, db: db, patientId: patientId);
                  },
                ),
              );
            }

            var hrSamplesBeforeEcg = 0;
            _hrStorageSub = broadcastStream.listen(
              (hr) {
                _sessionHrReadings.add(hr);
                if (_currentSessionId != null) {
                  db.insertHeartRate(
                    sessionId: _currentSessionId!,
                    patientId: patientId,
                    rate: hr,
                  );
                }
                if (!unified.isWeb) {
                  hrSamplesBeforeEcg++;
                  if (hrSamplesBeforeEcg >= 2) {
                    startEcgGraphOnce();
                  }
                }
              },
              onError: (Object error) {
                developer.log('HR stream stopped: $error');
                if (!mounted) return;
                setState(() {
                  _ecgStatus = 'HR signal unavailable. Reconnect Polar.';
                });
                _showStartError(
                  'Polar HR stream stopped: ${_friendlyError(error)}',
                );
              },
            );

            if (!isRecordingBR) {
              _pulseController.repeat(reverse: true);
            }
            if (unified.isWeb) {
              startEcgGraphOnce();
            }
            developer.log("HR recording started");
          } catch (e, st) {
            developer.log("HR recording error: $e", error: e, stackTrace: st);
            if (isRecordingBR && !_polarOnlyBR) {
              _showStartError(
                'Polar stream failed. Continuing breath recording only.',
              );
            } else {
              rethrow;
            }
          }
        }
      }
    } catch (e, st) {
      developer.log('Recording start failed: $e', error: e, stackTrace: st);
      await _cleanupFailedRecordingStart();
      _showStartError('Could not start recording: ${_friendlyError(e)}');
    } finally {
      if (mounted) {
        setState(() => _isStartingRecording = false);
      }
    }
  }

  Future<void> _cleanupFailedRecordingStart() async {
    _liveBreathRateTimer?.cancel();
    _liveBreathRateTimer = null;
    _breathRateTracker?.dispose();
    _breathRateTracker = null;
    _ecgRespirationTracker?.dispose();
    _ecgRespirationTracker = null;
    _lastEcgBreathSnapshot = null;
    _ecgRPeakDetector = null;

    await _hrStorageSub?.cancel();
    _hrStorageSub = null;
    await _ecgSub?.cancel();
    _ecgSub = null;
    await _accSub?.cancel();
    _accSub = null;

    try {
      final unified = context.read<PolarConnectProvider>().getPolarConnect();
      await unified?.stopEcgStreaming();
      await unified?.stopAccStreaming();
      await unified?.stopRecording();
    } catch (_) {}

    try {
      await _stopBelt();
    } catch (_) {}

    try {
      _recorder?.dispose();
    } catch (_) {}
    _recorder = null;

    if (_currentSessionId != null) {
      try {
        await context.read<AppDatabase>().endSession(_currentSessionId!);
      } catch (_) {}
    }
    _currentSessionId = null;
    _currentSessionStartedAt = null;
    _sessionHrReadings.clear();
    _polarOnlyBR = false;
    _breathRatePersisted = false;

    if (!kIsWeb) WakelockPlus.disable();
    await BackgroundSessionService.forceStop();
    _pulseController.repeat(reverse: true);
    _ecgSweepController.reset();

    if (!mounted) return;
    setState(() {
      _hrStream = null;
      isRecordingHR = false;
      isRecordingBR = false;
      breathingRate = -2;
      _breathRateConfidence = null;
      _isEcgStreaming = false;
      _ecgStatus = null;
      _ecgHasSamples = false;
      _ecgStartRequested = false;
    });
  }

  void _showStartError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.coralRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '');
  }

  Future<void> _stopBelt() async {
    _beltBreathTimer?.cancel();
    _beltBreathTimer = null;
    _beltSub?.cancel();
    _beltSub = null;
    _breathingAmplitudeSubscription?.cancel();
    _breathingAmplitudeSubscription = null;
    final gdProvider = context.read<GoDirectProvider>();
    if (gdProvider.isStreaming) {
      await gdProvider.stopMeasurements();
    }
    _beltActiveForSession = false;
    _beltStartTime = null;
  }

  Future<void> _startEcgGraph(
    UnifiedPolarConnect unified, {
    required AppDatabase db,
    required int patientId,
  }) async {
    await _ecgSub?.cancel();
    _ecgSub = null;
    _ecgSweepController.reset();
    _ecgHasSamples = false;
    _ecgSampleIndex = 0;
    if (mounted) {
      setState(() {
        _isEcgStreaming = false;
        _ecgStatus = 'Opening ECG stream...';
      });
    }

    try {
      final ecgStream = await unified.startEcgStreaming();
      if (!mounted) return;
      setState(() {
        _isEcgStreaming = true;
        _ecgStatus = 'Waiting for ECG signal';
      });

      _ecgSub = ecgStream.listen(
        (batch) {
          if (batch.isEmpty) return;
          _ecgSweepController.addRawBatch(
            batch.map((sample) => sample.voltageUv),
          );

          final rPeakEvents =
              _ecgRPeakDetector?.addBatch(
                batch.map((sample) => sample.voltageUv),
              ) ??
              const <RealtimeEcgRPeakEvent>[];
          if (rPeakEvents.isNotEmpty) {
            for (final event in rPeakEvents) {
              _ecgSweepController.markRPeak(
                event.globalSampleIndex,
                event.amplitudeUv,
              );
              final rrMs = event.rrMs;
              if (rrMs != null) {
                unified.addEcgDerivedRrInterval(rrMs, bpm: event.bpm);
              }
            }
            final latestBpmEvent = rPeakEvents.lastWhere(
              (event) => event.bpm != null,
              orElse: () => rPeakEvents.last,
            );
            if (mounted) {
              setState(() {
                _ecgDerivedBpm = latestBpmEvent.bpm ?? _ecgDerivedBpm;
                _ecgDerivedLastRrMs =
                    latestBpmEvent.rrMs ?? _ecgDerivedLastRrMs;
                _ecgRPeakCount =
                    _ecgRPeakDetector?.rPeakCount ?? _ecgRPeakCount;
              });
            }
          }

          _ecgRespirationTracker?.addEcgBatch(
            batch.map((sample) => sample.voltageUv),
          );

          final sessionId = _currentSessionId;
          if (sessionId != null) {
            final points = _ecgPointsFromBatch(batch);
            unawaited(
              db
                  .insertEcgSamples(
                    sessionId: sessionId,
                    patientId: patientId,
                    samples: points,
                  )
                  .catchError((Object e) {
                    developer.log('ECG storage error: $e');
                  }),
            );
          }

          if (!_ecgHasSamples) {
            if (mounted) {
              setState(() {
                _ecgHasSamples = true;
                _ecgStatus = null;
              });
            }
          }
        },
        onError: (Object error) {
          developer.log('ECG stream error: $error');
          if (mounted) {
            setState(() {
              _isEcgStreaming = false;
              _ecgStatus = _ecgStatusMessage(error);
            });
          }
        },
      );

      try {
        final accStream = await unified.startAccStreaming();
        _accSub = accStream.listen(
          (batch) {
            _ecgRespirationTracker?.addAccelerometerMagnitudes(
              batch.map((sample) => sample.magnitudeMg),
            );
          },
          onError: (Object error) {
            developer.log('ACC stream error: $error');
          },
        );
      } catch (e) {
        developer.log('Polar ACC unavailable for motion gating: $e');
      }
    } catch (e) {
      developer.log('Unable to start ECG graph: $e');
      if (mounted) {
        setState(() {
          _isEcgStreaming = false;
          _ecgStatus = _ecgStatusMessage(e);
        });
      }
    }
  }

  String _ecgStatusMessage(Object error) {
    final message = error.toString();
    if (message.contains('PMD service not found')) {
      return 'ECG service not found. Reconnect Polar with ECG permission.';
    }
    if (message.contains('No PMD response') ||
        message.contains('PMD start ECG failed')) {
      return 'ECG stream did not start. Tap stop, then start again.';
    }
    return 'ECG unavailable';
  }

  List<EcgSamplePoint> _ecgPointsFromBatch(List<UnifiedEcgSample> batch) {
    final receivedAtUs = DateTime.now().microsecondsSinceEpoch;
    final sessionStartedUs =
        _currentSessionStartedAt == null
            ? receivedAtUs
            : (DateTime.tryParse(
                  _currentSessionStartedAt!,
                )?.microsecondsSinceEpoch ??
                receivedAtUs);
    final points = <EcgSamplePoint>[];

    for (var i = 0; i < batch.length; i++) {
      final sample = batch[i];
      if (!sample.voltageUv.isFinite) continue;

      final timestampUs = _ecgTimestampUs(
        sample.timestampNs,
        receivedAtUs,
        batch.length,
        i,
      );
      points.add(
        EcgSamplePoint(
          timestampMs: timestampUs ~/ 1000,
          timestampUs: timestampUs,
          elapsedMs: math.max(0, timestampUs - sessionStartedUs) ~/ 1000,
          elapsedUs: math.max(0, timestampUs - sessionStartedUs),
          sampleIndex: _ecgSampleIndex++,
          ecgUv: sample.voltageUv,
        ),
      );
    }

    return points;
  }

  int _ecgTimestampUs(
    int timestampNs,
    int receivedAtUs,
    int batchLength,
    int batchIndex,
  ) {
    final rawUs = timestampNs ~/ 1000;
    const toleranceUs = 86400000000;
    if (rawUs >= receivedAtUs - toleranceUs &&
        rawUs <= receivedAtUs + toleranceUs) {
      return rawUs;
    }

    final samplePeriodUs = 1000000.0 / _EcgSweepController.rawSampleRateHz;
    final offsetFromBatchEnd =
        ((batchLength - 1 - batchIndex) * samplePeriodUs).round();
    return receivedAtUs - offsetFromBatchEnd;
  }

  Future<void> _stopEcgGraph(UnifiedPolarConnect? unified) async {
    await _ecgSub?.cancel();
    _ecgSub = null;
    await _accSub?.cancel();
    _accSub = null;
    _ecgStartRequested = false;
    try {
      await unified?.stopEcgStreaming();
      await unified?.stopAccStreaming();
    } catch (e) {
      developer.log('ECG stop warning: $e');
    }
    if (mounted) {
      setState(() {
        _isEcgStreaming = false;
        _ecgStatus = null;
      });
    }
  }

  void _startLiveBreathRateUpdates() {
    _liveBreathRateTimer?.cancel();
    _lastRrFedIndex = 0;
    _lastLiveRrSource = null;
    _lastEcgBreathSnapshot = null;

    _breathRateTracker?.dispose();
    _breathRateTracker = RealtimeBreathRateTracker(
      windowDurationSec: 45,
      shortWindowDurationSec: 20,
      minUpdateIntervalMs: 3000,
      minConfidence: 0.10,
      minFreqHz: HrvDerivedBreathingRate.guidedMinFreqHz,
      maxFreqHz: HrvDerivedBreathingRate.guidedMaxFreqHz,
    );
    _breathRateTracker!.start();

    _ecgRespirationTracker?.dispose();
    _ecgRespirationTracker = RealtimeEcgRespirationTracker(
      ecgSampleRate: 130.0,
      windowDurationSec: 45,
      updateIntervalMs: 3000,
      minConfidence: 0.15,
    );
    _ecgRespirationTracker!.start();

    _liveBreathRateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateLiveBreathRate();
    });
  }

  void _updateLiveBreathRate() {
    if (!mounted) return;

    if (_beltActiveForSession && _beltForceValues.length >= 40) {
      final recent =
          _beltForceValues.length > 300
              ? _beltForceValues.sublist(_beltForceValues.length - 300)
              : List<double>.from(_beltForceValues);
      final result = estimateBreathRateFromForce(recent, sampleRateHz: 10.0);
      final rate = result.bpm.round();
      if (rate > 0) {
        setState(() {
          breathingRate = rate;
          _breathSource = 'Respiration Belt';
          _breathRateConfidence = null;
        });
      }
      return;
    }

    if (!(_polarOnlyBR || (_usesWebWindowsUi && isRecordingHR))) return;

    final unified = context.read<PolarConnectProvider>().getPolarConnect();
    if (unified == null) return;

    final ecgRrIntervals = unified.ecgDerivedRrIntervals;
    final polarRrIntervals = unified.sessionRrIntervals;
    final useEcgRr = ecgRrIntervals.length >= 20;
    final rrIntervals = useEcgRr ? ecgRrIntervals : polarRrIntervals;
    final rrSourceKey = useEcgRr ? 'ecg' : 'polar_hr';
    if (rrIntervals.length < 20) return;

    final tracker = _breathRateTracker;
    if (tracker == null) return;

    if (_lastLiveRrSource != rrSourceKey) {
      tracker.reset();
      _lastRrFedIndex = 0;
      _lastLiveRrSource = rrSourceKey;
    }

    if (_lastRrFedIndex < rrIntervals.length) {
      final newRRs = rrIntervals.sublist(_lastRrFedIndex);
      tracker.addRRBatch(newRRs);
      _lastRrFedIndex = rrIntervals.length;
    }

    final rrSnapshot = tracker.forceUpdate();
    final rrBpm = rrSnapshot?.breathRateBpm ?? 0;
    final rrConf = rrSnapshot?.confidence ?? 0;

    final ecgTracker = _ecgRespirationTracker;
    final ecgSnapshot = ecgTracker?.forceUpdate();
    if (ecgSnapshot != null && ecgSnapshot.breathRateBpm > 0) {
      _lastEcgBreathSnapshot = ecgSnapshot;
    }
    final ecgBpm = ecgSnapshot?.breathRateBpm ?? 0;
    final ecgConf = ecgSnapshot?.confidence ?? 0;

    double displayBpm = 0;
    double displayConf = 0;
    String source = useEcgRr ? 'Polar (ECG RR-derived)' : 'Polar (HRV-derived)';

    final bool rrValid = rrBpm > 0 && rrConf >= 0.10;
    final bool ecgValid = ecgBpm > 0 && ecgConf >= 0.10;

    if (rrValid && ecgValid) {
      final totalConf = rrConf + ecgConf;
      displayBpm = (rrBpm * rrConf + ecgBpm * ecgConf) / totalConf;
      displayConf = math.max(rrConf, ecgConf);
      source = 'Polar (Fused)';
    } else if (ecgValid) {
      displayBpm = ecgBpm;
      displayConf = ecgConf;
      source = 'Polar (ECG-derived)';
    } else if (rrValid) {
      displayBpm = rrBpm;
      displayConf = rrConf;
    }

    if (displayBpm > 0) {
      final rate = displayBpm.round();

      setState(() {
        breathingRate = rate;
        _breathSource = source;
        _breathRateConfidence = displayConf;
        isRecordingBR = false;
      });
      developer.log(
        'Live BR: $rate bpm '
        '(conf: ${(displayConf * 100).toStringAsFixed(0)}%, '
        'source: $source, '
        'rrBpm: ${rrBpm.toStringAsFixed(1)}, '
        'ecgBpm: ${ecgBpm.toStringAsFixed(1)})',
      );
    }
  }

  Color _breathRateConfidenceColor() {
    final conf = _breathRateConfidence;
    if (conf == null || !_breathSource.startsWith('Polar')) {
      return AppTheme.emerald;
    }
    if (conf >= 0.60) return AppTheme.signalGood;
    if (conf >= 0.35) return AppTheme.signalWarn;
    return AppTheme.cardiacRose;
  }

  Future<void> _finishBeltBreathRate({
    required AppDatabase db,
    required int patientId,
  }) async {
    if (!mounted || !_beltActiveForSession || _breathRatePersisted) return;

    final result = estimateBreathRateFromForce(
      _beltForceValues,
      sampleRateHz: 10.0,
      durationSeconds:
          _beltStartTime == null
              ? null
              : DateTime.now().difference(_beltStartTime!).inMilliseconds /
                  1000.0,
    );
    final rate = result.bpm.round();

    if (rate > 0) {
      setState(() {
        breathingRate = rate;
        _breathSource = 'Respiration Belt';
        _breathRateConfidence = null;
        isRecordingBR = false;
      });

      if (_currentSessionId != null) {
        _breathRatePersisted = true;
        await db.insertBreathRate(
          sessionId: _currentSessionId!,
          patientId: patientId,
          rate: rate,
          source: 'belt',
        );
      }
    } else {
      setState(() {
        isRecordingBR = false;
      });
    }

    await _stopBelt();
    _checkStopEffect();
  }

  Future<void> _finalizeBreathRateForSession({
    required AppDatabase db,
    required int? patientId,
    required List<double> rrIntervals,
    HrvDerivedBreathingResult? polarBreathResult,
  }) async {
    if (patientId == null) return;

    if (_beltActiveForSession && !_breathRatePersisted) {
      await _finishBeltBreathRate(db: db, patientId: patientId);
    }

    final shouldUsePolarDerived =
        !_beltActiveForSession &&
        (_polarOnlyBR ||
            _breathSource.startsWith('Polar') ||
            (_usesWebWindowsUi && !_breathRatePersisted));

    if (shouldUsePolarDerived) {
      try {
        final ecgFinal =
            _ecgRespirationTracker?.forceUpdate() ?? _lastEcgBreathSnapshot;
        if (ecgFinal != null &&
            ecgFinal.breathRateBpm > 0 &&
            ecgFinal.confidence >= 0.15) {
          final rate = ecgFinal.breathRateBpm.round();
          setState(() {
            breathingRate = rate;
            _breathSource = 'Polar (ECG-derived)';
            _breathRateConfidence = ecgFinal.confidence;
            isRecordingBR = false;
          });
          if (_currentSessionId != null && !_breathRatePersisted) {
            _breathRatePersisted = true;
            await db.insertBreathRate(
              sessionId: _currentSessionId!,
              patientId: patientId,
              rate: rate,
              source: 'polar_ecg_edr',
            );
          }
          developer.log(
            'Polar ECG EDR BR: $rate bpm '
            '(confidence: ${(ecgFinal.confidence * 100).toStringAsFixed(0)}%, '
            'motion: ${(ecgFinal.motionQuality * 100).toStringAsFixed(0)}%)',
          );
          return;
        }

        if (rrIntervals.isEmpty) return;
        final brResult =
            polarBreathResult ??
            HrvDerivedBreathingRate.estimate(
              rrIntervals,
              minFreqHz: HrvDerivedBreathingRate.guidedMinFreqHz,
              maxFreqHz: HrvDerivedBreathingRate.guidedMaxFreqHz,
            );
        if (brResult.breathingRateBpm > 0) {
          final rate = brResult.breathingRateBpm.round();
          setState(() {
            breathingRate = rate;
            _breathSource = 'Polar (HRV-derived)';
            _breathRateConfidence = brResult.confidence;
            isRecordingBR = false;
          });
          if (_currentSessionId != null && !_breathRatePersisted) {
            _breathRatePersisted = true;
            await db.insertBreathRate(
              sessionId: _currentSessionId!,
              patientId: patientId,
              rate: rate,
              source: 'polar_hrv',
            );
          }
          developer.log(
            'Polar-derived BR: $rate bpm '
            '(confidence: ${(brResult.confidence * 100).toStringAsFixed(0)}%)',
          );
        } else {
          developer.log('Polar BR estimation failed: ${brResult.warning}');
        }
      } catch (e) {
        debugPrint('Polar-derived BR estimation error: $e');
      }
    }

    if (mounted && isRecordingBR) {
      setState(() => isRecordingBR = false);
    }
    _polarOnlyBR = false;
  }

  Future<void> _stopHRRecording({bool showResults = true}) async {
    _hrStorageSub?.cancel();
    _hrStorageSub = null;

    final polarConnectProvider = context.read<PolarConnectProvider>();
    final unified = polarConnectProvider.getPolarConnect();
    if (unified != null) {
      try {
        final rrIntervals = List<double>.from(unified.bestSessionRrIntervals);
        final hasEcgDerivedRr = unified.ecgDerivedRrIntervals.length >= 10;

        _liveBreathRateTimer?.cancel();
        _liveBreathRateTimer = null;
        _breathRateTracker?.dispose();
        _breathRateTracker = null;
        _lastRrFedIndex = 0;
        _lastLiveRrSource = null;
        await _stopEcgGraph(unified);
        await unified.stopRecording();
        var hrvResult = unified.lastSessionHrv;
        if (hasEcgDerivedRr) {
          try {
            hrvResult = HrvTimeDomain.compute(rrIntervals);
          } catch (e) {
            debugPrint('ECG-derived HRV skipped: $e');
          }
        }
        setState(() {
          _hrStream = null;
          isRecordingHR = false;
        });
        developer.log("HR recording stopped");
        _checkStopEffect();

        final db = context.read<AppDatabase>();
        final patientId = _activePatientId;

        if (hrvResult != null && mounted) {
          if (_currentSessionId != null && patientId != null) {
            await db.insertHrvResult(
              sessionId: _currentSessionId!,
              patientId: patientId,
              result: hrvResult,
            );
          }

          HrvFrequencyDomainResult? freqResult;
          try {
            freqResult = HrvFrequencyDomainAnalyzer.analyze(rrIntervals);
          } catch (e) {
            debugPrint('Frequency-domain HRV skipped: $e');
          }

          HrvRsaResult? rsaResult;
          try {
            rsaResult = HrvRsaAnalyzer.analyze(
              rrIntervals,
              breathingAmplitudes:
                  _breathingAmplitudes.isNotEmpty ? _breathingAmplitudes : null,
              breathingSamplingRateHz: _breathingSamplingRateHz,
            );
          } catch (e) {
            debugPrint('RSA analysis skipped: $e');
          }

          await _finalizeBreathRateForSession(
            db: db,
            patientId: patientId,
            rrIntervals: rrIntervals,
            polarBreathResult: rsaResult?.hrvBreathingDetail,
          );

          PsychophysiologicalResult? psychResult;
          try {
            psychResult = PsychophysiologicalAnalyzer.compute(
              rrIntervalsMs: rrIntervals,
              rmssd: hrvResult.rmssd,
              meanNN: hrvResult.meanNN,
              hfPower: freqResult?.hf.absolutePower,
              lfHfRatio: freqResult?.lfHfRatio,
            );
          } catch (e) {
            debugPrint('Psychophysiological indices skipped: $e');
          }

          final nowIso = DateTime.now().toIso8601String();
          if (_currentSessionId != null) {
            await db.endSession(_currentSessionId!);
          }

          if (patientId != null && _currentSessionStartedAt != null) {
            await _saveSessionSummary(
              patientId: patientId,
              startedAt: _currentSessionStartedAt!,
              endedAt: nowIso,
              breathRateVal: breathingRate > 0 ? breathingRate : null,
              breathSourceVal: _breathSource,
              hrvResult: hrvResult,
              freqResult: freqResult,
              rsaResult: rsaResult,
              psychResult: psychResult,
            );
          }
          _currentSessionId = null;
          _currentSessionStartedAt = null;

          _refreshHistory();
          if (showResults) {
            _showHrvResultSheet(hrvResult, freqResult, rsaResult, psychResult);
          }
        } else {
          final nowIso = DateTime.now().toIso8601String();
          if (_currentSessionId != null) {
            await db.endSession(_currentSessionId!);
          }
          if (patientId != null && _currentSessionStartedAt != null) {
            await _finalizeBreathRateForSession(
              db: db,
              patientId: patientId,
              rrIntervals: rrIntervals,
            );
            await _saveSessionSummary(
              patientId: patientId,
              startedAt: _currentSessionStartedAt!,
              endedAt: nowIso,
              breathRateVal: breathingRate > 0 ? breathingRate : null,
              breathSourceVal: _breathSource,
            );
          }
          _currentSessionId = null;
          _currentSessionStartedAt = null;
          _refreshHistory();
          _polarOnlyBR = false;
        }
      } catch (e) {
        developer.log("Error stopping HR recording: $e");
        _polarOnlyBR = false;
      }
    }
    setState(() {
      isRecordingHR = false;
    });
    _checkStopEffect();
  }

  void _openResonanceTrainer(PolarConnectProvider provider) {
    if (_isOpeningResonanceTrainer) return;

    void resetOpeningFlag() {
      if (!mounted) return;
      setState(() => _isOpeningResonanceTrainer = false);
    }

    setState(() => _isOpeningResonanceTrainer = true);

    try {
      if (!provider.hasDevice) {
        _showNotConnectedDialog();
        resetOpeningFlag();
        return;
      }

      final patientId = _activePatientId;
      if (patientId == null) {
        _showNotConnectedDialog(message: 'No active patient selected.');
        resetOpeningFlag();
        return;
      }

      final unified = provider.getPolarConnect();
      if (unified == null) {
        _showNotConnectedDialog();
        resetOpeningFlag();
        return;
      }

      final preparation = Completer<void>();
      final trainer = RfAssessmentScreen(
        polar: unified,
        patientId: patientId,
        preStartFuture: preparation.future,
      );

      final routeFuture = Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => trainer));
      unawaited(routeFuture.whenComplete(resetOpeningFlag));

      unawaited(
        Future<void>.delayed(Duration.zero, () async {
          try {
            await _stopHRRecording(showResults: false);
          } catch (e, stackTrace) {
            developer.log(
              'Error preparing resonance trainer: $e',
              error: e,
              stackTrace: stackTrace,
            );
          } finally {
            if (!preparation.isCompleted) preparation.complete();
          }
        }),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error opening resonance trainer: $e',
        error: e,
        stackTrace: stackTrace,
      );
      resetOpeningFlag();
    }
  }

  void _showHrvResultSheet(
    HrvTimeDomainResult result, [
    HrvFrequencyDomainResult? freqResult,
    HrvRsaResult? rsaResult,
    PsychophysiologicalResult? psychResult,
  ]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultCards = <Widget>[
      AnimatedEntrance(
        delay: Duration.zero,
        child: HrvResultCard(result: result),
      ),
      if (freqResult != null) ...[
        const SizedBox(height: 16),
        AnimatedEntrance(
          delay: const Duration(milliseconds: 100),
          child: HrvFrequencyResultCard(result: freqResult),
        ),
      ],
      if (rsaResult != null) ...[
        const SizedBox(height: 16),
        AnimatedEntrance(
          delay: const Duration(milliseconds: 200),
          child: HrvRsaResultCard(result: rsaResult),
        ),
      ],
      if (psychResult != null) ...[
        const SizedBox(height: 16),
        AnimatedEntrance(
          delay: const Duration(milliseconds: 300),
          child: PsychophysiologicalResultCard(result: psychResult),
        ),
      ],
    ];

    if (_usesWebWindowsUi) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          final maxHeight = MediaQuery.of(dialogContext).size.height * 0.86;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.charcoal : AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Session Results",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(children: resultCards),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.charcoal : AppTheme.pureWhite,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          "Session Results",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...resultCards,
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _checkStopEffect() {
    if (!isRecordingHR && !isRecordingBR) {
      _liveBreathRateTimer?.cancel();
      _liveBreathRateTimer = null;
      if (!kIsWeb) WakelockPlus.disable();
      unawaited(BackgroundSessionService.stop());
      _pulseController.repeat(reverse: true);
    }
  }

  void _showNotConnectedDialog({String? message}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Device Not Connected",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: Text(
              message ?? "Please connect to a Polar device in Settings.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final settingsIndex = context
                      .read<AppModeProvider>()
                      .indexForDestination('Settings', fallback: 0);
                  context.read<NavBarProvider>().changeIndex(settingsIndex);
                },
                child: const Text(
                  "Go to Settings",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _handleStartRecording() {
    if (_isStartingRecording || isRecordingBR || isRecordingHR) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'A session is already in progress. '
            'Stop the current recording before starting a new one.',
          ),
          backgroundColor: AppTheme.coralRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final polarProvider = context.read<PolarConnectProvider>();
    final gdProvider = context.read<GoDirectProvider>();

    if (!polarProvider.hasDevice) {
      if (kIsWeb) {
        _showNotConnectedDialog(
          message:
              "Please connect to a Polar sensor in Settings using Web Bluetooth.",
        );
      } else {
        _showMobilePolarNotConnectedDialog();
      }
      return;
    }

    final isBeltConnected = gdProvider.isConnected;

    if (isBeltConnected || _usesWebWindowsUi) {
      if (!isBeltConnected && _usesWebWindowsUi) {
        _polarOnlyBR = true;
      }
      unawaited(
        _startRecording(
          recordBR: isBeltConnected || !_usesWebWindowsUi,
          recordHR: true,
        ),
      );
    } else {
      _showPolarOnlyBreathRateOption();
    }
  }

  void _showMobilePolarNotConnectedDialog() {
    final isBeltConnected = context.read<GoDirectProvider>().isConnected;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(
              Icons.bluetooth_disabled_rounded,
              color: Colors.amber.shade600,
              size: 48,
            ),
            title: Text(
              "Polar Not Connected",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Heart rate recording requires a Polar device. You can still record your breathing rate.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
                if (!isBeltConnected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.air_rounded,
                          color: AppTheme.emerald,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Connect a Vernier Go Direct Respiration Belt for best results, or proceed with mic.",
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: AppTheme.emerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  final settingsIndex = context
                      .read<AppModeProvider>()
                      .indexForDestination('Settings', fallback: 0);
                  context.read<NavBarProvider>().changeIndex(settingsIndex);
                },
                child: const Text("Go to Settings"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  unawaited(_startRecording(recordBR: true, recordHR: false));
                },
                child: Text(
                  isBeltConnected ? "Continue with Belt" : "Proceed with Mic",
                ),
              ),
            ],
          ),
    );
  }

  void _showPolarOnlyBreathRateOption() {
    const polarPurple = Color(0xFF818CF8);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(
              Icons.watch_rounded,
              color: Colors.amber.shade600,
              size: 48,
            ),
            title: Text(
              "Respiration Belt Not Connected",
              style: Theme.of(ctx).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose how to estimate your breathing rate:",
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.softSage.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        color: AppTheme.softSage,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Mic uses your device microphone to detect breathing sounds.",
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: AppTheme.softSage,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: polarPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.watch_rounded, color: polarPurple, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Polar derives breath rate from heart rate variability (RSA) during the session.",
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: polarPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _polarOnlyBR = false;
                  unawaited(_startRecording(recordBR: true, recordHR: true));
                },
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: const Text("Continue with Mic"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _polarOnlyBR = true;
                  unawaited(_startRecording(recordBR: false, recordHR: true));
                },
                icon: const Icon(Icons.watch_rounded, size: 18),
                label: const Text("Continue with Polar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: polarPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildRecordingSurface(bool isActive) {
    if (isActive) {
      return _LiveEcgPanel(
        controller: _ecgSweepController,
        hasSamples: _ecgHasSamples,
        isStreaming: _isEcgStreaming,
        statusText: _ecgStatus,
        lastRrMs: _ecgDerivedLastRrMs,
        rPeakCount: _ecgRPeakCount,
        onStop: isRecordingHR ? _stopHRRecording : null,
      );
    }

    return Center(
      child: ScaleOnPress(
        onTap: _isStartingRecording ? null : _handleStartRecording,
        haptic: PressHaptic.medium,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.1);
            final shadowOpacity = 0.5 - (_pulseController.value * 0.3);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.emerald, AppTheme.softSage],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emerald.withValues(alpha: shadowOpacity),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isStartingRecording)
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _isStartingRecording ? "STARTING" : "START",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = isRecordingBR || isRecordingHR;
    final hPad = Responsive.horizontalPadding(context);

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 12.0, hPad, 24.0),
                child: ContentContainer(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          "Live Record",
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Monitor your biometrics in real-time.",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildRecordingSurface(isActive),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.air,
                                      color: _breathRateConfidenceColor(),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Breath Rate",
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    if (breathingRate == -1)
                                      const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      Text(
                                        breathingRate > 0
                                            ? "$breathingRate bpm"
                                            : "--",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall?.copyWith(
                                          color: _breathRateConfidenceColor(),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    if (isRecordingBR)
                                      Text(
                                        "Measuring...",
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.color,
                                          fontSize: 10,
                                        ),
                                      )
                                    else if (breathingRate > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _breathSource ==
                                                      'Respiration Belt'
                                                  ? AppTheme.emerald.withValues(
                                                    alpha: 0.15,
                                                  )
                                                  : _breathSource.startsWith(
                                                    'Polar',
                                                  )
                                                  ? const Color(
                                                    0xFF818CF8,
                                                  ).withValues(alpha: 0.15)
                                                  : AppTheme.softSage
                                                      .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _breathSource == 'Respiration Belt'
                                              ? 'Belt connected'
                                              : _breathSource.startsWith(
                                                'Polar',
                                              )
                                              ? _breathRateConfidence != null
                                                  ? 'Polar'
                                                  : 'Polar'
                                              : _breathSource == 'N/A'
                                              ? 'N/A'
                                              : 'Mic',
                                          style: TextStyle(
                                            color:
                                                _breathSource ==
                                                        'Respiration Belt'
                                                    ? AppTheme.emerald
                                                    : _breathSource.startsWith(
                                                      'Polar',
                                                    )
                                                    ? const Color(0xFF818CF8)
                                                    : AppTheme.softSage,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      color: AppTheme.dustyRose,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Heart Rate",
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    StreamBuilder<int>(
                                      stream: _hrStream,
                                      builder: (context, snapshot) {
                                        final ecgHr = _ecgDerivedBpm?.round();
                                        if (snapshot.connectionState ==
                                                ConnectionState.waiting &&
                                            isRecordingHR &&
                                            ecgHr == null) {
                                          return const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          );
                                        }
                                        final displayHr =
                                            snapshot.data ?? ecgHr;
                                        return Text(
                                          displayHr != null
                                              ? "$displayHr bpm"
                                              : "--",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall?.copyWith(
                                            color: AppTheme.dustyRose,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    if (isRecordingHR)
                                      Text(
                                        "Live",
                                        style: TextStyle(
                                          color: AppTheme.coralRose,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Consumer<GoDirectProvider>(
                          builder: (context, gdProvider, _) {
                            if (!gdProvider.isStreaming) {
                              return const SizedBox.shrink();
                            }
                            return RespirationWaveformCard(
                              forceStream: gdProvider.respirationForceStream,
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        Consumer<PolarConnectProvider>(
                          builder: (context, provider, child) {
                            return ScaleOnPress(
                              onTap:
                                  _isOpeningResonanceTrainer
                                      ? null
                                      : () => _openResonanceTrainer(provider),
                              child: GlassCard(
                                padding: EdgeInsets.zero,
                                color: Theme.of(context).primaryColor,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? Colors.white.withValues(
                                                    alpha: 0.2,
                                                  )
                                                  : Colors.black.withValues(
                                                    alpha: 0.1,
                                                  ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.favorite_rounded,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Precise RF Assessment",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Measured or estimated 78-breath protocol",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color:
                                                    isDark
                                                        ? Colors.white70
                                                        : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_isOpeningResonanceTrainer)
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  isDark
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                          ),
                                        )
                                      else
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color:
                                              isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        ScaleOnPress(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const QuickRfAssessmentScreen(),
                              ),
                            );
                          },
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emerald.withValues(
                                        alpha: isDark ? 0.18 : 0.10,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppTheme.emerald,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Quick RF Estimate",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Hasuo sex-and-height estimate",
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color:
                                        isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ScaleOnPress(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => const BiofeedbackDashboardScreen(),
                              ),
                            );
                          },
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? AppTheme.softSage.withValues(
                                                alpha: 0.2,
                                              )
                                              : AppTheme.softSage.withValues(
                                                alpha: 0.1,
                                              ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.monitor_heart_rounded,
                                      color: AppTheme.softSage,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Biofeedback Dashboard",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Live HRV, coherence & adaptive breathing",
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color:
                                        isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        ScaleOnPress(
                          onTap: () {
                            _stopHRRecording(showResults: false);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const VrBiofeedbackScreen(),
                              ),
                            );
                          },
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? const Color(
                                                0xFF818CF8,
                                              ).withValues(alpha: 0.2)
                                              : const Color(
                                                0xFF818CF8,
                                              ).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.view_in_ar_rounded,
                                      color: const Color(0xFF818CF8),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "VR Biofeedback",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Immersive 3D breathing sphere (Meta Quest)",
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color:
                                        isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_historyLoaded)
                          SessionHistoryCard(
                            sessions: _sessionHistory,
                            onTap: () {
                              final pid = _activePatientId;
                              if (pid == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => SessionHistoryPage(patientId: pid),
                                ),
                              ).then((_) => _refreshHistory());
                            },
                          ),

                        SizedBox(height: Responsive.bottomListPadding(context)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LiveEcgPanel extends StatelessWidget {
  final _EcgSweepController controller;
  final bool hasSamples;
  final bool isStreaming;
  final String? statusText;
  final double? lastRrMs;
  final int rPeakCount;
  final VoidCallback? onStop;

  const _LiveEcgPanel({
    required this.controller,
    required this.hasSamples,
    required this.isStreaming,
    required this.statusText,
    required this.lastRrMs,
    required this.rPeakCount,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    const monitorGreen = Color(0xFF38F26D);
    const panelColor = Color(0xFF030A06);
    const borderColor = Color(0xFF0F3A1F);
    const panelInnerGlow = Color(0xFF0A1F10);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: monitorGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.monitor_heart_rounded,
                  color: monitorGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live ECG',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isStreaming && hasSamples) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: monitorGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: monitorGreen.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          isStreaming
                              ? (hasSamples
                                  ? 'Lead II - 130 Hz'
                                  : 'Acquiring...')
                              : (statusText ?? 'Standby'),
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color:
                                isStreaming && hasSamples
                                    ? monitorGreen.withValues(alpha: 0.7)
                                    : labelColor.withValues(alpha: 0.62),
                            fontFamily: 'monospace',
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Stop recording',
                onPressed: onStop,
                icon: const Icon(Icons.stop_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: panelInnerGlow,
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _EcgChartPainter(
                    controller: controller,
                    lineColor: monitorGreen,
                    gridColor: monitorGreen.withValues(alpha: 0.06),
                    majorGridColor: monitorGreen.withValues(alpha: 0.12),
                    baselineColor: monitorGreen.withValues(alpha: 0.15),
                  ),
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.95,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                if (hasSamples)
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Text(
                      'II',
                      style: TextStyle(
                        color: monitorGreen.withValues(alpha: 0.35),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                if (hasSamples)
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: monitorGreen.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _EcgOverlayMetric(
                            label: 'RR interval',
                            value:
                                lastRrMs != null
                                    ? '${lastRrMs!.round()} ms'
                                    : '--',
                            color: monitorGreen,
                          ),
                          const SizedBox(height: 3),
                          _EcgOverlayMetric(
                            label: 'R peaks',
                            value: rPeakCount > 0 ? '$rPeakCount' : '--',
                            color: monitorGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!hasSamples)
                  Center(
                    child: Text(
                      statusText ?? 'Waiting for ECG signal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EcgOverlayMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _EcgOverlayMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: color.withValues(alpha: 0.52),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _CascadedBiquad {
  final _BiquadFilter _stage1;
  final _BiquadFilter _stage2;

  _CascadedBiquad._(this._stage1, this._stage2);

  factory _CascadedBiquad.lowPass({
    required double sampleRateHz,
    required double cutoffHz,
  }) {
    return _CascadedBiquad._(
      _BiquadFilter.lowPass(
        sampleRateHz: sampleRateHz,
        cutoffHz: cutoffHz,
        q: 0.5412,
      ),
      _BiquadFilter.lowPass(
        sampleRateHz: sampleRateHz,
        cutoffHz: cutoffHz,
        q: 1.3066,
      ),
    );
  }

  double process(double input) => _stage2.process(_stage1.process(input));

  void initSteadyState(double x0) {
    _stage1.initSteadyState(x0);
    _stage2.initSteadyState(x0 * _stage1.dcGain);
  }

  void reset() {
    _stage1.reset();
    _stage2.reset();
  }
}

class _MedianBaseline {
  static const int _winSize = 260;
  final List<double> _ring = List<double>.filled(_winSize, 0);
  int _head = 0;
  int _count = 0;

  double removeBaseline(double sample) {
    _ring[_head] = sample;
    _head = (_head + 1) % _winSize;
    if (_count < _winSize) _count++;
    final filled =
        _count < _winSize ? _ring.sublist(0, _count) : List<double>.from(_ring);
    filled.sort();
    final baseline = filled[filled.length ~/ 2];
    return sample - baseline;
  }

  void reset() {
    _ring.fillRange(0, _winSize, 0);
    _head = 0;
    _count = 0;
  }
}

class _RPeakMarker {
  final int displayIndex;
  final int rawSampleIndex;
  final double normalizedValue;

  const _RPeakMarker({
    required this.displayIndex,
    required this.rawSampleIndex,
    required this.normalizedValue,
  });
}

class _EcgSweepController extends ChangeNotifier {
  static const int rawSampleRateHz = 130;
  static const int upsampleFactor = 4;
  static const int displaySampleRateHz = rawSampleRateHz * upsampleFactor;
  static const int sweepSeconds = 10;
  static const int sweepSampleCount = displaySampleRateHz * sweepSeconds;
  static const double lowPassHz = 40.0;
  static const double notchHz = 50.0;
  static const double fixedMinUv = -1000.0;
  static const double fixedMaxUv = 2000.0;

  final List<double?> samples = List<double?>.filled(sweepSampleCount, null);
  final List<_RPeakMarker> rPeakMarkers = [];
  final List<double> _rawWindow = [];

  final _MedianBaseline _medianBaseline = _MedianBaseline();
  final _BiquadFilter _notch = _BiquadFilter.notch(
    sampleRateHz: rawSampleRateHz.toDouble(),
    centerHz: notchHz,
    q: 5.0,
  );
  final _CascadedBiquad _lowPass = _CascadedBiquad.lowPass(
    sampleRateHz: rawSampleRateHz.toDouble(),
    cutoffHz: lowPassHz,
  );

  late final Timer _renderTimer;

  int _sampleCount = 0;
  int _rawSampleCount = 0;
  int _lastMarkedRawSampleIndex = -1;
  int sweepCursor = 0;
  bool hasSamples = false;
  bool _dirty = false;
  bool _filtersInitialized = false;

  _EcgSweepController() {
    _renderTimer = Timer.periodic(const Duration(microseconds: 16667), (_) {
      if (!_dirty) return;
      _dirty = false;
      notifyListeners();
    });
  }

  void reset() {
    samples.fillRange(0, samples.length, null);
    _rawWindow.clear();
    rPeakMarkers.clear();
    _medianBaseline.reset();
    _notch.reset();
    _lowPass.reset();
    _sampleCount = 0;
    _rawSampleCount = 0;
    _lastMarkedRawSampleIndex = -1;
    sweepCursor = 0;
    hasSamples = false;
    _dirty = false;
    _filtersInitialized = false;
    notifyListeners();
  }

  void addRawBatch(Iterable<double> rawValues) {
    for (final raw in rawValues) {
      if (!raw.isFinite) continue;

      if (!_filtersInitialized) {
        _filtersInitialized = true;
        _notch.initSteadyState(0);
        _lowPass.initSteadyState(0);
      }

      final baselineFree = _medianBaseline.removeBaseline(raw);
      final filtered = _lowPass.process(_notch.process(baselineFree));

      _rawWindow.add(filtered);
      if (_rawWindow.length < 2) {
        _writeNormalized(filtered);
        _rawSampleCount++;
        continue;
      }

      final n = _rawWindow.length;
      final iSrc = n - 2;
      final y0 = _rawWindow[iSrc];
      final y1 = _rawWindow[iSrc + 1 < n ? iSrc + 1 : iSrc];
      final d0 = _pchipSlope(iSrc);
      final d1 = _pchipSlope(iSrc + 1 < n ? iSrc + 1 : iSrc);

      for (var i = 0; i < upsampleFactor; i++) {
        final t = i / upsampleFactor;
        _writeNormalized(_hermiteInterp(y0, y1, d0, d1, t));
      }

      if (_rawWindow.length > 4) {
        _rawWindow.removeAt(0);
      }
      _rawSampleCount++;
    }

    _dirty = true;
  }

  void markRPeak(int rawSampleIndex, double amplitudeUv) {
    if (rawSampleIndex <= _lastMarkedRawSampleIndex) return;
    _lastMarkedRawSampleIndex = rawSampleIndex;

    final displayIndex =
        (rawSampleIndex * upsampleFactor).abs() % sweepSampleCount;
    final normalized =
        samples[displayIndex] ?? _normalizeFixedVoltage(amplitudeUv);

    rPeakMarkers.add(
      _RPeakMarker(
        displayIndex: displayIndex,
        rawSampleIndex: rawSampleIndex,
        normalizedValue: normalized,
      ),
    );

    final oldestVisibleRaw = _rawSampleCount - rawSampleRateHz * sweepSeconds;
    rPeakMarkers.removeWhere(
      (marker) => marker.rawSampleIndex < oldestVisibleRaw,
    );
    _dirty = true;
  }

  double _pchipSlope(int i) {
    final n = _rawWindow.length;
    if (n < 2) return 0.0;
    if (i <= 0) {
      return n > 1 ? _rawWindow[1] - _rawWindow[0] : 0.0;
    }
    if (i >= n - 1) {
      return n > 1 ? _rawWindow[n - 1] - _rawWindow[n - 2] : 0.0;
    }
    final dLeft = _rawWindow[i] - _rawWindow[i - 1];
    final dRight = _rawWindow[i + 1] - _rawWindow[i];
    if (dLeft * dRight <= 0) return 0.0;
    return 2.0 * dLeft * dRight / (dLeft + dRight);
  }

  double _hermiteInterp(double y0, double y1, double d0, double d1, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    return (2 * t3 - 3 * t2 + 1) * y0 +
        (t3 - 2 * t2 + t) * d0 +
        (-2 * t3 + 3 * t2) * y1 +
        (t3 - t2) * d1;
  }

  void _writeNormalized(double filteredUv) {
    samples[sweepCursor] = _normalizeFixedVoltage(filteredUv);
    _sampleCount++;
    sweepCursor = _sampleCount % samples.length;
    hasSamples = true;
  }

  double _normalizeFixedVoltage(double uv) {
    const span = fixedMaxUv - fixedMinUv;
    return ((uv - fixedMinUv) / span).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _renderTimer.cancel();
    super.dispose();
  }
}

class _BiquadFilter {
  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;

  double _z1 = 0;
  double _z2 = 0;

  _BiquadFilter._({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  factory _BiquadFilter.lowPass({
    required double sampleRateHz,
    required double cutoffHz,
    double q = math.sqrt1_2,
  }) {
    final coeffs = _BiquadCoefficients.forCutoff(
      sampleRateHz: sampleRateHz,
      frequencyHz: cutoffHz,
      q: q,
      type: _BiquadType.lowPass,
    );
    return _BiquadFilter._(
      b0: coeffs.b0,
      b1: coeffs.b1,
      b2: coeffs.b2,
      a1: coeffs.a1,
      a2: coeffs.a2,
    );
  }

  factory _BiquadFilter.notch({
    required double sampleRateHz,
    required double centerHz,
    double q = 30.0,
  }) {
    final coeffs = _BiquadCoefficients.forCutoff(
      sampleRateHz: sampleRateHz,
      frequencyHz: centerHz,
      q: q,
      type: _BiquadType.notch,
    );
    return _BiquadFilter._(
      b0: coeffs.b0,
      b1: coeffs.b1,
      b2: coeffs.b2,
      a1: coeffs.a1,
      a2: coeffs.a2,
    );
  }

  double get dcGain {
    final denom = 1.0 + a1 + a2;
    if (denom.abs() < 1e-12) return 0.0;
    return (b0 + b1 + b2) / denom;
  }

  double process(double x) {
    final y = b0 * x + _z1;
    _z1 = b1 * x - a1 * y + _z2;
    _z2 = b2 * x - a2 * y;
    return y;
  }

  void initSteadyState(double x0) {
    final y0 = dcGain * x0;
    _z2 = (b2 * x0) - (a2 * y0);
    _z1 = (b1 * x0) - (a1 * y0) + _z2;
  }

  void reset() {
    _z1 = 0;
    _z2 = 0;
  }
}

enum _BiquadType { highPass, lowPass, notch }

class _BiquadCoefficients {
  final double b0, b1, b2, a1, a2;

  const _BiquadCoefficients({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  factory _BiquadCoefficients.forCutoff({
    required double sampleRateHz,
    required double frequencyHz,
    required double q,
    required _BiquadType type,
  }) {
    final omega = 2 * math.pi * frequencyHz / sampleRateHz;
    final sinOmega = math.sin(omega);
    final cosOmega = math.cos(omega);
    final alpha = sinOmega / (2 * q);

    late double b0, b1, b2;
    switch (type) {
      case _BiquadType.highPass:
        b0 = (1 + cosOmega) / 2;
        b1 = -(1 + cosOmega);
        b2 = (1 + cosOmega) / 2;
      case _BiquadType.lowPass:
        b0 = (1 - cosOmega) / 2;
        b1 = 1 - cosOmega;
        b2 = (1 - cosOmega) / 2;
      case _BiquadType.notch:
        b0 = 1;
        b1 = -2 * cosOmega;
        b2 = 1;
    }

    final a0 = 1 + alpha;
    return _BiquadCoefficients(
      b0: b0 / a0,
      b1: b1 / a0,
      b2: b2 / a0,
      a1: (-2 * cosOmega) / a0,
      a2: (1 - alpha) / a0,
    );
  }
}

class _EcgChartPainter extends CustomPainter {
  final _EcgSweepController controller;
  final Color lineColor;
  final Color gridColor;
  final Color majorGridColor;
  final Color baselineColor;

  _EcgChartPainter({
    required this.controller,
    required this.lineColor,
    required this.gridColor,
    required this.majorGridColor,
    required this.baselineColor,
  }) : super(repaint: controller);

  static const double _padLeft = 48;
  static const double _padRight = 8;
  static const double _padTop = 6;
  static const double _padBottom = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final samples = controller.samples;
    final totalWritten = controller._sampleCount;
    final displayRate = _EcgSweepController.displaySampleRateHz;
    final sweepSec = _EcgSweepController.sweepSeconds;

    final plotLeft = _padLeft;
    final plotRight = size.width - _padRight;
    final plotTop = _padTop;
    final plotBottom = size.height - _padBottom;
    final plotW = plotRight - plotLeft;
    final plotH = plotBottom - plotTop;
    if (plotW <= 0 || plotH <= 0) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(plotLeft, plotTop, plotRight, plotBottom));

    const minorCellsX = 50;
    const minorCellsY = 20;
    final minorGridPaint =
        Paint()
          ..color = gridColor
          ..strokeWidth = 0.4;
    for (var i = 1; i < minorCellsY; i++) {
      final y = plotTop + plotH * i / minorCellsY;
      canvas.drawLine(
        Offset(plotLeft, y),
        Offset(plotRight, y),
        minorGridPaint,
      );
    }
    for (var i = 1; i < minorCellsX; i++) {
      final x = plotLeft + plotW * i / minorCellsX;
      canvas.drawLine(
        Offset(x, plotTop),
        Offset(x, plotBottom),
        minorGridPaint,
      );
    }

    final majorGridPaint =
        Paint()
          ..color = majorGridColor
          ..strokeWidth = 0.8;
    for (var i = 1; i < 4; i++) {
      final y = plotTop + plotH * i / 4;
      canvas.drawLine(
        Offset(plotLeft, y),
        Offset(plotRight, y),
        majorGridPaint,
      );
    }
    for (var i = 1; i < 10; i++) {
      final x = plotLeft + plotW * i / 10;
      canvas.drawLine(
        Offset(x, plotTop),
        Offset(x, plotBottom),
        majorGridPaint,
      );
    }

    final baselinePaint =
        Paint()
          ..color = baselineColor
          ..strokeWidth = 1.0;
    final baselineY = plotTop + plotH / 2;
    canvas.drawLine(
      Offset(plotLeft, baselineY),
      Offset(plotRight, baselineY),
      baselinePaint,
    );

    if (!controller.hasSamples) {
      canvas.restore();
      return;
    }

    final endSample = totalWritten;
    final bufLen = samples.length;
    final startSample = math.max(0, endSample - bufLen);
    final visibleCount = endSample - startSample;
    if (visibleCount < 2) {
      canvas.restore();
      return;
    }

    final segments = <List<Offset>>[];
    var curSeg = <Offset>[];

    for (var s = startSample; s < endSample; s++) {
      final v = samples[s % bufLen];
      if (v == null) {
        if (curSeg.length > 1) segments.add(curSeg);
        curSeg = <Offset>[];
        continue;
      }
      final frac = (s - startSample) / (visibleCount - 1);
      final x = plotLeft + frac * plotW;
      final y = plotBottom - v * plotH;
      curSeg.add(Offset(x, y));
    }
    if (curSeg.length > 1) segments.add(curSeg);

    for (final seg in segments) {
      _drawEcgSegment(canvas, seg);
    }

    _drawRPeakMarkers(
      canvas,
      plotLeft,
      plotW,
      plotTop,
      plotH,
      plotBottom,
      startSample,
      visibleCount,
    );

    canvas.restore();

    _drawYAxisLabels(canvas, size, plotLeft, plotTop, plotH);
    _drawXAxisLabels(
      canvas,
      size,
      plotLeft,
      plotW,
      plotBottom,
      endSample,
      displayRate,
      sweepSec,
    );

    final scanlinePaint =
        Paint()
          ..color = const Color(0x04000000)
          ..strokeWidth = 0.5;
    for (var y = plotTop; y < plotBottom; y += 3.0) {
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), scanlinePaint);
    }
  }

  void _drawEcgSegment(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final path = _buildSplinePath(points);

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withValues(alpha: 0.08)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withValues(alpha: 0.20)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withValues(alpha: 0.95)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawRPeakMarkers(
    Canvas canvas,
    double plotLeft,
    double plotW,
    double plotTop,
    double plotH,
    double plotBottom,
    int startSample,
    int visibleCount,
  ) {
    if (controller.rPeakMarkers.isEmpty) return;

    final markerPaint =
        Paint()
          ..color = const Color(0xFFFF4D5D).withValues(alpha: 0.92)
          ..style = PaintingStyle.fill;
    final haloPaint =
        Paint()
          ..color = const Color(0xFFFF4D5D).withValues(alpha: 0.20)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final marker in controller.rPeakMarkers) {
      final displaySample =
          marker.rawSampleIndex * _EcgSweepController.upsampleFactor;
      if (displaySample < startSample ||
          displaySample >= startSample + visibleCount) {
        continue;
      }
      final frac =
          (displaySample - startSample) / math.max(1, visibleCount - 1);
      final x = plotLeft + frac * plotW;
      final y = plotBottom - marker.normalizedValue * plotH;

      canvas.drawCircle(Offset(x, y), 8, haloPaint);
      canvas.drawCircle(Offset(x, y), 3.5, markerPaint);
    }
  }

  void _drawYAxisLabels(
    Canvas canvas,
    Size size,
    double plotLeft,
    double plotTop,
    double plotH,
  ) {
    final labelStyle = TextStyle(
      color: lineColor.withValues(alpha: 0.48),
      fontSize: 9,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
    );

    for (var i = 0; i <= 3; i++) {
      final kuVValue = 2 - i;
      final y = plotTop + plotH * i / 3.0;
      final text = '$kuVValue';
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(plotLeft - tp.width - 6, y - tp.height / 2));
    }

    final unitTp = TextPainter(
      text: TextSpan(text: 'k uV', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    unitTp.paint(canvas, Offset(4, plotTop));
  }

  void _drawXAxisLabels(
    Canvas canvas,
    Size size,
    double plotLeft,
    double plotW,
    double plotBottom,
    int endSample,
    int displayRate,
    int sweepSec,
  ) {
    final labelStyle = TextStyle(
      color: lineColor.withValues(alpha: 0.48),
      fontSize: 9,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
    );

    final endTimeSec = endSample / displayRate;
    final startTimeSec = math.max(0.0, endTimeSec - sweepSec);
    final spanSec = endTimeSec - startTimeSec;
    if (spanSec <= 0) return;

    final firstTick = (startTimeSec / 2).ceil() * 2.0;
    for (var t = firstTick; t <= endTimeSec; t += 2.0) {
      final frac = (t - startTimeSec) / spanSec;
      final x = plotLeft + frac * plotW;
      final text = '${t.toStringAsFixed(0)}s';
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (x - tp.width / 2).clamp(
        plotLeft,
        plotLeft + plotW - tp.width,
      );
      tp.paint(canvas, Offset(dx, plotBottom + 4));
    }
  }

  Path _buildSplinePath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
      return path;
    }

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final c1 = p1 + (p2 - p0) / 6.0;
      final c2 = p2 - (p3 - p1) / 6.0;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _EcgChartPainter oldDelegate) => true;
}
