// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter/foundation.dart';

import 'fisher_lehrer_analyzer.dart';
import 'fisher_lehrer_models.dart';

                                                                       
Future<RfAssessmentResult> analyzeFisherLehrerInBackground(
  RfAssessmentInput input,
) async {
  final serialized = await compute(
    analyzeFisherLehrerAssessment,
    input.toJson(),
  );
  return RfAssessmentResult.fromJson(serialized);
}
