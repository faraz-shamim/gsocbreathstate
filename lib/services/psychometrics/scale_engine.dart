// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:convert';

enum PsychometricScaleType {
  phq9,
  gad7,
  pcl5;

  String get id {
    switch (this) {
      case PsychometricScaleType.phq9:
        return 'phq9';
      case PsychometricScaleType.gad7:
        return 'gad7';
      case PsychometricScaleType.pcl5:
        return 'pcl5';
    }
  }

  String get displayName {
    switch (this) {
      case PsychometricScaleType.phq9:
        return 'PHQ-9';
      case PsychometricScaleType.gad7:
        return 'GAD-7';
      case PsychometricScaleType.pcl5:
        return 'PCL-5';
    }
  }

  static PsychometricScaleType fromId(String id) {
    return PsychometricScaleType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => PsychometricScaleType.phq9,
    );
  }
}

class ScaleResponseOption {
  final int value;
  final String label;

  const ScaleResponseOption({required this.value, required this.label});
}

class ScaleQuestion {
  final int number;
  final String prompt;
  final String? cluster;

  const ScaleQuestion({
    required this.number,
    required this.prompt,
    this.cluster,
  });
}

class SeverityBand {
  final int min;
  final int max;
  final String label;

  const SeverityBand({
    required this.min,
    required this.max,
    required this.label,
  });

  bool contains(int score) => score >= min && score <= max;
}

class ClinicalFlag {
  final String code;
  final String label;
  final String detail;

  const ClinicalFlag({
    required this.code,
    required this.label,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'label': label,
    'detail': detail,
  };
}

class QuestionnaireResult {
  final PsychometricScaleType scaleType;
  final int totalScore;
  final String severityLabel;
  final Map<int, int> responses;
  final Map<String, int> clusterScores;
  final List<ClinicalFlag> flags;

  const QuestionnaireResult({
    required this.scaleType,
    required this.totalScore,
    required this.severityLabel,
    required this.responses,
    this.clusterScores = const {},
    this.flags = const [],
  });

  bool get requiresReview => flags.isNotEmpty;

  String toResponsesJson() {
    final payload = {
      'scaleType': scaleType.id,
      'responses': responses.map((key, value) => MapEntry('$key', value)),
      'clusterScores': clusterScores,
      'flags': flags.map((flag) => flag.toJson()).toList(),
    };
    return jsonEncode(payload);
  }
}

typedef ClinicalFlagBuilder =
    List<ClinicalFlag> Function(Map<int, int> responses, int totalScore);

class QuestionnaireDefinition {
  final PsychometricScaleType scaleType;
  final String title;
  final String subtitle;
  final String timeframe;
  final List<ScaleQuestion> questions;
  final List<ScaleResponseOption> responseOptions;
  final List<SeverityBand> severityBands;
  final ClinicalFlagBuilder? flagBuilder;

  const QuestionnaireDefinition({
    required this.scaleType,
    required this.title,
    required this.subtitle,
    required this.timeframe,
    required this.questions,
    required this.responseOptions,
    required this.severityBands,
    this.flagBuilder,
  });

  int get maxScore {
    final maxOption = responseOptions
        .map((option) => option.value)
        .reduce((a, b) => a > b ? a : b);
    return maxOption * questions.length;
  }

  QuestionnaireResult score(Map<int, int> responses) {
    final cleaned = <int, int>{};
    final allowed = responseOptions.map((option) => option.value).toSet();
    for (final question in questions) {
      final value = responses[question.number];
      if (value == null) {
        throw ArgumentError('Missing response for item ${question.number}.');
      }
      if (!allowed.contains(value)) {
        throw ArgumentError(
          'Invalid response $value for item ${question.number}.',
        );
      }
      cleaned[question.number] = value;
    }

    final total = cleaned.values.fold<int>(0, (sum, value) => sum + value);
    final clusters = _clusterScores(cleaned);
    final flags = flagBuilder?.call(cleaned, total) ?? const <ClinicalFlag>[];

    return QuestionnaireResult(
      scaleType: scaleType,
      totalScore: total,
      severityLabel: severityForScore(total),
      responses: cleaned,
      clusterScores: clusters,
      flags: flags,
    );
  }

  String severityForScore(int score) {
    return severityBands
        .firstWhere(
          (band) => band.contains(score),
          orElse: () => SeverityBand(min: 0, max: maxScore, label: 'Unscored'),
        )
        .label;
  }

  bool isComplete(Map<int, int> responses) {
    return questions.every((question) => responses[question.number] != null);
  }

  Map<String, int> _clusterScores(Map<int, int> responses) {
    final clusters = <String, int>{};
    for (final question in questions) {
      final cluster = question.cluster;
      if (cluster == null) continue;
      clusters[cluster] =
          (clusters[cluster] ?? 0) + responses[question.number]!;
    }
    return clusters;
  }
}
