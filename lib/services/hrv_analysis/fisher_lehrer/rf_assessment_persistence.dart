// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:convert';

import 'package:breath_state/services/db_service/database.dart';

import 'fisher_lehrer_models.dart';
import 'fisher_lehrer_protocol.dart';
import 'rf_release_validation.dart';

class RfAssessmentPersistenceReceipt {
  final int sessionSummaryId;
  final int assessmentRecordId;
  final bool appliedToPatient;

  const RfAssessmentPersistenceReceipt({
    required this.sessionSummaryId,
    required this.assessmentRecordId,
    required this.appliedToPatient,
  });
}

class RfAssessmentHistorySummary {
  final String protocolVersion;
  final String mode;
  final String status;
  final String surface;
  final double? rfBpm;
  final double? peakToTroughAmplitude;
  final double? scheduledBpmAtCenter;
  final double? fittedRespirationBpm;
  final double? adherenceDeltaBpm;
  final int ectopicCorrections;
  final bool qualityPassed;
  final List<String> qualityFlags;
  final bool appliedToPatient;
  final bool? estimateConfirmed;
  final String? rolloutStage;
  final bool? protocolConformancePassed;
  final String? protocolFingerprint;

  const RfAssessmentHistorySummary({
    required this.protocolVersion,
    required this.mode,
    required this.status,
    required this.surface,
    required this.rfBpm,
    required this.peakToTroughAmplitude,
    required this.scheduledBpmAtCenter,
    required this.fittedRespirationBpm,
    required this.adherenceDeltaBpm,
    required this.ectopicCorrections,
    required this.qualityPassed,
    required this.qualityFlags,
    required this.appliedToPatient,
    required this.estimateConfirmed,
    required this.rolloutStage,
    required this.protocolConformancePassed,
    required this.protocolFingerprint,
  });

  static RfAssessmentHistorySummary? tryParse(Map<String, dynamic> extended) {
    final precise = extended['preciseRf'];
    if (precise is Map) {
      final map = Map<String, dynamic>.from(precise);
      return _fromMap(map);
    }

    final legacyVr = extended['resonanceSweep'];
    if (legacyVr is Map) {
      final map = Map<String, dynamic>.from(legacyVr);
      final quality =
          map['quality'] is Map
              ? Map<String, dynamic>.from(map['quality'] as Map)
              : const <String, dynamic>{};
      final flags =
          quality['flags'] is List
              ? (quality['flags'] as List).map((value) => '$value').toList()
              : const <String>[];
      final release = _releaseMetadata(map);
      return RfAssessmentHistorySummary(
        protocolVersion: '${map['methodVersion'] ?? 'unknown'}',
        mode: '${map['resultMode'] ?? 'estimated'}',
        status: '${map['status'] ?? 'completed'}',
        surface: 'vr',
        rfBpm: (map['rfBpm'] as num?)?.toDouble(),
        peakToTroughAmplitude:
            (map['peakToTroughAmplitudeMs'] as num?)?.toDouble(),
        scheduledBpmAtCenter: (map['scheduledBpmAtCenter'] as num?)?.toDouble(),
        fittedRespirationBpm: (map['fittedRespirationBpm'] as num?)?.toDouble(),
        adherenceDeltaBpm: (map['adherenceDeltaBpm'] as num?)?.toDouble(),
        ectopicCorrections: (map['ectopicCorrections'] as num?)?.toInt() ?? 0,
        qualityPassed: flags.isEmpty,
        qualityFlags: flags,
        appliedToPatient: map['appliedPatientFrequencyBpm'] is num,
        estimateConfirmed: null,
        rolloutStage: release.rolloutStage,
        protocolConformancePassed: release.conformancePassed,
        protocolFingerprint: release.fingerprint,
      );
    }
    return null;
  }

  static RfAssessmentHistorySummary _fromMap(Map<String, dynamic> map) {
    final flags =
        map['qualityFlags'] is List
            ? (map['qualityFlags'] as List).map((value) => '$value').toList()
            : const <String>[];
    final release = _releaseMetadata(map);
    return RfAssessmentHistorySummary(
      protocolVersion: '${map['protocolVersion'] ?? 'unknown'}',
      mode: '${map['mode'] ?? 'estimated'}',
      status: '${map['status'] ?? 'completed'}',
      surface: '${map['surface'] ?? 'unknown'}',
      rfBpm: (map['rfBpm'] as num?)?.toDouble(),
      peakToTroughAmplitude: (map['peakToTroughAmplitude'] as num?)?.toDouble(),
      scheduledBpmAtCenter: (map['scheduledBpmAtCenter'] as num?)?.toDouble(),
      fittedRespirationBpm: (map['fittedRespirationBpm'] as num?)?.toDouble(),
      adherenceDeltaBpm: (map['adherenceDeltaBpm'] as num?)?.toDouble(),
      ectopicCorrections: (map['ectopicCorrections'] as num?)?.toInt() ?? 0,
      qualityPassed: map['qualityPassed'] == true,
      qualityFlags: flags,
      appliedToPatient: map['appliedToPatient'] == true,
      estimateConfirmed: map['estimateConfirmed'] as bool?,
      rolloutStage: release.rolloutStage,
      protocolConformancePassed: release.conformancePassed,
      protocolFingerprint: release.fingerprint,
    );
  }

  static ({String? rolloutStage, bool? conformancePassed, String? fingerprint})
  _releaseMetadata(Map<String, dynamic> map) {
    final rawRelease = map['releaseValidation'];
    if (rawRelease is! Map) {
      return (rolloutStage: null, conformancePassed: null, fingerprint: null);
    }
    final release = Map<String, dynamic>.from(rawRelease);
    final rawConformance = release['protocolConformance'];
    final conformance =
        rawConformance is Map
            ? Map<String, dynamic>.from(rawConformance)
            : const <String, dynamic>{};
    return (
      rolloutStage: release['rolloutStage'] as String?,
      conformancePassed: conformance['passed'] as bool?,
      fingerprint: conformance['configurationFingerprint'] as String?,
    );
  }
}

                                                                   
class RfAssessmentPersistenceService {
  final AppDatabase database;

  const RfAssessmentPersistenceService(this.database);

  Future<RfAssessmentPersistenceReceipt> persist({
    required int patientId,
    required String surface,
    required DateTime startedAt,
    required DateTime endedAt,
    required FisherLehrerProtocolConfig protocol,
    required RfAssessmentResult result,
    required List<RfBeatSample> rrSamples,
    required List<RfRespirationSample> respirationSamples,
    required int completedCycles,
    required bool appliedToPatient,
    required bool? estimateConfirmed,
    int? sessionSummaryId,
    String sessionType = 'rf_assessment',
    bool useTransaction = true,
    RfReleaseAudit? releaseAudit,
  }) async {
    final liveConformance = FisherLehrerProtocolValidator.validate(protocol);
    final suppliedReleaseAudit = releaseAudit;
    if (suppliedReleaseAudit != null &&
        suppliedReleaseAudit.protocolConformance.configurationFingerprint !=
            liveConformance.configurationFingerprint) {
      throw StateError(
        'Release validation metadata does not match the persisted protocol.',
      );
    }
    final resolvedReleaseAudit = RfReleaseAudit(
      rolloutStage:
          suppliedReleaseAudit?.rolloutStage ??
          PreciseRfRolloutPolicy.current().stage,
      protocolConformance: liveConformance,
    );
    if (!resolvedReleaseAudit.protocolConformance.passed) {
      throw StateError(
        'The precise RF protocol failed runtime conformance checks: '
        '${resolvedReleaseAudit.protocolConformance.issues.join(', ')}.',
      );
    }
    if (!resolvedReleaseAudit.assessmentsAllowed) {
      throw StateError('Precise RF assessments are disabled for this build.');
    }
    if (result.protocolVersion != protocol.protocolVersion) {
      throw StateError(
        'The RF result protocol version does not match the assessment protocol.',
      );
    }
    if (appliedToPatient && !resolvedReleaseAudit.patientApplicationAllowed) {
      throw StateError(
        'This rollout stage does not allow RF results to update a patient.',
      );
    }
    if (result.mode == RfAcquisitionMode.estimated &&
        appliedToPatient &&
        estimateConfirmed != true) {
      throw StateError(
        'An estimated RF cannot be applied without explicit confirmation.',
      );
    }
    if (result.mode == RfAcquisitionMode.measured &&
        estimateConfirmed != null) {
      throw StateError(
        'Estimate confirmation is only valid for estimated assessments.',
      );
    }

    Future<RfAssessmentPersistenceReceipt> operation() async {
      final compactPayload = _compactPayload(
        surface: surface,
        result: result,
        appliedToPatient: appliedToPatient,
        estimateConfirmed: estimateConfirmed,
        releaseAudit: resolvedReleaseAudit,
      );
      final resolvedSummaryId =
          sessionSummaryId ??
          await database.insertSessionSummary(
            patientId: patientId,
            sessionType: sessionType,
            startedAt: startedAt.toIso8601String(),
            endedAt: endedAt.toIso8601String(),
            durationSeconds: (protocol.scheduledDurationMs / 1000).ceil(),
            breathSource:
                result.mode == RfAcquisitionMode.measured
                    ? 'gdx_rb_measured'
                    : 'pacer_estimated',
            extendedMetricsJson: jsonEncode({'preciseRf': compactPayload}),
          );

      final recordId = await database.insertRfAssessmentRecord(
        patientId: patientId,
        sessionSummaryId: resolvedSummaryId,
        surface: surface,
        protocolVersion: result.protocolVersion,
        mode: result.mode.name,
        status: result.status.name,
        startedAt: startedAt.toIso8601String(),
        endedAt: endedAt.toIso8601String(),
        durationMs: protocol.scheduledDurationMs,
        completedCycles: completedCycles,
        rfBpm: result.rfBpm,
        rfCenterElapsedMs: result.rfCenterElapsedMs,
        peakToTroughAmplitude: result.peakToTroughAmplitude,
        scheduledBpmAtCenter: result.scheduledBpmAtCenter,
        fittedRespirationBpm: result.fittedRespirationBpm,
        adherenceDeltaBpm: result.adherenceDeltaBpm,
        respirationFitError: result.respirationFitError,
        ectopicCorrections: result.quality.ectopicCorrections,
        qualityPassed: result.quality.passed,
        qualityFlagsJson: jsonEncode(
          result.quality.flags.map((flag) => flag.name).toList(),
        ),
        appliedToPatient: appliedToPatient,
        estimateConfirmed: estimateConfirmed,
        protocolJson: jsonEncode({
          ...protocol.toJson(),
          'releaseValidation': resolvedReleaseAudit.toJson(),
        }),
        resultJson: jsonEncode({
          ...result.toJson(),
          'releaseValidation': resolvedReleaseAudit.toJson(),
        }),
        rrSamplesJson: jsonEncode(
          rrSamples.map((sample) => sample.toJson()).toList(),
        ),
        respirationSamplesJson:
            respirationSamples.isEmpty
                ? null
                : jsonEncode(
                  respirationSamples.map((sample) => sample.toJson()).toList(),
                ),
      );

      final rate = result.rfBpm;
      if (appliedToPatient && rate != null && rate.isFinite && rate > 0) {
        await database.updatePatientResonanceFrequency(patientId, rate);
      }

      final receipt = RfAssessmentPersistenceReceipt(
        sessionSummaryId: resolvedSummaryId,
        assessmentRecordId: recordId,
        appliedToPatient: appliedToPatient,
      );
      RfOperationalDiagnostics.recordPersistence(
        surface: surface,
        result: result,
        releaseAudit: resolvedReleaseAudit,
        completedCycles: completedCycles,
        rrSampleCount: rrSamples.length,
        respirationSampleCount: respirationSamples.length,
        appliedToPatient: appliedToPatient,
      );
      return receipt;
    }

    return useTransaction ? database.transaction(operation) : operation();
  }

  static Map<String, Object?> _compactPayload({
    required String surface,
    required RfAssessmentResult result,
    required bool appliedToPatient,
    required bool? estimateConfirmed,
    required RfReleaseAudit releaseAudit,
  }) {
    return {
      'schemaVersion': 1,
      'surface': surface,
      'protocolVersion': result.protocolVersion,
      'mode': result.mode.name,
      'status': result.status.name,
      'rfBpm': result.rfBpm,
      'rfHz': result.rfHz,
      'rfCenterElapsedMs': result.rfCenterElapsedMs,
      'peakToTroughAmplitude': result.peakToTroughAmplitude,
      'scheduledBpmAtCenter': result.scheduledBpmAtCenter,
      'fittedRespirationBpm': result.fittedRespirationBpm,
      'adherenceDeltaBpm': result.adherenceDeltaBpm,
      'respirationFitError': result.respirationFitError,
      'ectopicCorrections': result.quality.ectopicCorrections,
      'qualityPassed': result.quality.passed,
      'qualityFlags': result.quality.flags.map((flag) => flag.name).toList(),
      'appliedToPatient': appliedToPatient,
      'estimateConfirmed': estimateConfirmed,
      'releaseValidation': releaseAudit.toJson(),
    };
  }
}
