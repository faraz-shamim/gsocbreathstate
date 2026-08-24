// SPDX-License-Identifier: AGPL-3.0-only
                                                                
                                                    
   
                                                                  
                                 
   
                                                            
                                                               
                                                                
                                                             
                                                      
                                                                
                                                                    
                                             
   
                                                       
                                                                   
                                                            
                                                                   
                                                
   
              
                                                                 
                                                                     
             
library;

import 'dart:math' as math;

import 'signal_processing.dart';
import 'hrv_derived_breathing_rate.dart';

                                                                      
                    
                                                                      

                                                            
                    
class ResonanceTrialData {
                                                     
                                                
  final double targetBreathingRateBpm;

                                                              
  final List<double> rrIntervalsMs;

                                                     
  final int trialDurationSec;

  const ResonanceTrialData({
    required this.targetBreathingRateBpm,
    required this.rrIntervalsMs,
    this.trialDurationSec = 90,
  });
}

                                                                      
                    
                                                                      

                                                       
class ResonanceTrialResult {
                                                 
  final double targetBreathingRateBpm;

                                                 
  final double targetFrequencyHz;

                                                                

                                                   
  final double rmssd;

                                                                  
  final double lfPeakFrequencyHz;

                                        
  final double lfPeakPower;

                                                                 
                                               
  final double rsaBandPower;

                                                         
  final double totalLfPower;

                                                    
                                                             
                                                               
                                         
  final double coherenceRatio;

                                                              
                                                         
                                  
  final double? actualBreathingRateBpm;

                                                         
  final double? actualBreathingConfidence;

                                                               
                                                  
                                                   
  final double? breathingRateDeviationBpm;

                                                                

                                                       
  final double rmssdScore;

                                                               
                                                               
                
  final double peakAlignmentScore;

                                                               
  final double rsaAmplitudeScore;

                                                                

                                     
                                                             
  final double compositeScore;

                                       
  final int rank;

  const ResonanceTrialResult({
    required this.targetBreathingRateBpm,
    required this.targetFrequencyHz,
    required this.rmssd,
    required this.lfPeakFrequencyHz,
    required this.lfPeakPower,
    required this.rsaBandPower,
    required this.totalLfPower,
    required this.coherenceRatio,
    this.actualBreathingRateBpm,
    this.actualBreathingConfidence,
    this.breathingRateDeviationBpm,
    required this.rmssdScore,
    required this.peakAlignmentScore,
    required this.rsaAmplitudeScore,
    required this.compositeScore,
    this.rank = 0,
  });
}

                                                                      
                  
                                                                      

                                                              
class ResonanceFrequencyResult {
                                                                   
  final double optimalBreathingRateBpm;

                                       
  final double optimalFrequencyHz;

                                             
     
                                               
                                                                   
                                            
  final double confidence;

                                                                 
                         
  final List<ResonanceTrialResult> trials;

                                                                
                                                       
  final double rmssdOnlyOptimalBpm;

                                                                     
  final bool compositeAgreesWithRmssd;

                                                 
  final double optimalCompositeScore;

                                      
  final double optimalRmssd;

                                           
  final double optimalCoherence;

                                       
  final String? warning;

  const ResonanceFrequencyResult({
    required this.optimalBreathingRateBpm,
    required this.optimalFrequencyHz,
    required this.confidence,
    required this.trials,
    required this.rmssdOnlyOptimalBpm,
    required this.compositeAgreesWithRmssd,
    required this.optimalCompositeScore,
    required this.optimalRmssd,
    required this.optimalCoherence,
    this.warning,
  });

                                                                

                                                          
  Map<String, String> essentials() {
    return {
      'Optimal Rate': '${optimalBreathingRateBpm.toStringAsFixed(1)} BPM',
      'Composite Score':
          '${(optimalCompositeScore * 100).toStringAsFixed(0)}/100',
      'Confidence': '${(confidence * 100).toStringAsFixed(0)}%',
      'RMSSD': '${optimalRmssd.toStringAsFixed(1)} ms',
    };
  }

                                            
  Map<String, List<({String label, double? value, String unit})>>
      allMetrics() {
    final best = trials.isNotEmpty ? trials.first : null;
    return {
      'Optimal Rate': [
        (
          label: 'Breathing Rate',
          value: optimalBreathingRateBpm,
          unit: 'BPM'
        ),
        (
          label: 'Frequency',
          value: optimalFrequencyHz,
          unit: 'Hz'
        ),
        (
          label: 'Composite Score',
          value: optimalCompositeScore * 100,
          unit: '/100'
        ),
        (
          label: 'Confidence',
          value: confidence * 100,
          unit: '%'
        ),
      ],
      'Optimal Trial Metrics': [
        (label: 'RMSSD', value: best?.rmssd, unit: 'ms'),
        (
          label: 'LF Peak Freq',
          value: best?.lfPeakFrequencyHz,
          unit: 'Hz'
        ),
        (
          label: 'RSA Band Power',
          value: best?.rsaBandPower,
          unit: 'ms²'
        ),
        (
          label: 'Coherence',
          value: best != null ? best.coherenceRatio * 100 : null,
          unit: '%'
        ),
        (
          label: 'Actual Breath Rate',
          value: best?.actualBreathingRateBpm,
          unit: 'BPM'
        ),
      ],
      'Method Comparison': [
        (
          label: 'RMSSD-Only Choice',
          value: rmssdOnlyOptimalBpm,
          unit: 'BPM'
        ),
        (
          label: 'Composite Choice',
          value: optimalBreathingRateBpm,
          unit: 'BPM'
        ),
        (
          label: 'Methods Agree',
          value: compositeAgreesWithRmssd ? 1.0 : 0.0,
          unit: ''
        ),
      ],
    };
  }

                                                     
     
                                                                    
                                                    
  List<Map<String, dynamic>> trialComparisonData() {
    final sorted = List<ResonanceTrialResult>.from(trials)
      ..sort((a, b) => a.targetBreathingRateBpm
          .compareTo(b.targetBreathingRateBpm));

    return sorted.map((t) {
      return {
        'rateBpm': t.targetBreathingRateBpm,
        'compositeScore': t.compositeScore,
        'rmssd': t.rmssd,
        'rmssdScore': t.rmssdScore,
        'alignmentScore': t.peakAlignmentScore,
        'rsaScore': t.rsaAmplitudeScore,
        'coherence': t.coherenceRatio,
        'isOptimal':
            t.targetBreathingRateBpm == optimalBreathingRateBpm,
        'actualBpm': t.actualBreathingRateBpm,
      };
    }).toList();
  }

                              
  Map<String, double?> toExportMap() {
    final m = <String, double?>{
      'RF_Optimal_BPM': optimalBreathingRateBpm,
      'RF_Optimal_Hz': optimalFrequencyHz,
      'RF_Composite_Score': optimalCompositeScore,
      'RF_Confidence': confidence,
      'RF_Optimal_RMSSD': optimalRmssd,
      'RF_Optimal_Coherence': optimalCoherence,
      'RF_RMSSD_Only_BPM': rmssdOnlyOptimalBpm,
      'RF_Methods_Agree': compositeAgreesWithRmssd ? 1.0 : 0.0,
    };
    for (final t in trials) {
      final tag = t.targetBreathingRateBpm.toStringAsFixed(1);
      m['RF_${tag}BPM_Composite'] = t.compositeScore;
      m['RF_${tag}BPM_RMSSD'] = t.rmssd;
      m['RF_${tag}BPM_LFPeak'] = t.lfPeakFrequencyHz;
      m['RF_${tag}BPM_RSAPower'] = t.rsaBandPower;
      m['RF_${tag}BPM_Coherence'] = t.coherenceRatio;
    }
    return m;
  }
}

                                                                      
            
                                                                      

                                                                    
                                                   
   
           
                    
                                                                          
                                                                           
                                                                          
                                                                           
                                                                          
      
                                                              
                                                            
                                                                          
       
class ResonanceFrequencyAnalyzer {
  ResonanceFrequencyAnalyzer._();

                                                                
                                              
  static const double weightRmssd = 0.35;

                                                          
  static const double weightAlignment = 0.35;

                                                       
  static const double weightRsa = 0.30;

                                                                
                                                  
  static const double _interpolationRate = 4.0;

                              
  static const double _lfLow = 0.04;
  static const double _lfHigh = 0.15;

                                                               
                                               
                                         
  static const double _rsaBandHalfWidth = 0.02;

                                                                  
                                                                 
                                                            
  static const double _alignmentSigma = 0.015;

                                                                  
  static const int _minIntervalsPerTrial = 20;

                                                                

                                                                  
                             
     
                                                             
                                  
                                                                  
                                                                   
  static ResonanceFrequencyResult analyze(
    List<ResonanceTrialData> trials, {
    bool verifyActualRate = true,
  }) {
    if (trials.length < 2) {
      throw ArgumentError(
          'Need ≥ 2 trials for resonance frequency detection '
          '(got ${trials.length})');
    }

    final warnings = <String>[];

                                                                
                                                   
                                                                
    final rawResults = <_RawTrialMetrics>[];

    for (final trial in trials) {
      if (trial.rrIntervalsMs.length < _minIntervalsPerTrial) {
        warnings.add(
            '${trial.targetBreathingRateBpm} BPM trial: only '
            '${trial.rrIntervalsMs.length} intervals '
            '(need ≥ $_minIntervalsPerTrial). Skipped.');
        continue;
      }

      final raw = _computeRawMetrics(
        trial,
        verifyActualRate: verifyActualRate,
      );
      rawResults.add(raw);

                                                             
      if (raw.actualBreathingRateBpm != null &&
          raw.breathingRateDeviation != null &&
          raw.breathingRateDeviation! > 1.5) {
        warnings.add(
            '${trial.targetBreathingRateBpm} BPM trial: actual '
            'rate was ${raw.actualBreathingRateBpm!.toStringAsFixed(1)} BPM '
            '(deviation > 1.5 BPM).');
      }
    }

    if (rawResults.length < 2) {
      throw StateError(
          'Fewer than 2 valid trials after filtering. '
          'Cannot determine resonance frequency.');
    }

                                                                
                                                   
                                                                
    final double maxRmssd =
        rawResults.map((r) => r.rmssd).reduce(math.max);
    final double maxRsaPower =
        rawResults.map((r) => r.rsaBandPower).reduce(math.max);

    final scoredTrials = <ResonanceTrialResult>[];

    for (final raw in rawResults) {
                                         
      final double rmssdScore =
          maxRmssd > 0 ? raw.rmssd / maxRmssd : 0.0;

                                              
      final double deviation =
          (raw.lfPeakFrequencyHz - raw.targetFrequencyHz).abs();
      final double peakAlignmentScore = math.exp(
          -(deviation * deviation) /
              (2.0 * _alignmentSigma * _alignmentSigma));

                                                 
      final double rsaAmplitudeScore =
          maxRsaPower > 0 ? raw.rsaBandPower / maxRsaPower : 0.0;

                  
      final double compositeScore = weightRmssd * rmssdScore +
          weightAlignment * peakAlignmentScore +
          weightRsa * rsaAmplitudeScore;

      scoredTrials.add(ResonanceTrialResult(
        targetBreathingRateBpm: raw.targetBreathingRateBpm,
        targetFrequencyHz: raw.targetFrequencyHz,
        rmssd: raw.rmssd,
        lfPeakFrequencyHz: raw.lfPeakFrequencyHz,
        lfPeakPower: raw.lfPeakPower,
        rsaBandPower: raw.rsaBandPower,
        totalLfPower: raw.totalLfPower,
        coherenceRatio: raw.coherenceRatio,
        actualBreathingRateBpm: raw.actualBreathingRateBpm,
        actualBreathingConfidence: raw.actualBreathingConfidence,
        breathingRateDeviationBpm: raw.breathingRateDeviation,
        rmssdScore: rmssdScore,
        peakAlignmentScore: peakAlignmentScore,
        rsaAmplitudeScore: rsaAmplitudeScore,
        compositeScore: compositeScore,
      ));
    }

                                                                
                                          
                                                                

                                         
    scoredTrials.sort(
        (a, b) => b.compositeScore.compareTo(a.compositeScore));

                   
    final rankedTrials = <ResonanceTrialResult>[];
    for (int i = 0; i < scoredTrials.length; i++) {
      final t = scoredTrials[i];
      rankedTrials.add(ResonanceTrialResult(
        targetBreathingRateBpm: t.targetBreathingRateBpm,
        targetFrequencyHz: t.targetFrequencyHz,
        rmssd: t.rmssd,
        lfPeakFrequencyHz: t.lfPeakFrequencyHz,
        lfPeakPower: t.lfPeakPower,
        rsaBandPower: t.rsaBandPower,
        totalLfPower: t.totalLfPower,
        coherenceRatio: t.coherenceRatio,
        actualBreathingRateBpm: t.actualBreathingRateBpm,
        actualBreathingConfidence: t.actualBreathingConfidence,
        breathingRateDeviationBpm: t.breathingRateDeviationBpm,
        rmssdScore: t.rmssdScore,
        peakAlignmentScore: t.peakAlignmentScore,
        rsaAmplitudeScore: t.rsaAmplitudeScore,
        compositeScore: t.compositeScore,
        rank: i + 1,
      ));
    }

    final best = rankedTrials.first;

                       
    final double secondBestScore = rankedTrials.length >= 2
        ? rankedTrials[1].compositeScore
        : 0.0;

    double confidence = 0.0;
    if (best.compositeScore > 0) {
                                                
      final double separation =
          (best.compositeScore - secondBestScore) /
              best.compositeScore;
                                                    
      final double qualityFactor =
          math.min(1.0, best.compositeScore / 0.5);
      confidence = (separation * qualityFactor).clamp(0.0, 1.0);
    }

                                  
    final rmssdBest = List<ResonanceTrialResult>.from(rankedTrials)
      ..sort((a, b) => b.rmssd.compareTo(a.rmssd));
    final double rmssdOnlyBpm =
        rmssdBest.first.targetBreathingRateBpm;
    final bool agrees =
        (rmssdOnlyBpm - best.targetBreathingRateBpm).abs() < 0.01;

    if (!agrees) {
      warnings.add(
          'Composite method selected '
          '${best.targetBreathingRateBpm} BPM, but RMSSD-only '
          'would have selected $rmssdOnlyBpm BPM. The composite '
          'method accounts for spectral alignment and RSA '
          'amplitude in addition to RMSSD.');
    }

    return ResonanceFrequencyResult(
      optimalBreathingRateBpm: best.targetBreathingRateBpm,
      optimalFrequencyHz: best.targetFrequencyHz,
      confidence: confidence,
      trials: rankedTrials,
      rmssdOnlyOptimalBpm: rmssdOnlyBpm,
      compositeAgreesWithRmssd: agrees,
      optimalCompositeScore: best.compositeScore,
      optimalRmssd: best.rmssd,
      optimalCoherence: best.coherenceRatio,
      warning: warnings.isEmpty ? null : warnings.join('\n'),
    );
  }
}

                                                                      
                                              
                                                                      

class _RawTrialMetrics {
  final double targetBreathingRateBpm;
  final double targetFrequencyHz;
  final double rmssd;
  final double lfPeakFrequencyHz;
  final double lfPeakPower;
  final double rsaBandPower;
  final double totalLfPower;
  final double coherenceRatio;
  final double? actualBreathingRateBpm;
  final double? actualBreathingConfidence;
  final double? breathingRateDeviation;

  const _RawTrialMetrics({
    required this.targetBreathingRateBpm,
    required this.targetFrequencyHz,
    required this.rmssd,
    required this.lfPeakFrequencyHz,
    required this.lfPeakPower,
    required this.rsaBandPower,
    required this.totalLfPower,
    required this.coherenceRatio,
    this.actualBreathingRateBpm,
    this.actualBreathingConfidence,
    this.breathingRateDeviation,
  });
}

                                               
_RawTrialMetrics _computeRawMetrics(
  ResonanceTrialData trial, {
  bool verifyActualRate = true,
}) {
  final rr = trial.rrIntervalsMs;
  final double targetHz = trial.targetBreathingRateBpm / 60.0;

                                                             
  final double rmssd = _computeRmssd(rr);

                                                             
  final timesS = List<double>.filled(rr.length, 0.0);
  double cumMs = 0;
  for (int i = 0; i < rr.length; i++) {
    timesS[i] = cumMs / 1000.0;
    cumMs += rr[i];
  }

  final fs = ResonanceFrequencyAnalyzer._interpolationRate;
  final (_, resampled) = cubicInterpolate(timesS, rr, fs);

                
  final double mean =
      resampled.reduce((a, b) => a + b) / resampled.length;
  final detrended = resampled.map((v) => v - mean).toList();

                                                             
  final (freqs, psd) =
      welchPSD(detrended, fs, nperseg: detrended.length);

                                                             
  double lfPeakFreq = targetHz;            
  double lfPeakPower = 0;
  double totalLfPower = 0;
  final lfFreqs = <double>[];
  final lfPsd = <double>[];

  for (int i = 0; i < freqs.length; i++) {
    if (freqs[i] >= ResonanceFrequencyAnalyzer._lfLow &&
        freqs[i] <= ResonanceFrequencyAnalyzer._lfHigh) {
      lfFreqs.add(freqs[i]);
      lfPsd.add(psd[i]);
      if (psd[i] > lfPeakPower) {
        lfPeakPower = psd[i];
        lfPeakFreq = freqs[i];
      }
    }
  }

  if (lfFreqs.length >= 2) {
    totalLfPower = trapz(lfFreqs, lfPsd);
  }

                                                             
  final double rsaLow =
      targetHz - ResonanceFrequencyAnalyzer._rsaBandHalfWidth;
  final double rsaHigh =
      targetHz + ResonanceFrequencyAnalyzer._rsaBandHalfWidth;

  final rsaFreqs = <double>[];
  final rsaPsd = <double>[];
  for (int i = 0; i < freqs.length; i++) {
    if (freqs[i] >= rsaLow && freqs[i] <= rsaHigh) {
      rsaFreqs.add(freqs[i]);
      rsaPsd.add(psd[i]);
    }
  }

  double rsaBandPower = 0;
  if (rsaFreqs.length >= 2) {
    rsaBandPower = trapz(rsaFreqs, rsaPsd);
  } else if (rsaPsd.isNotEmpty) {
    rsaBandPower = rsaPsd[0] * (rsaHigh - rsaLow);
  }

                                                             
  final double coherence =
      totalLfPower > 0 ? rsaBandPower / totalLfPower : 0.0;

                                                             
  double? actualBpm;
  double? actualConfidence;
  double? deviation;

  if (verifyActualRate && rr.length >= 20) {
                                                 
    final breathResult = HrvDerivedBreathingRate.estimate(
      rr,
      minFreqHz: (targetHz - 0.04).clamp(0.05, 0.45),
      maxFreqHz: (targetHz + 0.04).clamp(0.06, 0.50),
    );
    if (breathResult.breathingRateBpm > 0) {
      actualBpm = breathResult.breathingRateBpm;
      actualConfidence = breathResult.confidence;
      deviation =
          (actualBpm - trial.targetBreathingRateBpm).abs();
    }
  }

  return _RawTrialMetrics(
    targetBreathingRateBpm: trial.targetBreathingRateBpm,
    targetFrequencyHz: targetHz,
    rmssd: rmssd,
    lfPeakFrequencyHz: lfPeakFreq,
    lfPeakPower: lfPeakPower,
    rsaBandPower: rsaBandPower,
    totalLfPower: totalLfPower,
    coherenceRatio: coherence.clamp(0.0, 1.0),
    actualBreathingRateBpm: actualBpm,
    actualBreathingConfidence: actualConfidence,
    breathingRateDeviation: deviation,
  );
}

                                                                      
                     
                                                                      

                                                                
                                        
double _computeRmssd(List<double> rrIntervalsMs) {
  if (rrIntervalsMs.length < 2) return 0.0;
  double sumSq = 0;
  for (int i = 0; i < rrIntervalsMs.length - 1; i++) {
    final double diff =
        rrIntervalsMs[i + 1] - rrIntervalsMs[i];
    sumSq += diff * diff;
  }
  return math.sqrt(sumSq / (rrIntervalsMs.length - 1));
}