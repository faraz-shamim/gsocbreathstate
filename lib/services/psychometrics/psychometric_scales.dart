// SPDX-License-Identifier: AGPL-3.0-only
import 'gad7.dart';
import 'pcl5.dart';
import 'phq9.dart';
import 'scale_engine.dart';

const psychometricDefinitions =
    <PsychometricScaleType, QuestionnaireDefinition>{
      PsychometricScaleType.phq9: phq9Definition,
      PsychometricScaleType.gad7: gad7Definition,
      PsychometricScaleType.pcl5: pcl5Definition,
    };

QuestionnaireDefinition definitionForScale(PsychometricScaleType type) {
  return psychometricDefinitions[type]!;
}

QuestionnaireDefinition definitionForScaleId(String id) {
  return definitionForScale(PsychometricScaleType.fromId(id));
}
