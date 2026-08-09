import 'scale_engine.dart';

const pcl5Definition = QuestionnaireDefinition(
  scaleType: PsychometricScaleType.pcl5,
  title: 'PCL-5',
  subtitle: 'PTSD symptom checklist',
  timeframe: 'Over the last month',
  responseOptions: [
    ScaleResponseOption(value: 0, label: 'Not at all'),
    ScaleResponseOption(value: 1, label: 'A little bit'),
    ScaleResponseOption(value: 2, label: 'Moderately'),
    ScaleResponseOption(value: 3, label: 'Quite a bit'),
    ScaleResponseOption(value: 4, label: 'Extremely'),
  ],
  severityBands: [
    SeverityBand(min: 0, max: 30, label: 'Below probable PTSD cutoff'),
    SeverityBand(min: 31, max: 33, label: 'Probable PTSD cutoff range'),
    SeverityBand(min: 34, max: 80, label: 'Above probable PTSD cutoff'),
  ],
  questions: [
    ScaleQuestion(
      number: 1,
      cluster: 'B',
      prompt:
          'Repeated, disturbing, and unwanted memories of the stressful experience',
    ),
    ScaleQuestion(
      number: 2,
      cluster: 'B',
      prompt: 'Repeated, disturbing dreams of the stressful experience',
    ),
    ScaleQuestion(
      number: 3,
      cluster: 'B',
      prompt:
          'Suddenly feeling or acting as if the stressful experience were happening again',
    ),
    ScaleQuestion(
      number: 4,
      cluster: 'B',
      prompt:
          'Feeling very upset when something reminded you of the stressful experience',
    ),
    ScaleQuestion(
      number: 5,
      cluster: 'B',
      prompt:
          'Having strong physical reactions when something reminded you of the stressful experience',
    ),
    ScaleQuestion(
      number: 6,
      cluster: 'C',
      prompt:
          'Avoiding memories, thoughts, or feelings related to the stressful experience',
    ),
    ScaleQuestion(
      number: 7,
      cluster: 'C',
      prompt: 'Avoiding external reminders of the stressful experience',
    ),
    ScaleQuestion(
      number: 8,
      cluster: 'D',
      prompt: 'Trouble remembering important parts of the stressful experience',
    ),
    ScaleQuestion(
      number: 9,
      cluster: 'D',
      prompt:
          'Strong negative beliefs about yourself, other people, or the world',
    ),
    ScaleQuestion(
      number: 10,
      cluster: 'D',
      prompt:
          'Blaming yourself or someone else for the stressful experience or what happened after it',
    ),
    ScaleQuestion(
      number: 11,
      cluster: 'D',
      prompt:
          'Strong negative feelings such as fear, horror, anger, guilt, or shame',
    ),
    ScaleQuestion(
      number: 12,
      cluster: 'D',
      prompt: 'Loss of interest in activities that you used to enjoy',
    ),
    ScaleQuestion(
      number: 13,
      cluster: 'D',
      prompt: 'Feeling distant or cut off from other people',
    ),
    ScaleQuestion(
      number: 14,
      cluster: 'D',
      prompt: 'Trouble experiencing positive feelings',
    ),
    ScaleQuestion(
      number: 15,
      cluster: 'E',
      prompt: 'Irritable behavior, angry outbursts, or acting aggressively',
    ),
    ScaleQuestion(
      number: 16,
      cluster: 'E',
      prompt: 'Taking too many risks or doing things that could cause you harm',
    ),
    ScaleQuestion(
      number: 17,
      cluster: 'E',
      prompt: 'Being superalert, watchful, or on guard',
    ),
    ScaleQuestion(
      number: 18,
      cluster: 'E',
      prompt: 'Feeling jumpy or easily startled',
    ),
    ScaleQuestion(
      number: 19,
      cluster: 'E',
      prompt: 'Having difficulty concentrating',
    ),
    ScaleQuestion(
      number: 20,
      cluster: 'E',
      prompt: 'Trouble falling or staying asleep',
    ),
  ],
  flagBuilder: _pcl5Flags,
);

List<ClinicalFlag> _pcl5Flags(Map<int, int> responses, int totalScore) {
  final endorsed = <String, int>{'B': 0, 'C': 0, 'D': 0, 'E': 0};
  for (final entry in responses.entries) {
    if (entry.value < 2) continue;
    final item = entry.key;
    if (item >= 1 && item <= 5) endorsed['B'] = endorsed['B']! + 1;
    if (item >= 6 && item <= 7) endorsed['C'] = endorsed['C']! + 1;
    if (item >= 8 && item <= 14) endorsed['D'] = endorsed['D']! + 1;
    if (item >= 15 && item <= 20) endorsed['E'] = endorsed['E']! + 1;
  }

  final flags = <ClinicalFlag>[];
  if (totalScore >= 31) {
    flags.add(
      const ClinicalFlag(
        code: 'pcl5_cutoff',
        label: 'Probable PTSD range',
        detail: 'PCL-5 total score is in or above the 31-33 cutoff range.',
      ),
    );
  }
  if (endorsed['B']! >= 1 &&
      endorsed['C']! >= 1 &&
      endorsed['D']! >= 2 &&
      endorsed['E']! >= 2) {
    flags.add(
      const ClinicalFlag(
        code: 'pcl5_dsm5_pattern',
        label: 'DSM-5 symptom pattern',
        detail: 'Endorsed items match the PCL-5 provisional symptom rule.',
      ),
    );
  }
  return flags;
}
