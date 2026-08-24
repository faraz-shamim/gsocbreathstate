// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/services/ai/rf_predictor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hasuo et al. Model 3', () {
    final predictor = RfPredictor();

    test('implements the published male equation without rounding', () {
      final result = predictor.predict(
        const RfPredictionInput(sex: 'Male', heightCm: 170),
      );

      expect(result.estimatedBpm, closeTo(17.90 - 0.07 * 170, 1e-12));
      expect(result.estimatedBpm, closeTo(6.0, 1e-12));
      expect(result.intercept, 17.90);
      expect(result.heightCoefficient, 0.07);
      expect(result.adjustedRSquared, 0.55);
      expect(result.formulaSex, HasuoFormulaSex.male);
    });

    test('implements the published female equation without rounding', () {
      final result = predictor.predict(
        const RfPredictionInput(sex: 'female', heightCm: 165),
      );

      expect(result.estimatedBpm, closeTo(15.88 - 0.06 * 165, 1e-12));
      expect(result.estimatedBpm, closeTo(5.98, 1e-12));
      expect(result.intercept, 15.88);
      expect(result.heightCoefficient, 0.06);
      expect(result.adjustedRSquared, 0.47);
      expect(result.formulaSex, HasuoFormulaSex.female);
    });

    test('does not clamp estimates to a breathing-rate range', () {
      final result = predictor.predict(
        const RfPredictionInput(sex: 'Male', heightCm: 100),
      );

      expect(result.estimatedBpm, closeTo(10.9, 1e-12));
      expect(result.isOutsideMeasuredRateRange, isTrue);
      expect(
        result.warnings,
        contains(
          'This estimate is outside the 5.0–7.0 BPM paced rates evaluated in '
          'the source study.',
        ),
      );
    });

    test('rejects a missing height instead of substituting a baseline', () {
      expect(
        () => predictor.predict(
          const RfPredictionInput(sex: 'Male', heightCm: null),
        ),
        throwsA(
          isA<RfPredictionInputException>().having(
            (error) => error.message,
            'message',
            contains('valid height'),
          ),
        ),
      );
    });

    test('rejects unsupported sex instead of inventing an equation', () {
      expect(
        () => predictor.predict(
          const RfPredictionInput(sex: 'Other', heightCm: 170),
        ),
        throwsA(
          isA<RfPredictionInputException>().having(
            (error) => error.message,
            'message',
            contains('Male or Female'),
          ),
        ),
      );
    });

    test('exposes the paper DOI and versioned model identity', () {
      expect(RfPredictor.doi, '10.1007/s10484-023-09602-5');
      expect(RfPredictor.modelVersion, 'hasuo-et-al-2024-model-3-v1');
      expect(
        RfPredictor.sourceUrl,
        'https://link.springer.com/article/10.1007/s10484-023-09602-5',
      );
    });
  });
}
