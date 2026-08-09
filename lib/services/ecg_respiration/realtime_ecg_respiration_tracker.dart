                                                   
   
                                                               
                                                              
                                                                 
   
                                                                     
                                                                    
                             
                                                          
                                                                    
                                               
                                                 
   
                                                                     
library;

import 'dart:async';
import 'dart:math' as math;
import 'edr_multi_channel.dart';

                                                                      
            
                                                                      

class EcgBreathRateSnapshot {
                                                        
  final double breathRateBpm;

                                                    
  final double rawBreathRateBpm;

                             
  final double confidence;

                                          
  final int bufferSamples;

                                
  final double bufferDurationSec;

                                             
  final double heartRateBpm;

                                                                          
  final double motionQuality;

                                                                        
  final double artifactRatio;

                                                                       
  final double? instantaneousBreathRateBpm;

                         
  final EdrFusionResult? detail;

                
  final DateTime timestamp;

  const EcgBreathRateSnapshot({
    required this.breathRateBpm,
    required this.rawBreathRateBpm,
    required this.confidence,
    required this.bufferSamples,
    required this.bufferDurationSec,
    required this.heartRateBpm,
    this.motionQuality = 1.0,
    this.artifactRatio = 0.0,
    this.instantaneousBreathRateBpm,
    this.detail,
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

                                                                
                                                                 
                                                                 
                                 
  final double processNoiseRate;

                                                                   
  final double processNoiseVelocity;

                                                             
  final double baseMeasurementNoise;

                                                                   
                                                           
  final double innovationGateStd;

                                                                    
  final double minAcceptConfidence;

  bool _initialized = false;

  _BreathRateKalman({
    this.processNoiseRate = 0.25,
    this.processNoiseVelocity = 0.05,
    this.baseMeasurementNoise = 1.0,
    this.innovationGateStd = 3.5,
    this.minAcceptConfidence = 0.10,
  });

  double get rate => _x0;
  double get velocity => _x1;
  double get uncertainty => math.sqrt(_p00);
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

                                                 
     
                                            
                                                  
                                                               
     
                                                                   
  bool update(
    double measurement,
    double confidence, [
    double agreementBonus = 0,
  ]) {
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

                                                     
    final effectiveConf = (confidence + agreementBonus * 0.5).clamp(0.0, 1.0);
    if (effectiveConf < minAcceptConfidence) return false;

                                                               
                                                       
                                                      
    final double R =
        baseMeasurementNoise / (effectiveConf * effectiveConf).clamp(0.01, 1.0);

                                           
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

                                             
                                                
    final double newP00 = (1 - k0) * _p00;
    final double newP01 = (1 - k0) * _p01;
    final double newP10 = _p10 - k1 * _p00;
    final double newP11 = _p11 - k1 * _p01;

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
}

                                                                      
           
                                                                      

class RealtimeEcgRespirationTracker {
                           
  final double ecgSampleRate;

                                        
  final int windowDurationSec;

                                     
  final int updateIntervalMs;

                                   
  final double minConfidence;

                        
  final List<double> _ecgBuffer = [];

                                                        
  final List<double> _accMagnitudeBuffer = [];

                                
  late final int _maxBufferSamples;
  late final int _maxAccSamples;

                                                  
  final _BreathRateKalman _kalman;

                            
  double _lastHeartRate = 0;

                                                        
  final List<double> _recentRawBpms = [];
  static const int _stabilityWindowSize = 6;

                    
  final StreamController<EcgBreathRateSnapshot> _controller =
      StreamController<EcgBreathRateSnapshot>.broadcast();

                     
  Timer? _timer;
  bool _running = false;

  RealtimeEcgRespirationTracker({
    this.ecgSampleRate = 130.0,
    this.windowDurationSec = 45,
    this.updateIntervalMs = 5000,
    this.minConfidence = 0.18,
    double processNoiseRate = 0.25,
    double processNoiseVelocity = 0.05,
    double baseMeasurementNoise = 1.0,
  }) : _kalman = _BreathRateKalman(
         processNoiseRate: processNoiseRate,
         processNoiseVelocity: processNoiseVelocity,
         baseMeasurementNoise: baseMeasurementNoise,
         minAcceptConfidence: minConfidence * 0.5,
       ) {
    _maxBufferSamples = (windowDurationSec * ecgSampleRate).round();
    _maxAccSamples = 200 * math.min(windowDurationSec, 15);
  }

                                           
  Stream<EcgBreathRateSnapshot> get snapshots => _controller.stream;

  bool get isRunning => _running;
  double get currentBpm => _kalman.rate.clamp(0.0, 60.0);
  double get currentConfidence => _kalman.kalmanConfidence;
  double get currentHeartRate => _lastHeartRate;
  int get bufferLength => _ecgBuffer.length;
  double get currentMotionQuality => _motionQuality();

                        
  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(
      Duration(milliseconds: updateIntervalMs),
      (_) => _computeAndEmit(),
    );
  }

                                   
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

                          
  void dispose() {
    stop();
    _controller.close();
  }

                                      
  void addEcgBatch(Iterable<double> samples) {
    _ecgBuffer.addAll(samples);
                         
    if (_ecgBuffer.length > _maxBufferSamples) {
      _ecgBuffer.removeRange(0, _ecgBuffer.length - _maxBufferSamples);
    }
  }

                                                     
  void addAccelerometerMagnitudes(Iterable<double> magnitudesMg) {
    for (final magnitude in magnitudesMg) {
      if (magnitude.isFinite) _accMagnitudeBuffer.add(magnitude);
    }
    if (_accMagnitudeBuffer.length > _maxAccSamples) {
      _accMagnitudeBuffer.removeRange(
        0,
        _accMagnitudeBuffer.length - _maxAccSamples,
      );
    }
  }

                                     
  EcgBreathRateSnapshot? forceUpdate() => _computeAndEmit();

                      
  void reset() {
    _ecgBuffer.clear();
    _accMagnitudeBuffer.clear();
    _kalman.reset();
    _lastHeartRate = 0;
    _recentRawBpms.clear();
  }

                                                         
  EcgBreathRateSnapshot? _computeAndEmit() {
    if (_controller.isClosed) return null;

    final int minSamples = (20.0 * ecgSampleRate).round();              
    if (_ecgBuffer.length < minSamples) {
      final snapshot = EcgBreathRateSnapshot(
        breathRateBpm: currentBpm,
        rawBreathRateBpm: 0,
        confidence: 0,
        bufferSamples: _ecgBuffer.length,
        bufferDurationSec: _ecgBuffer.length / ecgSampleRate,
        heartRateBpm: _lastHeartRate,
        timestamp: DateTime.now(),
      );
      _controller.add(snapshot);
      return snapshot;
    }

                            
    final motionQuality = _motionQuality();
    final result = EdrMultiChannelEngine.process(
      _ecgBuffer,
      ecgSampleRate: ecgSampleRate,
      motionQuality: motionQuality,
    );

    final double rawBpm = result.breathRateBpm;
    final double rawConf = result.confidence;
    _lastHeartRate = result.heartRateBpm;

                                                       
    final double agreementBonus = _crossChannelAgreementBonus(result);

                                                                
    _kalman.predict();

                                                                
    if (rawBpm > 0 && rawConf >= minConfidence) {
      _kalman.update(rawBpm, rawConf, agreementBonus);

                                                         
      _recentRawBpms.add(rawBpm);
      if (_recentRawBpms.length > _stabilityWindowSize) {
        _recentRawBpms.removeAt(0);
      }
    }
                                                             
                                                              
                                                                 

                                           
    final double outputBpm =
        _kalman.isInitialized
            ? _kalman.rate.clamp(3.0, 60.0)            
            : 0.0;

                                                           
    double stabilityBonus = 0.0;
    if (_recentRawBpms.length >= 3) {
      final maxBpm = _recentRawBpms.reduce((a, b) => a > b ? a : b);
      final minBpm = _recentRawBpms.reduce((a, b) => a < b ? a : b);
      final spread = maxBpm - minBpm;
      if (spread < 1.0 && _recentRawBpms.length >= _stabilityWindowSize) {
        stabilityBonus = 0.18;
      } else if (spread < 1.5) {
        stabilityBonus = 0.10;
      } else if (spread < 2.5) {
        stabilityBonus = 0.04;
      }
    }

                                                                        
                                   
    final double outputConf =
        _kalman.isInitialized
            ? ((_kalman.kalmanConfidence * 0.55 +
                        rawConf.clamp(0.0, 1.0) * 0.45) +
                    stabilityBonus)
                .clamp(0.0, 1.0)
            : 0.0;

    final snapshot = EcgBreathRateSnapshot(
      breathRateBpm: outputBpm,
      rawBreathRateBpm: rawBpm,
      confidence: outputConf,
      bufferSamples: _ecgBuffer.length,
      bufferDurationSec: _ecgBuffer.length / ecgSampleRate,
      heartRateBpm: _lastHeartRate,
      motionQuality: result.motionQuality,
      artifactRatio: result.artifactRatio,
      instantaneousBreathRateBpm: result.instantaneousBreathRateBpm,
      detail: result,
      timestamp: DateTime.now(),
    );

    _controller.add(snapshot);
    return snapshot;
  }

                                                                       
  double _crossChannelAgreementBonus(EdrFusionResult result) {
    final channels = result.channels;
    if (channels.length < 2) return 0.0;

    final bpms = channels.map((c) => c.breathRateBpm).toList();
    final spread =
        bpms.reduce((a, b) => a > b ? a : b) -
        bpms.reduce((a, b) => a < b ? a : b);

    if (spread < 1.0) return 0.30;                       
    if (spread < 2.0) return 0.15;                  
    if (spread < 3.0) return 0.05;                      
    return 0.0;                  
  }

  double _motionQuality() {
    if (_accMagnitudeBuffer.length < 40) return 1.0;

    final sampleCount = math.min(_accMagnitudeBuffer.length, 1000);
    final start = _accMagnitudeBuffer.length - sampleCount;
    final recent = _accMagnitudeBuffer.sublist(start);

    final mean = recent.reduce((a, b) => a + b) / recent.length;
    var sumSq = 0.0;
    var jerkSum = 0.0;
    for (int i = 0; i < recent.length; i++) {
      final delta = recent[i] - mean;
      sumSq += delta * delta;
      if (i > 0) jerkSum += (recent[i] - recent[i - 1]).abs();
    }

    final stdMg = math.sqrt(sumSq / recent.length);
    final meanJerkMg = jerkSum / math.max(1, recent.length - 1);

    final stdPenalty = ((stdMg - 8.0) / 45.0).clamp(0.0, 1.0);
    final jerkPenalty = ((meanJerkMg - 4.0) / 35.0).clamp(0.0, 1.0);
    return (1.0 - (stdPenalty * 0.55 + jerkPenalty * 0.45)).clamp(0.0, 1.0);
  }
}
