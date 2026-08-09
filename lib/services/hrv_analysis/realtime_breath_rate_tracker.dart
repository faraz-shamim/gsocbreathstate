                                                                   
                                                                          
   
                                                                        
                                                              
                                                     
   
                                                    
                                                                       
                                                                   
                                           
                                                                          
                                                                       
                                                                   
                                             
                                                                 
library;

import 'dart:async';
import 'dart:math' as math;
import 'hrv_derived_breathing_rate.dart';

                                                                      
                                   
                                                                      

class BreathRateSnapshot {
                                                      
  final double breathRateBpm;

                                                        
  final double rawBreathRateBpm;

                                
  final double confidence;

                                                   
  final int windowSize;

                                
  final double windowDurationSec;

                                                    
  final HrvDerivedBreathingResult? detail;

                                                            
  final bool changeDetected;

                                 
  final DateTime timestamp;

  const BreathRateSnapshot({
    required this.breathRateBpm,
    required this.rawBreathRateBpm,
    required this.confidence,
    required this.windowSize,
    required this.windowDurationSec,
    this.detail,
    this.changeDetected = false,
    required this.timestamp,
  });
}

                                                                      
                                                  
                                                                      

                                                                 
   
                
                                                   
                                                          
                                                       
   
                                                             
                                                                 
                                                            
class _BreathRateKalman {
                                                                   
  double _x0 = 0;              
  double _x1 = 0;                                      

                                                                  
  double _p00 = 100.0;
  double _p01 = 0.0;
  double _p10 = 0.0;
  double _p11 = 10.0;

                                                                   
  double processNoiseRate;
  double processNoiseVelocity;
  final double baseMeasurementNoise;
  final double innovationGateStd;
  final double minAcceptConfidence;

  bool _initialized = false;

  _BreathRateKalman({
    this.processNoiseRate = 0.30,
    this.processNoiseVelocity = 0.08,
    this.baseMeasurementNoise = 1.0,
    this.innovationGateStd = 3.5,
    this.minAcceptConfidence = 0.08,
  });

  double get rate => _x0;
  double get velocity => _x1;
  double get uncertainty => math.sqrt(_p00.clamp(0.01, 1000.0));
  bool get isInitialized => _initialized;

  void reset() {
    _x0 = 0;
    _x1 = 0;
    _p00 = 100.0;
    _p01 = 0.0;
    _p10 = 0.0;
    _p11 = 10.0;
    _initialized = false;
  }

                                                                 
  void predict() {
    if (!_initialized) return;
    const double dt = 1.0;

    _x0 += _x1 * dt;

    final p00 = _p00 + dt * (_p10 + _p01) + dt * dt * _p11;
    final p01 = _p01 + dt * _p11;
    final p10 = _p10 + dt * _p11;
    final p11 = _p11;

    _p00 = p00 + processNoiseRate;
    _p01 = p01;
    _p10 = p10;
    _p11 = p11 + processNoiseVelocity;
  }

                                                 
                                                               
  bool update(double measurement, double confidence) {
    if (measurement <= 0) return false;

    if (!_initialized) {
      _x0 = measurement;
      _x1 = 0;
      _p00 = 25.0;
      _p01 = 0.0;
      _p10 = 0.0;
      _p11 = 5.0;
      _initialized = true;
      return true;
    }

    if (confidence < minAcceptConfidence) return false;

                                                              
    final double R =
        baseMeasurementNoise / (confidence * confidence).clamp(0.01, 1.0);

                 
    final double innovation = measurement - _x0;
    final double S = _p00 + R;

                        
    final double mahalanobis = innovation.abs() / math.sqrt(S);
    if (mahalanobis > innovationGateStd) {
      _p00 *= 1.05;
      _p11 *= 1.02;
      return false;
    }

                  
    final double k0 = _p00 / S;
    final double k1 = _p10 / S;

                   
    _x0 += k0 * innovation;
    _x1 += k1 * innovation;

                                      
    final newP00 = (1 - k0) * _p00;
    final newP01 = (1 - k0) * _p01;
    final newP10 = _p10 - k1 * _p00;
    final newP11 = _p11 - k1 * _p01;

    _p00 = newP00;
    _p01 = newP01;
    _p10 = newP10;
    _p11 = newP11;

                     
    _x1 = _x1.clamp(-2.0, 2.0);

    return true;
  }

                                               
  double get kalmanConfidence {
    if (!_initialized) return 0.0;
    final sigma = math.sqrt(_p00.clamp(0.01, 1000.0));
    return (1.0 - sigma / 5.0).clamp(0.0, 1.0);
  }

                                                            
                                             
  void boostResponsiveness() {
    processNoiseRate = 2.0;
    processNoiseVelocity = 0.5;
                                                        
    _p00 = math.max(_p00, 16.0);
    _p11 = math.max(_p11, 4.0);
  }

                                                                  
  void restoreNormalTracking() {
    processNoiseRate = 0.30;
    processNoiseVelocity = 0.08;
  }
}

                                                                      
           
                                                                      

class RealtimeBreathRateTracker {
                                                       
  final int windowDurationSec;

                                                    
  final int shortWindowDurationSec;

                                                           
  final int minUpdateIntervalMs;

                                               
  final double minConfidence;

                              
  final double minFreqHz;
  final double maxFreqHz;

                                                    
  final List<_TimestampedRR> _buffer = [];

                                      
  final _BreathRateKalman _kalman;

                             
  bool _changeDetected = false;
  int _consecutiveDivergences = 0;
  int _ticksSinceChange = 0;
  static const int _changeSettleUpdates = 6;                      
  static const double _changeDivergenceThresholdBpm = 3.0;

                                                        
  final List<double> _recentBpmEstimates = [];
  static const int _stabilityWindowSize = 6;

                    
  final StreamController<BreathRateSnapshot> _controller =
      StreamController<BreathRateSnapshot>.broadcast();

                     
  Timer? _updateTimer;
  bool _running = false;

  RealtimeBreathRateTracker({
    this.windowDurationSec = 45,
    this.shortWindowDurationSec = 20,
    this.minUpdateIntervalMs = 3000,
    this.minConfidence = 0.10,
    this.minFreqHz = 0.10,
    this.maxFreqHz = 0.70,
                                                                 
    double smoothingAlpha = 0.50,
    bool useFullSessionWindow = false,
  }) : _kalman = _BreathRateKalman(
          minAcceptConfidence: minConfidence * 0.5,
        );

                                      
  Stream<BreathRateSnapshot> get snapshots => _controller.stream;

                                               
  bool get isRunning => _running;

                                                  
  double get currentBpm =>
      _kalman.isInitialized ? _kalman.rate.clamp(3.0, 60.0) : 0.0;

                                 
  double get currentConfidence => _kalman.kalmanConfidence;

                                             
  bool get changeDetected => _changeDetected;

                                                   
  void start() {
    if (_running) return;
    _running = true;
    _updateTimer = Timer.periodic(
      Duration(milliseconds: minUpdateIntervalMs),
      (_) => _computeAndEmit(),
    );
  }

                                                   
  void stop() {
    _running = false;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

                                                       
  void dispose() {
    stop();
    _controller.close();
  }

                                    
  void addRR(double rrMs) {
    final timestamp =
        _buffer.isEmpty
            ? DateTime.now()
            : _buffer.last.timestamp.add(
                Duration(milliseconds: rrMs.round()),
              );
    _buffer.add(_TimestampedRR(timestamp, rrMs));
    _pruneWindow();
  }

                                  
  void addRRBatch(List<double> rrIntervals) {
    if (rrIntervals.isEmpty) return;
    final totalMs = rrIntervals.fold<double>(0, (sum, rr) => sum + rr);
    var timestamp =
        _buffer.isEmpty
            ? DateTime.now().subtract(
                Duration(milliseconds: totalMs.round()),
              )
            : _buffer.last.timestamp;
    for (final rr in rrIntervals) {
      timestamp = timestamp.add(Duration(milliseconds: rr.round()));
      _buffer.add(_TimestampedRR(timestamp, rr));
    }
    _pruneWindow();
  }

                                     
  BreathRateSnapshot? forceUpdate() => _computeAndEmit();

                      
  void reset() {
    _buffer.clear();
    _kalman.reset();
    _changeDetected = false;
    _consecutiveDivergences = 0;
    _ticksSinceChange = 0;
    _recentBpmEstimates.clear();
  }

                                                  
  void _pruneWindow() {
    final cutoff = DateTime.now().subtract(
      Duration(seconds: windowDurationSec),
    );
    _buffer.removeWhere((r) => r.timestamp.isBefore(cutoff));
  }

                                                       
  List<double> _getRRsForWindow(int windowSec) {
    if (_buffer.isEmpty) return [];
    final cutoff = DateTime.now().subtract(Duration(seconds: windowSec));
    return _buffer
        .where((r) => r.timestamp.isAfter(cutoff))
        .map((r) => r.rr)
        .toList();
  }

                                  
  BreathRateSnapshot? _computeAndEmit() {
    if (_controller.isClosed) return null;
    _pruneWindow();

    final longRRs = _getRRsForWindow(windowDurationSec);
    final shortRRs = _getRRsForWindow(shortWindowDurationSec);

                        
    if (longRRs.length < 20 && shortRRs.length < 20) {
      final snapshot = BreathRateSnapshot(
        breathRateBpm: currentBpm,
        rawBreathRateBpm: 0,
        confidence: 0,
        windowSize: longRRs.length,
        windowDurationSec: _windowDuration(longRRs),
        changeDetected: _changeDetected,
        timestamp: DateTime.now(),
      );
      _controller.add(snapshot);
      return snapshot;
    }

                                                                  
    HrvDerivedBreathingResult? longResult;
    HrvDerivedBreathingResult? shortResult;

    if (longRRs.length >= 20) {
      longResult = HrvDerivedBreathingRate.estimate(
        longRRs,
        minFreqHz: minFreqHz,
        maxFreqHz: maxFreqHz,
      );
    }

    if (shortRRs.length >= 20) {
      shortResult = HrvDerivedBreathingRate.estimate(
        shortRRs,
        minFreqHz: minFreqHz,
        maxFreqHz: maxFreqHz,
      );
    }

                                                                  
    double rawBpm = 0;
    double rawConf = 0;
    HrvDerivedBreathingResult? primaryResult;

    final bool longValid =
        longResult != null &&
        longResult.breathingRateBpm > 0 &&
        longResult.confidence >= minConfidence;
    final bool shortValid =
        shortResult != null &&
        shortResult.breathingRateBpm > 0 &&
        shortResult.confidence >= minConfidence;

    if (longValid && shortValid) {
      final double divergence =
          (shortResult.breathingRateBpm - longResult.breathingRateBpm).abs();

      if (divergence > _changeDivergenceThresholdBpm &&
          shortResult.confidence >= minConfidence * 1.2) {
        _consecutiveDivergences++;
      } else {
        _consecutiveDivergences =
            (_consecutiveDivergences - 1).clamp(0, 100);
      }

                                                  
      if (_consecutiveDivergences >= 2 && !_changeDetected) {
        _changeDetected = true;
        _ticksSinceChange = 0;
        _kalman.boostResponsiveness();
      }

      if (_changeDetected) {
                                                              
        rawBpm = shortResult.breathingRateBpm;
        rawConf = shortResult.confidence;
        primaryResult = shortResult;
        _ticksSinceChange++;

                                                 
        if (_ticksSinceChange >= _changeSettleUpdates ||
            divergence < 1.5) {
          _changeDetected = false;
          _consecutiveDivergences = 0;
          _kalman.restoreNormalTracking();
        }
      } else {
                                                                 
        final longW = longResult.confidence;
        final shortW = shortResult.confidence;
        final totalW = longW + shortW;
        if (totalW > 0) {
          rawBpm = (longResult.breathingRateBpm * longW +
                  shortResult.breathingRateBpm * shortW) /
              totalW;
          rawConf = (longResult.confidence * longW +
                  shortResult.confidence * shortW) /
              totalW;
        } else {
          rawBpm = longResult.breathingRateBpm;
          rawConf = longResult.confidence;
        }
        primaryResult = longResult;
      }
    } else if (shortValid) {
      rawBpm = shortResult.breathingRateBpm;
      rawConf = shortResult.confidence;
      primaryResult = shortResult;
    } else if (longValid) {
      rawBpm = longResult.breathingRateBpm;
      rawConf = longResult.confidence;
      primaryResult = longResult;
    }

                                                                  
    _kalman.predict();

    if (rawBpm > 0 && rawConf >= minConfidence) {
      _kalman.update(rawBpm, rawConf);

                                                   
      _recentBpmEstimates.add(rawBpm);
      if (_recentBpmEstimates.length > _stabilityWindowSize) {
        _recentBpmEstimates.removeAt(0);
      }
    }

                               
    double stabilityBonus = 0.0;
    if (_recentBpmEstimates.length >= 3) {
      final maxBpm =
          _recentBpmEstimates.reduce((a, b) => a > b ? a : b);
      final minBpmVal =
          _recentBpmEstimates.reduce((a, b) => a < b ? a : b);
      final spread = maxBpm - minBpmVal;
      if (spread < 1.0 &&
          _recentBpmEstimates.length >= _stabilityWindowSize) {
        stabilityBonus = 0.20;
      } else if (spread < 1.5) {
        stabilityBonus = 0.12;
      } else if (spread < 2.5) {
        stabilityBonus = 0.05;
      }
    }

    final double outputBpm = currentBpm;
    final double outputConf =
        (_kalman.kalmanConfidence + stabilityBonus).clamp(0.0, 1.0);

    final snapshot = BreathRateSnapshot(
      breathRateBpm: outputBpm,
      rawBreathRateBpm: rawBpm,
      confidence: outputConf,
      windowSize: longRRs.length,
      windowDurationSec: _windowDuration(longRRs),
      detail: primaryResult,
      changeDetected: _changeDetected,
      timestamp: DateTime.now(),
    );

    _controller.add(snapshot);
    return snapshot;
  }

  double _windowDuration(List<double> rrList) {
    if (rrList.isEmpty) return 0;
    return rrList.reduce((a, b) => a + b) / 1000.0;
  }
}

class _TimestampedRR {
  final DateTime timestamp;
  final double rr;
  const _TimestampedRR(this.timestamp, this.rr);
}
