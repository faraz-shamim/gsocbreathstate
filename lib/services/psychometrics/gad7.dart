import 'scale_engine.dart';

const gad7Definition = QuestionnaireDefinition(
  scaleType: PsychometricScaleType.gad7,
  title: 'GAD-7',
  subtitle: 'Anxiety symptom screener',
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
    SeverityBand(min: 15, max: 21, label: 'Severe'),
  ],
  questions: [
    ScaleQuestion(number: 1, prompt: 'Feeling nervous, anxious, or on edge'),
    ScaleQuestion(
      number: 2,
      prompt: 'Not being able to stop or control worrying',
    ),
    ScaleQuestion(
      number: 3,
      prompt: 'Worrying too much about different things',
    ),
    ScaleQuestion(number: 4, prompt: 'Trouble relaxing'),
    ScaleQuestion(
      number: 5,
      prompt: 'Being so restless that it is hard to sit still',
    ),
    ScaleQuestion(number: 6, prompt: 'Becoming easily annoyed or irritable'),
    ScaleQuestion(
      number: 7,
      prompt: 'Feeling afraid as if something awful might happen',
    ),
  ],
);
