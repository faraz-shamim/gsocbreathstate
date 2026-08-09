enum HasuoFormulaSex {
  male,
  female;

  static HasuoFormulaSex? tryParse(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'male':
        return HasuoFormulaSex.male;
      case 'female':
        return HasuoFormulaSex.female;
      default:
        return null;
    }
  }

  String get displayName => switch (this) {
    HasuoFormulaSex.male => 'Male',
    HasuoFormulaSex.female => 'Female',
  };
}

class RfPredictionInput {
  final String? sex;
  final double? heightCm;

  const RfPredictionInput({required this.sex, required this.heightCm});
}

class RfPredictionResult {
  final double estimatedBpm;
  final HasuoFormulaSex formulaSex;
  final double heightCm;
  final double intercept;
  final double heightCoefficient;
  final double adjustedRSquared;
  final String modelVersion;
  final List<String> warnings;

  const RfPredictionResult({
    required this.estimatedBpm,
    required this.formulaSex,
    required this.heightCm,
    required this.intercept,
    required this.heightCoefficient,
    required this.adjustedRSquared,
    required this.modelVersion,
    required this.warnings,
  });

                                                                              
  double get predictedBpm => estimatedBpm;

  bool get requiresValidation => true;

  bool get isOutsideMeasuredRateRange =>
      estimatedBpm < RfPredictor.measuredRateMinimumBpm ||
      estimatedBpm > RfPredictor.measuredRateMaximumBpm;

  String get equation =>
      '${intercept.toStringAsFixed(2)} − '
      '${heightCoefficient.toStringAsFixed(2)} × '
      '${heightCm.toStringAsFixed(1)}';
}

class RfPredictionInputException implements Exception {
  final String message;

  const RfPredictionInputException(this.message);

  @override
  String toString() => message;
}

                                                                   
   
           
                                                                    
                                                                    
                                                            
                                                         
                                              
class RfPredictor {
  static const modelVersion = 'hasuo-et-al-2024-model-3-v1';
  static const doi = '10.1007/s10484-023-09602-5';
  static const sourceUrl =
      'https://link.springer.com/article/10.1007/s10484-023-09602-5';

  static const maleIntercept = 17.90;
  static const maleHeightCoefficient = 0.07;
  static const maleAdjustedRSquared = 0.55;

  static const femaleIntercept = 15.88;
  static const femaleHeightCoefficient = 0.06;
  static const femaleAdjustedRSquared = 0.47;

                                                                      
  static const measuredRateMinimumBpm = 5.0;
  static const measuredRateMaximumBpm = 7.0;

  RfPredictionResult predict(RfPredictionInput input) {
    final formulaSex = HasuoFormulaSex.tryParse(input.sex);
    if (formulaSex == null) {
      throw const RfPredictionInputException(
        'Hasuo Model 3 requires sex recorded as Male or Female because the '
        'paper publishes separate equations for those two groups.',
      );
    }

    final heightCm = input.heightCm;
    if (heightCm == null || !heightCm.isFinite || heightCm <= 0) {
      throw const RfPredictionInputException(
        'Hasuo Model 3 requires a valid height in centimeters.',
      );
    }

    final (intercept, coefficient, adjustedRSquared) = switch (formulaSex) {
      HasuoFormulaSex.male => (
        maleIntercept,
        maleHeightCoefficient,
        maleAdjustedRSquared,
      ),
      HasuoFormulaSex.female => (
        femaleIntercept,
        femaleHeightCoefficient,
        femaleAdjustedRSquared,
      ),
    };

                                                              
    final estimatedBpm = intercept - coefficient * heightCm;
    final warnings = <String>[
      'This is a sex-and-height estimate, not a physiological RF '
          'measurement.',
      'The source model explained ${(adjustedRSquared * 100).round()}% of '
          'variance in its healthy-volunteer development sample.',
      if (estimatedBpm < measuredRateMinimumBpm ||
          estimatedBpm > measuredRateMaximumBpm)
        'This estimate is outside the 5.0–7.0 BPM paced rates evaluated in '
            'the source study.',
      'In the incurable-cancer sample, the formula tended to estimate '
          'slightly high when measured RF was 6 BPM or lower.',
    ];

    return RfPredictionResult(
      estimatedBpm: estimatedBpm,
      formulaSex: formulaSex,
      heightCm: heightCm,
      intercept: intercept,
      heightCoefficient: coefficient,
      adjustedRSquared: adjustedRSquared,
      modelVersion: modelVersion,
      warnings: List.unmodifiable(warnings),
    );
  }
}
