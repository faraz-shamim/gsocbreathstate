// SPDX-License-Identifier: AGPL-3.0-only
library;

import 'dart:math' as math;

class VrGamificationTracker {
  static const double buildingCoherence = 40;
  static const double highCoherence = 70;
  static const double peakCoherence = 85;

  double _startingVitality = 50;
  double _treeVitalityScore = 50;
  double _coherenceSum = 0;
  int _coherenceSamples = 0;

  int _currentBuildingStreakSec = 0;
  int _currentHighStreakSec = 0;
  int _currentPeakStreakSec = 0;
  int _bestBuildingStreakSec = 0;
  int _bestHighStreakSec = 0;
  int _bestPeakStreakSec = 0;

  int _currentBreathSyncStreakSec = 0;
  int _bestBreathSyncStreakSec = 0;

  void reset({double startingVitality = 50}) {
    _startingVitality = startingVitality.clamp(0, 100).toDouble();
    _treeVitalityScore = _startingVitality;
    _coherenceSum = 0;
    _coherenceSamples = 0;
    _currentBuildingStreakSec = 0;
    _currentHighStreakSec = 0;
    _currentPeakStreakSec = 0;
    _bestBuildingStreakSec = 0;
    _bestHighStreakSec = 0;
    _bestPeakStreakSec = 0;
    _currentBreathSyncStreakSec = 0;
    _bestBreathSyncStreakSec = 0;
  }

  void addBiofeedbackSample({
    required double coherence,
    required Duration sampleInterval,
    required double targetBpm,
    double? coherencePeakFrequencyHz,
    String? signalQuality,
  }) {
    final c = coherence.clamp(0, 100).toDouble();
    final seconds = math.max(1, sampleInterval.inSeconds);

    _coherenceSum += c;
    _coherenceSamples++;

    _updateCoherenceStreak(
      c >= buildingCoherence,
      seconds,
      () => _currentBuildingStreakSec,
      (value) => _currentBuildingStreakSec = value,
      () => _bestBuildingStreakSec,
      (value) => _bestBuildingStreakSec = value,
    );
    _updateCoherenceStreak(
      c >= highCoherence,
      seconds,
      () => _currentHighStreakSec,
      (value) => _currentHighStreakSec = value,
      () => _bestHighStreakSec,
      (value) => _bestHighStreakSec = value,
    );
    _updateCoherenceStreak(
      c >= peakCoherence,
      seconds,
      () => _currentPeakStreakSec,
      (value) => _currentPeakStreakSec = value,
      () => _bestPeakStreakSec,
      (value) => _bestPeakStreakSec = value,
    );

    if (isBreathAligned(
      coherence: c,
      targetBpm: targetBpm,
      coherencePeakFrequencyHz: coherencePeakFrequencyHz,
      signalQuality: signalQuality,
    )) {
      _currentBreathSyncStreakSec += seconds;
      _bestBreathSyncStreakSec = math.max(
        _bestBreathSyncStreakSec,
        _currentBreathSyncStreakSec,
      );
    } else {
      _currentBreathSyncStreakSec = 0;
    }

    var targetVitality = 22 + c * 0.72;
    if (c >= peakCoherence) targetVitality += 6;
    if (_currentBreathSyncStreakSec >= 20) targetVitality += 4;
    if (signalQuality == 'bad') targetVitality -= 8;
    targetVitality = targetVitality.clamp(8, 100).toDouble();

    final alpha = c >= averageCoherence ? 0.24 : 0.12;
    _treeVitalityScore += (targetVitality - _treeVitalityScore) * alpha;
    _treeVitalityScore = _treeVitalityScore.clamp(0, 100).toDouble();
  }

  static bool isBreathAligned({
    required double coherence,
    required double targetBpm,
    double? coherencePeakFrequencyHz,
    String? signalQuality,
  }) {
    if (signalQuality == 'bad' || coherence < 35 || targetBpm <= 0) {
      return false;
    }

    if (coherencePeakFrequencyHz != null &&
        coherencePeakFrequencyHz.isFinite &&
        coherencePeakFrequencyHz > 0) {
      final targetHz = targetBpm / 60.0;
      final toleranceHz = math.max(0.018, targetHz * 0.18);
      return (coherencePeakFrequencyHz - targetHz).abs() <= toleranceHz;
    }

    return coherence >= buildingCoherence;
  }

  VrSessionResult buildResult({
    required Duration elapsed,
    required Duration targetDuration,
    required double finalBreathingRate,
  }) {
    final completion =
        targetDuration.inSeconds <= 0
            ? 0.0
            : (elapsed.inSeconds / targetDuration.inSeconds)
                .clamp(0.0, 1.0)
                .toDouble();
    final score = sessionScore(completion: completion);

    return VrSessionResult(
      durationSeconds: elapsed.inSeconds,
      targetDurationSeconds: targetDuration.inSeconds,
      completion: completion,
      averageCoherence: averageCoherence,
      bestBuildingCoherenceStreakSeconds: _bestBuildingStreakSec,
      bestHighCoherenceStreakSeconds: _bestHighStreakSec,
      bestPeakCoherenceStreakSeconds: _bestPeakStreakSec,
      bestBreathSyncStreakSeconds: _bestBreathSyncStreakSec,
      treeVitalityScore: _treeVitalityScore,
      vitalityDelta: _treeVitalityScore - _startingVitality,
      sessionScore: score,
      unlockedAmbientTier: _sessionUnlockTier(score),
      finalBreathingRate: finalBreathingRate,
      recommendation: _recommendation(completion),
    );
  }

  Map<String, Object?> livePayload({
    required Duration elapsed,
    required Duration targetDuration,
  }) {
    final completion =
        targetDuration.inSeconds <= 0
            ? 0.0
            : (elapsed.inSeconds / targetDuration.inSeconds)
                .clamp(0.0, 1.0)
                .toDouble();
    final score = sessionScore(completion: completion);
    return {
      'treeVitalityScore': _treeVitalityScore,
      'vitalityDelta': _treeVitalityScore - _startingVitality,
      'sessionScore': score,
      'completion': completion,
      'averageCoherence': averageCoherence,
      'currentStreaks': {
        'building40': _currentBuildingStreakSec,
        'high70': _currentHighStreakSec,
        'peak85': _currentPeakStreakSec,
        'breathSync': _currentBreathSyncStreakSec,
      },
      'bestStreaks': {
        'building40': _bestBuildingStreakSec,
        'high70': _bestHighStreakSec,
        'peak85': _bestPeakStreakSec,
        'breathSync': _bestBreathSyncStreakSec,
      },
      'unlockedAmbientTier': _sessionUnlockTier(score),
    };
  }

  double sessionScore({required double completion}) {
    final streakBonus =
        math.min(_bestBuildingStreakSec / 90, 1) * 5 +
        math.min(_bestHighStreakSec / 60, 1) * 8 +
        math.min(_bestPeakStreakSec / 30, 1) * 7 +
        math.min(_bestBreathSyncStreakSec / 60, 1) * 8;
    final completionBonus = completion * 12;
    return (averageCoherence * 0.72 + streakBonus + completionBonus)
        .clamp(0, 100)
        .toDouble();
  }

  double get averageCoherence =>
      _coherenceSamples == 0 ? 0 : _coherenceSum / _coherenceSamples;

  double get treeVitalityScore => _treeVitalityScore;
  int get currentHighCoherenceStreakSeconds => _currentHighStreakSec;
  int get bestBuildingCoherenceStreakSeconds => _bestBuildingStreakSec;
  int get bestHighCoherenceStreakSeconds => _bestHighStreakSec;
  int get bestPeakCoherenceStreakSeconds => _bestPeakStreakSec;
  int get bestBreathSyncStreakSeconds => _bestBreathSyncStreakSec;

  void _updateCoherenceStreak(
    bool isActive,
    int seconds,
    int Function() current,
    void Function(int value) setCurrent,
    int Function() best,
    void Function(int value) setBest,
  ) {
    if (!isActive) {
      setCurrent(0);
      return;
    }
    final updated = current() + seconds;
    setCurrent(updated);
    setBest(math.max(best(), updated));
  }

  int _sessionUnlockTier(double score) {
    if (score >= 88 || _bestPeakStreakSec >= 30) return 4;
    if (score >= 74 || _bestHighStreakSec >= 60) return 3;
    if (score >= 56 || _bestBuildingStreakSec >= 90) return 2;
    if (score >= 36 || _bestBuildingStreakSec >= 30) return 1;
    return 0;
  }

  String _recommendation(double completion) {
    if (averageCoherence >= 75 && _bestBreathSyncStreakSec >= 45) {
      return 'Excellent coherence. Keep the same resonance pace next time.';
    }
    if (averageCoherence >= 55) {
      return 'Good practice. Repeat this duration and keep the exhale gentle.';
    }
    if (completion < 0.8) {
      return 'Try a shorter session and let the rhythm feel effortless.';
    }
    return 'Stay with the guide and soften the breath before chasing a score.';
  }
}

class VrSessionResult {
  final int durationSeconds;
  final int targetDurationSeconds;
  final double completion;
  final double averageCoherence;
  final int bestBuildingCoherenceStreakSeconds;
  final int bestHighCoherenceStreakSeconds;
  final int bestPeakCoherenceStreakSeconds;
  final int bestBreathSyncStreakSeconds;
  final double treeVitalityScore;
  final double vitalityDelta;
  final double sessionScore;
  final int unlockedAmbientTier;
  final double finalBreathingRate;
  final String recommendation;

  const VrSessionResult({
    required this.durationSeconds,
    required this.targetDurationSeconds,
    required this.completion,
    required this.averageCoherence,
    required this.bestBuildingCoherenceStreakSeconds,
    required this.bestHighCoherenceStreakSeconds,
    required this.bestPeakCoherenceStreakSeconds,
    required this.bestBreathSyncStreakSeconds,
    required this.treeVitalityScore,
    required this.vitalityDelta,
    required this.sessionScore,
    required this.unlockedAmbientTier,
    required this.finalBreathingRate,
    required this.recommendation,
  });

  Map<String, Object?> toPayload({VrTreeProgress? progressAfterSession}) {
    return {
      'durationSeconds': durationSeconds,
      'targetDurationSeconds': targetDurationSeconds,
      'completion': completion,
      'averageCoherence': averageCoherence,
      'bestHighCoherenceStreakSeconds': bestHighCoherenceStreakSeconds,
      'bestBreathSyncStreakSeconds': bestBreathSyncStreakSeconds,
      'treeVitalityScore': treeVitalityScore,
      'vitalityDelta': vitalityDelta,
      'sessionScore': sessionScore,
      'unlockedAmbientTier': unlockedAmbientTier,
      'finalBreathingRate': finalBreathingRate,
      'recommendation': recommendation,
      'coherenceStreaks': {
        'building40': bestBuildingCoherenceStreakSeconds,
        'high70': bestHighCoherenceStreakSeconds,
        'peak85': bestPeakCoherenceStreakSeconds,
      },
      'unlockedVisuals': VrTreeProgress.visualLayersForTier(
        unlockedAmbientTier,
      ),
      if (progressAfterSession != null)
        'progressAfterSession': progressAfterSession.toPayload(),
    };
  }
}

class VrTreeProgress {
  final double treeVitality;
  final int totalVrMinutes;
  final int bestCoherenceStreakSeconds;
  final Map<String, Object?>? lastSessionResult;
  final int unlockedAmbientTier;

  const VrTreeProgress({
    required this.treeVitality,
    required this.totalVrMinutes,
    required this.bestCoherenceStreakSeconds,
    required this.lastSessionResult,
    required this.unlockedAmbientTier,
  });

  factory VrTreeProgress.initial() {
    return const VrTreeProgress(
      treeVitality: 50,
      totalVrMinutes: 0,
      bestCoherenceStreakSeconds: 0,
      lastSessionResult: null,
      unlockedAmbientTier: 1,
    );
  }

  static VrTreeProgress? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final vitality = raw['treeVitality'];
    final minutes = raw['totalVrMinutes'];
    final bestStreak = raw['bestCoherenceStreakSeconds'];
    final tier = raw['unlockedAmbientTier'];
    final last = raw['lastSessionResult'];
    return VrTreeProgress(
      treeVitality:
          vitality is num ? vitality.toDouble().clamp(0, 100).toDouble() : 50,
      totalVrMinutes: minutes is num ? math.max(0, minutes.round()) : 0,
      bestCoherenceStreakSeconds:
          bestStreak is num ? math.max(0, bestStreak.round()) : 0,
      lastSessionResult:
          last is Map
              ? last.map((key, value) => MapEntry('$key', value))
              : null,
      unlockedAmbientTier: tier is num ? tier.round().clamp(0, 4).toInt() : 1,
    );
  }

  VrTreeProgress applySession(VrSessionResult result) {
    final minutesGained = (result.durationSeconds / 60).ceil();
    final delta =
        (result.treeVitalityScore - 50) * 0.18 +
        result.completion * 4 -
        (result.averageCoherence < 30 ? 2 : 0);
    final nextVitality = (treeVitality + delta).clamp(15, 100).toDouble();
    final vitalityTier = _tierForVitality(nextVitality);
    final nextTier = math.max(
      unlockedAmbientTier,
      math.max(vitalityTier, result.unlockedAmbientTier),
    );

    return VrTreeProgress(
      treeVitality: nextVitality,
      totalVrMinutes: totalVrMinutes + minutesGained,
      bestCoherenceStreakSeconds: math.max(
        bestCoherenceStreakSeconds,
        result.bestHighCoherenceStreakSeconds,
      ),
      lastSessionResult: result.toPayload(),
      unlockedAmbientTier: nextTier,
    );
  }

  Map<String, Object?> toPayload() {
    return {
      'treeVitality': treeVitality,
      'totalVrMinutes': totalVrMinutes,
      'bestCoherenceStreakSeconds': bestCoherenceStreakSeconds,
      'lastSessionResult': lastSessionResult,
      'unlockedAmbientTier': unlockedAmbientTier,
      'unlockedVisuals': visualLayersForTier(unlockedAmbientTier),
    };
  }

  static List<String> visualLayersForTier(int tier) {
    final layers = <String>['single_tree'];
    if (tier >= 1) layers.add('richer_canopy');
    if (tier >= 2) layers.add('blossom_accents');
    if (tier >= 3) layers.add('warmer_sky');
    if (tier >= 4) layers.add('elegant_particles');
    return layers;
  }

  static int _tierForVitality(double vitality) {
    if (vitality >= 88) return 4;
    if (vitality >= 74) return 3;
    if (vitality >= 60) return 2;
    if (vitality >= 42) return 1;
    return 0;
  }
}
