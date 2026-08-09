                                                              
                                           
   
                                                                  
                                                                     
   
                                                                       
                                                                
                                                                       
                                                                        
                                     
                                                                
                                                         
                                                                     
                                                           
   
               
                                                                
                                                              
                                                        
library;

import 'dart:math' as math;

import 'signal_processing.dart';
import 'respiratory_phase_detector.dart';
import 'hrv_derived_breathing_rate.dart';

                                                                      
                
                                                                      

                                        
class HrvRsaResult {
                                                                
                                                                 
                                                                
                                                                  
  final double? hrvDerivedBreathRateBpm;

                                                         
  final double? hrvBreathRateConfidence;

                                                            
                    
  final double? hrvBreathRatePeakHz;

                                                                     
  final HrvDerivedBreathingResult? hrvBreathingDetail;

                                                                
                                                                  
  final double? p2tMean;

                                        
  final double? p2tMeanLog;

                                                      
  final double? p2tSd;

                                                              
  final int p2tNoRsa;

                                                                
  final List<double> p2tValues;

                                                                
                                           
  final double? porgesBohrer;

                                                                
                                                               
  final double? gatesMean;

                                                            
  final double? gatesMeanLog;

                                                                  
  final double? gatesSd;

                                                                
                                                                
                                                       
  final int breathCycleCount;

                                                       
                                                   
  final double? respiratoryBreathRateBpm;

                                                          
  final String? warning;

  const HrvRsaResult({
    this.hrvDerivedBreathRateBpm,
    this.hrvBreathRateConfidence,
    this.hrvBreathRatePeakHz,
    this.hrvBreathingDetail,
    this.p2tMean,
    this.p2tMeanLog,
    this.p2tSd,
    this.p2tNoRsa = 0,
    this.p2tValues = const [],
    this.porgesBohrer,
    this.gatesMean,
    this.gatesMeanLog,
    this.gatesSd,
    this.breathCycleCount = 0,
    this.respiratoryBreathRateBpm,
    this.warning,
  });

                                                                 
                     
                                                                 

                                                            
     
                                                              
                                                    
  Map<String, String> essentials() {
    return {
      'Breath Rate (HRV)':
          hrvDerivedBreathRateBpm != null && hrvDerivedBreathRateBpm! > 0
              ? '${hrvDerivedBreathRateBpm!.toStringAsFixed(1)} BPM'
              : 'N/A',
      'RSA (P2T)':
          p2tMean != null ? '${p2tMean!.toStringAsFixed(1)} ms' : 'N/A',
      'Porges-Bohrer':
          porgesBohrer != null
              ? '${porgesBohrer!.toStringAsFixed(3)} ln(ms²)'
              : 'N/A',
      'Breath Cycles': breathCycleCount > 0 ? '$breathCycleCount' : '—',
    };
  }

                                                             
  Map<String, List<({String label, double? value, String unit})>> allMetrics() {
    return {
      'HRV-Derived Breathing': [
        (
          label: 'Breath Rate (HRV)',
          value: hrvDerivedBreathRateBpm,
          unit: 'BPM',
        ),
        (
          label: 'Confidence',
          value:
              hrvBreathRateConfidence != null
                  ? hrvBreathRateConfidence! * 100
                  : null,
          unit: '%',
        ),
        (label: 'Peak Frequency', value: hrvBreathRatePeakHz, unit: 'Hz'),
      ],
      if (respiratoryBreathRateBpm != null || breathCycleCount > 0)
        'Respiratory Signal': [
          (
            label: 'Signal Breath Rate',
            value: respiratoryBreathRateBpm,
            unit: 'BPM',
          ),
          (
            label: 'Breath Cycles Detected',
            value: breathCycleCount.toDouble(),
            unit: '',
          ),
          (
            label: 'Valid P2T Cycles',
            value: p2tValues.length.toDouble(),
            unit: '',
          ),
        ],
      'Peak-to-Trough': [
        (label: 'P2T Mean', value: p2tMean, unit: 'ms'),
        (label: 'P2T Mean (log)', value: p2tMeanLog, unit: 'ln(ms)'),
        (label: 'P2T SD', value: p2tSd, unit: 'ms'),
        (label: 'No-RSA Cycles', value: p2tNoRsa.toDouble(), unit: ''),
      ],
      'Porges-Bohrer': [
        (label: 'RSA Porges-Bohrer', value: porgesBohrer, unit: 'ln(ms²)'),
      ],
      'Gates (Spectral)': [
        (label: 'Gates Mean', value: gatesMean, unit: 'ln(ms²)'),
        (label: 'Gates Mean (log)', value: gatesMeanLog, unit: 'ln(ln(ms²))'),
        (label: 'Gates SD', value: gatesSd, unit: 'ln(ms²)'),
      ],
    };
  }

                                                              
  Map<String, double?> toNeuroKitMap() {
    return {
      'HRV_RSA_P2T_Mean': p2tMean,
      'HRV_RSA_P2T_Mean_log': p2tMeanLog,
      'HRV_RSA_P2T_SD': p2tSd,
      'HRV_RSA_P2T_NoRSA': p2tNoRsa.toDouble(),
      'HRV_RSA_PorgesBohrer': porgesBohrer,
      'HRV_RSA_Gates_Mean': gatesMean,
      'HRV_RSA_Gates_Mean_log': gatesMeanLog,
      'HRV_RSA_Gates_SD': gatesSd,
      'RSA_HRV_BreathRate_BPM': hrvDerivedBreathRateBpm,
      'RSA_HRV_BreathRate_Confidence': hrvBreathRateConfidence,
      'RSA_HRV_BreathRate_PeakHz': hrvBreathRatePeakHz,
      'RSA_Respiratory_BreathRate_BPM': respiratoryBreathRateBpm,
    };
  }
}

                                                                      
            
                                                                      

                                                
   
                                                         
           
                                                         
                                                              
                                                             
       
   
                                                 
           
                                          
                    
                                           
                                    
      
                                                           
                                                          
                                                             
       
class HrvRsaAnalyzer {
  HrvRsaAnalyzer._();

                              
     
                                                                    
                                                                     
                                                               
                                                                
                       
                                                                           
                                                         
                                                                 
                                                            
                                                                    
                                                               
                                                                    
                            
  static HrvRsaResult analyze(
    List<double> rrIntervalsMs, {
    List<double>? breathingAmplitudes,
    double breathingSamplingRateHz = 25.0,
    double p2tOffsetMs = 750.0,
    double pbDesiredRate = 2.0,
    double gatesDesiredRate = 4.0,
    double gatesWindowSec = 32.0,
    double breathMinFreqHz = HrvDerivedBreathingRate.guidedMinFreqHz,
    double breathMaxFreqHz = HrvDerivedBreathingRate.guidedMaxFreqHz,
  }) {
    if (rrIntervalsMs.length < 4) {
      return const HrvRsaResult(
        warning: 'Too few RR intervals (need ≥ 4) for RSA analysis.',
      );
    }

                                                                
    final rPeakTimesMs = _buildRPeakTimestamps(rrIntervalsMs);
    final double totalDurationMs = rPeakTimesMs.last;
    final double totalDurationSec = totalDurationMs / 1000.0;

    final warnings = <String>[];

                                                                
                                                        
                                                                
    final hrvBreathResult = HrvDerivedBreathingRate.estimate(
      rrIntervalsMs,
      minFreqHz: breathMinFreqHz,
      maxFreqHz: breathMaxFreqHz,
    );

    final double? hrvBreathRate =
        hrvBreathResult.breathingRateBpm > 0
            ? hrvBreathResult.breathingRateBpm
            : null;
    final double? hrvConfidence =
        hrvBreathRate != null ? hrvBreathResult.confidence : null;
    final double? hrvPeakHz =
        hrvBreathRate != null ? hrvBreathResult.peakFrequencyHz : null;

    if (hrvBreathResult.warning != null) {
      warnings.add('HRV breath rate: ${hrvBreathResult.warning}');
    }

                                                                
                                                                
                                                                
    RespiratoryPhaseResult? respPhases;
    if (breathingAmplitudes != null && breathingAmplitudes.length >= 4) {
      respPhases = RespiratoryPhaseDetector.detect(
        breathingAmplitudes,
        breathingSamplingRateHz,
      );
    }

                                                                
                                                             
                                                                
    double? p2tMean;
    double? p2tMeanLog;
    double? p2tSd;
    int p2tNoRsa = 0;
    List<double> p2tValues = [];
    int breathCycleCount = 0;
    double? respiratoryBreathRate;

    if (respPhases != null &&
        respPhases.inspirationOnsetTimesMs.length >= 2 &&
        respPhases.respiratoryPeakTimesMs.isNotEmpty) {
      final p2t = _computeP2T(rPeakTimesMs, respPhases, p2tOffsetMs);
      p2tMean = p2t.mean;
      p2tMeanLog = p2t.meanLog;
      p2tSd = p2t.sd;
      p2tNoRsa = p2t.noRsaCount;
      p2tValues = p2t.values;
      breathCycleCount = respPhases.breathCycleCount;
      respiratoryBreathRate = respPhases.estimatedBreathRateBpm;

      if (breathCycleCount < 3) {
        warnings.add(
          'Only $breathCycleCount breath cycle(s) detected — '
          'P2T results may be unreliable.',
        );
      }
    } else if (breathingAmplitudes == null) {
                                                             
                               
    } else {
      warnings.add(
        'Could not detect enough respiratory cycles — '
        'P2T skipped.',
      );
    }

                                                                
                        
                                                                
    double? porgesBohrer;
    if (totalDurationSec >= 30) {
      porgesBohrer = _computePorgesBohrer(
        rPeakTimesMs,
        rrIntervalsMs,
        pbDesiredRate,
      );
      if (porgesBohrer != null && porgesBohrer!.isNaN) {
        porgesBohrer = null;
        warnings.add('Porges-Bohrer: variance computation failed.');
      }
    } else {
      warnings.add('Recording < 30s — Porges-Bohrer skipped.');
    }

                                                                
                             
                                                                
    double? gatesMean;
    double? gatesMeanLog;
    double? gatesSd;
    if (totalDurationSec >= gatesWindowSec) {
      final gates = _computeGatesSimplified(
        rPeakTimesMs,
        rrIntervalsMs,
        gatesDesiredRate,
        gatesWindowSec,
      );
      gatesMean = gates.mean;
      gatesMeanLog = gates.meanLog;
      gatesSd = gates.sd;
    } else {
      warnings.add(
        'Recording < ${gatesWindowSec.toInt()}s — '
        'Gates method skipped.',
      );
    }

    return HrvRsaResult(
      hrvDerivedBreathRateBpm: hrvBreathRate,
      hrvBreathRateConfidence: hrvConfidence,
      hrvBreathRatePeakHz: hrvPeakHz,
      hrvBreathingDetail: hrvBreathResult,
      p2tMean: p2tMean,
      p2tMeanLog: p2tMeanLog,
      p2tSd: p2tSd,
      p2tNoRsa: p2tNoRsa,
      p2tValues: p2tValues,
      porgesBohrer: porgesBohrer,
      gatesMean: gatesMean,
      gatesMeanLog: gatesMeanLog,
      gatesSd: gatesSd,
      breathCycleCount: breathCycleCount,
      respiratoryBreathRateBpm: respiratoryBreathRate,
      warning: warnings.isEmpty ? null : warnings.join('\n'),
    );
  }
}

                                                                      
                   
                                                                      

class _P2TResult {
  final double? mean;
  final double? meanLog;
  final double? sd;
  final int noRsaCount;
  final List<double> values;
  const _P2TResult(
    this.mean,
    this.meanLog,
    this.sd,
    this.noRsaCount,
    this.values,
  );
}

_P2TResult _computeP2T(
  List<double> rPeakTimesMs,
  RespiratoryPhaseResult respPhases,
  double offsetMs,
) {
  final onsets = respPhases.inspirationOnsetTimesMs;
  final peaks = respPhases.respiratoryPeakTimesMs;

  if (onsets.length < 2) {
    return const _P2TResult(null, null, null, 0, []);
  }

  final rsaValues = <double>[];
  int noRsa = 0;

  for (int i = 0; i < onsets.length - 1; i++) {
    final double cycleInit = onsets[i];
    final double cycleEnd = onsets[i + 1] + offsetMs;

    double? rspPeak;
    for (final p in peaks) {
      if (p > cycleInit && p < onsets[i + 1]) {
        rspPeak = p;
        break;
      }
    }
    if (rspPeak == null) {
      noRsa++;
      continue;
    }

    final double rspPeakOffset = rspPeak + offsetMs;

    final inhRPeaks = <double>[];
    for (final t in rPeakTimesMs) {
      if (t >= cycleInit && t < rspPeakOffset) inhRPeaks.add(t);
    }

    final exhRPeaks = <double>[];
    for (final t in rPeakTimesMs) {
      if (t >= rspPeak && t < cycleEnd) exhRPeaks.add(t);
    }

    final inhRR = _consecutiveDiffs(inhRPeaks);
    final exhRR = _consecutiveDiffs(exhRPeaks);

    if (inhRR.isNotEmpty && exhRR.isNotEmpty) {
      final double maxExh = exhRR.reduce(math.max);
      final double minInh = inhRR.reduce(math.min);
      final double rsaValue = maxExh - minInh;

      if (rsaValue > 0) {
        rsaValues.add(rsaValue);
      } else {
        rsaValues.add(0.0);
      }
    } else {
      noRsa++;
    }
  }

  if (rsaValues.isEmpty) {
    return _P2TResult(null, null, null, noRsa, []);
  }

  final double mean = _nanMean(rsaValues);
  final double? meanLog = mean > 0 ? math.log(mean) : null;
  final double? sd = rsaValues.length >= 2 ? _nanStd(rsaValues) : null;

  return _P2TResult(mean, meanLog, sd, noRsa, List<double>.from(rsaValues));
}

                                                                      
                             
                                                                      

double? _computePorgesBohrer(
  List<double> rPeakTimesMs,
  List<double> rrIntervalsMs,
  double desiredRate,
) {
  if (rrIntervalsMs.length < 3) return null;
  final timesS =
      rPeakTimesMs
          .sublist(0, rrIntervalsMs.length)
          .map((t) => t / 1000.0)
          .toList();

  final (_, resampled) = cubicInterpolate(timesS, rrIntervalsMs, desiredRate);

  if (resampled.length < 22) return null;

  final trend = _savitzkyGolaySmooth(resampled, 21, 3);

  final zeroMean = List<double>.generate(
    resampled.length,
    (i) => resampled[i] - trend[i],
  );

  final filtered = _fftBandpass(zeroMean, desiredRate, 0.12, 0.40);

  final int epochSamples = (30 * desiredRate).round();
  final int nEpochs = filtered.length ~/ epochSamples;

  if (nEpochs < 1) return null;

  final logVariances = <double>[];
  for (int e = 0; e < nEpochs; e++) {
    final start = e * epochSamples;
    final end = start + epochSamples;
    final epoch = filtered.sublist(start, end);

    final double epochMean = epoch.reduce((a, b) => a + b) / epoch.length;
    double sumSq = 0;
    for (final v in epoch) {
      sumSq += (v - epochMean) * (v - epochMean);
    }
    final double variance = sumSq / (epoch.length - 1);

    if (variance > 0 && variance.isFinite) {
      logVariances.add(math.log(variance));
    }
  }

  if (logVariances.isEmpty) return null;

  return logVariances.reduce((a, b) => a + b) / logVariances.length;
}

                                                                      
                                  
                                                                      

class _GatesResult {
  final double? mean;
  final double? meanLog;
  final double? sd;
  const _GatesResult(this.mean, this.meanLog, this.sd);
}

_GatesResult _computeGatesSimplified(
  List<double> rPeakTimesMs,
  List<double> rrIntervalsMs,
  double desiredRate,
  double windowSec,
) {
  if (rrIntervalsMs.length < 3) {
    return const _GatesResult(null, null, null);
  }

  final timesS =
      rPeakTimesMs
          .sublist(0, rrIntervalsMs.length)
          .map((t) => t / 1000.0)
          .toList();

  final (_, resampled) = cubicInterpolate(timesS, rrIntervalsMs, desiredRate);

  final double mean = resampled.reduce((a, b) => a + b) / resampled.length;
  final detrended = resampled.map((v) => v - mean).toList();

  final int windowSamples = (windowSec * desiredRate).round();
  final int stepSamples = (1 * desiredRate).round();
  final int nWindows = (detrended.length - windowSamples) ~/ stepSamples + 1;

  if (nWindows < 1) return const _GatesResult(null, null, null);

  final logPowers = <double>[];

  for (int w = 0; w < nWindows; w++) {
    final start = w * stepSamples;
    final end = start + windowSamples;
    if (end > detrended.length) break;

    final segment = detrended.sublist(start, end);

    final (freqs, psd) = welchPSD(segment, desiredRate, nperseg: windowSamples);

    final bandFreqs = <double>[];
    final bandPsd = <double>[];
    for (int i = 0; i < freqs.length; i++) {
      if (freqs[i] >= 0.12 && freqs[i] <= 0.40) {
        bandFreqs.add(freqs[i]);
        bandPsd.add(psd[i]);
      }
    }

    if (bandFreqs.length >= 2) {
      final double power = trapz(bandFreqs, bandPsd);
      if (power > 0 && power.isFinite) {
        logPowers.add(math.log(power));
      }
    }
  }

  if (logPowers.isEmpty) {
    return const _GatesResult(null, null, null);
  }

  final double meanLnPower = _nanMean(logPowers);
  final double? meanLog = meanLnPower > 0 ? math.log(meanLnPower) : null;
  final double? sd = logPowers.length >= 2 ? _nanStd(logPowers) : null;

  return _GatesResult(meanLnPower, meanLog, sd);
}

                                                                      
                                        
                                                                      

void _ifftInPlace(List<double> re, List<double> im) {
  final int n = re.length;
  for (int i = 0; i < n; i++) {
    im[i] = -im[i];
  }
  fftInPlace(re, im);
  for (int i = 0; i < n; i++) {
    re[i] /= n;
    im[i] = -im[i] / n;
  }
}

List<double> _fftBandpass(
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

  for (int k = 0; k < nfft; k++) {
    final double freq;
    if (k <= nfft ~/ 2) {
      freq = k * samplingRate / nfft;
    } else {
      freq = (nfft - k) * samplingRate / nfft;
    }
    if (freq < lowcut || freq > highcut) {
      re[k] = 0.0;
      im[k] = 0.0;
    }
  }

  _ifftInPlace(re, im);

  return re.sublist(0, n);
}

List<double> _savitzkyGolaySmooth(
  List<double> signal,
  int windowSize,
  int polyOrder,
) {
  assert(windowSize.isOdd, 'SG window size must be odd');
  assert(windowSize >= polyOrder + 2, 'SG window too small for order');

  final int halfWin = windowSize ~/ 2;
  final coeffs = _sgCoefficients(windowSize, polyOrder);

  final padded = <double>[
    for (int i = halfWin; i >= 1; i--) signal[i],
    ...signal,
    for (int i = signal.length - 2; i >= signal.length - 1 - halfWin; i--)
      signal[i],
  ];

  final result = List<double>.filled(signal.length, 0.0);
  for (int i = 0; i < signal.length; i++) {
    double sum = 0;
    for (int j = 0; j < windowSize; j++) {
      sum += coeffs[j] * padded[i + j];
    }
    result[i] = sum;
  }
  return result;
}

List<double> _sgCoefficients(int windowSize, int polyOrder) {
  final int halfWin = windowSize ~/ 2;
  final int m = polyOrder + 1;

  final a = List.generate(
    windowSize,
    (i) => List.generate(m, (j) => math.pow(i - halfWin, j).toDouble()),
  );

  final ata = List.generate(
    m,
    (i) => List.generate(m, (j) {
      double s = 0;
      for (int k = 0; k < windowSize; k++) {
        s += a[k][i] * a[k][j];
      }
      return s;
    }),
  );

  final e0 = List<double>.filled(m, 0.0);
  e0[0] = 1.0;
  final c = _solveLinearSystem(ata, e0);

  final coeffs = List<double>.filled(windowSize, 0.0);
  for (int i = 0; i < windowSize; i++) {
    double s = 0;
    for (int j = 0; j < m; j++) {
      s += a[i][j] * c[j];
    }
    coeffs[i] = s;
  }
  return coeffs;
}

List<double> _solveLinearSystem(List<List<double>> a, List<double> b) {
  final int n = b.length;

  final aug = List.generate(n, (i) => [...a[i].map((v) => v), b[i]]);

  for (int col = 0; col < n; col++) {
    int maxRow = col;
    double maxVal = aug[col][col].abs();
    for (int row = col + 1; row < n; row++) {
      if (aug[row][col].abs() > maxVal) {
        maxVal = aug[row][col].abs();
        maxRow = row;
      }
    }
    if (maxRow != col) {
      final temp = aug[col];
      aug[col] = aug[maxRow];
      aug[maxRow] = temp;
    }

    final double pivot = aug[col][col];
    if (pivot.abs() < 1e-15) continue;

    for (int row = col + 1; row < n; row++) {
      final double factor = aug[row][col] / pivot;
      for (int j = col; j <= n; j++) {
        aug[row][j] -= factor * aug[col][j];
      }
    }
  }

  final x = List<double>.filled(n, 0.0);
  for (int i = n - 1; i >= 0; i--) {
    double s = aug[i][n];
    for (int j = i + 1; j < n; j++) {
      s -= aug[i][j] * x[j];
    }
    x[i] = aug[i][i].abs() > 1e-15 ? s / aug[i][i] : 0.0;
  }
  return x;
}

                                                                      
                             
                                                                      

List<double> _buildRPeakTimestamps(List<double> rrIntervalsMs) {
  final times = List<double>.filled(rrIntervalsMs.length + 1, 0.0);
  for (int i = 0; i < rrIntervalsMs.length; i++) {
    times[i + 1] = times[i] + rrIntervalsMs[i];
  }
  return times;
}

List<double> _consecutiveDiffs(List<double> values) {
  if (values.length < 2) return [];
  return List<double>.generate(
    values.length - 1,
    (i) => values[i + 1] - values[i],
  );
}

double _nanMean(List<double> values) {
  final valid = values.where((v) => v.isFinite).toList();
  if (valid.isEmpty) return 0.0;
  return valid.reduce((a, b) => a + b) / valid.length;
}

double _nanStd(List<double> values) {
  final valid = values.where((v) => v.isFinite).toList();
  if (valid.length < 2) return 0.0;
  final double m = valid.reduce((a, b) => a + b) / valid.length;
  double sumSq = 0;
  for (final v in valid) {
    sumSq += (v - m) * (v - m);
  }
  return math.sqrt(sumSq / (valid.length - 1));
}
