// SPDX-License-Identifier: AGPL-3.0-only
library;

import 'dart:math' as math;

enum SqiLevel {
  good,                                                  
  warning,                                          
  bad,                                              
}

class SqiResult {
  final SqiLevel level;
  final double score; 
  final String reason;

  const SqiResult({
    required this.level,
    required this.score,
    required this.reason,
  });
}

class SignalQualityIndex {
  SignalQualityIndex._();

  static const double _minRR = 250.0;  
  static const double _maxRR = 2000.0; 

  static const double _maxRelativeDiff = 0.20;

  static SqiResult classify(double currentRR, List<double> recentRRs) {
    if (currentRR < _minRR || currentRR > _maxRR) {
      return const SqiResult(
        level: SqiLevel.bad,
        score: 0.0,
        reason: 'Outside physiological range',
      );
    }

    if (recentRRs.isEmpty) {
      return const SqiResult(
        level: SqiLevel.good,
        score: 0.8,
        reason: 'No history — assumed OK',
      );
    }

    final validRecent =
        recentRRs.where((r) => r >= _minRR && r <= _maxRR).toList();
    if (validRecent.isEmpty) {
      return const SqiResult(
        level: SqiLevel.warning,
        score: 0.5,
        reason: 'No valid recent intervals for comparison',
      );
    }

    final double localMean =
        validRecent.reduce((a, b) => a + b) / validRecent.length;

    final double lastRR = recentRRs.last;
    final double succDiff = (currentRR - lastRR).abs();
    final double relativeDiff =
        localMean > 0 ? succDiff / localMean : 1.0;

    final double meanDev = (currentRR - localMean).abs();
    final double relativeMeanDev =
        localMean > 0 ? meanDev / localMean : 1.0;

    final double diffScore =
        math.exp(-3.0 * relativeDiff / _maxRelativeDiff);

    final double meanScore =
        math.exp(-2.0 * relativeMeanDev / _maxRelativeDiff);

    final double score = (0.6 * diffScore + 0.4 * meanScore).clamp(0.0, 1.0);

    if (score >= 0.7) {
      return SqiResult(
        level: SqiLevel.good,
        score: score,
        reason: 'Normal',
      );
    } else if (score >= 0.4) {
      return SqiResult(
        level: SqiLevel.warning,
        score: score,
        reason: 'Borderline — possible artifact',
      );
    } else {
      return SqiResult(
        level: SqiLevel.bad,
        score: score,
        reason: 'Likely artifact or ectopic beat',
      );
    }
  }

  static List<SqiResult> classifyAll(
    List<double> rrIntervals, {
    int historyWindow = 10,
  }) {
    final results = <SqiResult>[];
    for (int i = 0; i < rrIntervals.length; i++) {
      final start = math.max(0, i - historyWindow);
      final history = rrIntervals.sublist(start, i);
      results.add(classify(rrIntervals[i], history));
    }
    return results;
  }
}