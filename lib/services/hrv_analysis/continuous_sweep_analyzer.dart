// SPDX-License-Identifier: AGPL-3.0-only
                                                     
   
                                                                  
                                                                    
                                                                
                                                
   
                                      
                                                                       
                                                               
                                                                      
                                                           
   
             
                                                                   
                                                             
                                              
   
               
                                                                           
                                                                              
library;

import 'dart:math' as math;
import 'dart:developer' as developer;

import 'signal_processing.dart';

                                                                      
                 
                                                                      

class SweepConfig {
                                                        
  final double startRateBpm;

                                                    
  final double endRateBpm;

                                     
  final double sweepDurationSec;

                                                                     
  final double inhaleFraction;

                                                                       
  final double minDataBeforeStopSec;

                                                                           
  final double earlyStopDropThreshold;

                                                                           
  final double earlyStopDeclineDurationSec;

                                                  
  final double interpolationRate;

  const SweepConfig({
    this.startRateBpm = 7.0,
    this.endRateBpm = 4.5,
    this.sweepDurationSec = 300.0,
    this.inhaleFraction = 0.4,
    this.minDataBeforeStopSec = 90.0,
    this.earlyStopDropThreshold = 0.25,
    this.earlyStopDeclineDurationSec = 30.0,
    this.interpolationRate = 4.0,
  });

                                                                        
  double rateAtTime(double elapsedSec) {
    final t = (elapsedSec / sweepDurationSec).clamp(0.0, 1.0);
    return startRateBpm + (endRateBpm - startRateBpm) * t;
  }

                                                              
  double cycleDurationAtTime(double elapsedSec) {
    return 60.0 / rateAtTime(elapsedSec);
  }

                                               
  int inhaleMsAtTime(double elapsedSec) {
    return (cycleDurationAtTime(elapsedSec) * inhaleFraction * 1000).round();
  }

                                               
  int exhaleMsAtTime(double elapsedSec) {
    return (cycleDurationAtTime(elapsedSec) * (1.0 - inhaleFraction) * 1000)
        .round();
  }
}

                                                                      
                                                         
                                                                      

class SweepDataPoint {
                                       
  final double timeSec;

                                                       
  final double breathingRateBpm;

                                                                
                                            
  final double rsaAmplitude;

                                                            
                                                
  final double phaseCoherence;

                                                                      
  final double lfPower;

                                                       
  final double rmssd;

                                                        
  final double compositeScore;

  const SweepDataPoint({
    required this.timeSec,
    required this.breathingRateBpm,
    required this.rsaAmplitude,
    required this.phaseCoherence,
    required this.lfPower,
    required this.rmssd,
    required this.compositeScore,
  });
}

                                                                      
                
                                                                      

class SweepResonanceResult {
                                                  
                                             
  final double optimalBreathingRateBpm;

                                       
  final double optimalFrequencyHz;

                                             
  final double confidence;

                                    
  final double peakCompositeScore;

                                             
  final double optimalRsaAmplitude;

                                          
  final double optimalPhaseCoherence;

                                     
  final double optimalRmssd;

                                           
  final bool earlyStopTriggered;

                                                   
  final double actualDurationSec;

                                                  
  final List<SweepDataPoint> dataPoints;

                              
  final String? warning;

  const SweepResonanceResult({
    required this.optimalBreathingRateBpm,
    required this.optimalFrequencyHz,
    required this.confidence,
    required this.peakCompositeScore,
    required this.optimalRsaAmplitude,
    required this.optimalPhaseCoherence,
    required this.optimalRmssd,
    required this.earlyStopTriggered,
    required this.actualDurationSec,
    required this.dataPoints,
    this.warning,
  });

  Map<String, String> essentials() {
    return {
      'Optimal Rate': '${optimalBreathingRateBpm.toStringAsFixed(1)} BPM',
      'Composite Score': '${(peakCompositeScore * 100).toStringAsFixed(0)}/100',
      'Confidence': '${(confidence * 100).toStringAsFixed(0)}%',
      'RSA Amplitude': '${optimalRsaAmplitude.toStringAsFixed(1)} ms',
    };
  }
}

                                                                      
                          
                                                                      

                                                                  
   
          
           
                                           
                   
                              
                                                          
                                               
                 
                                     
       
class ContinuousSweepEngine {
  final SweepConfig config;

                           
  final List<double> _rrIntervalsMs = [];
  final List<double> _rrTimestampsSec = [];                              
  final List<SweepDataPoint> _dataPoints = [];

                        
  double _peakComposite = 0.0;
  double _peakCompositeBpm = 0.0;
  double _lastDeclineStartTime = -1.0;
  bool _earlyStopTriggered = false;

                                     
  double _maxRsa = 1.0;
  double _maxLf = 1.0;
  double _maxRmssd = 1.0;

                    
  static const double _wRsa = 0.40;
  static const double _wPhase = 0.30;
  static const double _wLf = 0.20;
  static const double _wRmssd = 0.10;

                                              
  static const double _windowDurationSec = 30.0;

                                                       
  static const double _analysisIntervalSec = 5.0;
  double _lastAnalysisTime = 0.0;

  ContinuousSweepEngine({this.config = const SweepConfig()});

  bool get hasDataPoints => _dataPoints.isNotEmpty;

                                                                 
                             
  SweepStatus addRrInterval(double rrMs, double sweepElapsedSec) {
                                       
    final double cumTime =
        _rrTimestampsSec.isEmpty ? 0.0 : _rrTimestampsSec.last + rrMs / 1000.0;
    _rrTimestampsSec.add(cumTime);
    _rrIntervalsMs.add(rrMs);

                                              
    if (sweepElapsedSec - _lastAnalysisTime < _analysisIntervalSec) {
      return SweepStatus(
        shouldStop: false,
        currentRate: config.rateAtTime(sweepElapsedSec),
        latestComposite:
            _dataPoints.isNotEmpty ? _dataPoints.last.compositeScore : 0.0,
      );
    }
    _lastAnalysisTime = sweepElapsedSec;

                                      
    if (_rrIntervalsMs.length < 10) {
      return SweepStatus(
        shouldStop: false,
        currentRate: config.rateAtTime(sweepElapsedSec),
        latestComposite: 0.0,
      );
    }

                                             
    final windowRR = _getWindowedRR();
    if (windowRR.length < 8) {
      return SweepStatus(
        shouldStop: false,
        currentRate: config.rateAtTime(sweepElapsedSec),
        latestComposite: 0.0,
      );
    }

    final double currentBpm = config.rateAtTime(sweepElapsedSec);
    final double targetHz = currentBpm / 60.0;

                            
    final double rsaAmp = _computeRsaAmplitude(windowRR);
    final double phase = _computePhaseCoherence(windowRR, targetHz);
    final double lfPow = _computeLfPower(windowRR, targetHz);
    final double rmssd = _computeRmssd(windowRR);

                                      
    if (rsaAmp > _maxRsa) _maxRsa = rsaAmp;
    if (lfPow > _maxLf) _maxLf = lfPow;
    if (rmssd > _maxRmssd) _maxRmssd = rmssd;

                      
    final double nRsa = _maxRsa > 0 ? rsaAmp / _maxRsa : 0.0;
    final double nPhase = phase;               
    final double nLf = _maxLf > 0 ? lfPow / _maxLf : 0.0;
    final double nRmssd = _maxRmssd > 0 ? rmssd / _maxRmssd : 0.0;

    final double composite =
        _wRsa * nRsa + _wPhase * nPhase + _wLf * nLf + _wRmssd * nRmssd;

    final point = SweepDataPoint(
      timeSec: sweepElapsedSec,
      breathingRateBpm: currentBpm,
      rsaAmplitude: rsaAmp,
      phaseCoherence: phase,
      lfPower: lfPow,
      rmssd: rmssd,
      compositeScore: composite,
    );
    _dataPoints.add(point);

                 
    if (composite > _peakComposite) {
      _peakComposite = composite;
      _peakCompositeBpm = currentBpm;
      _lastDeclineStartTime = -1.0;
    }

                                 
    bool shouldStop = false;
    if (sweepElapsedSec >= config.minDataBeforeStopSec && _peakComposite > 0) {
      final double dropFraction = (_peakComposite - composite) / _peakComposite;

      if (dropFraction >= config.earlyStopDropThreshold) {
        if (_lastDeclineStartTime < 0) {
          _lastDeclineStartTime = sweepElapsedSec;
        }
        final double declineDuration = sweepElapsedSec - _lastDeclineStartTime;
        if (declineDuration >= config.earlyStopDeclineDurationSec) {
          shouldStop = true;
          _earlyStopTriggered = true;
          developer.log(
            'Early stop: peak at ${_peakCompositeBpm.toStringAsFixed(1)} BPM, '
            'composite dropped ${(dropFraction * 100).toStringAsFixed(0)}% '
            'for ${declineDuration.toStringAsFixed(0)}s',
          );
        }
      } else {
        _lastDeclineStartTime = -1.0;
      }
    }

    return SweepStatus(
      shouldStop: shouldStop,
      currentRate: currentBpm,
      latestComposite: composite,
      latestRsa: rsaAmp,
      latestPhase: phase,
    );
  }

                                                
  SweepResonanceResult finalize(double totalElapsedSec) {
    if (_dataPoints.isEmpty) {
      return SweepResonanceResult(
        optimalBreathingRateBpm: 6.0,
        optimalFrequencyHz: 0.1,
        confidence: 0.0,
        peakCompositeScore: 0.0,
        optimalRsaAmplitude: 0.0,
        optimalPhaseCoherence: 0.0,
        optimalRmssd: 0.0,
        earlyStopTriggered: false,
        actualDurationSec: totalElapsedSec,
        dataPoints: [],
        warning: 'No data points collected during sweep.',
      );
    }

                                                     
    final renormed = <SweepDataPoint>[];
    double bestComposite = 0.0;
    SweepDataPoint? bestPoint;

    for (final p in _dataPoints) {
      final nRsa = _maxRsa > 0 ? p.rsaAmplitude / _maxRsa : 0.0;
      final nPhase = p.phaseCoherence;
      final nLf = _maxLf > 0 ? p.lfPower / _maxLf : 0.0;
      final nRmssd = _maxRmssd > 0 ? p.rmssd / _maxRmssd : 0.0;
      final composite =
          _wRsa * nRsa + _wPhase * nPhase + _wLf * nLf + _wRmssd * nRmssd;

      final rp = SweepDataPoint(
        timeSec: p.timeSec,
        breathingRateBpm: p.breathingRateBpm,
        rsaAmplitude: p.rsaAmplitude,
        phaseCoherence: p.phaseCoherence,
        lfPower: p.lfPower,
        rmssd: p.rmssd,
        compositeScore: composite,
      );
      renormed.add(rp);

      if (composite > bestComposite) {
        bestComposite = composite;
        bestPoint = rp;
      }
    }

    final best = bestPoint ?? renormed.first;

                                               
    final scores = renormed.map((p) => p.compositeScore).toList();
    final meanScore = scores.reduce((a, b) => a + b) / scores.length;
    final double confidence =
        bestComposite > 0
            ? ((bestComposite - meanScore) / bestComposite).clamp(0.0, 1.0)
            : 0.0;

    return SweepResonanceResult(
      optimalBreathingRateBpm: double.parse(
        best.breathingRateBpm.toStringAsFixed(1),
      ),
      optimalFrequencyHz: best.breathingRateBpm / 60.0,
      confidence: confidence,
      peakCompositeScore: bestComposite,
      optimalRsaAmplitude: best.rsaAmplitude,
      optimalPhaseCoherence: best.phaseCoherence,
      optimalRmssd: best.rmssd,
      earlyStopTriggered: _earlyStopTriggered,
      actualDurationSec: totalElapsedSec,
      dataPoints: renormed,
    );
  }

                                                                    
                         
                                                                    

                                                          
  List<double> _getWindowedRR() {
    if (_rrIntervalsMs.isEmpty) return [];

    double totalMs = 0;
    int startIdx = _rrIntervalsMs.length - 1;
    while (startIdx > 0 && totalMs < _windowDurationSec * 1000) {
      totalMs += _rrIntervalsMs[startIdx];
      startIdx--;
    }
    return _rrIntervalsMs.sublist(startIdx);
  }

                                                  
                                                                  
                                    
  double _computeRsaAmplitude(List<double> rrIntervals) {
    if (rrIntervals.length < 4) return 0.0;

                                                                 
                                                              
                                                          
    final maxRR = rrIntervals.reduce(math.max);
    final minRR = rrIntervals.reduce(math.min);
    return maxRR - minRR;
  }

                                                              
                                                 
     
                                                                   
                                           
  double _computePhaseCoherence(List<double> rrIntervals, double targetFreqHz) {
    if (rrIntervals.length < 8) return 0.0;

                                               
    final timesS = <double>[];
    double cumS = 0;
    for (int i = 0; i < rrIntervals.length; i++) {
      timesS.add(cumS);
      cumS += rrIntervals[i] / 1000.0;
    }

                                    
    final double meanRR =
        rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    final rrCentered = rrIntervals.map((v) => v - meanRR).toList();

                                                                
    final refSin = <double>[];
    final refCos = <double>[];
    for (int i = 0; i < timesS.length; i++) {
      final phase = 2.0 * math.pi * targetFreqHz * timesS[i];
      refSin.add(math.sin(phase));
      refCos.add(math.cos(phase));
    }

                                                                
    double sumSin = 0, sumCos = 0, sumRR2 = 0;
    for (int i = 0; i < rrCentered.length; i++) {
      sumSin += rrCentered[i] * refSin[i];
      sumCos += rrCentered[i] * refCos[i];
      sumRR2 += rrCentered[i] * rrCentered[i];
    }

    if (sumRR2 < 1e-10) return 0.0;

                                                           
                                    
    final double amplitude = math.sqrt(sumSin * sumSin + sumCos * sumCos);
    final double totalEnergy = math.sqrt(sumRR2);
    final double coherence = (amplitude / totalEnergy).clamp(0.0, 1.0);

    return coherence;
  }

                                                   
  double _computeLfPower(List<double> rrIntervals, double targetFreqHz) {
    if (rrIntervals.length < 8) return 0.0;

                       
    final timesS = <double>[];
    double cumS = 0;
    for (int i = 0; i < rrIntervals.length; i++) {
      timesS.add(cumS);
      cumS += rrIntervals[i] / 1000.0;
    }

                               
    final fs = config.interpolationRate;
    if (timesS.length < 2) return 0.0;

    try {
      final (_, resampled) = cubicInterpolate(timesS, rrIntervals, fs);
      if (resampled.length < 4) return 0.0;

                    
      final mean = resampled.reduce((a, b) => a + b) / resampled.length;
      final detrended = resampled.map((v) => v - mean).toList();

                  
      final (freqs, psd) = welchPSD(detrended, fs, nperseg: detrended.length);

                                                               
      final double bandLow = targetFreqHz - 0.025;
      final double bandHigh = targetFreqHz + 0.025;
      double bandPower = 0;
      int count = 0;

      for (int i = 0; i < freqs.length; i++) {
        if (freqs[i] >= bandLow && freqs[i] <= bandHigh) {
          bandPower += psd[i];
          count++;
        }
      }

      if (count > 1 && freqs.length > 1) {
        final df = freqs[1] - freqs[0];
        bandPower *= df;
      }

      return bandPower;
    } catch (e) {
      developer.log('LF power computation failed: $e');
      return 0.0;
    }
  }

                              
  double _computeRmssd(List<double> rrIntervals) {
    if (rrIntervals.length < 2) return 0.0;
    double sumSq = 0;
    for (int i = 0; i < rrIntervals.length - 1; i++) {
      final diff = rrIntervals[i + 1] - rrIntervals[i];
      sumSq += diff * diff;
    }
    return math.sqrt(sumSq / (rrIntervals.length - 1));
  }
}

                                                                      
                                               
                                                                      

class SweepStatus {
                                                             
  final bool shouldStop;

                                                
  final double currentRate;

                             
  final double latestComposite;

                                
  final double? latestRsa;

                                   
  final double? latestPhase;

  const SweepStatus({
    required this.shouldStop,
    required this.currentRate,
    required this.latestComposite,
    this.latestRsa,
    this.latestPhase,
  });
}
