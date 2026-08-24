// SPDX-License-Identifier: AGPL-3.0-only
                                                                      
   
                                                              
                                                                      
                                             
                                                      
   
                                                                 
                                                  
   
               
                                                          
                                                            
library;

import 'dart:math' as math;
import 'ecg_rpeak_detector.dart';
import '../hrv_analysis/signal_processing.dart'
    show lombScarglePSD, pchipInterpolate, fftInPlace, nextPowerOfTwo;

                                                                      
                  
                                                                      

                                          
class ChannelEstimate {
  final String name;
  final double breathRateBpm;
  final double frequencyHz;
  final double confidence;       
  final double rqi;                                 

  const ChannelEstimate({
    required this.name,
    required this.breathRateBpm,
    required this.frequencyHz,
    required this.confidence,
    required this.rqi,
  });
}

                                                    
class EdrFusionResult {
                                         
  final double breathRateBpm;

                             
  final double confidence;

                                                                              
  final double? instantaneousBreathRateBpm;

                                                                                
  final double motionQuality;

                                                                     
  final double artifactRatio;

                            
  final List<ChannelEstimate> channels;

                                     
  final Map<String, double> channelWeights;

                               
  final double signalQuality;

                               
  final double heartRateBpm;

                 
  final String? warning;

  const EdrFusionResult({
    required this.breathRateBpm,
    required this.confidence,
    this.instantaneousBreathRateBpm,
    this.motionQuality = 1.0,
    this.artifactRatio = 0.0,
    required this.channels,
    required this.channelWeights,
    required this.signalQuality,
    required this.heartRateBpm,
    this.warning,
  });
}

                                                                      
                            
                                                                      

class _EdrBeat {
  final int sampleIndex;
  final double timeSec;
  final double amplitudeUv;
  final double? rrMs;
  final bool corrected;

  const _EdrBeat({
    required this.sampleIndex,
    required this.timeSec,
    required this.amplitudeUv,
    required this.rrMs,
    required this.corrected,
  });
}

class EdrMultiChannelEngine {
  EdrMultiChannelEngine._();

                                        
                                                                     
  static const double minRespFreqHz = 0.10;         
  static const double maxRespFreqHz = 0.50;          

                                    
  static const double resampleHz = 4.0;

                                                         
     
                                   
                                                                 
  static EdrFusionResult process(
    List<double> ecgSamples, {
    double ecgSampleRate = 130.0,
    double motionQuality = 1.0,
  }) {
                                                                
    final rpResult = EcgRPeakDetector.detect(
      ecgSamples,
      sampleRate: ecgSampleRate,
    );

    if (rpResult.peaks.length < 10) {
      return EdrFusionResult(
        breathRateBpm: 0,
        confidence: 0,
        channels: const [],
        channelWeights: const {},
        signalQuality: rpResult.signalQuality,
        heartRateBpm: 0,
        warning: 'Too few R-peaks detected (${rpResult.peaks.length})',
      );
    }

    final correctedBeats = _buildCorrectedBeats(rpResult.peaks, ecgSampleRate);
    if (correctedBeats.length < 8) {
      return EdrFusionResult(
        breathRateBpm: 0,
        confidence: 0,
        channels: const [],
        channelWeights: const {},
        signalQuality: rpResult.signalQuality,
        heartRateBpm: 0,
        warning: 'Too few usable beats (${correctedBeats.length})',
      );
    }

    final correctedCount = correctedBeats.where((b) => b.corrected).length;
    final artifactRatio =
        correctedBeats.isEmpty ? 0.0 : correctedCount / correctedBeats.length;

                                   
    final correctedRrs =
        correctedBeats
            .map((b) => b.rrMs)
            .whereType<double>()
            .where((rr) => rr.isFinite && rr > 0)
            .toList();
    final double meanRR =
        correctedRrs.isNotEmpty
            ? correctedRrs.reduce((a, b) => a + b) / correctedRrs.length
            : 800.0;
    final double heartRateBpm = 60000.0 / meanRR;

                                                                 
                                                                  
                                                
    final rrForQuality = correctedRrs;
    final rsaQualityOk = _checkRsaQuality(rrForQuality);

                                                                
    final channels = <ChannelEstimate>[];

                                                    
    final fm = _extractFmChannel(correctedBeats);
    if (fm != null) channels.add(fm);

                                                  
    final am = _extractAmChannel(correctedBeats);
    if (am != null) channels.add(am);

                                                             
    final qrs = _extractQrsEnergyChannel(
      correctedBeats,
      ecgSamples,
      ecgSampleRate,
    );
    if (qrs != null) channels.add(qrs);

    final bw = _extractBaselineWanderChannel(ecgSamples, ecgSampleRate);
    if (bw != null) channels.add(bw);

                                                            
                                                                         
                                                               
    final hilbert = _extractHilbertChannel(correctedBeats);
    if (hilbert != null) channels.add(hilbert);

    final fusedInstant = _extractFusedInstantRate(
      correctedBeats,
      ecgSamples,
      ecgSampleRate,
    );
    if (fusedInstant != null) channels.add(fusedInstant);

    if (channels.isEmpty) {
      return EdrFusionResult(
        breathRateBpm: 0,
        confidence: 0,
        channels: const [],
        channelWeights: const {},
        signalQuality: rpResult.signalQuality,
        heartRateBpm: heartRateBpm,
        warning:
            rsaQualityOk
                ? 'No channel produced a valid estimate'
                : 'RSA power too weak for reliable EDR',
      );
    }

                                                                
    final weights = _computeAdaptiveWeights(channels, heartRateBpm);

                                                         
    if (!rsaQualityOk) {
      for (final key in weights.keys.toList()) {
        weights[key] = (weights[key] ?? 0) * 0.6;
      }
    }

    final boundedMotionQuality = motionQuality.clamp(0.0, 1.0);
    if (boundedMotionQuality < 0.85) {
      for (final key in weights.keys.toList()) {
        final motionSensitive =
            key.contains('AM') ||
            key.contains('QRS') ||
            key.contains('Baseline') ||
            key.contains('Fused');
        final scale =
            motionSensitive
                ? (0.25 + 0.75 * boundedMotionQuality)
                : (0.55 + 0.45 * boundedMotionQuality);
        weights[key] = (weights[key] ?? 0) * scale;
      }
      _normalizeWeights(weights);
    }

    final consensusChannels = _selectConsensusChannels(channels, weights);
    final fusionChannels =
        consensusChannels.isEmpty ? channels : consensusChannels;

                                                                
    final sortedChannels = List<ChannelEstimate>.from(fusionChannels)
      ..sort((a, b) => a.frequencyHz.compareTo(b.frequencyHz));

    double weightSum = 0;
    for (final ch in sortedChannels) {
      weightSum += weights[ch.name] ?? 0;
    }

    double fusedFreqHz = fusionChannels.first.frequencyHz;
    if (weightSum > 0) {
      double cumulativeWeight = 0;
      for (final ch in sortedChannels) {
        cumulativeWeight += weights[ch.name] ?? 0;
        if (cumulativeWeight >= weightSum / 2.0) {
          fusedFreqHz = ch.frequencyHz;
          break;
        }
      }
    }

    double weightedConfSum = 0;
    for (final ch in fusionChannels) {
      weightedConfSum += ch.confidence * (weights[ch.name] ?? 0);
    }
    final fusedConf =
        weightSum > 0
            ? weightedConfSum / weightSum
            : fusionChannels.first.confidence;

                                    
    double agreementBonus = 0;
    if (fusionChannels.length >= 2) {
      final bpms = fusionChannels.map((c) => c.breathRateBpm).toList();
      final spread = bpms.reduce(math.max) - bpms.reduce(math.min);
      if (spread < 1.5) {
        agreementBonus = 0.15;
      } else if (spread < 3.0) {
        agreementBonus = 0.05;
      }
    }
    final isolationPenalty =
        fusionChannels.length == 1 && channels.length > 1 ? 0.85 : 1.0;

    String? warning;
    if (fusionChannels.length < channels.length) {
      final excluded = channels
          .where((c) => !fusionChannels.any((f) => f.name == c.name))
          .map((c) => c.name)
          .join(', ');
      warning = 'Excluded discordant channel(s): $excluded';
    }

    final artifactPenalty = (1.0 - artifactRatio * 0.7).clamp(0.35, 1.0);
    final motionPenalty = (0.35 + 0.65 * boundedMotionQuality).clamp(0.35, 1.0);
    final outputConfidence = ((fusedConf + agreementBonus) *
            isolationPenalty *
            artifactPenalty *
            motionPenalty)
        .clamp(0.0, 1.0);
    final instantBpm = fusedInstant?.breathRateBpm;

    return EdrFusionResult(
      breathRateBpm: fusedFreqHz * 60.0,
      confidence: outputConfidence,
      instantaneousBreathRateBpm: instantBpm,
      motionQuality: boundedMotionQuality,
      artifactRatio: artifactRatio,
      channels: channels,
      channelWeights: weights,
      signalQuality: rpResult.signalQuality,
      heartRateBpm: heartRateBpm,
      warning: warning,
    );
  }

                                                                  
  static List<_EdrBeat> _buildCorrectedBeats(
    List<DetectedRPeak> peaks,
    double ecgSampleRate,
  ) {
    if (peaks.length < 2) {
      return peaks
          .map(
            (p) => _EdrBeat(
              sampleIndex: p.sampleIndex,
              timeSec: p.timeSec,
              amplitudeUv: p.amplitudeUv,
              rrMs: null,
              corrected: p.isEctopic,
            ),
          )
          .toList();
    }

    final rawRrs = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      rawRrs.add(
        (peaks[i].sampleIndex - peaks[i - 1].sampleIndex) /
            ecgSampleRate *
            1000.0,
      );
    }

    final correctedRrs = <double>[];
    final rrCorrected = <bool>[];
    for (int i = 0; i < rawRrs.length; i++) {
      final rr = rawRrs[i];
      var replacement = rr;
      var corrected = rr < 300 || rr > 2000 || peaks[i + 1].isEctopic;

      final neighbors = <double>[];
      final start = math.max(0, i - 3);
      final end = math.min(rawRrs.length, i + 4);
      for (int j = start; j < end; j++) {
        if (j == i) continue;
        final candidate = rawRrs[j];
        if (candidate >= 300 && candidate <= 2000) neighbors.add(candidate);
      }

      if (neighbors.isNotEmpty) {
        final median = _median(neighbors);
        if (median > 0 && (rr - median).abs() / median > 0.20) {
          replacement = median;
          corrected = true;
        } else if (corrected) {
          replacement = median;
        }
      }

      correctedRrs.add(replacement.clamp(300.0, 2000.0));
      rrCorrected.add(corrected);
    }

    final beats = <_EdrBeat>[];
    beats.add(
      _EdrBeat(
        sampleIndex: peaks.first.sampleIndex,
        timeSec: peaks.first.timeSec,
        amplitudeUv: peaks.first.amplitudeUv,
        rrMs: null,
        corrected: peaks.first.isEctopic,
      ),
    );
    for (int i = 1; i < peaks.length; i++) {
      beats.add(
        _EdrBeat(
          sampleIndex: peaks[i].sampleIndex,
          timeSec: peaks[i].timeSec,
          amplitudeUv: peaks[i].amplitudeUv,
          rrMs: correctedRrs[i - 1],
          corrected: peaks[i].isEctopic || rrCorrected[i - 1],
        ),
      );
    }
    return beats;
  }

  static List<double> _interpolateCorrectedValues(
    List<double> values,
    List<bool> corrected,
  ) {
    final result = List<double>.from(values);
    for (int i = 0; i < result.length; i++) {
      if (!corrected[i] || !result[i].isFinite) continue;

      int? prev;
      for (int j = i - 1; j >= 0; j--) {
        if (!corrected[j] && result[j].isFinite) {
          prev = j;
          break;
        }
      }

      int? next;
      for (int j = i + 1; j < result.length; j++) {
        if (!corrected[j] && result[j].isFinite) {
          next = j;
          break;
        }
      }

      if (prev != null && next != null && next != prev) {
        final t = (i - prev) / (next - prev);
        result[i] = result[prev] + (result[next] - result[prev]) * t;
      } else if (prev != null) {
        result[i] = result[prev];
      } else if (next != null) {
        result[i] = result[next];
      }
    }
    return result;
  }

  static void _normalizeWeights(Map<String, double> weights) {
    final total = weights.values.fold(0.0, (s, v) => s + v);
    if (total <= 0) return;
    for (final key in weights.keys.toList()) {
      weights[key] = weights[key]! / total;
    }
  }

  static List<ChannelEstimate> _selectConsensusChannels(
    List<ChannelEstimate> channels,
    Map<String, double> weights,
  ) {
    if (channels.length <= 2) return List<ChannelEstimate>.from(channels);

                                                           
    const toleranceBpm = 2.0;
    var bestCluster = <ChannelEstimate>[];
    var bestWeight = -1.0;

    for (final center in channels) {
      final cluster =
          channels
              .where(
                (c) =>
                    (c.breathRateBpm - center.breathRateBpm).abs() <=
                    toleranceBpm,
              )
              .toList();
      final weight = cluster.fold<double>(
        0.0,
        (sum, c) => sum + (weights[c.name] ?? 0) * c.confidence,
      );
      if (weight > bestWeight ||
          (weight == bestWeight && cluster.length > bestCluster.length)) {
        bestWeight = weight;
        bestCluster = cluster;
      }
    }

    return bestCluster;
  }

                                          
                                                                  

  static ChannelEstimate? _extractFmChannel(List<_EdrBeat> beats) {
    if (beats.length < 8) return null;

    final times = beats.map((p) => p.timeSec).toList();
    final rrValues = <double>[];
    for (int i = 1; i < beats.length; i++) {
      final rr = beats[i].rrMs;
      if (rr != null && rr.isFinite && rr > 0) rrValues.add(rr);
    }
    final rrTimes = times.sublist(1);

    return _spectralEstimate('FM (RSA)', rrTimes, rrValues);
  }

                                                                  
                                                 
                                                                  

  static ChannelEstimate? _extractAmChannel(List<_EdrBeat> beats) {
    if (beats.length < 8) return null;

    final times = beats.map((p) => p.timeSec).toList();
    final amplitudes = _interpolateCorrectedValues(
      beats.map((p) => p.amplitudeUv).toList(),
      beats.map((p) => p.corrected).toList(),
    );

    return _spectralEstimate('AM (Amplitude)', times, amplitudes);
  }

                                                                  
                                                          
                                                                  

  static ChannelEstimate? _extractQrsEnergyChannel(
    List<_EdrBeat> beats,
    List<double> ecgSamples,
    double ecgSampleRate,
  ) {
    if (beats.length < 8) return null;

    final times = <double>[];
    final features = <double>[];

                                                                
    final int halfWin = (0.030 * ecgSampleRate).round().clamp(1, 10);
    for (final peak in beats) {
      final int lo = (peak.sampleIndex - halfWin).clamp(
        0,
        ecgSamples.length - 1,
      );
      final int hi = (peak.sampleIndex + halfWin).clamp(
        0,
        ecgSamples.length - 1,
      );

      double area = 0;
      for (int i = lo; i <= hi; i++) {
        area += ecgSamples[i].abs();
      }

      times.add(peak.timeSec);
      features.add(area);
    }

    return _spectralEstimate(
      'QRS Energy',
      times,
      _interpolateCorrectedValues(
        features,
        beats.map((b) => b.corrected).toList(),
      ),
    );
  }

                                                                  
                                                            
                                                                  

  static ChannelEstimate? _extractBaselineWanderChannel(
    List<double> ecgSamples,
    double ecgSampleRate,
  ) {
    if (ecgSamples.length < (15 * ecgSampleRate).round()) return null;

    final detrended = _linearDetrendWithTimes(
      List<double>.generate(ecgSamples.length, (i) => i / ecgSampleRate),
      ecgSamples,
    );
    final baseline = _fftBandpass(detrended, ecgSampleRate, 0.05, 0.50);
    if (baseline.length < 16) return null;

    final step = math.max(1, (ecgSampleRate / resampleHz).round());
    final times = <double>[];
    final values = <double>[];
    for (int i = 0; i < baseline.length; i += step) {
      times.add(i / ecgSampleRate);
      values.add(baseline[i]);
    }

    return _spectralEstimate('Baseline Wander', times, values);
  }

  static ChannelEstimate? _extractFusedInstantRate(
    List<_EdrBeat> beats,
    List<double> ecgSamples,
    double ecgSampleRate,
  ) {
    if (beats.length < 12) return null;

    final series = <({List<double> times, List<double> values})>[];

    final rrTimes = <double>[];
    final rrValues = <double>[];
    for (int i = 1; i < beats.length; i++) {
      final rr = beats[i].rrMs;
      if (rr != null && rr.isFinite && rr > 0) {
        rrTimes.add(beats[i].timeSec);
        rrValues.add(rr);
      }
    }
    if (rrTimes.length >= 8) {
      series.add((times: rrTimes, values: rrValues));
    }

    final beatTimes = beats.map((b) => b.timeSec).toList();
    final correctedFlags = beats.map((b) => b.corrected).toList();
    series.add((
      times: beatTimes,
      values: _interpolateCorrectedValues(
        beats.map((b) => b.amplitudeUv).toList(),
        correctedFlags,
      ),
    ));

    final qrsValues = <double>[];
    final halfWin = (0.030 * ecgSampleRate).round().clamp(1, 10);
    for (final beat in beats) {
      final lo = (beat.sampleIndex - halfWin).clamp(0, ecgSamples.length - 1);
      final hi = (beat.sampleIndex + halfWin).clamp(0, ecgSamples.length - 1);
      var area = 0.0;
      for (int i = lo; i <= hi; i++) {
        area += ecgSamples[i].abs();
      }
      qrsValues.add(area);
    }
    series.add((
      times: beatTimes,
      values: _interpolateCorrectedValues(qrsValues, correctedFlags),
    ));

    final baselineSeries = _baselineWanderSeries(ecgSamples, ecgSampleRate);
    if (baselineSeries != null) series.add(baselineSeries);

    final prepared =
        series
            .map((s) => _prepareChannelSeries(s.times, s.values))
            .where((s) => s.times.length >= 8)
            .toList();
    if (prepared.length < 2) return null;

    final start = prepared.map((s) => s.times.first).reduce(math.max);
    final end = prepared.map((s) => s.times.last).reduce(math.min);
    if (end - start < 15.0) return null;

    final n = ((end - start) * resampleHz).floor() + 1;
    if (n < 32) return null;
    final fused = List<double>.filled(n, 0.0);
    var used = 0;

    for (final s in prepared) {
      final values = <double>[];
      for (int i = 0; i < n; i++) {
        values.add(
          _linearInterpolateAt(s.times, s.values, start + i / resampleHz),
        );
      }
      final detrended = _linearDetrendWithTimes(
        List<double>.generate(n, (i) => start + i / resampleHz),
        values,
      );
      final scale = _robustScale(detrended);
      if (scale <= 1e-9) continue;
      for (int i = 0; i < n; i++) {
        fused[i] += detrended[i] / scale;
      }
      used++;
    }

    if (used < 2) return null;
    for (int i = 0; i < fused.length; i++) {
      fused[i] /= used;
    }

    final bandpassed = _fftBandpass(
      fused,
      resampleHz,
      minRespFreqHz,
      maxRespFreqHz,
    );
    return _hilbertEstimateFromBandpassed(
      'Fused Hilbert',
      bandpassed,
      end - start,
    );
  }

  static ({List<double> times, List<double> values})? _baselineWanderSeries(
    List<double> ecgSamples,
    double ecgSampleRate,
  ) {
    if (ecgSamples.length < (15 * ecgSampleRate).round()) return null;
    final detrended = _linearDetrendWithTimes(
      List<double>.generate(ecgSamples.length, (i) => i / ecgSampleRate),
      ecgSamples,
    );
    final baseline = _fftBandpass(detrended, ecgSampleRate, 0.05, 0.50);
    final step = math.max(1, (ecgSampleRate / resampleHz).round());
    final times = <double>[];
    final values = <double>[];
    for (int i = 0; i < baseline.length; i += step) {
      times.add(i / ecgSampleRate);
      values.add(baseline[i]);
    }
    return (times: times, values: values);
  }

  static double _linearInterpolateAt(
    List<double> times,
    List<double> values,
    double t,
  ) {
    if (t <= times.first) return values.first;
    if (t >= times.last) return values.last;
    var hi = 1;
    while (hi < times.length && times[hi] < t) {
      hi++;
    }
    final lo = hi - 1;
    final span = times[hi] - times[lo];
    if (span <= 0) return values[lo];
    final f = (t - times[lo]) / span;
    return values[lo] + (values[hi] - values[lo]) * f;
  }

  static ({List<double> times, List<double> values}) _prepareChannelSeries(
    List<double> times,
    List<double> values,
  ) {
    final n = math.min(times.length, values.length);
    final pairs = <({double time, double value})>[];
    for (int i = 0; i < n; i++) {
      final time = times[i];
      final value = values[i];
      if (time.isFinite && value.isFinite) {
        pairs.add((time: time, value: value));
      }
    }
    if (pairs.length < 6) return (times: const [], values: const []);

    pairs.sort((a, b) => a.time.compareTo(b.time));
    final cleanTimes = <double>[];
    final cleanValues = <double>[];
    for (final pair in pairs) {
      if (cleanTimes.isNotEmpty && pair.time <= cleanTimes.last) continue;
      cleanTimes.add(pair.time);
      cleanValues.add(pair.value);
    }
    if (cleanTimes.length < 6) return (times: const [], values: const []);

    final median = _median(cleanValues);
    final scale = _robustScale(cleanValues);
    if (scale <= 1e-9) return (times: const [], values: const []);

    final clipped =
        cleanValues
            .map((v) => v.clamp(median - 4.0 * scale, median + 4.0 * scale))
            .map((v) => v.toDouble())
            .toList();

    return (
      times: cleanTimes,
      values: _linearDetrendWithTimes(cleanTimes, clipped),
    );
  }

  static List<double> _linearDetrendWithTimes(
    List<double> times,
    List<double> values,
  ) {
    final n = math.min(times.length, values.length);
    if (n < 2) return List<double>.from(values);

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      final x = times[i] - times.first;
      final y = values[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denom = n * sumX2 - sumX * sumX;
    if (denom.abs() < 1e-15) {
      final mean = sumY / n;
      return values.map((v) => v - mean).toList();
    }

    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    return List<double>.generate(
      n,
      (i) => values[i] - (intercept + slope * (times[i] - times.first)),
    );
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) * 0.5;
  }

  static double _robustScale(List<double> values) {
    if (values.isEmpty) return 0.0;
    final median = _median(values);
    final deviations = values.map((v) => (v - median).abs()).toList();
    final mad = _median(deviations) * 1.4826;
    if (mad > 1e-9) return mad;

    final mean = values.reduce((a, b) => a + b) / values.length;
    var sumSq = 0.0;
    for (final value in values) {
      sumSq += (value - mean) * (value - mean);
    }
    return math.sqrt(sumSq / values.length);
  }

  static double _edgePenalty(double freqHz) {
    final bandWidth = maxRespFreqHz - minRespFreqHz;
    final margin = math.max(0.015, bandWidth * 0.08);
    final distance = math.min(freqHz - minRespFreqHz, maxRespFreqHz - freqHz);
    if (distance >= margin) return 1.0;
    return (0.35 + 0.65 * (distance / margin).clamp(0.0, 1.0)).clamp(0.0, 1.0);
  }

                                                                 
                                                               
                                                                  
                                                                        
  static double _physiologicalPrior(double freqHz) {
    const double mu = 0.25;                 
    const double sigma = 0.10;                      
    final double d = freqHz - mu;
    return math.exp(-0.5 * d * d / (sigma * sigma));
  }

  static ChannelEstimate? _spectralEstimate(
    String name,
    List<double> times,
    List<double> values,
  ) {
    if (times.length < 6 || values.length < 6) return null;

    final cleaned = _prepareChannelSeries(times, values);
    if (cleaned.times.length < 6) return null;

    final durationSec = cleaned.times.last - cleaned.times.first;
    if (durationSec < 15.0) return null;
    final normalizedTimes =
        cleaned.times.map((t) => t - cleaned.times.first).toList();

                                                          
    const int nFreqs = 200;
    final freqs = List<double>.generate(
      nFreqs,
      (i) => minRespFreqHz + i * (maxRespFreqHz - minRespFreqHz) / (nFreqs - 1),
    );

    final psd = lombScarglePSD(normalizedTimes, cleaned.values, freqs);

                                                    
                                                               
                                                                
    int peakIdx = 0;
    double bestWeightedPower = psd[0] * _physiologicalPrior(freqs[0]);
    for (int i = 1; i < psd.length; i++) {
      final double wp = psd[i] * _physiologicalPrior(freqs[i]);
      if (wp > bestWeightedPower) {
        bestWeightedPower = wp;
        peakIdx = i;
      }
    }

    if (psd[peakIdx] <= 0) return null;

    double peakFreq = freqs[peakIdx];
    if (peakIdx > 0 && peakIdx < freqs.length - 1) {
      final a = psd[peakIdx - 1];
      final b = psd[peakIdx];
      final c = psd[peakIdx + 1];
      final denom = a - 2.0 * b + c;
      if (denom.abs() > 1e-15) {
        final p = 0.5 * (a - c) / denom;
        final df = freqs[1] - freqs[0];
        peakFreq = (freqs[peakIdx] + p * df).clamp(
          minRespFreqHz,
          maxRespFreqHz,
        );
      }
    }

                                               
    final sorted = List<double>.from(psd)..sort();
    final median = sorted[sorted.length ~/ 2];
    final concentration =
        median > 0
            ? ((psd[peakIdx] / median - 1.0) / 2.0).clamp(0.0, 1.0)
            : 0.0;

                                    
    final rqi = _computeChannelRqi(psd, peakIdx, freqs);
    final cycles = peakFreq * durationSec;
    final cycleConfidence =
        cycles < 2.0
            ? 0.0
            : cycles < 4.0
            ? 0.35 + (cycles - 2.0) * 0.25
            : 1.0;
    final durationConfidence =
        durationSec < 30.0 ? 0.65 + (durationSec - 15.0) / 15.0 * 0.25 : 1.0;
    final confidence =
        (concentration * 0.55 +
            rqi * 0.30 +
            cycleConfidence.clamp(0.0, 1.0) * 0.15) *
        durationConfidence.clamp(0.0, 1.0) *
        _edgePenalty(peakFreq);

    if (confidence < 0.05 || rqi < 0.05) return null;

    return ChannelEstimate(
      name: name,
      breathRateBpm: peakFreq * 60.0,
      frequencyHz: peakFreq,
      confidence: confidence,
      rqi: rqi,
    );
  }

                                            
  static double _computeChannelRqi(
    List<double> psd,
    int peakIdx,
    List<double> freqs,
  ) {
    if (psd.isEmpty) return 0;

    final peakPower = psd[peakIdx];
    final totalPower = psd.reduce((a, b) => a + b);
    if (totalPower <= 0) return 0;

                                                                    
    final peakFreq = freqs[peakIdx];
    double peakBandPower = 0;
    for (int i = 0; i < freqs.length; i++) {
      if ((freqs[i] - peakFreq).abs() <= 0.05) {
        peakBandPower += psd[i];
      }
    }
    final concentration = (peakBandPower / totalPower).clamp(0.0, 1.0);

                                   
    final meanPsd = totalPower / psd.length;
    final prominence =
        meanPsd > 0 ? ((peakPower / meanPsd - 1.0) / 4.0).clamp(0.0, 1.0) : 0.0;

    double secondPower = 0;
    for (int i = 0; i < psd.length; i++) {
      if (i == peakIdx) continue;
      if ((freqs[i] - peakFreq).abs() < 0.04) continue;
      secondPower = math.max(secondPower, psd[i]);
    }
    final separation =
        secondPower > 0
            ? ((peakPower / secondPower - 1.0) / 1.5).clamp(0.0, 1.0)
            : 1.0;

    var entropy = 0.0;
    for (final power in psd) {
      if (power <= 0) continue;
      final p = power / totalPower;
      entropy -= p * math.log(p);
    }
    final entropyScore =
        psd.length > 1
            ? (1.0 - entropy / math.log(psd.length)).clamp(0.0, 1.0)
            : 0.0;

    return (concentration * 0.40 +
            prominence * 0.25 +
            separation * 0.25 +
            entropyScore * 0.10) *
        _edgePenalty(peakFreq);
  }

                                                                  
                                                            
                                                                  
                                                                  

  static ChannelEstimate? _extractHilbertChannel(List<_EdrBeat> beats) {
    if (beats.length < 12) return null;

                         
    final rrTimes = <double>[];
    final rrValues = <double>[];
    for (int i = 1; i < beats.length; i++) {
      final rr = beats[i].rrMs;
      if (rr == null || !rr.isFinite || rr <= 0) continue;
      rrTimes.add(beats[i].timeSec);
      rrValues.add(rr);
    }
    if (rrTimes.length < 8) return null;

    final durationSec = rrTimes.last - rrTimes.first;
    if (durationSec < 15.0) return null;

                                                              
    final (resampledTimes, resampled) = pchipInterpolate(
      rrTimes,
      rrValues,
      resampleHz,
    );
    if (resampled.length < 16) return null;

                     
    final detrended = _linearDetrendWithTimes(resampledTimes, resampled);

                                             
    final bandpassed = _fftBandpass(
      detrended,
      resampleHz,
      minRespFreqHz,
      maxRespFreqHz,
    );
    if (bandpassed.length < 16) return null;

                                          
    final int n = bandpassed.length;
    final int nfft = nextPowerOfTwo(n);
    final re = List<double>.filled(nfft, 0.0);
    final im = List<double>.filled(nfft, 0.0);
    for (int i = 0; i < n; i++) {
      re[i] = bandpassed[i];
    }
    fftInPlace(re, im);

                                                                
                                  
    re[0] = re[0];
    im[0] = im[0];
    for (int k = 1; k < nfft ~/ 2; k++) {
      re[k] *= 2.0;
      im[k] *= 2.0;
    }
                              
    for (int k = nfft ~/ 2 + 1; k < nfft; k++) {
      re[k] = 0.0;
      im[k] = 0.0;
    }

                  
    final ire = List<double>.from(re);
    final iim = im.map((v) => -v).toList();
    fftInPlace(ire, iim);
    for (int i = 0; i < nfft; i++) {
      ire[i] /= nfft;
      iim[i] = -iim[i] / nfft;
    }

                                                
    final phase = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      phase[i] = math.atan2(iim[i], ire[i]);
    }

                       
    for (int i = 1; i < n; i++) {
      double d = phase[i] - phase[i - 1];
      while (d > math.pi) {
        d -= 2 * math.pi;
      }
      while (d < -math.pi) {
        d += 2 * math.pi;
      }
      phase[i] = phase[i - 1] + d;
    }

                                                                    
    final smoothed = _savitzkyGolaySmooth(phase, 31, 3);

                                           
    final instFreq = List<double>.filled(n, 0.0);
    for (int i = 1; i < n - 1; i++) {
      instFreq[i] =
          (smoothed[i + 1] - smoothed[i - 1]) /
          2.0 /
          (2 * math.pi) *
          resampleHz;
    }
    instFreq[0] = instFreq[1];
    instFreq[n - 1] = instFreq[n - 2];

                                                     
    final validFreqs = <double>[];
    for (int i = 0; i < n; i++) {
      final f = instFreq[i].clamp(minRespFreqHz, maxRespFreqHz);
      if (f > 0) validFreqs.add(f);
    }
    if (validFreqs.length < 4) return null;

                                          
    final medianFreq = _median(validFreqs);
    if (medianFreq < minRespFreqHz || medianFreq > maxRespFreqHz) return null;

                                                                              
    final meanFreq = validFreqs.reduce((a, b) => a + b) / validFreqs.length;
    double sumSq = 0;
    for (final f in validFreqs) {
      sumSq += (f - meanFreq) * (f - meanFreq);
    }
    final cv =
        meanFreq > 0 ? math.sqrt(sumSq / validFreqs.length) / meanFreq : 1.0;
    final consistency = (1.0 - cv * 2.5).clamp(0.0, 1.0);
    final confidence = (consistency *
            _edgePenalty(medianFreq) *
            (durationSec < 30.0
                ? 0.65 + (durationSec - 15.0) / 15.0 * 0.25
                : 1.0))
        .clamp(0.0, 1.0);

    if (confidence < 0.05) return null;

    return ChannelEstimate(
      name: 'Hilbert (Inst. Freq)',
      breathRateBpm: medianFreq * 60.0,
      frequencyHz: medianFreq,
      confidence: confidence,
      rqi: consistency,
    );
  }

  static ChannelEstimate? _hilbertEstimateFromBandpassed(
    String name,
    List<double> bandpassed,
    double durationSec,
  ) {
    if (bandpassed.length < 16) return null;

    final n = bandpassed.length;
    final nfft = nextPowerOfTwo(n);
    final re = List<double>.filled(nfft, 0.0);
    final im = List<double>.filled(nfft, 0.0);
    for (int i = 0; i < n; i++) {
      re[i] = bandpassed[i];
    }
    fftInPlace(re, im);

    for (int k = 1; k < nfft ~/ 2; k++) {
      re[k] *= 2.0;
      im[k] *= 2.0;
    }
    for (int k = nfft ~/ 2 + 1; k < nfft; k++) {
      re[k] = 0.0;
      im[k] = 0.0;
    }

    final ire = List<double>.from(re);
    final iim = im.map((v) => -v).toList();
    fftInPlace(ire, iim);
    for (int i = 0; i < nfft; i++) {
      ire[i] /= nfft;
      iim[i] = -iim[i] / nfft;
    }

    final phase = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      phase[i] = math.atan2(iim[i], ire[i]);
    }
    for (int i = 1; i < n; i++) {
      var d = phase[i] - phase[i - 1];
      while (d > math.pi) {
        d -= 2 * math.pi;
      }
      while (d < -math.pi) {
        d += 2 * math.pi;
      }
      phase[i] = phase[i - 1] + d;
    }

    final window = math.min(31, n.isOdd ? n : n - 1);
    final smoothed =
        window >= 7 ? _savitzkyGolaySmooth(phase, window, 3) : phase;
    final instFreq = List<double>.filled(n, 0.0);
    for (int i = 1; i < n - 1; i++) {
      instFreq[i] =
          (smoothed[i + 1] - smoothed[i - 1]) /
          2.0 /
          (2 * math.pi) *
          resampleHz;
    }
    instFreq[0] = instFreq[1];
    instFreq[n - 1] = instFreq[n - 2];

    final validFreqs = <double>[];
    for (final f in instFreq) {
      if (f >= minRespFreqHz && f <= maxRespFreqHz && f.isFinite) {
        validFreqs.add(f);
      }
    }
    if (validFreqs.length < 4) return null;

    final medianFreq = _median(validFreqs);
    final meanFreq = validFreqs.reduce((a, b) => a + b) / validFreqs.length;
    var sumSq = 0.0;
    for (final f in validFreqs) {
      sumSq += (f - meanFreq) * (f - meanFreq);
    }
    final cv =
        meanFreq > 0 ? math.sqrt(sumSq / validFreqs.length) / meanFreq : 1.0;
    final consistency = (1.0 - cv * 2.5).clamp(0.0, 1.0);
    final durationConfidence =
        durationSec < 30.0 ? 0.65 + (durationSec - 15.0) / 15.0 * 0.25 : 1.0;
    final confidence = (consistency *
            durationConfidence.clamp(0.0, 1.0) *
            _edgePenalty(medianFreq))
        .clamp(0.0, 1.0);
    if (confidence < 0.05) return null;

    return ChannelEstimate(
      name: name,
      breathRateBpm: medianFreq * 60.0,
      frequencyHz: medianFreq,
      confidence: confidence,
      rqi: consistency,
    );
  }

                                                                       
  static List<double> _savitzkyGolaySmooth(
    List<double> signal,
    int windowSize,
    int polyOrder,
  ) {
    if (signal.length < windowSize) return List<double>.from(signal);
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

  static List<double> _sgCoefficients(int windowSize, int polyOrder) {
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

  static List<double> _solveLinearSystem(List<List<double>> a, List<double> b) {
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

    final double rolloff = (highcut - lowcut) * 0.15;
    for (int k = 0; k < nfft; k++) {
      final double freq =
          k <= nfft ~/ 2
              ? k * samplingRate / nfft
              : (nfft - k) * samplingRate / nfft;
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

    for (int i = 0; i < nfft; i++) {
      im[i] = -im[i];
    }
    fftInPlace(re, im);
    for (int i = 0; i < nfft; i++) {
      re[i] /= nfft;
    }
    return re.sublist(0, n);
  }

                                                                  
                                             
                                                                  

                                                                         
                                                              
  static bool _checkRsaQuality(List<double> rrIntervalsMs) {
    if (rrIntervalsMs.length < 10) return false;

                     
    final mean = rrIntervalsMs.reduce((a, b) => a + b) / rrIntervalsMs.length;
    double totalVar = 0;
    for (final rr in rrIntervalsMs) {
      totalVar += (rr - mean) * (rr - mean);
    }
    totalVar /= rrIntervalsMs.length;
    if (totalVar <= 0) return false;

                                                                          
    double diffVar = 0;
    for (int i = 1; i < rrIntervalsMs.length; i++) {
      final d = rrIntervalsMs[i] - rrIntervalsMs[i - 1];
      diffVar += d * d;
    }
    diffVar /= (rrIntervalsMs.length - 1);

                                                                        
    final rsaPower = diffVar * 0.5;
    return rsaPower >= 0.02 * totalVar;
  }

                                                                  
                           
                                                                  

                                       
                                                                 
                                                               
  static Map<String, double> _computeAdaptiveWeights(
    List<ChannelEstimate> channels,
    double heartRateBpm,
  ) {
    final weights = <String, double>{};

                            
    for (final ch in channels) {
      weights[ch.name] = ch.rqi * ch.confidence;
    }

                          
    double fmScale = 1.0;
    double amBwScale = 1.0;

    if (heartRateBpm > 120) {
                                         
      fmScale = 0.3;
      amBwScale = 1.5;
    } else if (heartRateBpm > 100) {
                           
      final t = (heartRateBpm - 100) / 20.0;
      fmScale = 1.0 - 0.7 * t;
      amBwScale = 1.0 + 0.5 * t;
    }

    for (final ch in channels) {
      if (ch.name.contains('FM') ||
          ch.name.contains('RSA') ||
          ch.name.contains('Hilbert')) {
        weights[ch.name] = (weights[ch.name] ?? 0) * fmScale;
      } else {
        weights[ch.name] = (weights[ch.name] ?? 0) * amBwScale;
      }
    }

                
    final total = weights.values.fold(0.0, (s, v) => s + v);
    if (total > 0) {
      for (final key in weights.keys.toList()) {
        weights[key] = weights[key]! / total;
      }
    }

    return weights;
  }
}
