// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:convert';

import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('precise RF release validation', () {
    test('locked reference protocol passes runtime conformance', () {
      const protocol = FisherLehrerProtocolConfig();
      final report = FisherLehrerProtocolValidator.validate(protocol);

      expect(report.passed, isTrue);
      expect(report.issues, isEmpty);
      expect(
        report.protocolVersion,
        FisherLehrerProtocolConfig.referenceVersion,
      );
      expect(report.configurationFingerprint, startsWith('fnv1a32-'));
      expect(report.configurationFingerprint, hasLength(16));
    });

    test('changed result-defining constants fail closed', () {
      const changed = FisherLehrerProtocolConfig(
        protocolVersion: 'unreviewed',
        cycleCount: 77,
        ibiLowessPoints: 39,
      );
      final audit = RfReleaseAudit.capture(
        changed,
        policy: const PreciseRfRolloutPolicy(PreciseRfRolloutStage.enabled),
      );

      expect(audit.assessmentsAllowed, isFalse);
      expect(
        audit.protocolConformance.issues,
        containsAll([
          'protocol_version_mismatch',
          'cycle_count_mismatch',
          'ibi_lowess_mismatch',
          'schedule_length_mismatch',
        ]),
      );
    });

    test('rollout aliases parse deterministically', () {
      expect(
        PreciseRfRolloutPolicy.parseStage('off'),
        PreciseRfRolloutStage.disabled,
      );
      expect(
        PreciseRfRolloutPolicy.parseStage('shadow'),
        PreciseRfRolloutStage.validation,
      );
      expect(
        PreciseRfRolloutPolicy.parseStage('production'),
        PreciseRfRolloutStage.enabled,
      );
      expect(
        PreciseRfRolloutPolicy.parseStage('unexpected'),
        PreciseRfRolloutStage.disabled,
      );
    });

    test('validation-only runs assessments but blocks profile updates', () {
      final audit = RfReleaseAudit.capture(
        const FisherLehrerProtocolConfig(),
        policy: const PreciseRfRolloutPolicy(PreciseRfRolloutStage.validation),
      );

      expect(audit.assessmentsAllowed, isTrue);
      expect(audit.patientApplicationAllowed, isFalse);
      expect(audit.toJson()['rolloutStage'], 'validation');
    });

    test('operational diagnostics contain no patient or raw samples', () {
      final payload = RfOperationalDiagnostics.persistencePayload(
        surface: 'web',
        result: _result,
        releaseAudit: RfReleaseAudit.capture(
          const FisherLehrerProtocolConfig(),
        ),
        completedCycles: 78,
        rrSampleCount: 912,
        respirationSampleCount: 8947,
        appliedToPatient: true,
      );
      final encoded = jsonEncode(payload).toLowerCase();

      expect(encoded, isNot(contains('patientid')));
      expect(encoded, isNot(contains('patient_id')));
      expect(encoded, isNot(contains('"rrsamples":')));
      expect(encoded, isNot(contains('"respirationsamples":')));
      expect(payload['rrSampleCount'], 912);
      expect(payload['respirationSampleCount'], 8947);
    });
  });
}

const _result = RfAssessmentResult(
  protocolVersion: FisherLehrerProtocolConfig.referenceVersion,
  mode: RfAcquisitionMode.measured,
  status: RfResultStatus.completed,
  rfBpm: 5.8,
  rfCenterElapsedMs: 600000,
  peakToTroughAmplitude: 122,
  scheduledBpmAtCenter: 5.75,
  fittedRespirationBpm: 5.79,
  adherenceDeltaBpm: 0.04,
  respirationFitError: 0.02,
  quality: RfQualityReport(
    protocolCompleted: true,
    fullAnalysisWindowAvailable: true,
    rrContinuityPassed: true,
    beltCoveragePassed: true,
    respirationFitConverged: true,
    breathingAdherencePassed: true,
    beltCoverage: 1,
    maximumObservedBeltGapMs: 100,
    maximumObservedRrGapMs: 1100,
    ectopicCorrections: 2,
    flags: [],
  ),
  trace: RfAnalysisTrace(),
);
