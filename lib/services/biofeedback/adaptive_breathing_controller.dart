library;

import 'dart:async';

import 'package:breath_state/services/biofeedback/realtime_hrv_engine.dart';

class AdaptiveBreathingState {
  final double currentRateBpm;

  final int inhaleMs;

  final int exhaleMs;

  final double coherence;

  final double? rmssd;

  final int lastAdjustmentDirection;

  final int adjustmentCount;

  final String adjustmentReason;

  const AdaptiveBreathingState({
    required this.currentRateBpm,
    required this.inhaleMs,
    required this.exhaleMs,
    required this.coherence,
    this.rmssd,
    required this.lastAdjustmentDirection,
    required this.adjustmentCount,
    required this.adjustmentReason,
  });
}

class AdaptiveBreathingController {
  final double initialRateBpm;

  final double minBpm;

  final double maxBpm;

  final double stepBpm;

  final int adjustmentIntervalSec;

  final double coherenceImprovementThreshold;

  final RealtimeHrvEngine hrvEngine;

  double _currentRate;
  int _lastDirection = 0;
  int _adjustmentCount = 0;
  String _adjustmentReason = 'Initial rate';
  double _prevCoherence = 0;
  double _prevRmssd = 0;
  double _bestCoherence = 0;
  double _bestRate = 0;

  Timer? _adjustTimer;
  StreamSubscription<RealtimeHrvSnapshot>? _hrvSub;
  RealtimeHrvSnapshot? _latestSnapshot;

  final StreamController<AdaptiveBreathingState> _stateController =
      StreamController<AdaptiveBreathingState>.broadcast();

  AdaptiveBreathingController({
    required this.hrvEngine,
    this.initialRateBpm = 6.0,
    this.minBpm = 4.5,
    this.maxBpm = 7.5,
    this.stepBpm = 0.2,
    this.adjustmentIntervalSec = 30,
    this.coherenceImprovementThreshold = 3.0,
  }) : _currentRate = initialRateBpm,
       _bestRate = initialRateBpm;

  Stream<AdaptiveBreathingState> get stateStream => _stateController.stream;

  double get currentRate => _currentRate;

  int get inhaleMs => (60000.0 / _currentRate / 2).round();

  int get exhaleMs => (60000.0 / _currentRate / 2).round();

  void start() {
    _hrvSub = hrvEngine.snapshots.listen((snapshot) {
      _latestSnapshot = snapshot;
    });

    _adjustTimer = Timer.periodic(
      Duration(seconds: adjustmentIntervalSec),
      (_) => _evaluate(),
    );

    _emitState();
  }

  void stop() {
    _adjustTimer?.cancel();
    _adjustTimer = null;
    _hrvSub?.cancel();
    _hrvSub = null;
  }

  void dispose() {
    stop();
    _stateController.close();
  }

  void forceEvaluate() => _evaluate();

  void _evaluate() {
    if (_stateController.isClosed) return;

    final snapshot = _latestSnapshot;
    if (snapshot == null) {
      _adjustmentReason = 'Waiting for HRV data';
      _emitState();
      return;
    }

    final double currentCoherence = snapshot.coherence;
    final double currentRmssd = snapshot.timeDomain?.rmssd ?? 0;

    final double coherenceDelta = currentCoherence - _prevCoherence;
    final double rmssdDelta = currentRmssd - _prevRmssd;

    if (currentCoherence > _bestCoherence) {
      _bestCoherence = currentCoherence;
      _bestRate = _currentRate;
    }

    if (coherenceDelta > coherenceImprovementThreshold) {
      _adjustmentReason = 'Coherence improving — holding rate';
      _lastDirection = 0;
    } else if (coherenceDelta < -coherenceImprovementThreshold) {
      if (_lastDirection != 0) {
        _lastDirection = -_lastDirection;
        _adjustmentReason = 'Coherence dropped — reversing direction';
      } else {
        if (_bestRate < _currentRate) {
          _lastDirection = -1;
        } else if (_bestRate > _currentRate) {
          _lastDirection = 1;
        } else {
          _lastDirection = -1;
        }
        _adjustmentReason = 'Coherence dropped — seeking better rate';
      }
      _applyAdjustment();
    } else {
      if (rmssdDelta > 2.0) {
        _adjustmentReason = 'Stable coherence, RMSSD improving — hold';
        _lastDirection = 0;
      } else if (_adjustmentCount < 3) {
        if (_lastDirection == 0) {
          _lastDirection = -1; 
        }
        _adjustmentReason = 'Exploring — nudging rate';
        _applyAdjustment();
      } else {
        _adjustmentReason = 'Stable — maintaining rate';
        _lastDirection = 0;
      }
    }

    _prevCoherence = currentCoherence;
    _prevRmssd = currentRmssd;
    _emitState();
  }

  void _applyAdjustment() {
    final double newRate = _currentRate + (_lastDirection * stepBpm);
    _currentRate = newRate.clamp(minBpm, maxBpm);
    _adjustmentCount++;
  }

  void _emitState() {
    if (_stateController.isClosed) return;
    _stateController.add(
      AdaptiveBreathingState(
        currentRateBpm: _currentRate,
        inhaleMs: inhaleMs,
        exhaleMs: exhaleMs,
        coherence: _latestSnapshot?.coherence ?? 0,
        rmssd: _latestSnapshot?.timeDomain?.rmssd,
        lastAdjustmentDirection: _lastDirection,
        adjustmentCount: _adjustmentCount,
        adjustmentReason: _adjustmentReason,
      ),
    );
  }

  void reset() {
    _currentRate = initialRateBpm;
    _lastDirection = 0;
    _adjustmentCount = 0;
    _adjustmentReason = 'Reset';
    _prevCoherence = 0;
    _prevRmssd = 0;
    _bestCoherence = 0;
    _bestRate = initialRateBpm;
    _emitState();
  }
}
