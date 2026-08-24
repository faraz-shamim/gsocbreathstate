// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/services/webxr/vr_gamification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VR gamification tracker', () {
    test('tracks coherence bands and breath-sync streaks', () {
      final tracker = VrGamificationTracker()..reset(startingVitality: 50);

      for (var i = 0; i < 8; i++) {
        tracker.addBiofeedbackSample(
          coherence: 78,
          sampleInterval: const Duration(seconds: 5),
          targetBpm: 6,
          coherencePeakFrequencyHz: 0.101,
          signalQuality: 'good',
        );
      }

      expect(tracker.bestBuildingCoherenceStreakSeconds, 40);
      expect(tracker.bestHighCoherenceStreakSeconds, 40);
      expect(tracker.bestPeakCoherenceStreakSeconds, 0);
      expect(tracker.bestBreathSyncStreakSeconds, 40);
      expect(tracker.treeVitalityScore, greaterThan(50));
    });

    test('breaks breath sync when the coherence peak drifts from target', () {
      final tracker = VrGamificationTracker()..reset(startingVitality: 50);

      tracker.addBiofeedbackSample(
        coherence: 74,
        sampleInterval: const Duration(seconds: 5),
        targetBpm: 6,
        coherencePeakFrequencyHz: 0.1,
        signalQuality: 'good',
      );
      tracker.addBiofeedbackSample(
        coherence: 72,
        sampleInterval: const Duration(seconds: 5),
        targetBpm: 6,
        coherencePeakFrequencyHz: 0.19,
        signalQuality: 'good',
      );

      expect(tracker.bestBreathSyncStreakSeconds, 5);
      expect(tracker.bestHighCoherenceStreakSeconds, 10);
    });

    test(
      'updates persistent tree progress without arcade-style volatility',
      () {
        final tracker = VrGamificationTracker()..reset(startingVitality: 50);
        for (var i = 0; i < 12; i++) {
          tracker.addBiofeedbackSample(
            coherence: 86,
            sampleInterval: const Duration(seconds: 5),
            targetBpm: 5.8,
            coherencePeakFrequencyHz: 5.8 / 60,
            signalQuality: 'good',
          );
        }

        final result = tracker.buildResult(
          elapsed: const Duration(minutes: 5),
          targetDuration: const Duration(minutes: 5),
          finalBreathingRate: 5.8,
        );
        final progress = VrTreeProgress.initial().applySession(result);

        expect(result.unlockedAmbientTier, greaterThanOrEqualTo(3));
        expect(progress.treeVitality, greaterThan(50));
        expect(progress.totalVrMinutes, 5);
        expect(progress.bestCoherenceStreakSeconds, 60);
        expect(progress.unlockedAmbientTier, greaterThanOrEqualTo(3));
      },
    );
  });
}
