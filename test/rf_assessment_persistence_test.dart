// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:convert';

import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RF assessment persistence', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    test('stores a complete measured audit record and applies RF', () async {
      final patient = (await database.getAllPatients()).single;
      final service = RfAssessmentPersistenceService(database);
      final result = _result(RfAcquisitionMode.measured);
      final receipt = await service.persist(
        patientId: patient.id,
        surface: 'native',
        startedAt: DateTime.utc(2026, 1, 1, 10),
        endedAt: DateTime.utc(2026, 1, 1, 10, 15),
        protocol: const FisherLehrerProtocolConfig(),
        result: result,
        rrSamples: const [
          RfBeatSample(elapsedMs: 900, rrMs: 900),
          RfBeatSample(elapsedMs: 1800, rrMs: 900),
        ],
        respirationSamples: const [
          RfRespirationSample(elapsedMs: 0, value: 1),
          RfRespirationSample(elapsedMs: 100, value: 2),
        ],
        completedCycles: 78,
        appliedToPatient: true,
        estimateConfirmed: null,
      );

      final records = await database.getRfAssessmentsForPatient(patient.id);
      expect(records, hasLength(1));
      final record = records.single;
      expect(record.id, receipt.assessmentRecordId);
      expect(record.sessionSummaryId, receipt.sessionSummaryId);
      expect(record.mode, 'measured');
      expect(record.rfBpm, 5.8);
      expect(record.qualityPassed, isTrue);
      expect(record.appliedToPatient, isTrue);
      expect(record.estimateConfirmed, isNull);
      expect(jsonDecode(record.rrSamplesJson), hasLength(2));
      expect(jsonDecode(record.respirationSamplesJson!), hasLength(2));
      final protocolAudit =
          jsonDecode(record.protocolJson) as Map<String, dynamic>;
      expect(
        protocolAudit['releaseValidation']['protocolConformance']['passed'],
        isTrue,
      );
      expect(protocolAudit['releaseValidation']['rolloutStage'], 'enabled');
      expect(
        (await database.getPatientById(patient.id))!.resonanceFrequency,
        5.8,
      );

      final summaries = await database.getSessionSummaries(patient.id);
      expect(summaries.single.sessionType, 'rf_assessment');
      final extended =
          jsonDecode(summaries.single.extendedMetricsJson!)
              as Map<String, dynamic>;
      final history = RfAssessmentHistorySummary.tryParse(extended);
      expect(history, isNotNull);
      expect(history!.mode, 'measured');
      expect(history.appliedToPatient, isTrue);
      expect(history.rolloutStage, 'enabled');
      expect(history.protocolConformancePassed, isTrue);
      expect(history.protocolFingerprint, startsWith('fnv1a32-'));
    });

    test('requires confirmation before applying an estimate', () async {
      final patient = (await database.getAllPatients()).single;
      final service = RfAssessmentPersistenceService(database);

      await expectLater(
        service.persist(
          patientId: patient.id,
          surface: 'web',
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: DateTime.utc(2026, 1, 1, 0, 15),
          protocol: const FisherLehrerProtocolConfig(),
          result: _result(RfAcquisitionMode.estimated),
          rrSamples: const [],
          respirationSamples: const [],
          completedCycles: 78,
          appliedToPatient: true,
          estimateConfirmed: false,
        ),
        throwsStateError,
      );

      expect(await database.getRfAssessmentsForPatient(patient.id), isEmpty);
    });

    test('validation-only persistence cannot update the patient RF', () async {
      final patient = (await database.getAllPatients()).single;
      final service = RfAssessmentPersistenceService(database);
      final audit = RfReleaseAudit.capture(
        const FisherLehrerProtocolConfig(),
        policy: const PreciseRfRolloutPolicy(PreciseRfRolloutStage.validation),
      );

      await expectLater(
        service.persist(
          patientId: patient.id,
          surface: 'native',
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: DateTime.utc(2026, 1, 1, 0, 15),
          protocol: const FisherLehrerProtocolConfig(),
          result: _result(RfAcquisitionMode.measured),
          rrSamples: const [],
          respirationSamples: const [],
          completedCycles: 78,
          appliedToPatient: true,
          estimateConfirmed: null,
          releaseAudit: audit,
        ),
        throwsStateError,
      );

      expect(
        (await database.getPatientById(patient.id))!.resonanceFrequency,
        isNull,
      );
      expect(await database.getRfAssessmentsForPatient(patient.id), isEmpty);
    });

    test('disabled rollout rejects persistence without side effects', () async {
      final patient = (await database.getAllPatients()).single;
      final audit = RfReleaseAudit.capture(
        const FisherLehrerProtocolConfig(),
        policy: const PreciseRfRolloutPolicy(PreciseRfRolloutStage.disabled),
      );

      await expectLater(
        RfAssessmentPersistenceService(database).persist(
          patientId: patient.id,
          surface: 'web',
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: DateTime.utc(2026, 1, 1, 0, 15),
          protocol: const FisherLehrerProtocolConfig(),
          result: _result(RfAcquisitionMode.estimated),
          rrSamples: const [],
          respirationSamples: const [],
          completedCycles: 78,
          appliedToPatient: false,
          estimateConfirmed: null,
          releaseAudit: audit,
        ),
        throwsStateError,
      );

      expect(await database.getRfAssessmentsForPatient(patient.id), isEmpty);
      expect(await database.getSessionSummaries(patient.id), isEmpty);
    });

    test('mutated protocol cannot be persisted under a valid audit', () async {
      final patient = (await database.getAllPatients()).single;
      const mutated = FisherLehrerProtocolConfig(maximumAdherenceDeltaBpm: 0.6);

      await expectLater(
        RfAssessmentPersistenceService(database).persist(
          patientId: patient.id,
          surface: 'native',
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: DateTime.utc(2026, 1, 1, 0, 15),
          protocol: mutated,
          result: _result(RfAcquisitionMode.measured),
          rrSamples: const [],
          respirationSamples: const [],
          completedCycles: 78,
          appliedToPatient: false,
          estimateConfirmed: null,
        ),
        throwsStateError,
      );

      expect(await database.getRfAssessmentsForPatient(patient.id), isEmpty);
    });

    test('exports RF provenance, quality, and application state', () async {
      final patient = (await database.getAllPatients()).single;
      await RfAssessmentPersistenceService(database).persist(
        patientId: patient.id,
        surface: 'web',
        startedAt: DateTime.utc(2026, 1, 1),
        endedAt: DateTime.utc(2026, 1, 1, 0, 15),
        protocol: const FisherLehrerProtocolConfig(),
        result: _result(RfAcquisitionMode.estimated),
        rrSamples: const [],
        respirationSamples: const [],
        completedCycles: 78,
        appliedToPatient: false,
        estimateConfirmed: false,
      );

      final csv = await database.generatePatientCsv(patient.id);
      expect(csv, contains('rf_bpm,rf_mode,rf_protocol_version'));
      expect(csv, contains('rf_rollout_stage'));
      expect(csv, contains('rf_protocol_conformance_passed'));
      expect(csv, contains('rf_protocol_fingerprint'));
      expect(csv, contains('rf_assessment'));
      expect(csv, contains('estimated'));
      expect(csv, contains('enabled'));
      expect(csv, contains('fnv1a32-'));
      expect(csv, contains(FisherLehrerProtocolConfig.referenceVersion));
    });
  });

  test('schema v7 upgrades by creating the RF audit table', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE patients (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              date_of_birth TEXT NULL,
              age INTEGER NULL,
              sex TEXT NULL,
              height_cm REAL NULL,
              notes TEXT NULL,
              resonance_frequency REAL NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          raw.execute('''
            CREATE TABLE session_summaries (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              patient_id INTEGER NOT NULL REFERENCES patients(id)
                ON DELETE CASCADE,
              session_type TEXT NOT NULL DEFAULT 'recording',
              started_at TEXT NOT NULL,
              ended_at TEXT NULL,
              duration_seconds INTEGER NOT NULL DEFAULT 0,
              breath_rate INTEGER NULL,
              breath_source TEXT NULL,
              avg_heart_rate REAL NULL,
              min_heart_rate INTEGER NULL,
              max_heart_rate INTEGER NULL,
              rmssd REAL NULL,
              sdnn REAL NULL,
              mean_nn REAL NULL,
              pnn50 REAL NULL,
              hr_readings_json TEXT NULL,
              extended_metrics_json TEXT NULL
            )
          ''');
          raw.execute('PRAGMA user_version = 7');
        },
      ),
    );
    addTearDown(database.close);

    final tables =
        await database
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type = 'table' AND name = 'rf_assessment_records'",
            )
            .get();
    expect(tables, hasLength(1));
  });
}

RfAssessmentResult _result(RfAcquisitionMode mode) => RfAssessmentResult(
  protocolVersion: FisherLehrerProtocolConfig.referenceVersion,
  mode: mode,
  status: RfResultStatus.completed,
  rfBpm: 5.8,
  rfCenterElapsedMs: 600000,
  peakToTroughAmplitude: 122,
  scheduledBpmAtCenter: 5.75,
  fittedRespirationBpm: mode == RfAcquisitionMode.measured ? 5.79 : null,
  adherenceDeltaBpm: mode == RfAcquisitionMode.measured ? 0.04 : null,
  respirationFitError: mode == RfAcquisitionMode.measured ? 0.02 : null,
  quality: const RfQualityReport(
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
  trace: const RfAnalysisTrace(),
);
