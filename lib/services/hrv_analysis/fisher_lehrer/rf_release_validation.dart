import 'dart:convert';
import 'dart:developer' as developer;

import 'fisher_lehrer_models.dart';
import 'fisher_lehrer_protocol.dart';

                                                          
   
                                                                             
                                           
enum PreciseRfRolloutStage { disabled, validation, enabled }

class PreciseRfRolloutPolicy {
  static const String environmentKey = 'PRECISE_RF_ROLLOUT';
  static const String configuredValue = String.fromEnvironment(
    environmentKey,
    defaultValue: 'enabled',
  );

  final PreciseRfRolloutStage stage;

  const PreciseRfRolloutPolicy(this.stage);

  factory PreciseRfRolloutPolicy.current() =>
      PreciseRfRolloutPolicy(parseStage(configuredValue));

  static PreciseRfRolloutStage parseStage(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'off':
      case 'disabled':
      case 'false':
      case '0':
        return PreciseRfRolloutStage.disabled;
      case 'validation':
      case 'validation-only':
      case 'shadow':
        return PreciseRfRolloutStage.validation;
      case 'on':
      case 'enabled':
      case 'production':
      case 'true':
      case '1':
        return PreciseRfRolloutStage.enabled;
      default:
        return PreciseRfRolloutStage.disabled;
    }
  }

  bool get assessmentsAllowed => stage != PreciseRfRolloutStage.disabled;

  bool get patientApplicationAllowed => stage == PreciseRfRolloutStage.enabled;

  String get label => switch (stage) {
    PreciseRfRolloutStage.disabled => 'Disabled',
    PreciseRfRolloutStage.validation => 'Validation only',
    PreciseRfRolloutStage.enabled => 'Enabled',
  };
}

class RfProtocolConformanceReport {
  final String protocolVersion;
  final String configurationFingerprint;
  final List<String> issues;

  const RfProtocolConformanceReport({
    required this.protocolVersion,
    required this.configurationFingerprint,
    required this.issues,
  });

  bool get passed => issues.isEmpty;

  Map<String, Object> toJson() => {
    'passed': passed,
    'protocolVersion': protocolVersion,
    'configurationFingerprint': configurationFingerprint,
    'issues': issues,
  };
}

                                                                              
   
                                                                            
class FisherLehrerProtocolValidator {
  static const double _expectedPeriodIncrementMs = 67.0353611530082;
  static const double _expectedLastExecutedPeriodMs = 14050.6116976705;
  static const double _expectedScheduledDurationMs = 894640.522875817;
  static const double _tolerance = 1e-9;

  static RfProtocolConformanceReport validate(
    FisherLehrerProtocolConfig protocol,
  ) {
    final issues = <String>[];

    void expectValue(bool matches, String issue) {
      if (!matches) issues.add(issue);
    }

    bool near(double actual, double expected) =>
        (actual - expected).abs() <= _tolerance;

    expectValue(
      protocol.protocolVersion == FisherLehrerProtocolConfig.referenceVersion,
      'protocol_version_mismatch',
    );
    expectValue(protocol.cycleCount == 78, 'cycle_count_mismatch');
    expectValue(near(protocol.startBpm, 6.75), 'start_bpm_mismatch');
    expectValue(near(protocol.targetEndBpm, 4.25), 'target_end_bpm_mismatch');
    expectValue(near(protocol.inhaleFraction, 0.5), 'inhale_fraction_mismatch');
    expectValue(
      near(protocol.analysisWindowSeconds, 60),
      'analysis_window_mismatch',
    );
    expectValue(protocol.ibiLowessPoints == 41, 'ibi_lowess_mismatch');
    expectValue(
      protocol.excursionLowessPoints == 17,
      'excursion_lowess_mismatch',
    );
    expectValue(
      near(protocol.referenceSampleRateHz, 256),
      'reference_sample_rate_mismatch',
    );
    expectValue(
      near(protocol.respirationSampleRateHz, 10),
      'respiration_sample_rate_mismatch',
    );
    expectValue(
      near(protocol.minimumBeltCoverage, 0.9),
      'belt_coverage_gate_mismatch',
    );
    expectValue(
      near(protocol.maximumBeltGapMs, 1000),
      'belt_gap_gate_mismatch',
    );
    expectValue(near(protocol.maximumRrGapMs, 3000), 'rr_gap_gate_mismatch');
    expectValue(
      near(protocol.maximumAdherenceDeltaBpm, 0.5),
      'adherence_gate_mismatch',
    );
    expectValue(
      near(protocol.periodIncrementMs, _expectedPeriodIncrementMs),
      'period_increment_mismatch',
    );
    expectValue(
      near(protocol.scheduledDurationMs, _expectedScheduledDurationMs),
      'scheduled_duration_mismatch',
    );

    final schedule = protocol.buildSchedule();
    expectValue(schedule.length == 78, 'schedule_length_mismatch');
    if (schedule.isNotEmpty) {
      expectValue(
        near(schedule.first.periodMs, 8888.88888888889),
        'first_period_mismatch',
      );
      expectValue(
        near(schedule.last.periodMs, _expectedLastExecutedPeriodMs),
        'last_executed_period_mismatch',
      );
      for (var index = 1; index < schedule.length; index++) {
        if (schedule[index].periodMs <= schedule[index - 1].periodMs ||
            !near(
              schedule[index].startElapsedMs,
              schedule[index - 1].endElapsedMs,
            )) {
          issues.add('schedule_continuity_mismatch');
          break;
        }
      }
    }

    return RfProtocolConformanceReport(
      protocolVersion: protocol.protocolVersion,
      configurationFingerprint: configurationFingerprint(protocol),
      issues: List.unmodifiable(issues),
    );
  }

                                                                              
  static String configurationFingerprint(FisherLehrerProtocolConfig protocol) {
    final canonical = jsonEncode(protocol.toJson());
    var hash = 0x811c9dc5;
    for (final codeUnit in canonical.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'fnv1a32-${hash.toRadixString(16).padLeft(8, '0')}';
  }
}

class RfReleaseAudit {
  final PreciseRfRolloutStage rolloutStage;
  final RfProtocolConformanceReport protocolConformance;

  const RfReleaseAudit({
    required this.rolloutStage,
    required this.protocolConformance,
  });

  factory RfReleaseAudit.capture(
    FisherLehrerProtocolConfig protocol, {
    PreciseRfRolloutPolicy? policy,
  }) {
    final resolvedPolicy = policy ?? PreciseRfRolloutPolicy.current();
    return RfReleaseAudit(
      rolloutStage: resolvedPolicy.stage,
      protocolConformance: FisherLehrerProtocolValidator.validate(protocol),
    );
  }

  bool get assessmentsAllowed =>
      rolloutStage != PreciseRfRolloutStage.disabled &&
      protocolConformance.passed;

  bool get patientApplicationAllowed =>
      rolloutStage == PreciseRfRolloutStage.enabled &&
      protocolConformance.passed;

  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'rolloutStage': rolloutStage.name,
    'assessmentAllowed': assessmentsAllowed,
    'patientApplicationAllowed': patientApplicationAllowed,
    'protocolConformance': protocolConformance.toJson(),
  };
}

                                                                             
                              
class RfOperationalDiagnostics {
  static Map<String, Object?> persistencePayload({
    required String surface,
    required RfAssessmentResult result,
    required RfReleaseAudit releaseAudit,
    required int completedCycles,
    required int rrSampleCount,
    required int respirationSampleCount,
    required bool appliedToPatient,
  }) => {
    'event': 'precise_rf_persisted',
    'surface': surface,
    'protocolVersion': result.protocolVersion,
    'mode': result.mode.name,
    'status': result.status.name,
    'qualityPassed': result.quality.passed,
    'qualityFlags': result.quality.flags.map((flag) => flag.name).toList(),
    'completedCycles': completedCycles,
    'rrSampleCount': rrSampleCount,
    'respirationSampleCount': respirationSampleCount,
    'appliedToPatient': appliedToPatient,
    'release': releaseAudit.toJson(),
  };

  static void recordPersistence({
    required String surface,
    required RfAssessmentResult result,
    required RfReleaseAudit releaseAudit,
    required int completedCycles,
    required int rrSampleCount,
    required int respirationSampleCount,
    required bool appliedToPatient,
  }) {
    developer.log(
      jsonEncode(
        persistencePayload(
          surface: surface,
          result: result,
          releaseAudit: releaseAudit,
          completedCycles: completedCycles,
          rrSampleCount: rrSampleCount,
          respirationSampleCount: respirationSampleCount,
          appliedToPatient: appliedToPatient,
        ),
      ),
      name: 'breath_state.precise_rf',
    );
  }
}
