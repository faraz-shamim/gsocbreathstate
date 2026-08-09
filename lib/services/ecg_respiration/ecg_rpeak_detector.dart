                                                                      
   
                                                               
                                                        
                                                 
                                                         
                                                            
                                               
                                                 
                               
   
                                                                  
library;

import 'dart:math' as math;

                                                                      
                  
                                                                      

                             
class DetectedRPeak {
                                       
  final int sampleIndex;

                                             
  final double timeSec;

                                        
  final double amplitudeUv;

                                                  
  final bool isEctopic;

  const DetectedRPeak({
    required this.sampleIndex,
    required this.timeSec,
    required this.amplitudeUv,
    this.isEctopic = false,
  });
}

                                                 
class RPeakDetectionResult {
                                               
  final List<DetectedRPeak> peaks;

                                        
  List<DetectedRPeak> get normalPeaks =>
      peaks.where((p) => !p.isEctopic).toList();

                                                         
  final List<double> rrIntervalsMs;

                                            
  List<double> get amplitudes => peaks.map((p) => p.amplitudeUv).toList();

                                              
  List<double> get peakTimesSec => peaks.map((p) => p.timeSec).toList();

                                    
  final double signalQuality;

                                       
  int get ectopicCount => peaks.where((p) => p.isEctopic).length;

  const RPeakDetectionResult({
    required this.peaks,
    required this.rrIntervalsMs,
    required this.signalQuality,
  });
}

                                                                      
            
                                                                      

class EcgRPeakDetector {
  EcgRPeakDetector._();

                                            
  static const double defaultSampleRate = 130.0;

                                      
     
                                                        
                                                                     
                                                                                    
  static RPeakDetectionResult detect(
    List<double> ecgSamples, {
    double sampleRate = defaultSampleRate,
    double refractoryMs = 300.0,
  }) {
    if (ecgSamples.length < 10) {
      return const RPeakDetectionResult(
        peaks: [],
        rrIntervalsMs: [],
        signalQuality: 0,
      );
    }

                                                                
    final bandpassed = _bandpassFilter(ecgSamples, sampleRate);

                                                                
    final differentiated = _differentiate(bandpassed);

                                                                
    final squared = List<double>.generate(
      differentiated.length,
      (i) => differentiated[i] * differentiated[i],
    );

                                                                
                                                        
    final int winWidth = (0.150 * sampleRate).round().clamp(1, squared.length);
    final integrated = _movingWindowIntegration(squared, winWidth);

                                                                
    final int refractorySamples = (refractoryMs / 1000.0 * sampleRate)
        .round()
        .clamp(1, ecgSamples.length);
    final peakIndices = _adaptiveThreshold(
      integrated,
      refractorySamples,
      sampleRate,
    );

                                                                
                                                                   
    final int searchRadius = (0.050 * sampleRate).round().clamp(1, 20);
    final refinedPeaks = <DetectedRPeak>[];
    for (final idx in peakIndices) {
      final int lo = (idx - searchRadius).clamp(0, ecgSamples.length - 1);
      final int hi = (idx + searchRadius).clamp(0, ecgSamples.length - 1);
      int bestIdx = idx;
      double bestVal = ecgSamples[idx].abs();
      for (int i = lo; i <= hi; i++) {
        if (ecgSamples[i].abs() > bestVal) {
          bestVal = ecgSamples[i].abs();
          bestIdx = i;
        }
      }
      refinedPeaks.add(
        DetectedRPeak(
          sampleIndex: bestIdx,
          timeSec: bestIdx / sampleRate,
          amplitudeUv: ecgSamples[bestIdx],
        ),
      );
    }

    if (refinedPeaks.isEmpty) {
      return _detectAdaptivePolar(
        ecgSamples,
        sampleRate: sampleRate,
        refractoryMs: refractoryMs,
      );
    }

                                                                
    final rrIntervals = <double>[];
    for (int i = 1; i < refinedPeaks.length; i++) {
      final double rrMs =
          (refinedPeaks[i].sampleIndex - refinedPeaks[i - 1].sampleIndex) /
          sampleRate *
          1000.0;
      rrIntervals.add(rrMs);
    }

                                                                
    final classifiedPeaks = _classifyEctopic(refinedPeaks, rrIntervals);

                                                                
    final quality = _estimateSignalQuality(
      classifiedPeaks,
      rrIntervals,
      ecgSamples.length / sampleRate,
    );

                                                   
    final normalPeaks = classifiedPeaks.where((p) => !p.isEctopic).toList();
    final normalRR = <double>[];
    for (int i = 1; i < normalPeaks.length; i++) {
      normalRR.add(
        (normalPeaks[i].sampleIndex - normalPeaks[i - 1].sampleIndex) /
            sampleRate *
            1000.0,
      );
    }

    final panTompkinsResult = RPeakDetectionResult(
      peaks: classifiedPeaks,
      rrIntervalsMs: normalRR,
      signalQuality: quality,
    );
    final adaptiveResult = _detectAdaptivePolar(
      ecgSamples,
      sampleRate: sampleRate,
      refractoryMs: refractoryMs,
    );
    return _chooseBestResult(
      panTompkinsResult,
      adaptiveResult,
      durationSec: ecgSamples.length / sampleRate,
    );
  }

                                                                  
                         
                                                                  

                                                             
                                      
  static List<double> _bandpassFilter(List<double> signal, double fs) {
                                                                   
    final int n = signal.length;
    final int nfft = _nextPow2(n);
    final re = List<double>.filled(nfft, 0.0);
    final im = List<double>.filled(nfft, 0.0);
    for (int i = 0; i < n; i++) {
      re[i] = signal[i];
    }
    _fft(re, im);

    const double lowcut = 5.0;
    const double highcut = 15.0;
    final double rolloff = (highcut - lowcut) * 0.2;

    for (int k = 0; k < nfft; k++) {
      final double freq =
          k <= nfft ~/ 2 ? k * fs / nfft : (nfft - k) * fs / nfft;
      double gain;
      if (freq < lowcut - rolloff || freq > highcut + rolloff) {
        gain = 0.0;
      } else if (freq < lowcut) {
        gain = 0.5 * (1.0 + math.cos(math.pi * (lowcut - freq) / rolloff));
      } else if (freq > highcut) {
        gain = 0.5 * (1.0 + math.cos(math.pi * (freq - highcut) / rolloff));
      } else {
        gain = 1.0;
      }
      re[k] *= gain;
      im[k] *= gain;
    }

                  
    for (int i = 0; i < nfft; i++) im[i] = -im[i];
    _fft(re, im);
    for (int i = 0; i < nfft; i++) re[i] /= nfft;

    return re.sublist(0, n);
  }

                                                                                
  static List<double> _differentiate(List<double> signal) {
    final n = signal.length;
    final result = List<double>.filled(n, 0.0);
    for (int i = 2; i < n - 2; i++) {
      result[i] =
          (-signal[i - 2] -
              2 * signal[i - 1] +
              2 * signal[i + 1] +
              signal[i + 2]) /
          8.0;
    }
    return result;
  }

                                
  static List<double> _movingWindowIntegration(
    List<double> signal,
    int windowWidth,
  ) {
    final n = signal.length;
    final result = List<double>.filled(n, 0.0);
    double sum = 0;
    for (int i = 0; i < n; i++) {
      sum += signal[i];
      if (i >= windowWidth) sum -= signal[i - windowWidth];
      result[i] = sum / windowWidth;
    }
    return result;
  }

                                             
  static List<int> _adaptiveThreshold(
    List<double> integrated,
    int refractorySamples,
    double sampleRate,
  ) {
    final n = integrated.length;
    if (n < 4) return [];

                                                 
    final int initSamples = math.min((2.0 * sampleRate).round(), n);
    double spki = 0;                                
    double npki = 0;                               

                                        
    for (int i = 0; i < initSamples; i++) {
      if (integrated[i] > spki) spki = integrated[i];
    }
    npki = spki * 0.1;

    double threshold1 = npki + 0.25 * (spki - npki);

    final peaks = <int>[];
    int lastPeakIdx = -refractorySamples;

    for (int i = 1; i < n - 1; i++) {
                            
      if (integrated[i] <= integrated[i - 1] ||
          integrated[i] < integrated[i + 1]) {
        continue;
      }

                                
      if (i - lastPeakIdx < refractorySamples) continue;

      if (integrated[i] > threshold1) {
                      
        peaks.add(i);
        lastPeakIdx = i;
        spki = 0.125 * integrated[i] + 0.875 * spki;
      } else {
                     
        npki = 0.125 * integrated[i] + 0.875 * npki;
      }

                         
      threshold1 = npki + 0.25 * (spki - npki);
    }

                                                               
    if (peaks.length >= 2) {
      final avgRR = (peaks.last - peaks.first) / (peaks.length - 1);
      final maxGap = (1.66 * avgRR).round();
      final searchBackPeaks = <int>[];

      for (int i = 0; i < peaks.length - 1; i++) {
        searchBackPeaks.add(peaks[i]);
        final gap = peaks[i + 1] - peaks[i];
        if (gap > maxGap) {
                                                                
          final threshold2 = 0.5 * threshold1;
          int bestIdx = -1;
          double bestVal = 0;
          for (
            int j = peaks[i] + refractorySamples;
            j < peaks[i + 1] - refractorySamples;
            j++
          ) {
            if (integrated[j] > threshold2 && integrated[j] > bestVal) {
              bestVal = integrated[j];
              bestIdx = j;
            }
          }
          if (bestIdx > 0) searchBackPeaks.add(bestIdx);
        }
      }
      searchBackPeaks.add(peaks.last);
      searchBackPeaks.sort();
      return searchBackPeaks;
    }

    return peaks;
  }

                                                             
  static List<DetectedRPeak> _classifyEctopic(
    List<DetectedRPeak> peaks,
    List<double> rrIntervals,
  ) {
    if (peaks.length < 3) return peaks;

    final classified = <DetectedRPeak>[
      peaks.first,
    ];                             

    for (int i = 1; i < peaks.length; i++) {
      bool isEctopic = false;

      if (i <= rrIntervals.length) {
        final rrMs =
            i > 0 && i - 1 < rrIntervals.length ? rrIntervals[i - 1] : 0.0;

                               
        if (rrMs < 250 || rrMs > 2000) {
          isEctopic = true;
        } else {
                                                       
          final start = math.max(0, i - 3);
          final end = math.min(rrIntervals.length, i + 2);
          final neighbors = <double>[];
          for (int j = start; j < end; j++) {
            if (j != i - 1) neighbors.add(rrIntervals[j]);
          }
          if (neighbors.isNotEmpty) {
            neighbors.sort();
            final median = neighbors[neighbors.length ~/ 2];
            if (median > 0 && (rrMs - median).abs() / median > 0.20) {
              isEctopic = true;
            }
          }
        }
      }

      classified.add(
        DetectedRPeak(
          sampleIndex: peaks[i].sampleIndex,
          timeSec: peaks[i].timeSec,
          amplitudeUv: peaks[i].amplitudeUv,
          isEctopic: isEctopic,
        ),
      );
    }

    return classified;
  }

                                                        
  static double _estimateSignalQuality(
    List<DetectedRPeak> peaks,
    List<double> rrIntervals,
    double durationSec,
  ) {
    if (peaks.isEmpty || durationSec < 1) return 0.0;

                                                                  
    final double detectedHR = peaks.length / durationSec * 60.0;
    final double hrScore =
        (detectedHR >= 40 && detectedHR <= 200)
            ? 1.0
            : (detectedHR >= 30 && detectedHR <= 220)
            ? 0.5
            : 0.1;

                              
    final int ectopicCount = peaks.where((p) => p.isEctopic).length;
    final double ectopicRatio = ectopicCount / peaks.length;
    final double ectopicScore = (1.0 - ectopicRatio * 3.0).clamp(0.0, 1.0);

                                        
    double rrScore = 1.0;
    if (rrIntervals.length >= 3) {
      final mean = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
      double sumSq = 0;
      for (final rr in rrIntervals) {
        sumSq += (rr - mean) * (rr - mean);
      }
      final cv = mean > 0 ? math.sqrt(sumSq / rrIntervals.length) / mean : 1.0;
      rrScore = (1.0 - cv * 2.0).clamp(0.0, 1.0);
    }

    return (hrScore * 0.3 + ectopicScore * 0.3 + rrScore * 0.4).clamp(0.0, 1.0);
  }

                                                                  
                                                      
                                                                  

  static RPeakDetectionResult _detectAdaptivePolar(
    List<double> ecgSamples, {
    required double sampleRate,
    required double refractoryMs,
  }) {
    if (ecgSamples.length < 10) {
      return const RPeakDetectionResult(
        peaks: [],
        rrIntervalsMs: [],
        signalQuality: 0,
      );
    }

    final filtered = _movingAverage(ecgSamples, 5);
    final mean = filtered.reduce((a, b) => a + b) / filtered.length;
    var sumSq = 0.0;
    var minValue = filtered.first;
    var maxValue = filtered.first;
    for (final value in filtered) {
      final delta = value - mean;
      sumSq += delta * delta;
      minValue = math.min(minValue, value);
      maxValue = math.max(maxValue, value);
    }
    final std = math.sqrt(sumSq / filtered.length);
    if (std <= 0 || (maxValue - minValue).abs() < 1e-9) {
      return const RPeakDetectionResult(
        peaks: [],
        rrIntervalsMs: [],
        signalQuality: 0,
      );
    }

    final distanceSamples = (math.max(refractoryMs, 300.0) /
            1000.0 *
            sampleRate)
        .round()
        .clamp(1, ecgSamples.length);
    final threshold = mean + 0.5 * std;
    final minProminence = std * 0.2;
    final peakIndices = _findProminentPeaks(
      filtered,
      heightThreshold: threshold,
      minDistanceSamples: distanceSamples,
      minProminence: minProminence,
    );

    final searchRadius = (0.050 * sampleRate).round().clamp(1, 20);
    final refined = <DetectedRPeak>[];
    var lastIdx = -distanceSamples;
    for (final idx in peakIndices) {
      final lo = (idx - searchRadius).clamp(0, ecgSamples.length - 1);
      final hi = (idx + searchRadius).clamp(0, ecgSamples.length - 1);
      var bestIdx = idx;
      var bestVal = ecgSamples[idx].abs();
      for (var i = lo; i <= hi; i++) {
        final value = ecgSamples[i].abs();
        if (value > bestVal) {
          bestVal = value;
          bestIdx = i;
        }
      }
      if (bestIdx - lastIdx < distanceSamples) {
        if (refined.isNotEmpty &&
            ecgSamples[bestIdx].abs() > refined.last.amplitudeUv.abs()) {
          refined[refined.length - 1] = DetectedRPeak(
            sampleIndex: bestIdx,
            timeSec: bestIdx / sampleRate,
            amplitudeUv: ecgSamples[bestIdx],
          );
          lastIdx = bestIdx;
        }
        continue;
      }
      refined.add(
        DetectedRPeak(
          sampleIndex: bestIdx,
          timeSec: bestIdx / sampleRate,
          amplitudeUv: ecgSamples[bestIdx],
        ),
      );
      lastIdx = bestIdx;
    }

    if (refined.isEmpty) {
      return const RPeakDetectionResult(
        peaks: [],
        rrIntervalsMs: [],
        signalQuality: 0,
      );
    }

    final rrIntervals = <double>[];
    for (var i = 1; i < refined.length; i++) {
      rrIntervals.add(
        (refined[i].sampleIndex - refined[i - 1].sampleIndex) /
            sampleRate *
            1000.0,
      );
    }

    final classified = _classifyEctopic(refined, rrIntervals);
    final normalPeaks = classified.where((p) => !p.isEctopic).toList();
    final normalRr = <double>[];
    for (var i = 1; i < normalPeaks.length; i++) {
      normalRr.add(
        (normalPeaks[i].sampleIndex - normalPeaks[i - 1].sampleIndex) /
            sampleRate *
            1000.0,
      );
    }

    return RPeakDetectionResult(
      peaks: classified,
      rrIntervalsMs: normalRr,
      signalQuality: _estimateSignalQuality(
        classified,
        normalRr,
        ecgSamples.length / sampleRate,
      ),
    );
  }

  static RPeakDetectionResult _chooseBestResult(
    RPeakDetectionResult panTompkins,
    RPeakDetectionResult adaptive, {
    required double durationSec,
  }) {
    if (adaptive.normalPeaks.length < 2) return panTompkins;
    if (panTompkins.normalPeaks.length < 2) return adaptive;
    final panScore = _resultScore(panTompkins, durationSec);
    final adaptiveScore = _resultScore(adaptive, durationSec);
    return adaptiveScore > panScore + 0.05 ? adaptive : panTompkins;
  }

  static double _resultScore(RPeakDetectionResult result, double durationSec) {
    if (durationSec <= 0 || result.normalPeaks.isEmpty) return 0;
    final detectedHr = result.normalPeaks.length / durationSec * 60.0;
    final hrScore =
        (detectedHr >= 40 && detectedHr <= 200)
            ? 1.0
            : (detectedHr >= 30 && detectedHr <= 220)
            ? 0.6
            : 0.1;
    final rrCountScore = (result.rrIntervalsMs.length / 8.0).clamp(0.0, 1.0);
    return (result.signalQuality * 0.55 + hrScore * 0.30 + rrCountScore * 0.15)
        .clamp(0.0, 1.0);
  }

  static List<double> _movingAverage(List<double> signal, int windowSize) {
    if (signal.length < windowSize || windowSize <= 1) {
      return List<double>.from(signal);
    }
    final half = windowSize ~/ 2;
    return List<double>.generate(signal.length, (i) {
      final lo = math.max(0, i - half);
      final hi = math.min(signal.length - 1, i + half);
      var sum = 0.0;
      for (var j = lo; j <= hi; j++) {
        sum += signal[j];
      }
      return sum / (hi - lo + 1);
    });
  }

  static List<int> _findProminentPeaks(
    List<double> signal, {
    required double heightThreshold,
    required int minDistanceSamples,
    required double minProminence,
  }) {
    final peaks = <int>[];
    for (var i = 1; i < signal.length - 1; i++) {
      final value = signal[i];
      if (value < heightThreshold ||
          value <= signal[i - 1] ||
          value < signal[i + 1]) {
        continue;
      }

      if (_localProminence(signal, i, minDistanceSamples) < minProminence) {
        continue;
      }

      if (peaks.isEmpty || i - peaks.last >= minDistanceSamples) {
        peaks.add(i);
      } else if (value > signal[peaks.last]) {
        peaks[peaks.length - 1] = i;
      }
    }
    return peaks;
  }

  static double _localProminence(
    List<double> signal,
    int peakIndex,
    int minDistanceSamples,
  ) {
    final radius = math.max(1, minDistanceSamples ~/ 2);
    final leftStart = math.max(0, peakIndex - radius);
    final rightEnd = math.min(signal.length - 1, peakIndex + radius);
    var leftMin = signal[peakIndex];
    var rightMin = signal[peakIndex];
    for (var i = leftStart; i <= peakIndex; i++) {
      leftMin = math.min(leftMin, signal[i]);
    }
    for (var i = peakIndex; i <= rightEnd; i++) {
      rightMin = math.min(rightMin, signal[i]);
    }
    return signal[peakIndex] - math.max(leftMin, rightMin);
  }

  static int _nextPow2(int n) {
    int p = 1;
    while (p < n) p <<= 1;
    return p;
  }

  static void _fft(List<double> re, List<double> im) {
    final int n = re.length;
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        double t = re[i];
        re[i] = re[j];
        re[j] = t;
        t = im[i];
        im[i] = im[j];
        im[j] = t;
      }
      int m = n >> 1;
      while (m >= 1 && j >= m) {
        j -= m;
        m >>= 1;
      }
      j += m;
    }
    for (int size = 2; size <= n; size <<= 1) {
      final int half = size >> 1;
      final double theta = -2.0 * math.pi / size;
      final double wR = math.cos(theta), wI = math.sin(theta);
      for (int i = 0; i < n; i += size) {
        double uR = 1.0, uI = 0.0;
        for (int k = 0; k < half; k++) {
          final int a = i + k, b = a + half;
          final double tR = uR * re[b] - uI * im[b];
          final double tI = uR * im[b] + uI * re[b];
          re[b] = re[a] - tR;
          im[b] = im[a] - tI;
          re[a] += tR;
          im[a] += tI;
          final double nu = uR * wR - uI * wI;
          uI = uR * wI + uI * wR;
          uR = nu;
        }
      }
    }
  }
}
