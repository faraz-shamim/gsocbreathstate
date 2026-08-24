// SPDX-License-Identifier: AGPL-3.0-only
                                                                      
                                   
   
                                                                      
                                                         
   
                                                                     
                            
                                                                      
                                                           
                                                                    
                                                                  
                                                                    
                                                                   
   
                                   
                                                                          
                                                           
                                                
                                              
   
                                                                     
                                 
   
               
                                                            
                                                          
                                                   
library;

import 'dart:math' as math;
import 'signal_processing.dart'
    show welchPSD, lombScarglePSD, pchipInterpolate, trapz, fftInPlace, nextPowerOfTwo;

                                                                      
                
                                                                      

                                                    
class HrvDerivedBreathingResult {
                                                    
                                               
  final double breathingRateBpm;

                                                      
  final double peakFrequencyHz;

                                             
     
                                                             
                                        
                                                    
     
                                                                 
                                              
  final double confidence;

                                               
  final double peakPower;

                                                             
  final double totalBandPower;

                                                              
  final int artifactsCorrected;

                                                        
  final List<double> frequencies;

                                                       
  final List<double> psd;

                                           
  final List<_MethodEstimate> methodEstimates;

                                                  
  final double durationSec;

                                                                    
  final double estimatedCycles;

                                                  
  final Map<String, double> confidenceFactors;

                                                         
  final String? warning;

  const HrvDerivedBreathingResult({
    required this.breathingRateBpm,
    required this.peakFrequencyHz,
    required this.confidence,
    required this.peakPower,
    required this.totalBandPower,
    this.artifactsCorrected = 0,
    required this.frequencies,
    required this.psd,
    this.methodEstimates = const [],
    this.durationSec = 0,
    this.estimatedCycles = 0,
    this.confidenceFactors = const {},
    this.warning,
  });
}

                                               
class _MethodEstimate {
  final String name;
  final double frequencyHz;
  final double confidence;
  const _MethodEstimate(this.name, this.frequencyHz, this.confidence);
}

                                                                      
             
                                                                      

                                                              
                        
   
           
                                                                   
                                           
                                                                           
       
class HrvDerivedBreathingRate {
  HrvDerivedBreathingRate._();

                                                                     
  static const double standardMinFreqHz = 0.15;
  static const double standardMaxFreqHz = 0.40;

                                                                     
                                                                         
                                                                       
                                                               
                                                           
  static const double guidedMinFreqHz = 0.10;
  static const double guidedMaxFreqHz = 0.70;

                                                   
     
                                                              
                                             
                                                            
                                                              
                                                          
  static HrvDerivedBreathingResult estimate(
    List<double> rrIntervalsMs, {
    double interpolationRateHz = 4.0,
    double minFreqHz = standardMinFreqHz,
    double maxFreqHz = standardMaxFreqHz,
  }) {
                                                               
    if (rrIntervalsMs.length < 20) {
      return HrvDerivedBreathingResult(
        breathingRateBpm: 0,
        peakFrequencyHz: 0,
        confidence: 0,
        peakPower: 0,
        totalBandPower: 0,
        frequencies: const [],
        psd: const [],
        warning:
            'Too few RR intervals (${rrIntervalsMs.length}, '
            'need ≥ 20) for breathing rate estimation.',
      );
    }

                                                                
    final (cleanRR, nCorrected) = _malikArtifactCorrect(rrIntervalsMs);

                                                                
    final rrTimesS = List<double>.filled(cleanRR.length, 0.0);
    double cumMs = 0;
    for (int i = 0; i < cleanRR.length; i++) {
      rrTimesS[i] = cumMs / 1000.0;
      cumMs += cleanRR[i];
    }
    final double durationSec = cumMs / 1000.0;

                     
    String? warning;
    if (durationSec < 15) {
      return HrvDerivedBreathingResult(
        breathingRateBpm: 0,
        peakFrequencyHz: 0,
        confidence: 0,
        peakPower: 0,
        totalBandPower: 0,
        artifactsCorrected: nCorrected,
        frequencies: const [],
        psd: const [],
        durationSec: durationSec,
        warning:
            'Recording too short '
            '(${durationSec.toStringAsFixed(0)}s, need ≥ 15s).',
      );
    }
    if (durationSec < 30) {
      warning =
          'Recording < 30s — breathing rate estimate '
          'may have low frequency resolution.';
    } else if (durationSec < 60) {
      warning =
          'Recording < 60s: RSA breathing estimates '
          'are less stable than full-minute windows.';
    }
    if (nCorrected > 0) {
      final pct = (nCorrected / rrIntervalsMs.length * 100).toStringAsFixed(1);
      final artMsg = '$nCorrected interval(s) corrected ($pct%).';
      warning = warning != null ? '$warning\n$artMsg' : artMsg;
    }

                                                                
                                                              
                                                              
                                                                   
    final (_, resampled) = pchipInterpolate(
      rrTimesS,
      cleanRR,
      interpolationRateHz,
    );

    if (resampled.length < 8) {
      return HrvDerivedBreathingResult(
        breathingRateBpm: 0,
        peakFrequencyHz: 0,
        confidence: 0,
        peakPower: 0,
        totalBandPower: 0,
        artifactsCorrected: nCorrected,
        frequencies: const [],
        psd: const [],
        durationSec: durationSec,
        warning: 'Resampled signal too short for PSD.',
      );
    }

                                                                
    final detrended = _linearDetrend(resampled);

                                                                
                                                             
                                                                
                                                
                                                                       
                                                                    
                                                      
    final int idealSeg = (45.0 * interpolationRateHz).round();
    final int nperseg =
        detrended.length <= idealSeg ? detrended.length : idealSeg;
    final (freqs, psd) = welchPSD(
      detrended,
      interpolationRateHz,
      nperseg: nperseg,
    );

                                                                
                                                                    
                                                                   
                                                                  
    final double timeDomainMinFreq = math.max(minFreqHz, 0.15);
    final bandpassed = _fftBandpass(
      detrended,
      interpolationRateHz,
      timeDomainMinFreq,
      maxFreqHz,
    );

                                                                
    final methods = <_MethodEstimate>[];

                                                                  
    final spectral = _spectralMethod(freqs, psd, minFreqHz, maxFreqHz);
    if (spectral != null) methods.add(spectral);

                                                           
                                                          
    final lombScargle = _lombScargleMethod(
      rrTimesS,
      cleanRR,
      minFreqHz,
      maxFreqHz,
    );
    if (lombScargle != null) methods.add(lombScargle);

                                          
                                                
    final peakCount = _peakCountMethod(
      bandpassed,
      interpolationRateHz,
      timeDomainMinFreq,
      maxFreqHz,
    );
    if (peakCount != null) methods.add(peakCount);

                               
    final acov = _autocovarianceMethod(
      bandpassed,
      interpolationRateHz,
      timeDomainMinFreq,
      maxFreqHz,
    );
    if (acov != null) methods.add(acov);

                                                         
    final zeroCrossing = _zeroCrossingMethod(
      bandpassed,
      interpolationRateHz,
      timeDomainMinFreq,
      maxFreqHz,
    );
    if (zeroCrossing != null) methods.add(zeroCrossing);

                                                                
    if (methods.isEmpty) {
      return HrvDerivedBreathingResult(
        breathingRateBpm: 0,
        peakFrequencyHz: 0,
        confidence: 0,
        peakPower: 0,
        totalBandPower: 0,
        artifactsCorrected: nCorrected,
        frequencies: freqs,
        psd: psd,
        methodEstimates: methods,
        durationSec: durationSec,
        warning: 'No method produced a valid respiratory estimate.',
      );
    }

    final fusionMethods = _dominantMethodCluster(methods);
    if (fusionMethods.length < methods.length) {
      final excluded = methods.length - fusionMethods.length;
      final msg = '$excluded respiratory-rate method(s) excluded as outliers.';
      warning = warning != null ? '$warning\n$msg' : msg;
    }

    double weightedFreqSum = 0;
    double weightSum = 0;
    for (final m in fusionMethods) {
      final weight = math.max(0.02, m.confidence);
      weightedFreqSum += m.frequencyHz * weight;
      weightSum += weight;
    }
    final double fusedFreqHz =
        weightSum > 0
            ? weightedFreqSum / weightSum
            : fusionMethods.first.frequencyHz;
    final double fusedBpm = fusedFreqHz * 60.0;

                                                                   
                                                                      
    double fusedConfidence =
        weightSum > 0
            ? weightSum / fusionMethods.length
            : fusionMethods.first.confidence;

    if (fusionMethods.length >= 2) {
      final spread = _methodSpreadBpm(fusionMethods);
      if (spread < 1.0) {
        fusedConfidence = (fusedConfidence * 1.3).clamp(0.0, 1.0);
      } else if (spread < 2.0) {
        fusedConfidence = (fusedConfidence * 1.1).clamp(0.0, 1.0);
      } else if (spread > 4.0) {
        fusedConfidence *= 0.7;
      }
    } else {
      fusedConfidence *= 0.85;
    }

                                                                
    double peakPower = 0;
    double totalBandPower = 0;
    double bandPowerSum = 0;
    final bandFreqs = <double>[];
    final bandPsd = <double>[];
    for (int i = 0; i < freqs.length; i++) {
      if (freqs[i] >= minFreqHz && freqs[i] <= maxFreqHz) {
        bandFreqs.add(freqs[i]);
        bandPsd.add(psd[i]);
        bandPowerSum += math.max(0.0, psd[i]);
        if (psd[i] > peakPower) peakPower = psd[i];
      }
    }
    if (bandFreqs.length >= 2) {
      totalBandPower = trapz(bandFreqs, bandPsd);
    }

    final double estimatedCycles = fusedFreqHz * durationSec;
    final double methodAgreementConfidence = fusedConfidence.clamp(0.0, 1.0);
    final double peakFraction =
        bandPowerSum > 0 ? (peakPower / bandPowerSum).clamp(0.0, 1.0) : 0.0;
                                                                      
                                                                 
                                                                   
    final double spectralPeakConfidence = (peakFraction / 0.12).clamp(0.0, 1.0);
    final double durationConfidence = _durationConfidence(durationSec);
    final double cycleConfidence = _cycleConfidence(estimatedCycles);
    final double artifactConfidence = _artifactConfidence(
      nCorrected,
      rrIntervalsMs.length,
    );
                                                                
                                                              
                                                                  
                                            
    final double adjustedConfidence = (methodAgreementConfidence * 0.50 +
            spectralPeakConfidence * 0.15 +
            durationConfidence * 0.12 +
            cycleConfidence * 0.13 +
            artifactConfidence * 0.10)
        .clamp(0.0, 1.0);

    if (estimatedCycles < 4) {
      final cycleMsg =
          'Fewer than 4 respiratory cycles detected '
          '(${estimatedCycles.toStringAsFixed(1)}): confidence reduced.';
      warning = warning != null ? '$warning\n$cycleMsg' : cycleMsg;
    }

    return HrvDerivedBreathingResult(
      breathingRateBpm: fusedBpm,
      peakFrequencyHz: fusedFreqHz,
      confidence: adjustedConfidence,
      peakPower: peakPower,
      totalBandPower: totalBandPower,
      artifactsCorrected: nCorrected,
      frequencies: freqs,
      psd: psd,
      methodEstimates: methods,
      durationSec: durationSec,
      estimatedCycles: estimatedCycles,
      confidenceFactors: {
        'method_agreement': methodAgreementConfidence,
        'spectral_peak': spectralPeakConfidence,
        'duration': durationConfidence,
        'cycles': cycleConfidence,
        'artifacts': artifactConfidence,
      },
      warning: warning,
    );
  }

                                                                  
  static List<_MethodEstimate> _dominantMethodCluster(
    List<_MethodEstimate> methods,
  ) {
    if (methods.length <= 2) return List<_MethodEstimate>.from(methods);

                                                                   
                                                                   
    const double toleranceHz = 3.5 / 60.0;           
    var bestCluster = <_MethodEstimate>[];
    var bestWeight = -1.0;

    for (final center in methods) {
      final cluster =
          methods
              .where(
                (m) =>
                    (m.frequencyHz - center.frequencyHz).abs() <= toleranceHz,
              )
              .toList();
      final weight = cluster.fold<double>(
        0.0,
        (sum, m) => sum + math.max(0.02, m.confidence),
      );
      if (weight > bestWeight ||
          (weight == bestWeight && cluster.length > bestCluster.length)) {
        bestWeight = weight;
        bestCluster = cluster;
      }
    }

    if (bestCluster.isEmpty) return [methods.first];
    return bestCluster;
  }

                                                                  
                                                                
                                                               
                                                             
                                                            
                                                                 
                   
                                                    
                                                    
  static double _physiologicalPrior(double freqHz) {
    const double mu = 0.25;                    
    const double sigma = 0.15;                                 
    final double d = freqHz - mu;
    return math.exp(-0.5 * d * d / (sigma * sigma));
  }

  static double _methodSpreadBpm(List<_MethodEstimate> methods) {
    final bpms = methods.map((m) => m.frequencyHz * 60.0).toList();
    return bpms.reduce(math.max) - bpms.reduce(math.min);
  }

  static double _edgePenalty(
    double freqHz,
    double minFreqHz,
    double maxFreqHz,
  ) {
    final bandWidth = maxFreqHz - minFreqHz;
    if (bandWidth <= 0) return 1.0;
    final margin = math.max(0.015, bandWidth * 0.08);
    final distance = math.min(freqHz - minFreqHz, maxFreqHz - freqHz);
    if (distance >= margin) return 1.0;
    return (0.35 + 0.65 * (distance / margin).clamp(0.0, 1.0)).clamp(0.0, 1.0);
  }

                                                                       
                                                                       
                                                                       
                                                                   
                                                               
  static (int, double)? _mayerWaveCheck(
    List<double> freqs,
    List<double> psd,
    int candidateIdx,
    double candidateFreq,
  ) {
                                               
    if (candidateFreq >= 0.12 || candidateFreq < 0.067) return null;

    final double candidatePower = psd[candidateIdx];
    int bestAltIdx = -1;
    double bestAltPower = 0;

    for (int i = 0; i < freqs.length; i++) {
      if (freqs[i] >= 0.12 && freqs[i] <= 0.25 && psd[i] > bestAltPower) {
        bestAltPower = psd[i];
        bestAltIdx = i;
      }
    }

                                                                    
                                              
    if (bestAltIdx >= 0 && bestAltPower >= candidatePower * 0.50) {
      return (bestAltIdx, freqs[bestAltIdx]);
    }
    return null;
  }

  static double _peakSeparationScore(
    List<double> freqs,
    List<double> psd,
    int peakIdx,
    double minFreqHz,
    double maxFreqHz,
  ) {
    if (peakIdx < 0 || peakIdx >= psd.length) return 0.0;
    final peakFreq = freqs[peakIdx];
    final peakPower = psd[peakIdx];
    if (peakPower <= 0) return 0.0;

    var secondPower = 0.0;
    for (int i = 0; i < psd.length; i++) {
      if (i == peakIdx) continue;
      if (freqs[i] < minFreqHz || freqs[i] > maxFreqHz) continue;
      if ((freqs[i] - peakFreq).abs() < 0.04) continue;
      secondPower = math.max(secondPower, psd[i]);
    }

    if (secondPower <= 0) return 1.0;
    final ratio = peakPower / secondPower;
    return ((ratio - 1.0) / 1.5).clamp(0.25, 1.0);
  }

  static double _robustScale(List<double> values) {
    if (values.isEmpty) return 0.0;
    final median = _median(values);
    final deviations = values.map((v) => (v - median).abs()).toList();
    final mad = _median(deviations) * 1.4826;
    if (mad > 1e-9) return mad;

    final mean = values.reduce((a, b) => a + b) / values.length;
    var sumSq = 0.0;
    for (final v in values) {
      sumSq += (v - mean) * (v - mean);
    }
    return math.sqrt(sumSq / values.length);
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) * 0.5;
  }

  static double _localProminence(
    List<double> signal,
    int peakIndex,
    int radius,
  ) {
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

                                                           
                                                                  

  static _MethodEstimate? _spectralMethod(
    List<double> freqs,
    List<double> psd,
    double minFreqHz,
    double maxFreqHz,
  ) {
    int peakIdx = -1;
    double peakVal = -1;
    final bandPowers = <double>[];

                                                                 
                                                              
                                                                   
                                                                  
    for (int i = 0; i < freqs.length; i++) {
      if (freqs[i] >= minFreqHz && freqs[i] <= maxFreqHz) {
        bandPowers.add(psd[i]);
        final double weightedPower = psd[i] * _physiologicalPrior(freqs[i]);
        if (weightedPower > peakVal) {
          peakVal = weightedPower;
          peakIdx = i;
        }
      }
    }

    if (peakIdx < 0 || bandPowers.isEmpty) return null;

                                                   
    double peakFreq = freqs[peakIdx];
    if (peakIdx > 0 && peakIdx < freqs.length - 1) {
      final double alpha = psd[peakIdx - 1];
      final double beta = psd[peakIdx];
      final double gamma = psd[peakIdx + 1];
      final double denom = alpha - 2.0 * beta + gamma;
      if (denom.abs() > 1e-15) {
        final double p = 0.5 * (alpha - gamma) / denom;
        final double df = freqs[1] - freqs[0];
        peakFreq = freqs[peakIdx] + p * df;
      }
    }

                           
    peakFreq = peakFreq.clamp(minFreqHz, maxFreqHz);

                           
    final mayerAlt = _mayerWaveCheck(freqs, psd, peakIdx, peakFreq);
    if (mayerAlt != null) {
      peakIdx = mayerAlt.$1;
      peakFreq = mayerAlt.$2;
    }

                                                
                                                             
                                                               
                                                   
                                                                    
    final double actualPeakVal = psd[peakIdx];
    final sortedBand = List<double>.from(bandPowers)..sort();
    final double medianPower = sortedBand[sortedBand.length ~/ 2];
    final double concentration =
        medianPower > 0
            ? ((actualPeakVal / medianPower - 1.0) / 2.0).clamp(0.0, 1.0)
            : 0.0;
    final double confidence = (concentration *
            _peakSeparationScore(freqs, psd, peakIdx, minFreqHz, maxFreqHz) *
            _edgePenalty(peakFreq, minFreqHz, maxFreqHz))
        .clamp(0.0, 1.0);

    if (confidence < 0.03) return null;

    return _MethodEstimate('Spectral (FFT)', peakFreq, confidence);
  }

                                                                  
                                                                 
                                                                  

                                                           
                                                      
                                                           
  static _MethodEstimate? _lombScargleMethod(
    List<double> rrTimesS,
    List<double> rrValues,
    double minFreqHz,
    double maxFreqHz,
  ) {
    if (rrTimesS.length < 20) return null;

                                  
    final double mean = rrValues.reduce((a, b) => a + b) / rrValues.length;
    final centered = rrValues.map((v) => v - mean).toList();

                                                          
    const int nFreqs = 200;
    final freqs = List<double>.generate(
      nFreqs,
      (i) => minFreqHz + i * (maxFreqHz - minFreqHz) / (nFreqs - 1),
    );

    final psd = lombScarglePSD(rrTimesS, centered, freqs);

                                                   
                                                             
    int peakIdx = 0;
    double bestWeightedPower = psd[0] * _physiologicalPrior(freqs[0]);
    for (int i = 1; i < psd.length; i++) {
      final double wp = psd[i] * _physiologicalPrior(freqs[i]);
      if (wp > bestWeightedPower) {
        bestWeightedPower = wp;
        peakIdx = i;
      }
    }

    final double peakVal = psd[peakIdx];
    if (peakVal <= 0) return null;

                              
    double peakFreq = freqs[peakIdx];
    if (peakIdx > 0 && peakIdx < freqs.length - 1) {
      final double a = psd[peakIdx - 1];
      final double b = psd[peakIdx];
      final double c = psd[peakIdx + 1];
      final double denom = a - 2.0 * b + c;
      if (denom.abs() > 1e-15) {
        final double p = 0.5 * (a - c) / denom;
        final double df = freqs[1] - freqs[0];
        peakFreq = (freqs[peakIdx] + p * df).clamp(minFreqHz, maxFreqHz);
      }
    }

                           
    final mayerAlt = _mayerWaveCheck(freqs, psd, peakIdx, peakFreq);
    if (mayerAlt != null) {
      peakIdx = mayerAlt.$1;
      peakFreq = mayerAlt.$2;
    }

                                                                       
    final double actualPeakVal = psd[peakIdx];
    final sorted = List<double>.from(psd)..sort();
    final double median = sorted[sorted.length ~/ 2];
    final double concentration =
        median > 0 ? ((actualPeakVal / median - 1.0) / 2.0).clamp(0.0, 1.0) : 0.0;
    final double confidence = (concentration *
            _peakSeparationScore(freqs, psd, peakIdx, minFreqHz, maxFreqHz) *
            _edgePenalty(peakFreq, minFreqHz, maxFreqHz))
        .clamp(0.0, 1.0);

    if (confidence < 0.03) return null;

    return _MethodEstimate('Lomb-Scargle', peakFreq, confidence);
  }

                                                                  
                                         
                                                                  

  static _MethodEstimate? _peakCountMethod(
    List<double> bandpassed,
    double fs,
    double minFreqHz,
    double maxFreqHz,
  ) {
    if (bandpassed.length < 8) return null;

    final double globalScale = _robustScale(bandpassed);
    if (globalScale <= 1e-9) return null;
    final int prominenceRadius = (fs / maxFreqHz * 0.35).round().clamp(
      1,
      bandpassed.length,
    );
    
                                                     
    final int rollingWindowSamples = (10.0 * fs).round();

                                                                              
    final peaks = <int>[];
    for (int i = 1; i < bandpassed.length - 1; i++) {
      if (bandpassed[i] > bandpassed[i - 1] &&
          bandpassed[i] > bandpassed[i + 1]) {
                                                       
        final int winStart = math.max(0, i - rollingWindowSamples);
        double localMax = bandpassed[i];
        double localMin = bandpassed[i];
        for (int j = winStart; j <= i; j++) {
           if (bandpassed[j] > localMax) localMax = bandpassed[j];
           if (bandpassed[j] < localMin) localMin = bandpassed[j];
        }
        
        final double localP2p = localMax - localMin;
        final double adaptiveFloor = math.max(globalScale * 0.10, localP2p * 0.15);

        if (bandpassed[i] > adaptiveFloor * 0.5 &&
            _localProminence(bandpassed, i, prominenceRadius) >
                adaptiveFloor * 0.75) {
          peaks.add(i);
        }
      }
    }

    if (peaks.length < 2) return null;

                                                       
    final int minDist = (fs / maxFreqHz * 0.7).round().clamp(
      1,
      bandpassed.length,
    );
    final filteredPeaks = <int>[peaks.first];
    for (int i = 1; i < peaks.length; i++) {
      if (peaks[i] - filteredPeaks.last >= minDist) {
        filteredPeaks.add(peaks[i]);
      } else if (bandpassed[peaks[i]] > bandpassed[filteredPeaks.last]) {
        filteredPeaks[filteredPeaks.length - 1] = peaks[i];
      }
    }

    if (filteredPeaks.length < 2) return null;

                                   
    final intervals = <double>[];
    for (int i = 1; i < filteredPeaks.length; i++) {
      intervals.add((filteredPeaks[i] - filteredPeaks[i - 1]) / fs);
    }

                                  
    final sortedIntervals = List<double>.from(intervals)..sort();
    final double medianInterval = sortedIntervals[sortedIntervals.length ~/ 2];

    if (medianInterval <= 0) return null;

    final double freqHz = 1.0 / medianInterval;
    if (freqHz < minFreqHz || freqHz > maxFreqHz) return null;

                                                                         
    final double meanInt = intervals.reduce((a, b) => a + b) / intervals.length;
    double sumSq = 0;
    for (final v in intervals) {
      sumSq += (v - meanInt) * (v - meanInt);
    }
    final double cv =
        meanInt > 0 ? math.sqrt(sumSq / intervals.length) / meanInt : 1.0;
    final double consistency = (1.0 - cv * 2.0).clamp(0.0, 1.0);
    final double cycleSupport = (intervals.length / 4.0).clamp(0.0, 1.0);
    final double confidence = (consistency *
            cycleSupport *
            _edgePenalty(freqHz, minFreqHz, maxFreqHz))
        .clamp(0.0, 1.0);

    if (confidence < 0.03) return null;

    return _MethodEstimate('Peak Counting', freqHz, confidence);
  }

                                                                  
                              
                                                                  

  static _MethodEstimate? _autocovarianceMethod(
    List<double> bandpassed,
    double fs,
    double minFreqHz,
    double maxFreqHz,
  ) {
    final int n = bandpassed.length;
    if (n < 16) return null;

                   
    double mean = 0;
    for (final v in bandpassed) {
      mean += v;
    }
    mean /= n;

                                                                 
    final int minLag = (fs / maxFreqHz).floor().clamp(1, n - 1);
    final int maxLag = (fs / minFreqHz).ceil().clamp(minLag + 1, n ~/ 2);

    final acovs = <int, double>{};
    double bestAcov = -double.infinity;
    int bestLag = -1;

    for (int lag = minLag; lag <= maxLag; lag++) {
      double acov = 0;
      for (int i = 0; i < n - lag; i++) {
        acov += (bandpassed[i] - mean) * (bandpassed[i + lag] - mean);
      }
      acov /= (n - lag);
      acovs[lag] = acov;
      if (acov > bestAcov) {
        bestAcov = acov;
        bestLag = lag;
      }
    }

    if (bestLag <= 0) return null;

                                               
    double refinedLag = bestLag.toDouble();
    if (bestLag > minLag && bestLag < maxLag) {
      double acovPrev = 0, acovNext = 0;
      for (int i = 0; i < n - (bestLag - 1); i++) {
        acovPrev +=
            (bandpassed[i] - mean) * (bandpassed[i + bestLag - 1] - mean);
      }
      acovPrev /= (n - bestLag + 1);

      for (int i = 0; i < n - (bestLag + 1); i++) {
        acovNext +=
            (bandpassed[i] - mean) * (bandpassed[i + bestLag + 1] - mean);
      }
      acovNext /= (n - bestLag - 1);

      final double denom = acovPrev - 2.0 * bestAcov + acovNext;
      if (denom.abs() > 1e-15) {
        final double p = 0.5 * (acovPrev - acovNext) / denom;
        refinedLag = bestLag + p;
      }
    }

    final double freqHz = fs / refinedLag;
    if (freqHz < minFreqHz || freqHz > maxFreqHz) return null;

                                                           
    double variance = 0;
    for (final v in bandpassed) {
      variance += (v - mean) * (v - mean);
    }
    variance /= n;
                                                                  
                                                           
    final prevAcov = acovs[bestLag - 1];
    final nextAcov = acovs[bestLag + 1];
    final localPeakPenalty =
        prevAcov != null &&
                nextAcov != null &&
                bestAcov >= prevAcov &&
                bestAcov >= nextAcov
            ? 1.0
            : 0.65;
    final double confidence =
        (variance > 0 ? (bestAcov / variance * 1.5).clamp(0.0, 1.0) : 0.0) *
        localPeakPenalty *
        _edgePenalty(freqHz, minFreqHz, maxFreqHz);

    if (confidence < 0.03) return null;

    return _MethodEstimate('Autocovariance', freqHz, confidence);
  }

  static _MethodEstimate? _zeroCrossingMethod(
    List<double> bandpassed,
    double fs,
    double minFreqHz,
    double maxFreqHz,
  ) {
    if (bandpassed.length < 8) return null;
    if (_robustScale(bandpassed) <= 1e-9) return null;

    final crossings = <double>[];
    for (int i = 1; i < bandpassed.length; i++) {
      final prev = bandpassed[i - 1];
      final curr = bandpassed[i];
      if (prev <= 0 && curr > 0) {
        final denom = curr - prev;
        final frac = denom.abs() > 1e-12 ? -prev / denom : 0.0;
        crossings.add((i - 1 + frac.clamp(0.0, 1.0)) / fs);
      }
    }

    if (crossings.length < 3) return null;

    final intervals = <double>[];
    for (int i = 1; i < crossings.length; i++) {
      final interval = crossings[i] - crossings[i - 1];
      if (interval > 0) intervals.add(interval);
    }
    if (intervals.length < 2) return null;

    final sortedIntervals = List<double>.from(intervals)..sort();
    final medianInterval = sortedIntervals[sortedIntervals.length ~/ 2];
    if (medianInterval <= 0) return null;

    final freqHz = 1.0 / medianInterval;
    if (freqHz < minFreqHz || freqHz > maxFreqHz) return null;

    final meanInt = intervals.reduce((a, b) => a + b) / intervals.length;
    double sumSq = 0;
    for (final interval in intervals) {
      sumSq += (interval - meanInt) * (interval - meanInt);
    }
    final cv =
        meanInt > 0 ? math.sqrt(sumSq / intervals.length) / meanInt : 1.0;
    final consistency = (1.0 - cv * 2.0).clamp(0.0, 1.0);
    final cycleSupport = (intervals.length / 4.0).clamp(0.0, 1.0);
    final confidence = (consistency *
            cycleSupport *
            _edgePenalty(freqHz, minFreqHz, maxFreqHz))
        .clamp(0.0, 1.0);

    if (confidence < 0.03) return null;

    return _MethodEstimate('Zero Crossing', freqHz, confidence);
  }

  static double _durationConfidence(double durationSec) {
    if (durationSec < 15) return 0.0;
    if (durationSec < 30) return 0.35 + (durationSec - 15) / 15 * 0.20;
    if (durationSec < 60) return 0.55 + (durationSec - 30) / 30 * 0.25;
    if (durationSec < 120) return 0.80 + (durationSec - 60) / 60 * 0.15;
    return 1.0;
  }

  static double _cycleConfidence(double estimatedCycles) {
    if (estimatedCycles < 1) return 0.0;
    if (estimatedCycles < 4) return 0.25 + (estimatedCycles - 1) / 3 * 0.45;
    if (estimatedCycles < 6) return 0.70 + (estimatedCycles - 4) / 2 * 0.20;
    return 1.0;
  }

  static double _artifactConfidence(int corrected, int total) {
    if (total <= 0) return 0.0;
    final ratio = corrected / total;
    if (ratio <= 0.03) return 1.0;
    if (ratio <= 0.10) return 1.0 - (ratio - 0.03) / 0.07 * 0.25;
    if (ratio <= 0.25) return 0.75 - (ratio - 0.10) / 0.15 * 0.35;
    return 0.25;
  }

                                                                  
                                    
                                                                  

                                                                 
     
                                                                     
                                                                     
                                                               
                     
  static (List<double>, int) _malikArtifactCorrect(List<double> rrIntervalsMs) {
    final corrected = List<double>.from(rrIntervalsMs);
    final int n = corrected.length;
    int count = 0;

                                         
    final globalSorted = List<double>.from(corrected)..sort();
    final double globalMedian = globalSorted[globalSorted.length ~/ 2];
    for (int i = 0; i < n; i++) {
      if (corrected[i] < 250 || corrected[i] > 2500) {
        corrected[i] = globalMedian;
        count++;
      }
    }

                                                              
                                                                  
                                                            
                                                               
                                                               
                                                               
                                           
    const double threshold = 0.25;
    const int halfWin = 3;                 
    for (int i = 0; i < n; i++) {
      final int start = (i - halfWin).clamp(0, n - 1);
      final int end = (i + halfWin).clamp(0, n - 1);

                                                      
      final neighbors = <double>[];
      for (int j = start; j <= end; j++) {
        if (j != i) neighbors.add(corrected[j]);
      }
      if (neighbors.isEmpty) continue;
      neighbors.sort();
      final double localMedian = neighbors[neighbors.length ~/ 2];

      if (localMedian > 0) {
        final double deviation =
            (corrected[i] - localMedian).abs() / localMedian;
        if (deviation > threshold) {
          corrected[i] = localMedian;
          count++;
        }
      }
    }

    return (corrected, count);
  }

                                                                  
                   
                                                                  

                                                           
  static List<double> _linearDetrend(List<double> signal) {
    final int n = signal.length;
    if (n < 2) return List<double>.from(signal);

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += signal[i];
      sumXY += i * signal[i];
      sumX2 += i * i;
    }
    final double denom = n * sumX2 - sumX * sumX;
    if (denom.abs() < 1e-15) {
      final double mean = sumY / n;
      return signal.map((v) => v - mean).toList();
    }
    final double slope = (n * sumXY - sumX * sumY) / denom;
    final double intercept = (sumY - slope * sumX) / n;

    return List<double>.generate(n, (i) => signal[i] - (intercept + slope * i));
  }

                                
  static List<double> _fftBandpass(
    List<double> signal,
    double samplingRate,
    double lowcut,
    double highcut,
  ) {
    final int n = signal.length;
    final int nfft = nextPowerOfTwo(n);

    final re = List<double>.filled(nfft, 0.0);
    final im = List<double>.filled(nfft, 0.0);
    for (int i = 0; i < n; i++) {
      re[i] = signal[i];
    }

    fftInPlace(re, im);

                                                          
                                                 
    final double rolloffWidth = (highcut - lowcut) * 0.15;
    for (int k = 0; k < nfft; k++) {
      final double freq;
      if (k <= nfft ~/ 2) {
        freq = k * samplingRate / nfft;
      } else {
        freq = (nfft - k) * samplingRate / nfft;
      }
      double gain;
      if (freq < lowcut - rolloffWidth || freq > highcut + rolloffWidth) {
        gain = 0.0;
      } else if (freq < lowcut) {
        gain = 0.5 * (1.0 + math.cos(math.pi * (lowcut - freq) / rolloffWidth));
      } else if (freq > highcut) {
        gain =
            0.5 * (1.0 + math.cos(math.pi * (freq - highcut) / rolloffWidth));
      } else {
        gain = 1.0;
      }
      re[k] *= gain;
      im[k] *= gain;
    }

                  
    for (int i = 0; i < nfft; i++) {
      im[i] = -im[i];
    }
    fftInPlace(re, im);
    for (int i = 0; i < nfft; i++) {
      re[i] /= nfft;
    }

    return re.sublist(0, n);
  }
}
