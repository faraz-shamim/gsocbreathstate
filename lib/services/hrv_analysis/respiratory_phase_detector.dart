// SPDX-License-Identifier: AGPL-3.0-only
                                                                 
   
                                                                      
                                                                        
   
                                                           
library;

import 'dart:math' as math;

                                                                      
                
                                                                      

                                          
class RespiratoryPhaseResult {
                                                                
                                                            
  final List<double> inspirationOnsetTimesMs;

                                                               
                                                               
  final List<double> respiratoryPeakTimesMs;

                                                
     
                                                                    
                                                  
  int get breathCycleCount =>
      math.max(0, inspirationOnsetTimesMs.length - 1);

                                                                  
  final double estimatedBreathRateBpm;

                                                       
  final double samplingRateHz;

  const RespiratoryPhaseResult({
    required this.inspirationOnsetTimesMs,
    required this.respiratoryPeakTimesMs,
    required this.estimatedBreathRateBpm,
    required this.samplingRateHz,
  });
}

                                                                      
            
                                                                      

                                                                     
   
                                                                  
                                                                   
                                                                 
                                                                  
class RespiratoryPhaseDetector {
  RespiratoryPhaseDetector._();

                                                      
     
                                                                   
                                                                    
                                                         
                                                                   
                                                                    
                                                                    
                                                                  
                      
  static RespiratoryPhaseResult detect(
    List<double> amplitudes,
    double samplingRateHz, {
    double minBreathRateBpm = 4.0,
    double maxBreathRateBpm = 30.0,
    double smoothingWindowMs = 0,
  }) {
    if (amplitudes.length < 4) {
      return const RespiratoryPhaseResult(
        inspirationOnsetTimesMs: [],
        respiratoryPeakTimesMs: [],
        estimatedBreathRateBpm: 0,
        samplingRateHz: 0,
      );
    }

                                                                  
    final int smoothWin;
    if (smoothingWindowMs > 0) {
      smoothWin = (smoothingWindowMs / 1000.0 * samplingRateHz)
          .round()
          .clamp(1, amplitudes.length);
    } else {
                                                      
      smoothWin = (samplingRateHz / (2.0 * maxBreathRateBpm / 60.0))
          .round()
          .clamp(3, amplitudes.length);
    }
    final smoothed = _movingAverageSmooth(amplitudes, smoothWin);

                                                                  
                                                                  
    final int minDistSamples =
        (samplingRateHz * 60.0 / maxBreathRateBpm)
            .floor()
            .clamp(2, smoothed.length);

    final peakIndices = _findPeaks(smoothed, minDistSamples);

    if (peakIndices.length < 2) {
      return RespiratoryPhaseResult(
        inspirationOnsetTimesMs: const [],
        respiratoryPeakTimesMs: peakIndices
            .map((i) => i / samplingRateHz * 1000.0)
            .toList(),
        estimatedBreathRateBpm: 0,
        samplingRateHz: samplingRateHz,
      );
    }

                                                                  
    final troughIndices =
        _findTroughsBetweenPeaks(smoothed, peakIndices);

                                                                  
    final peakTimesMs =
        peakIndices.map((i) => i / samplingRateHz * 1000.0).toList();
    final troughTimesMs =
        troughIndices.map((i) => i / samplingRateHz * 1000.0).toList();

                                                                  
    double breathRate = 0;
    if (troughTimesMs.length >= 2) {
      final cycleDurationsMs = <double>[];
      for (int i = 0; i < troughTimesMs.length - 1; i++) {
        cycleDurationsMs
            .add(troughTimesMs[i + 1] - troughTimesMs[i]);
      }
      final meanCycleMs = cycleDurationsMs.reduce((a, b) => a + b) /
          cycleDurationsMs.length;
      breathRate = meanCycleMs > 0 ? 60000.0 / meanCycleMs : 0;
    }

    return RespiratoryPhaseResult(
      inspirationOnsetTimesMs: troughTimesMs,
      respiratoryPeakTimesMs: peakTimesMs,
      estimatedBreathRateBpm: breathRate,
      samplingRateHz: samplingRateHz,
    );
  }
}

                                                                      
                   
                                                                      

                                                              
List<double> _movingAverageSmooth(List<double> data, int windowSize) {
  if (windowSize <= 1) return List<double>.from(data);
  final int half = windowSize ~/ 2;
  final result = List<double>.filled(data.length, 0.0);

                                       
  final prefix = List<double>.filled(data.length + 1, 0.0);
  for (int i = 0; i < data.length; i++) {
    prefix[i + 1] = prefix[i] + data[i];
  }
  for (int i = 0; i < data.length; i++) {
    final int lo = math.max(0, i - half);
    final int hi = math.min(data.length - 1, i + half);
    result[i] = (prefix[hi + 1] - prefix[lo]) / (hi - lo + 1);
  }
  return result;
}

                                                                   
               
   
                                  
                                                              
                                    
   
                                                                    
            
List<int> _findPeaks(List<double> signal, int minDistance) {
  if (signal.length < 3) return [];

                            
  double sum = 0;
  for (final v in signal) {
    sum += v;
  }
  final double threshold = sum / signal.length;

                                             
  final candidates = <int>[];
  for (int i = 1; i < signal.length - 1; i++) {
    if (signal[i] > signal[i - 1] &&
        signal[i] >= signal[i + 1] &&
        signal[i] > threshold) {
      candidates.add(i);
    }
  }
  if (candidates.isEmpty) return [];

                                                               
  final selected = <int>[candidates[0]];
  for (int i = 1; i < candidates.length; i++) {
    if (candidates[i] - selected.last >= minDistance) {
      selected.add(candidates[i]);
    } else if (signal[candidates[i]] > signal[selected.last]) {
      selected[selected.length - 1] = candidates[i];
    }
  }
  return selected;
}

                                                                    
                                                                      
   
                                                                    
List<int> _findTroughsBetweenPeaks(
    List<double> signal, List<int> peaks) {
  if (peaks.length < 2) return [];
  final troughs = <int>[];

                                 
  if (peaks.first > 0) {
    int minIdx = 0;
    double minVal = signal[0];
    for (int i = 1; i < peaks.first; i++) {
      if (signal[i] < minVal) {
        minVal = signal[i];
        minIdx = i;
      }
    }
    troughs.add(minIdx);
  }

                                                  
  for (int p = 0; p < peaks.length - 1; p++) {
    int minIdx = peaks[p];
    double minVal = signal[peaks[p]];
    for (int i = peaks[p] + 1; i < peaks[p + 1]; i++) {
      if (signal[i] < minVal) {
        minVal = signal[i];
        minIdx = i;
      }
    }
    troughs.add(minIdx);
  }

                               
  if (peaks.last < signal.length - 1) {
    int minIdx = peaks.last;
    double minVal = signal[peaks.last];
    for (int i = peaks.last + 1; i < signal.length; i++) {
      if (signal[i] < minVal) {
        minVal = signal[i];
        minIdx = i;
      }
    }
    troughs.add(minIdx);
  }

  return troughs;
}