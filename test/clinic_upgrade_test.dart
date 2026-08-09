import 'package:breath_state/services/ai/rf_predictor.dart';
import 'package:breath_state/services/biofeedback/sensor_synchronizer.dart';
import 'package:breath_state/services/psychometrics/gad7.dart';
import 'package:breath_state/services/psychometrics/pcl5.dart';
import 'package:breath_state/services/psychometrics/phq9.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('psychometric scoring', () {
    test('PHQ-9 scores minimal symptoms and flags item 9 review', () {
      final result = phq9Definition.score({
        for (final question in phq9Definition.questions) question.number: 0,
        9: 1,
      });

      expect(result.totalScore, 1);
      expect(result.severityLabel, 'Minimal');
      expect(result.requiresReview, isTrue);
      expect(result.flags.map((flag) => flag.code), contains('phq9_item_9'));
    });

    test('GAD-7 maps score 14 to moderate anxiety', () {
      final result = gad7Definition.score({
        for (final question in gad7Definition.questions) question.number: 2,
      });

      expect(result.totalScore, 14);
      expect(result.severityLabel, 'Moderate');
      expect(result.requiresReview, isFalse);
    });

    test('PCL-5 reports cutoff and DSM-5 pattern flags', () {
      final result = pcl5Definition.score({
        for (final question in pcl5Definition.questions) question.number: 2,
      });

      expect(result.totalScore, 40);
      expect(result.severityLabel, 'Above probable PTSD cutoff');
      expect(result.requiresReview, isTrue);
      expect(result.flags.map((flag) => flag.code), contains('pcl5_cutoff'));
      expect(
        result.flags.map((flag) => flag.code),
        contains('pcl5_dsm5_pattern'),
      );
    });
  });

  group('RF prediction', () {
    test('implements the Hasuo female Model 3 equation', () {
      final result = RfPredictor().predict(
        const RfPredictionInput(sex: 'Female', heightCm: 165),
      );

      expect(result.estimatedBpm, closeTo(15.88 - 0.06 * 165, 1e-12));
      expect(result.adjustedRSquared, 0.47);
      expect(result.modelVersion, 'hasuo-et-al-2024-model-3-v1');
      expect(result.requiresValidation, isTrue);
      expect(result.warnings.first, contains('not a physiological'));
    });
  });

  group('sensor synchronization', () {
    test('resamples RR and respiration to a common 4 Hz clock', () {
      final synchronizer = SensorSynchronizer(sampleRateHz: 4);
      final start = DateTime.now();

      for (var i = 0; i <= 12; i++) {
        synchronizer.addRrInterval(
          820 + i.toDouble(),
          timestamp: start.add(Duration(seconds: i)),
        );
      }

      for (var i = 0; i <= 48; i++) {
        synchronizer.addRespiration(
          i / 48,
          timestamp: start.add(Duration(milliseconds: i * 250)),
        );
      }

      final frames = synchronizer.alignedFrames();

      expect(frames.length, greaterThanOrEqualTo(40));
      expect(frames.first.timestamp, start);
      expect(frames.every((frame) => frame.rrMs.isFinite), isTrue);
      expect(frames.every((frame) => frame.respiration.isFinite), isTrue);
    });
  });
}
