import 'scale_engine.dart';

const phq9Definition = QuestionnaireDefinition(
  scaleType: PsychometricScaleType.phq9,
  title: 'PHQ-9',
  subtitle: 'Depression symptom screener',
  timeframe: 'Over the last 2 weeks',
  responseOptions: [
    ScaleResponseOption(value: 0, label: 'Not at all'),
    ScaleResponseOption(value: 1, label: 'Several days'),
    ScaleResponseOption(value: 2, label: 'More than half the days'),
    ScaleResponseOption(value: 3, label: 'Nearly every day'),
  ],
  severityBands: [
    SeverityBand(min: 0, max: 4, label: 'Minimal'),
    SeverityBand(min: 5, max: 9, label: 'Mild'),
    SeverityBand(min: 10, max: 14, label: 'Moderate'),
    SeverityBand(min: 15, max: 19, label: 'Moderately severe'),
    SeverityBand(min: 20, max: 27, label: 'Severe'),
  ],
  questions: [
    ScaleQuestion(
      number: 1,
      prompt: 'Little interest or pleasure in doing things',
    ),
    ScaleQuestion(number: 2, prompt: 'Feeling down, depressed, or hopeless'),
    ScaleQuestion(
      number: 3,
      prompt: 'Trouble falling or staying asleep, or sleeping too much',
    ),
    ScaleQuestion(number: 4, prompt: 'Feeling tired or having little energy'),
    ScaleQuestion(number: 5, prompt: 'Poor appetite or overeating'),
    ScaleQuestion(
      number: 6,
      prompt:
          'Feeling bad about yourself, or that you are a failure or have let yourself or your family down',
    ),
    ScaleQuestion(number: 7, prompt: 'Trouble concentrating on things'),
    ScaleQuestion(
      number: 8,
      prompt:
          'Moving or speaking so slowly that other people could have noticed, or being so fidgety or restless that you have been moving around a lot more than usual',
    ),
    ScaleQuestion(
      number: 9,
      prompt:
          'Thoughts that you would be better off dead or of hurting yourself in some way',
    ),
  ],
  flagBuilder: _phq9Flags,
);

List<ClinicalFlag> _phq9Flags(Map<int, int> responses, int totalScore) {
  final item9 = responses[9] ?? 0;
  if (item9 <= 0) return const [];
  return const [
    ClinicalFlag(
      code: 'phq9_item_9',
      label: 'Clinician review',
      detail: 'PHQ-9 item 9 was endorsed and should be reviewed promptly.',
    ),
  ];
}
