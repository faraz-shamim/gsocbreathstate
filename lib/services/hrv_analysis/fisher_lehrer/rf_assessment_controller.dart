import 'dart:async';
import 'dart:math' as math;

import 'fisher_lehrer_background.dart';
import 'fisher_lehrer_models.dart';
import 'fisher_lehrer_protocol.dart';
import 'rf_acquisition_sources.dart';

enum RfAssessmentControllerState {
  idle,
  preflight,
  readyMeasured,
  readyEstimated,
  running,
  analyzing,
  completed,
  invalid,
  aborted,
}

enum RfBreathPhase { inhale, exhale }

enum RfAbortReason {
  userCancelled,
  polarDisconnected,
  beltDisconnected,
  appBackgrounded,
  webHidden,
  vrPaused,
  pacerTimingDiscontinuity,
  disposed,
}

typedef RfAnalysisRunner =
    Future<RfAssessmentResult> Function(RfAssessmentInput input);

abstract interface class RfMonotonicClock {
  bool get isRunning;
  int get elapsedMicroseconds;
  void start();
  void stop();
  void reset();
}

class StopwatchRfMonotonicClock implements RfMonotonicClock {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  bool get isRunning => _stopwatch.isRunning;

  @override
  int get elapsedMicroseconds => _stopwatch.elapsedMicroseconds;

  @override
  void reset() => _stopwatch.reset();

  @override
  void start() => _stopwatch.start();

  @override
  void stop() => _stopwatch.stop();
}

class RfAssessmentSnapshot {
  final RfAssessmentControllerState state;
  final RfAcquisitionMode? mode;
  final int cycleIndex;
  final int cycleCount;
  final RfBreathPhase phase;
  final double phaseProgress;
  final double scheduledBpm;
  final double elapsedMs;
  final double remainingMs;
  final int rrCount;
  final int respirationCount;
  final bool polarReady;
  final bool beltConnected;
  final bool beltSignalDetected;
  final String? message;
  final RfAbortReason? abortReason;
  final RfAssessmentResult? result;

  const RfAssessmentSnapshot({
    required this.state,
    required this.mode,
    required this.cycleIndex,
    required this.cycleCount,
    required this.phase,
    required this.phaseProgress,
    required this.scheduledBpm,
    required this.elapsedMs,
    required this.remainingMs,
    required this.rrCount,
    required this.respirationCount,
    required this.polarReady,
    required this.beltConnected,
    required this.beltSignalDetected,
    this.message,
    this.abortReason,
    this.result,
  });

  bool get isTerminal =>
      state == RfAssessmentControllerState.completed ||
      state == RfAssessmentControllerState.invalid ||
      state == RfAssessmentControllerState.aborted;

  RfAssessmentSnapshot copyWith({
    RfAssessmentControllerState? state,
    RfAcquisitionMode? mode,
    bool clearMode = false,
    int? cycleIndex,
    RfBreathPhase? phase,
    double? phaseProgress,
    double? scheduledBpm,
    double? elapsedMs,
    double? remainingMs,
    int? rrCount,
    int? respirationCount,
    bool? polarReady,
    bool? beltConnected,
    bool? beltSignalDetected,
    String? message,
    bool clearMessage = false,
    RfAbortReason? abortReason,
    bool clearAbortReason = false,
    RfAssessmentResult? result,
    bool clearResult = false,
  }) {
    return RfAssessmentSnapshot(
      state: state ?? this.state,
      mode: clearMode ? null : mode ?? this.mode,
      cycleIndex: cycleIndex ?? this.cycleIndex,
      cycleCount: cycleCount,
      phase: phase ?? this.phase,
      phaseProgress: phaseProgress ?? this.phaseProgress,
      scheduledBpm: scheduledBpm ?? this.scheduledBpm,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      remainingMs: remainingMs ?? this.remainingMs,
      rrCount: rrCount ?? this.rrCount,
      respirationCount: respirationCount ?? this.respirationCount,
      polarReady: polarReady ?? this.polarReady,
      beltConnected: beltConnected ?? this.beltConnected,
      beltSignalDetected: beltSignalDetected ?? this.beltSignalDetected,
      message: clearMessage ? null : message ?? this.message,
      abortReason: clearAbortReason ? null : abortReason ?? this.abortReason,
      result: clearResult ? null : result ?? this.result,
    );
  }
}

                                                                           
   
                                                                                
class RfAssessmentController {
  final FisherLehrerProtocolConfig protocol;
  final RfPolarAcquisitionSource polarSource;
  final RfRespirationAcquisitionSource? respirationSource;
  final RfMonotonicClock clock;
  final RfAnalysisRunner analysisRunner;
  final Duration tickInterval;
  final Duration polarPreflightTimeout;
  final Duration beltPreflightTimeout;
  final Duration maximumTickGap;
  final int minimumBeltMovementSamples;
  final double minimumBeltMovementRange;
  final bool automaticTicker;

  final StreamController<RfAssessmentSnapshot> _snapshotController =
      StreamController<RfAssessmentSnapshot>.broadcast();
  StreamSubscription<List<double>>? _rrSubscription;
  StreamSubscription<RfRespirationReading>? _respirationSubscription;
  StreamSubscription<bool>? _polarConnectionSubscription;
  StreamSubscription<bool>? _beltConnectionSubscription;
  Timer? _ticker;

  final List<RfBeatSample> _rrSamples = [];
  final List<RfRespirationSample> _respirationSamples = [];
  Completer<void>? _firstRrCompleter;
  Completer<void>? _beltMovementCompleter;
  double _preflightBeltMinimum = double.infinity;
  double _preflightBeltMaximum = -double.infinity;
  int _preflightRrCount = 0;
  int _preflightRespirationCount = 0;
  bool _beltSignalDetected = false;
  double? _lastBeatElapsedMs;
  double? _lastTickElapsedMs;
  bool _completionStarted = false;
  bool _disposed = false;

  late RfAssessmentSnapshot _snapshot;

  RfAssessmentController({
    required this.polarSource,
    this.respirationSource,
    this.protocol = const FisherLehrerProtocolConfig(),
    RfMonotonicClock? clock,
    RfAnalysisRunner? analysisRunner,
    this.tickInterval = const Duration(milliseconds: 50),
    this.polarPreflightTimeout = const Duration(seconds: 12),
    this.beltPreflightTimeout = const Duration(seconds: 3),
    this.maximumTickGap = const Duration(seconds: 2),
    this.minimumBeltMovementSamples = 5,
    this.minimumBeltMovementRange = 1e-6,
    this.automaticTicker = true,
  }) : clock = clock ?? StopwatchRfMonotonicClock(),
       analysisRunner = analysisRunner ?? analyzeFisherLehrerInBackground {
    final firstCycle = protocol.buildSchedule().first;
    _snapshot = RfAssessmentSnapshot(
      state: RfAssessmentControllerState.idle,
      mode: null,
      cycleIndex: 0,
      cycleCount: protocol.cycleCount,
      phase: RfBreathPhase.inhale,
      phaseProgress: 0,
      scheduledBpm: firstCycle.scheduledBpm,
      elapsedMs: 0,
      remainingMs: protocol.scheduledDurationMs,
      rrCount: 0,
      respirationCount: 0,
      polarReady: false,
      beltConnected: respirationSource?.isConnected ?? false,
      beltSignalDetected: false,
    );
  }

  Stream<RfAssessmentSnapshot> get snapshots => _snapshotController.stream;
  RfAssessmentSnapshot get snapshot => _snapshot;
  List<RfBeatSample> get rrSamples => List.unmodifiable(_rrSamples);
  List<RfRespirationSample> get respirationSamples =>
      List.unmodifiable(_respirationSamples);

  Future<void> initializePreflight() async {
    _assertNotDisposed();
    await _cancelSubscriptions(stopSources: true);
    _resetCollection();
    _completionStarted = false;
    _preflightRrCount = 0;
    _preflightRespirationCount = 0;
    _preflightBeltMinimum = double.infinity;
    _preflightBeltMaximum = -double.infinity;
    _beltSignalDetected = false;
    _firstRrCompleter = Completer<void>();
    _beltMovementCompleter = Completer<void>();
    _emit(
      _snapshot.copyWith(
        state: RfAssessmentControllerState.preflight,
        clearMode: true,
        polarReady: false,
        beltConnected: respirationSource?.isConnected ?? false,
        beltSignalDetected: false,
        rrCount: 0,
        respirationCount: 0,
        message: 'Checking Polar RR and respiration signals.',
        clearAbortReason: true,
        clearResult: true,
      ),
    );

    _polarConnectionSubscription = polarSource.connectionStateChanges.listen(
      _onPolarConnectionChanged,
      onError: _onPolarStreamError,
    );
    if (respirationSource != null) {
      _beltConnectionSubscription = respirationSource!.connectionStateChanges
          .listen(_onBeltConnectionChanged, onError: _onBeltStreamError);
    }

    final results = await Future.wait<bool>([
      _startPolarPreflight(),
      _startBeltPreflight(),
    ]);
    if (_disposed || _snapshot.state != RfAssessmentControllerState.preflight) {
      return;
    }

    final polarReady = results[0];
    final beltReady = results[1];
    if (!polarReady) {
      await _cancelSubscriptions(stopSources: true);
      _emit(
        _snapshot.copyWith(
          state: RfAssessmentControllerState.invalid,
          polarReady: false,
          message: 'No valid Polar RR intervals were received.',
        ),
      );
      return;
    }

    if (!beltReady) {
      await _respirationSubscription?.cancel();
      _respirationSubscription = null;
      await _safeStopRespiration();
    }
    _emit(
      _snapshot.copyWith(
        state:
            beltReady
                ? RfAssessmentControllerState.readyMeasured
                : RfAssessmentControllerState.readyEstimated,
        mode:
            beltReady
                ? RfAcquisitionMode.measured
                : RfAcquisitionMode.estimated,
        polarReady: true,
        beltConnected: respirationSource?.isConnected ?? false,
        beltSignalDetected: beltReady,
        rrCount: _preflightRrCount,
        respirationCount: _preflightRespirationCount,
        message:
            beltReady
                ? 'Polar RR and GDX-RB signals are ready.'
                : 'Polar RR is ready. RF will be estimated from pacer timing.',
      ),
    );
  }

  Future<void> startAssessment({RfAcquisitionMode? mode}) async {
    _assertNotDisposed();
    final state = _snapshot.state;
    if (state != RfAssessmentControllerState.readyMeasured &&
        state != RfAssessmentControllerState.readyEstimated) {
      throw StateError('RF assessment is not ready to start.');
    }
    final selectedMode = mode ?? _snapshot.mode ?? RfAcquisitionMode.estimated;
    if (selectedMode == RfAcquisitionMode.measured && !_beltSignalDetected) {
      throw StateError('Measured mode requires a live GDX-RB signal.');
    }
    if (selectedMode == RfAcquisitionMode.estimated) {
      await _respirationSubscription?.cancel();
      _respirationSubscription = null;
      await _safeStopRespiration();
    }

    _resetCollection();
    _completionStarted = false;
    clock
      ..reset()
      ..start();
    _emitRunningSnapshot(selectedMode, 0);
    if (automaticTicker) {
      _ticker = Timer.periodic(tickInterval, (_) => tick());
    }
  }

                                                       
     
                                                                
  void tick() {
    if (_snapshot.state != RfAssessmentControllerState.running ||
        _completionStarted) {
      return;
    }
    final elapsedMs = clock.elapsedMicroseconds / 1000;
    if (_lastTickElapsedMs != null &&
        elapsedMs < protocol.scheduledDurationMs &&
        elapsedMs - _lastTickElapsedMs! >
            maximumTickGap.inMicroseconds / 1000) {
      unawaited(abort(RfAbortReason.pacerTimingDiscontinuity));
      return;
    }
    _lastTickElapsedMs = elapsedMs;
    if (elapsedMs >= protocol.scheduledDurationMs) {
      unawaited(_completeAssessment());
      return;
    }
    _emitRunningSnapshot(_snapshot.mode!, elapsedMs);
  }

  Future<void> abort(RfAbortReason reason) async {
    if (_disposed && reason != RfAbortReason.disposed) return;
    if (_snapshot.isTerminal || _completionStarted) return;
    _completionStarted = true;
    _ticker?.cancel();
    _ticker = null;
    clock.stop();
    _emit(
      _snapshot.copyWith(
        state: RfAssessmentControllerState.aborted,
        abortReason: reason,
        message: _abortMessage(reason),
      ),
    );
    await _cancelSubscriptions(stopSources: true);
  }

  Future<void> _completeAssessment() async {
    if (_completionStarted ||
        _snapshot.state != RfAssessmentControllerState.running) {
      return;
    }
    _completionStarted = true;
    _ticker?.cancel();
    _ticker = null;
    clock.stop();
    final mode = _snapshot.mode!;
    _emit(
      _snapshot.copyWith(
        state: RfAssessmentControllerState.analyzing,
        elapsedMs: protocol.scheduledDurationMs,
        remainingMs: 0,
        cycleIndex: protocol.cycleCount - 1,
        message: 'Analyzing the completed RF assessment.',
      ),
    );
    await _cancelSubscriptions(stopSources: true);

    try {
      final result = await analysisRunner(
        RfAssessmentInput(
          protocol: protocol,
          rrSamples: List.unmodifiable(_rrSamples),
          respirationSamples:
              mode == RfAcquisitionMode.measured
                  ? List.unmodifiable(_respirationSamples)
                  : const [],
          mode: mode,
          completedCycles: protocol.cycleCount,
        ),
      );
      if (_disposed) return;
      _emit(
        _snapshot.copyWith(
          state:
              result.status == RfResultStatus.completed
                  ? RfAssessmentControllerState.completed
                  : RfAssessmentControllerState.invalid,
          result: result,
          message:
              result.status == RfResultStatus.completed
                  ? 'RF assessment complete.'
                  : 'The completed assessment did not pass quality checks.',
        ),
      );
    } catch (error) {
      if (_disposed) return;
      _emit(
        _snapshot.copyWith(
          state: RfAssessmentControllerState.invalid,
          message: 'RF analysis failed: $error',
        ),
      );
    }
  }

  Future<bool> _startPolarPreflight() async {
    try {
      final stream = await polarSource.startRrBatches();
      _rrSubscription = stream.listen(_onRrBatch, onError: _onPolarStreamError);
      await _firstRrCompleter!.future.timeout(polarPreflightTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _startBeltPreflight() async {
    final source = respirationSource;
    if (source == null || !source.isConnected) return false;
    try {
      _respirationSubscription = source.readings.listen(
        _onRespirationReading,
        onError: _onBeltStreamError,
      );
      await source.startRespiration();
      await _beltMovementCompleter!.future.timeout(beltPreflightTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onRrBatch(List<double> batch) {
    final valid = batch
        .where((rr) => rr.isFinite && rr > 0)
        .toList(growable: false);
    if (valid.isEmpty) return;
    if (_snapshot.state == RfAssessmentControllerState.preflight) {
      _preflightRrCount += valid.length;
      if (!(_firstRrCompleter?.isCompleted ?? true)) {
        _firstRrCompleter!.complete();
      }
      _emit(_snapshot.copyWith(rrCount: _preflightRrCount, polarReady: true));
      return;
    }
    if (_snapshot.state != RfAssessmentControllerState.running) return;

    final arrivalMs = clock.elapsedMicroseconds / 1000;
    var beatElapsedMs =
        _lastBeatElapsedMs ??
        arrivalMs - valid.fold<double>(0, (sum, rr) => sum + rr);
    for (final rrMs in valid) {
      beatElapsedMs += rrMs;
      if (beatElapsedMs < 0) continue;
      _rrSamples.add(
        RfBeatSample(
          elapsedMs: beatElapsedMs,
          rrMs: rrMs,
          notificationElapsedMs: arrivalMs,
        ),
      );
    }
    _lastBeatElapsedMs = beatElapsedMs;
  }

  void _onRespirationReading(RfRespirationReading reading) {
    if (reading.sensorNumber != 1 || !reading.value.isFinite) return;
    if (_snapshot.state == RfAssessmentControllerState.preflight) {
      _preflightRespirationCount++;
      _preflightBeltMinimum = math.min(_preflightBeltMinimum, reading.value);
      _preflightBeltMaximum = math.max(_preflightBeltMaximum, reading.value);
      if (_preflightRespirationCount >= minimumBeltMovementSamples &&
          _preflightBeltMaximum - _preflightBeltMinimum >=
              minimumBeltMovementRange) {
        _beltSignalDetected = true;
        if (!(_beltMovementCompleter?.isCompleted ?? true)) {
          _beltMovementCompleter!.complete();
        }
      }
      _emit(
        _snapshot.copyWith(
          respirationCount: _preflightRespirationCount,
          beltSignalDetected: _beltSignalDetected,
        ),
      );
      return;
    }
    if (_snapshot.state != RfAssessmentControllerState.running ||
        _snapshot.mode != RfAcquisitionMode.measured) {
      return;
    }
    _respirationSamples.add(
      RfRespirationSample(
        elapsedMs: clock.elapsedMicroseconds / 1000,
        value: reading.value,
        sensorNumber: reading.sensorNumber,
      ),
    );
  }

  void _onPolarConnectionChanged(bool connected) {
    if (connected) return;
    if (_snapshot.state == RfAssessmentControllerState.running) {
      unawaited(abort(RfAbortReason.polarDisconnected));
    } else if (_snapshot.state == RfAssessmentControllerState.preflight) {
      if (!(_firstRrCompleter?.isCompleted ?? true)) {
        _firstRrCompleter!.completeError(
          StateError('Polar disconnected during preflight.'),
        );
      }
    } else if (_snapshot.state == RfAssessmentControllerState.readyMeasured ||
        _snapshot.state == RfAssessmentControllerState.readyEstimated) {
      unawaited(_invalidateReadyPolar());
    }
  }

  void _onBeltConnectionChanged(bool connected) {
    if (connected) return;
    if (_snapshot.state == RfAssessmentControllerState.running &&
        _snapshot.mode == RfAcquisitionMode.measured) {
      unawaited(abort(RfAbortReason.beltDisconnected));
    } else if (_snapshot.state == RfAssessmentControllerState.preflight) {
      if (!(_beltMovementCompleter?.isCompleted ?? true)) {
        _beltMovementCompleter!.completeError(
          StateError('Respiration belt disconnected during preflight.'),
        );
      }
    } else if (_snapshot.state == RfAssessmentControllerState.readyMeasured) {
      unawaited(_downgradeReadyToEstimated());
    }
  }

  void _onPolarStreamError(Object error, StackTrace stackTrace) {
    if (_snapshot.state == RfAssessmentControllerState.running) {
      unawaited(abort(RfAbortReason.polarDisconnected));
    } else if (!(_firstRrCompleter?.isCompleted ?? true)) {
      _firstRrCompleter!.completeError(error, stackTrace);
    }
  }

  void _onBeltStreamError(Object error, StackTrace stackTrace) {
    if (_snapshot.state == RfAssessmentControllerState.running &&
        _snapshot.mode == RfAcquisitionMode.measured) {
      unawaited(abort(RfAbortReason.beltDisconnected));
    } else if (!(_beltMovementCompleter?.isCompleted ?? true)) {
      _beltMovementCompleter!.completeError(error, stackTrace);
    }
  }

  Future<void> _invalidateReadyPolar() async {
    await _cancelSubscriptions(stopSources: true);
    if (_disposed) return;
    _emit(
      _snapshot.copyWith(
        state: RfAssessmentControllerState.invalid,
        polarReady: false,
        message: 'Polar disconnected before the assessment started.',
      ),
    );
  }

  Future<void> _downgradeReadyToEstimated() async {
    await _respirationSubscription?.cancel();
    _respirationSubscription = null;
    await _safeStopRespiration();
    if (_disposed ||
        _snapshot.state != RfAssessmentControllerState.readyMeasured) {
      return;
    }
    _beltSignalDetected = false;
    _emit(
      _snapshot.copyWith(
        state: RfAssessmentControllerState.readyEstimated,
        mode: RfAcquisitionMode.estimated,
        beltConnected: false,
        beltSignalDetected: false,
        message: 'The belt disconnected. RF can continue only as an estimate.',
      ),
    );
  }

  void _emitRunningSnapshot(RfAcquisitionMode mode, double elapsedMs) {
    final cycle = protocol.cycleAtElapsedMs(elapsedMs);
    final cycleElapsed = elapsedMs - cycle.startElapsedMs;
    final isInhale = cycleElapsed < cycle.inhaleMs;
    final phaseElapsed =
        isInhale ? cycleElapsed : cycleElapsed - cycle.inhaleMs;
    final phaseDuration = isInhale ? cycle.inhaleMs : cycle.exhaleMs;
    _emit(
      _snapshot.copyWith(
        state: RfAssessmentControllerState.running,
        mode: mode,
        cycleIndex: cycle.index,
        phase: isInhale ? RfBreathPhase.inhale : RfBreathPhase.exhale,
        phaseProgress: (phaseElapsed / phaseDuration).clamp(0.0, 1.0),
        scheduledBpm: cycle.scheduledBpm,
        elapsedMs: elapsedMs,
        remainingMs: math.max(0, protocol.scheduledDurationMs - elapsedMs),
        rrCount: _rrSamples.length,
        respirationCount: _respirationSamples.length,
        polarReady: true,
        beltSignalDetected: _beltSignalDetected,
        clearMessage: true,
        clearAbortReason: true,
        clearResult: true,
      ),
    );
  }

  void _resetCollection() {
    _rrSamples.clear();
    _respirationSamples.clear();
    _lastBeatElapsedMs = null;
    _lastTickElapsedMs = null;
    clock
      ..stop()
      ..reset();
  }

  Future<void> _cancelSubscriptions({required bool stopSources}) async {
    _ticker?.cancel();
    _ticker = null;
    await _rrSubscription?.cancel();
    _rrSubscription = null;
    await _respirationSubscription?.cancel();
    _respirationSubscription = null;
    await _polarConnectionSubscription?.cancel();
    _polarConnectionSubscription = null;
    await _beltConnectionSubscription?.cancel();
    _beltConnectionSubscription = null;
    if (stopSources) {
      try {
        await polarSource.stopRrBatches();
      } catch (_) {}
      await _safeStopRespiration();
    }
  }

  Future<void> _safeStopRespiration() async {
    try {
      await respirationSource?.stopRespiration();
    } catch (_) {}
  }

  void _emit(RfAssessmentSnapshot value) {
    _snapshot = value;
    if (!_snapshotController.isClosed) {
      _snapshotController.add(value);
    }
  }

  String _abortMessage(RfAbortReason reason) => switch (reason) {
    RfAbortReason.userCancelled => 'RF assessment ended by the user.',
    RfAbortReason.polarDisconnected =>
      'Polar disconnected. Restart the RF assessment.',
    RfAbortReason.beltDisconnected =>
      'The respiration belt disconnected. Restart the RF assessment.',
    RfAbortReason.appBackgrounded =>
      'The app was backgrounded. Restart the RF assessment.',
    RfAbortReason.webHidden =>
      'The browser tab was hidden. Restart the RF assessment.',
    RfAbortReason.vrPaused => 'VR was paused. Restart the RF assessment.',
    RfAbortReason.pacerTimingDiscontinuity =>
      'Pacer timing was interrupted. Restart the RF assessment.',
    RfAbortReason.disposed => 'RF assessment controller was closed.',
  };

  void _assertNotDisposed() {
    if (_disposed) throw StateError('RF assessment controller is disposed.');
  }

  Future<void> dispose() async {
    if (_disposed) return;
    if (!_snapshot.isTerminal) {
      await abort(RfAbortReason.disposed);
    } else {
      await _cancelSubscriptions(stopSources: true);
    }
    _disposed = true;
    await _snapshotController.close();
  }
}
