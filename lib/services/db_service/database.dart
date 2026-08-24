library;

import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:breath_state/services/db_service/connection.dart' as conn;
import 'package:breath_state/services/biofeedback/signal_quality_index.dart';
import 'package:breath_state/services/ecg_respiration/ecg_rpeak_detector.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';

part 'database.g.dart';

class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get dateOfBirth => text().nullable()();
  IntColumn get age => integer().nullable()();
  TextColumn get sex => text().nullable()();
  RealColumn get heightCm => real().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get resonanceFrequency => real().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  TextColumn get sessionType => text()();
  TextColumn get startedAt => text()();
  TextColumn get endedAt => text().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('BreathRateEntry')
class BreathRateEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  TextColumn get timestamp => text()();
  IntColumn get rate => integer()();
  TextColumn get source => text().withDefault(const Constant('microphone'))();
}

@DataClassName('HeartRateEntry')
class HeartRateEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  TextColumn get timestamp => text()();
  IntColumn get rate => integer()();
}

@DataClassName('EcgSampleEntry')
class EcgSampleEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  IntColumn get timestampMs => integer()();
  IntColumn get timestampUs => integer().nullable()();
  IntColumn get elapsedMs => integer()();
  IntColumn get elapsedUs => integer().nullable()();
  IntColumn get sampleIndex => integer()();
  RealColumn get ecgUv => real()();
}

@DataClassName('HrvEntry')
class HrvEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  TextColumn get timestamp => text()();

  RealColumn get meanNn => real().nullable()();
  RealColumn get sdnn => real().nullable()();
  RealColumn get rmssd => real().nullable()();
  RealColumn get sdsd => real().nullable()();
  RealColumn get cvnn => real().nullable()();
  RealColumn get cvsd => real().nullable()();
  RealColumn get medianNn => real().nullable()();
  RealColumn get madNn => real().nullable()();
  RealColumn get mcvnn => real().nullable()();
  RealColumn get iqrnn => real().nullable()();
  RealColumn get sdrmssd => real().nullable()();
  RealColumn get prc20nn => real().nullable()();
  RealColumn get prc80nn => real().nullable()();
  RealColumn get pnn50 => real().nullable()();
  RealColumn get pnn20 => real().nullable()();
  RealColumn get minNn => real().nullable()();
  RealColumn get maxNn => real().nullable()();
  RealColumn get hti => real().nullable()();
  RealColumn get tinn => real().nullable()();
  RealColumn get sdann1 => real().nullable()();
  RealColumn get sdann2 => real().nullable()();
  RealColumn get sdann5 => real().nullable()();
  RealColumn get sdnni1 => real().nullable()();
  RealColumn get sdnni2 => real().nullable()();
  RealColumn get sdnni5 => real().nullable()();
}

@DataClassName('PsychometricEntry')
class PsychometricEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  TextColumn get scaleType => text()();
  IntColumn get totalScore => integer()();
  TextColumn get severityLevel => text()();
  TextColumn get responsesJson => text()();
  TextColumn get administeredAt => text()();
  TextColumn get administeredBy => text().nullable()();
  BoolColumn get requiresReview =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
}

@DataClassName('SessionSummary')
class SessionSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  TextColumn get sessionType =>
      text().withDefault(const Constant('recording'))();
  TextColumn get startedAt => text()();
  TextColumn get endedAt => text().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  IntColumn get breathRate => integer().nullable()();
  TextColumn get breathSource => text().nullable()();

  RealColumn get avgHeartRate => real().nullable()();
  IntColumn get minHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();

  RealColumn get rmssd => real().nullable()();
  RealColumn get sdnn => real().nullable()();
  RealColumn get meanNn => real().nullable()();
  RealColumn get pnn50 => real().nullable()();

  TextColumn get hrReadingsJson => text().nullable()();
  TextColumn get extendedMetricsJson => text().nullable()();
}

@DataClassName('RfAssessmentRecord')
class RfAssessmentRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  IntColumn get sessionSummaryId =>
      integer().nullable().references(
        SessionSummaries,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get surface => text()();
  TextColumn get protocolVersion => text()();
  TextColumn get mode => text()();
  TextColumn get status => text()();
  TextColumn get startedAt => text()();
  TextColumn get endedAt => text()();
  RealColumn get durationMs => real()();
  IntColumn get completedCycles => integer()();
  RealColumn get rfBpm => real().nullable()();
  RealColumn get rfCenterElapsedMs => real().nullable()();
  RealColumn get peakToTroughAmplitude => real().nullable()();
  RealColumn get scheduledBpmAtCenter => real().nullable()();
  RealColumn get fittedRespirationBpm => real().nullable()();
  RealColumn get adherenceDeltaBpm => real().nullable()();
  RealColumn get respirationFitError => real().nullable()();
  IntColumn get ectopicCorrections => integer()();
  BoolColumn get qualityPassed => boolean()();
  TextColumn get qualityFlagsJson => text()();
  BoolColumn get appliedToPatient =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get estimateConfirmed => boolean().nullable()();
  TextColumn get protocolJson => text()();
  TextColumn get resultJson => text()();
  TextColumn get rrSamplesJson => text()();
  TextColumn get respirationSamplesJson => text().nullable()();
  TextColumn get createdAt => text()();
}

@DriftDatabase(
  tables: [
    Patients,
    Sessions,
    BreathRateEntries,
    HeartRateEntries,
    EcgSampleEntries,
    HrvEntries,
    PsychometricEntries,
    SessionSummaries,
    RfAssessmentRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _instance;

  factory AppDatabase() {
    _instance ??= AppDatabase._internal(conn.connectDatabase());
    return _instance!;
  }

  AppDatabase._internal(super.e);
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      final now = DateTime.now().toIso8601String();
      await into(patients).insert(
        PatientsCompanion(
          name: const Value('Self'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(sessionSummaries);
      }
      if (from < 3) {
        await m.addColumn(sessionSummaries, sessionSummaries.hrReadingsJson);
        await m.addColumn(
          sessionSummaries,
          sessionSummaries.extendedMetricsJson,
        );
      }
      if (from < 4) {
        await m.createTable(ecgSampleEntries);
      }
      if (from < 5) {
        await m.addColumn(patients, patients.age);
        await m.addColumn(patients, patients.sex);
      }
      if (from < 6) {
        await m.addColumn(ecgSampleEntries, ecgSampleEntries.timestampUs);
        await m.addColumn(ecgSampleEntries, ecgSampleEntries.elapsedUs);
      }
      if (from < 7) {
        await m.addColumn(patients, patients.heightCm);
        await m.createTable(psychometricEntries);
      }
      if (from < 8) {
        await m.createTable(rfAssessmentRecords);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<List<Patient>> getAllPatients() => select(patients).get();
  Stream<List<Patient>> watchAllPatients() => select(patients).watch();

  Future<Patient?> getPatientById(int id) =>
      (select(patients)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Patient> createPatient({
    required String name,
    String? dateOfBirth,
    int? age,
    String? sex,
    double? heightCm,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = await into(patients).insert(
      PatientsCompanion(
        name: Value(name),
        dateOfBirth: Value(dateOfBirth),
        age: Value(age),
        sex: Value(sex),
        heightCm: Value(heightCm),
        notes: Value(notes),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return (await getPatientById(id))!;
  }

  Future<void> updatePatientInfo({
    required int id,
    required String name,
    int? age,
    String? sex,
    double? heightCm,
    String? notes,
  }) async {
    await (update(patients)..where((p) => p.id.equals(id))).write(
      PatientsCompanion(
        name: Value(name),
        age: Value(age),
        sex: Value(sex),
        heightCm: Value(heightCm),
        notes: Value(notes),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> updatePatientResonanceFrequency(int id, double frequency) async {
    await (update(patients)..where((p) => p.id.equals(id))).write(
      PatientsCompanion(
        resonanceFrequency: Value(frequency),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> deletePatient(int id) async {
    await (delete(patients)..where((p) => p.id.equals(id))).go();
  }

  Future<int> createSession({
    required int patientId,
    required String sessionType,
  }) async {
    return into(sessions).insert(
      SessionsCompanion(
        patientId: Value(patientId),
        sessionType: Value(sessionType),
        startedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> endSession(int sessionId) async {
    await (update(sessions)..where((s) => s.id.equals(sessionId))).write(
      SessionsCompanion(endedAt: Value(DateTime.now().toIso8601String())),
    );
  }

  Future<List<Session>> getSessionsForPatient(int patientId) {
    return (select(sessions)
          ..where((s) => s.patientId.equals(patientId))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
  }

  Future<int> insertSessionSummary({
    required int patientId,
    String sessionType = 'recording',
    required String startedAt,
    String? endedAt,
    int durationSeconds = 0,
    int? breathRate,
    String? breathSource,
    double? avgHeartRate,
    int? minHeartRate,
    int? maxHeartRate,
    double? rmssd,
    double? sdnn,
    double? meanNn,
    double? pnn50,
    String? hrReadingsJson,
    String? extendedMetricsJson,
  }) async {
    return into(sessionSummaries).insert(
      SessionSummariesCompanion(
        patientId: Value(patientId),
        sessionType: Value(sessionType),
        startedAt: Value(startedAt),
        endedAt: Value(endedAt),
        durationSeconds: Value(durationSeconds),
        breathRate: Value(breathRate),
        breathSource: Value(breathSource),
        avgHeartRate: Value(avgHeartRate),
        minHeartRate: Value(minHeartRate),
        maxHeartRate: Value(maxHeartRate),
        rmssd: Value(rmssd),
        sdnn: Value(sdnn),
        meanNn: Value(meanNn),
        pnn50: Value(pnn50),
        hrReadingsJson: Value(hrReadingsJson),
        extendedMetricsJson: Value(extendedMetricsJson),
      ),
    );
  }

  Future<int> insertRfAssessmentRecord({
    required int patientId,
    required int sessionSummaryId,
    required String surface,
    required String protocolVersion,
    required String mode,
    required String status,
    required String startedAt,
    required String endedAt,
    required double durationMs,
    required int completedCycles,
    double? rfBpm,
    double? rfCenterElapsedMs,
    double? peakToTroughAmplitude,
    double? scheduledBpmAtCenter,
    double? fittedRespirationBpm,
    double? adherenceDeltaBpm,
    double? respirationFitError,
    required int ectopicCorrections,
    required bool qualityPassed,
    required String qualityFlagsJson,
    required bool appliedToPatient,
    bool? estimateConfirmed,
    required String protocolJson,
    required String resultJson,
    required String rrSamplesJson,
    String? respirationSamplesJson,
  }) {
    return into(rfAssessmentRecords).insert(
      RfAssessmentRecordsCompanion(
        patientId: Value(patientId),
        sessionSummaryId: Value(sessionSummaryId),
        surface: Value(surface),
        protocolVersion: Value(protocolVersion),
        mode: Value(mode),
        status: Value(status),
        startedAt: Value(startedAt),
        endedAt: Value(endedAt),
        durationMs: Value(durationMs),
        completedCycles: Value(completedCycles),
        rfBpm: Value(rfBpm),
        rfCenterElapsedMs: Value(rfCenterElapsedMs),
        peakToTroughAmplitude: Value(peakToTroughAmplitude),
        scheduledBpmAtCenter: Value(scheduledBpmAtCenter),
        fittedRespirationBpm: Value(fittedRespirationBpm),
        adherenceDeltaBpm: Value(adherenceDeltaBpm),
        respirationFitError: Value(respirationFitError),
        ectopicCorrections: Value(ectopicCorrections),
        qualityPassed: Value(qualityPassed),
        qualityFlagsJson: Value(qualityFlagsJson),
        appliedToPatient: Value(appliedToPatient),
        estimateConfirmed: Value(estimateConfirmed),
        protocolJson: Value(protocolJson),
        resultJson: Value(resultJson),
        rrSamplesJson: Value(rrSamplesJson),
        respirationSamplesJson: Value(respirationSamplesJson),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<List<RfAssessmentRecord>> getRfAssessmentsForPatient(int patientId) {
    return (select(rfAssessmentRecords)
          ..where((record) => record.patientId.equals(patientId))
          ..orderBy([(record) => OrderingTerm.desc(record.startedAt)]))
        .get();
  }

  Future<RfAssessmentRecord?> getRfAssessmentForSummary(int summaryId) {
    return (select(rfAssessmentRecords)..where(
      (record) => record.sessionSummaryId.equals(summaryId),
    )).getSingleOrNull();
  }

  Stream<List<RfAssessmentRecord>> watchRfAssessmentsForPatient(int patientId) {
    return (select(rfAssessmentRecords)
          ..where((record) => record.patientId.equals(patientId))
          ..orderBy([(record) => OrderingTerm.desc(record.startedAt)]))
        .watch();
  }

  Future<List<SessionSummary>> getSessionSummaries(int patientId) {
    return (select(sessionSummaries)
          ..where((s) => s.patientId.equals(patientId))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
  }

  Stream<List<SessionSummary>> watchSessionSummariesForPatient(int patientId) {
    return (select(sessionSummaries)
          ..where((s) => s.patientId.equals(patientId))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .watch();
  }

  Future<void> deleteSessionSummary(int id) async {
    await (delete(sessionSummaries)..where((s) => s.id.equals(id))).go();
  }

  Future<void> insertBreathRate({
    required int sessionId,
    required int patientId,
    required int rate,
    String source = 'microphone',
    String? timestamp,
  }) async {
    await into(breathRateEntries).insert(
      BreathRateEntriesCompanion(
        sessionId: Value(sessionId),
        patientId: Value(patientId),
        timestamp: Value(timestamp ?? DateTime.now().toIso8601String()),
        rate: Value(rate),
        source: Value(source),
      ),
    );
  }

  Future<List<BreathRateEntry>> getBreathRatesForPatient(int patientId) {
    return (select(breathRateEntries)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.asc(e.timestamp)]))
        .get();
  }

  Stream<List<BreathRateEntry>> watchBreathRatesForPatient(int patientId) {
    return (select(breathRateEntries)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.asc(e.timestamp)]))
        .watch();
  }

  Future<void> insertHeartRate({
    required int sessionId,
    required int patientId,
    required int rate,
    String? timestamp,
  }) async {
    await into(heartRateEntries).insert(
      HeartRateEntriesCompanion(
        sessionId: Value(sessionId),
        patientId: Value(patientId),
        timestamp: Value(timestamp ?? DateTime.now().toIso8601String()),
        rate: Value(rate),
      ),
    );
  }

  Future<List<HeartRateEntry>> getHeartRatesForPatient(int patientId) {
    return (select(heartRateEntries)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.asc(e.timestamp)]))
        .get();
  }

  Stream<List<HeartRateEntry>> watchHeartRatesForPatient(int patientId) {
    return (select(heartRateEntries)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.asc(e.timestamp)]))
        .watch();
  }

  Future<void> insertEcgSamples({
    required int sessionId,
    required int patientId,
    required Iterable<EcgSamplePoint> samples,
  }) async {
    final entries = samples
        .map(
          (s) => EcgSampleEntriesCompanion.insert(
            sessionId: sessionId,
            patientId: patientId,
            timestampMs: s.timestampMs,
            timestampUs: Value(s.timestampUs),
            elapsedMs: s.elapsedMs,
            elapsedUs: Value(s.elapsedUs),
            sampleIndex: s.sampleIndex,
            ecgUv: s.ecgUv,
          ),
        )
        .toList(growable: false);
    if (entries.isEmpty) return;

    await batch((b) => b.insertAll(ecgSampleEntries, entries));
  }

  Future<List<EcgSampleEntry>> getEcgSamplesForPatient(int patientId) {
    return (select(ecgSampleEntries)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.asc(e.timestampMs)]))
        .get();
  }

  Future<void> insertHrvResult({
    required int sessionId,
    required int patientId,
    required HrvTimeDomainResult result,
  }) async {
    final m = result.toMap();
    await into(hrvEntries).insert(
      HrvEntriesCompanion(
        sessionId: Value(sessionId),
        patientId: Value(patientId),
        timestamp: Value(DateTime.now().toIso8601String()),
        meanNn: Value(m['HRV_MeanNN']),
        sdnn: Value(m['HRV_SDNN']),
        rmssd: Value(m['HRV_RMSSD']),
        sdsd: Value(m['HRV_SDSD']),
        cvnn: Value(m['HRV_CVNN']),
        cvsd: Value(m['HRV_CVSD']),
        medianNn: Value(m['HRV_MedianNN']),
        madNn: Value(m['HRV_MadNN']),
        mcvnn: Value(m['HRV_MCVNN']),
        iqrnn: Value(m['HRV_IQRNN']),
        sdrmssd: Value(m['HRV_SDRMSSD']),
        prc20nn: Value(m['HRV_Prc20NN']),
        prc80nn: Value(m['HRV_Prc80NN']),
        pnn50: Value(m['HRV_pNN50']),
        pnn20: Value(m['HRV_pNN20']),
        minNn: Value(m['HRV_MinNN']),
        maxNn: Value(m['HRV_MaxNN']),
        hti: Value(m['HRV_HTI']),
        tinn: Value(m['HRV_TINN']),
        sdann1: Value(m['HRV_SDANN1']),
        sdann2: Value(m['HRV_SDANN2']),
        sdann5: Value(m['HRV_SDANN5']),
        sdnni1: Value(m['HRV_SDNNI1']),
        sdnni2: Value(m['HRV_SDNNI2']),
        sdnni5: Value(m['HRV_SDNNI5']),
      ),
    );
  }

  Future<List<HrvEntry>> getHrvEntriesForPatient(int patientId) {
    return (select(hrvEntries)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]))
        .get();
  }

  Future<int> insertPsychometricEntry({
    required int patientId,
    required String scaleType,
    required int totalScore,
    required String severityLevel,
    required String responsesJson,
    String? administeredAt,
    String? administeredBy,
    bool requiresReview = false,
    String? notes,
  }) {
    return into(psychometricEntries).insert(
      PsychometricEntriesCompanion(
        patientId: Value(patientId),
        scaleType: Value(scaleType),
        totalScore: Value(totalScore),
        severityLevel: Value(severityLevel),
        responsesJson: Value(responsesJson),
        administeredAt: Value(
          administeredAt ?? DateTime.now().toIso8601String(),
        ),
        administeredBy: Value(administeredBy),
        requiresReview: Value(requiresReview),
        notes: Value(notes),
      ),
    );
  }

  Future<List<PsychometricEntry>> getPsychometricEntriesForPatient(
    int patientId,
  ) {
    return (select(psychometricEntries)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.desc(e.administeredAt)]))
        .get();
  }

  Stream<List<PsychometricEntry>> watchPsychometricEntriesForPatient(
    int patientId,
  ) {
    return (select(psychometricEntries)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.desc(e.administeredAt)]))
        .watch();
  }

  Future<void> deletePsychometricEntry(int id) async {
    await (delete(psychometricEntries)..where((e) => e.id.equals(id))).go();
  }

  static const List<String> _patientExportColumns = [
    'patient_id',
    'patient_name',
    'patient_age',
    'patient_sex',
    'patient_height_cm',
    'timestamp_us',
    'timestamp_ms',
    'elapsed_us',
    'elapsed_ms',
    'sample_index',
    'signal_quality',
    'ecg_rr_ms',
    'hr_bpm',
    'rr_bpm',
    'rmssd',
    'sdnn',
    'stress_index',
    'psychometric_scale',
    'psychometric_score',
    'psychometric_severity',
    'row_type',
    'session_id',
    'source',
    'rf_bpm',
    'rf_mode',
    'rf_protocol_version',
    'rf_quality_passed',
    'rf_quality_flags',
    'rf_applied_to_patient',
    'rf_estimate_confirmed',
    'rf_peak_to_trough_ms',
    'rf_scheduled_bpm',
    'rf_measured_respiration_bpm',
    'rf_ectopic_corrections',
    'rf_rollout_stage',
    'rf_protocol_conformance_passed',
    'rf_protocol_fingerprint',
    'patient_date_of_birth',
    'patient_notes',
    'patient_resonance_frequency_bpm',
    'patient_created_at',
    'patient_updated_at',
    'record_id',
    'summary_id',
    'session_summary_id',
    'session_type',
    'session_started_at',
    'session_ended_at',
    'session_notes',
    'session_duration_seconds',
    'source_timestamp',
    'measurement_rate_bpm',
    'ecg_uv',
    'ecg_source',
    'hrv_mean_nn',
    'hrv_sdnn',
    'hrv_rmssd',
    'hrv_sdsd',
    'hrv_cvnn',
    'hrv_cvsd',
    'hrv_median_nn',
    'hrv_mad_nn',
    'hrv_mcvnn',
    'hrv_iqrnn',
    'hrv_sdrmssd',
    'hrv_prc20nn',
    'hrv_prc80nn',
    'hrv_pnn50',
    'hrv_pnn20',
    'hrv_min_nn',
    'hrv_max_nn',
    'hrv_hti',
    'hrv_tinn',
    'hrv_sdann1',
    'hrv_sdann2',
    'hrv_sdann5',
    'hrv_sdnni1',
    'hrv_sdnni2',
    'hrv_sdnni5',
    'psychometric_responses_json',
    'psychometric_administered_at',
    'psychometric_administered_by',
    'psychometric_requires_review',
    'psychometric_notes',
    'summary_breath_rate',
    'summary_breath_source',
    'summary_avg_heart_rate',
    'summary_min_heart_rate',
    'summary_max_heart_rate',
    'summary_mean_nn',
    'summary_pnn50',
    'summary_hr_readings_json',
    'summary_extended_metrics_json',
    'rf_assessment_id',
    'rf_status',
    'rf_duration_ms',
    'rf_completed_cycles',
    'rf_center_elapsed_ms',
    'rf_adherence_delta_bpm',
    'rf_respiration_fit_error',
    'rf_quality_flags_json',
    'rf_protocol_json',
    'rf_result_json',
    'rf_rr_samples_json',
    'rf_respiration_samples_json',
    'rf_created_at',
  ];

  Future<String> generatePatientCsv(int patientId) async {
    final patient = await getPatientById(patientId);
    if (patient == null) {
      throw StateError('Cannot export an unknown patient (id $patientId).');
    }

    final breathList = await getBreathRatesForPatient(patientId);
    final heartList = await getHeartRatesForPatient(patientId);
    final ecgList = await getEcgSamplesForPatient(patientId);
    final hrvList = await getHrvEntriesForPatient(patientId);
    final psychometricList = await getPsychometricEntriesForPatient(patientId);
    final summaryList = await getSessionSummaries(patientId);
    final rfAssessmentList = await getRfAssessmentsForPatient(patientId);
    final sessionsList = await getSessionsForPatient(patientId);
    final sessionStarts = {
      for (final s in sessionsList)
        s.id: DateTime.tryParse(s.startedAt)?.millisecondsSinceEpoch,
    };
    final patientFields = _PatientExportFields.from(patient);
    final ecgRrByEntryId = _ecgRrIntervalsByEntryId(ecgList);

    final buf = StringBuffer();
    buf.writeln(_patientMetadataLine(patient));
    buf.writeln(_patientExportColumns.join(','));

    final rows = <_ExportRow>[];

    rows.add(
      _ExportRow(
        rowType: 'patient',
        fields: {'record_id': patient.id, 'source': 'database'},
      ),
    );

    for (final session in sessionsList) {
      final startedMs = _parseTimestampMs(session.startedAt);
      rows.add(
        _ExportRow(
          timestampUs: startedMs == null ? null : startedMs * 1000,
          timestampMs: startedMs,
          elapsedUs: 0,
          elapsedMs: 0,
          rowType: 'session',
          fields: {
            'record_id': session.id,
            'session_id': session.id,
            'source': 'database',
            'session_type': session.sessionType,
            'session_started_at': session.startedAt,
            'session_ended_at': session.endedAt,
            'session_notes': session.notes,
          },
        ),
      );
    }

    for (final e in ecgList) {
      final ecgRr = ecgRrByEntryId[e.id];
      rows.add(
        _ExportRow(
          timestampUs: e.timestampUs ?? e.timestampMs * 1000,
          timestampMs: e.timestampMs,
          elapsedUs: e.elapsedUs ?? e.elapsedMs * 1000,
          elapsedMs: e.elapsedMs,
          sampleIndex: e.sampleIndex,
          signalQuality: ecgRr?.signalQuality,
          ecgRrMs: ecgRr?.rrMs,
          rowType: 'ecg',
          fields: {
            'record_id': e.id,
            'session_id': e.sessionId,
            'source': 'polar',
            'ecg_uv': e.ecgUv,
            'ecg_source': 'polar',
          },
        ),
      );
    }

    final rrHistoryBySession = <int, List<double>>{};
    for (final e in heartList) {
      final timestampMs = _parseTimestampMs(e.timestamp);
      final rrMs = e.rate > 0 ? 60000.0 / e.rate : 0.0;
      final history = rrHistoryBySession.putIfAbsent(e.sessionId, () => []);
      final sqi = rrMs > 0 ? SignalQualityIndex.classify(rrMs, history) : null;
      if (rrMs > 0) history.add(rrMs);

      rows.add(
        _ExportRow(
          timestampUs: timestampMs == null ? null : timestampMs * 1000,
          timestampMs: timestampMs,
          elapsedUs:
              _elapsedMs(timestampMs, sessionStarts[e.sessionId]) == null
                  ? null
                  : _elapsedMs(timestampMs, sessionStarts[e.sessionId])! * 1000,
          elapsedMs: _elapsedMs(timestampMs, sessionStarts[e.sessionId]),
          signalQuality: sqi == null ? null : _sqiLabel(sqi.level),
          hrBpm: e.rate,
          rowType: 'heart_rate',
          fields: {
            'record_id': e.id,
            'session_id': e.sessionId,
            'source': 'polar',
            'source_timestamp': e.timestamp,
            'measurement_rate_bpm': e.rate,
          },
        ),
      );
    }

    for (final e in breathList) {
      final timestampMs = _parseTimestampMs(e.timestamp);
      rows.add(
        _ExportRow(
          timestampUs: timestampMs == null ? null : timestampMs * 1000,
          timestampMs: timestampMs,
          elapsedUs:
              _elapsedMs(timestampMs, sessionStarts[e.sessionId]) == null
                  ? null
                  : _elapsedMs(timestampMs, sessionStarts[e.sessionId])! * 1000,
          elapsedMs: _elapsedMs(timestampMs, sessionStarts[e.sessionId]),
          rrBpm: e.rate,
          rowType: 'breath_rate',
          fields: {
            'record_id': e.id,
            'session_id': e.sessionId,
            'source': e.source,
            'source_timestamp': e.timestamp,
            'measurement_rate_bpm': e.rate,
          },
        ),
      );
    }

    for (final e in hrvList) {
      final timestampMs = _parseTimestampMs(e.timestamp);
      rows.add(
        _ExportRow(
          timestampUs: timestampMs == null ? null : timestampMs * 1000,
          timestampMs: timestampMs,
          elapsedUs:
              _elapsedMs(timestampMs, sessionStarts[e.sessionId]) == null
                  ? null
                  : _elapsedMs(timestampMs, sessionStarts[e.sessionId])! * 1000,
          elapsedMs: _elapsedMs(timestampMs, sessionStarts[e.sessionId]),
          rmssd: e.rmssd,
          sdnn: e.sdnn,
          rowType: 'hrv',
          fields: {
            'record_id': e.id,
            'session_id': e.sessionId,
            'source': 'polar',
            'source_timestamp': e.timestamp,
            'hrv_mean_nn': e.meanNn,
            'hrv_sdnn': e.sdnn,
            'hrv_rmssd': e.rmssd,
            'hrv_sdsd': e.sdsd,
            'hrv_cvnn': e.cvnn,
            'hrv_cvsd': e.cvsd,
            'hrv_median_nn': e.medianNn,
            'hrv_mad_nn': e.madNn,
            'hrv_mcvnn': e.mcvnn,
            'hrv_iqrnn': e.iqrnn,
            'hrv_sdrmssd': e.sdrmssd,
            'hrv_prc20nn': e.prc20nn,
            'hrv_prc80nn': e.prc80nn,
            'hrv_pnn50': e.pnn50,
            'hrv_pnn20': e.pnn20,
            'hrv_min_nn': e.minNn,
            'hrv_max_nn': e.maxNn,
            'hrv_hti': e.hti,
            'hrv_tinn': e.tinn,
            'hrv_sdann1': e.sdann1,
            'hrv_sdann2': e.sdann2,
            'hrv_sdann5': e.sdann5,
            'hrv_sdnni1': e.sdnni1,
            'hrv_sdnni2': e.sdnni2,
            'hrv_sdnni5': e.sdnni5,
          },
        ),
      );
    }

    for (final e in psychometricList) {
      final timestampMs = _parseTimestampMs(e.administeredAt);
      rows.add(
        _ExportRow(
          timestampUs: timestampMs == null ? null : timestampMs * 1000,
          timestampMs: timestampMs,
          elapsedUs: null,
          elapsedMs: null,
          psychometricScale: e.scaleType,
          psychometricScore: e.totalScore,
          psychometricSeverity: e.severityLevel,
          rowType: 'psychometric',
          fields: {
            'record_id': e.id,
            'source': e.administeredBy,
            'source_timestamp': e.administeredAt,
            'psychometric_responses_json': e.responsesJson,
            'psychometric_administered_at': e.administeredAt,
            'psychometric_administered_by': e.administeredBy,
            'psychometric_requires_review': e.requiresReview,
            'psychometric_notes': e.notes,
          },
        ),
      );
    }

    for (final s in summaryList) {
      final startedMs = _parseTimestampMs(s.startedAt);
      final timestampMs = _parseTimestampMs(s.endedAt ?? s.startedAt);
      rows.add(
        _ExportRow(
          timestampUs: timestampMs == null ? null : timestampMs * 1000,
          timestampMs: timestampMs,
          elapsedUs:
              _elapsedMs(timestampMs, startedMs) == null
                  ? null
                  : _elapsedMs(timestampMs, startedMs)! * 1000,
          elapsedMs: _elapsedMs(timestampMs, startedMs),
          hrBpm: s.avgHeartRate,
          rrBpm: s.breathRate,
          rmssd: s.rmssd,
          sdnn: s.sdnn,
          stressIndex: _stressIndexFromSummary(s),
          rowType: 'session_summary',
          fields: {
            'record_id': s.id,
            'summary_id': s.id,
            'source': s.breathSource,
            'session_type': s.sessionType,
            'session_started_at': s.startedAt,
            'session_ended_at': s.endedAt,
            'session_duration_seconds': s.durationSeconds,
            'summary_breath_rate': s.breathRate,
            'summary_breath_source': s.breathSource,
            'summary_avg_heart_rate': s.avgHeartRate,
            'summary_min_heart_rate': s.minHeartRate,
            'summary_max_heart_rate': s.maxHeartRate,
            'summary_mean_nn': s.meanNn,
            'summary_pnn50': s.pnn50,
            'summary_hr_readings_json': s.hrReadingsJson,
            'summary_extended_metrics_json': s.extendedMetricsJson,
          },
        ),
      );
    }

    for (final record in rfAssessmentList) {
      final timestampMs = _parseTimestampMs(record.endedAt);
      final release = _rfReleaseExportFields(record.protocolJson);
      rows.add(
        _ExportRow(
          timestampUs: timestampMs == null ? null : timestampMs * 1000,
          timestampMs: timestampMs,
          elapsedUs: (record.durationMs * 1000).round(),
          elapsedMs: record.durationMs.round(),
          rrBpm: record.fittedRespirationBpm,
          rowType: 'rf_assessment',
          fields: {
            'record_id': record.id,
            'source': record.surface,
            'session_summary_id': record.sessionSummaryId,
            'rf_assessment_id': record.id,
            'rf_status': record.status,
            'rf_duration_ms': record.durationMs,
            'rf_completed_cycles': record.completedCycles,
            'rf_center_elapsed_ms': record.rfCenterElapsedMs,
            'rf_adherence_delta_bpm': record.adherenceDeltaBpm,
            'rf_respiration_fit_error': record.respirationFitError,
            'rf_quality_flags_json': record.qualityFlagsJson,
            'rf_protocol_json': record.protocolJson,
            'rf_result_json': record.resultJson,
            'rf_rr_samples_json': record.rrSamplesJson,
            'rf_respiration_samples_json': record.respirationSamplesJson,
            'rf_created_at': record.createdAt,
          },
          rfBpm: record.rfBpm,
          rfMode: record.mode,
          rfProtocolVersion: record.protocolVersion,
          rfQualityPassed: record.qualityPassed,
          rfQualityFlags: record.qualityFlagsJson,
          rfAppliedToPatient: record.appliedToPatient,
          rfEstimateConfirmed: record.estimateConfirmed,
          rfPeakToTroughMs: record.peakToTroughAmplitude,
          rfScheduledBpm: record.scheduledBpmAtCenter,
          rfMeasuredRespirationBpm: record.fittedRespirationBpm,
          rfEctopicCorrections: record.ectopicCorrections,
          rfRolloutStage: release.rolloutStage,
          rfProtocolConformancePassed: release.conformancePassed,
          rfProtocolFingerprint: release.fingerprint,
        ),
      );
    }

    rows.sort((a, b) {
      final aTime =
          a.timestampUs ??
          (a.timestampMs == null ? null : a.timestampMs! * 1000);
      final bTime =
          b.timestampUs ??
          (b.timestampMs == null ? null : b.timestampMs! * 1000);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final byTime = aTime.compareTo(bTime);
      if (byTime != 0) return byTime;
      final bySample = (a.sampleIndex ?? -1).compareTo(b.sampleIndex ?? -1);
      if (bySample != 0) return bySample;
      final byType = a.rowType.compareTo(b.rowType);
      if (byType != 0) return byType;
      return (a.fields['record_id'] as int? ?? -1).compareTo(
        b.fields['record_id'] as int? ?? -1,
      );
    });

    for (final row in rows) {
      buf.writeln(row.toCsvLine(patientFields));
    }

    return buf.toString();
  }

  static int? _parseTimestampMs(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return null;
    return DateTime.tryParse(timestamp)?.millisecondsSinceEpoch;
  }

  static int? _elapsedMs(int? timestampMs, int? sessionStartedMs) {
    if (timestampMs == null || sessionStartedMs == null) return null;
    return timestampMs - sessionStartedMs;
  }

  static String _patientMetadataLine(Patient? patient) {
    if (patient == null) return 'patient_id=';
    final values = [
      'export_schema_version=2',
      'patient_id=${patient.id}',
      'patient_name=${patient.name}',
      'patient_age=${patient.age ?? ''}',
      'patient_sex=${patient.sex ?? ''}',
      'patient_height_cm=${patient.heightCm ?? ''}',
      'patient_date_of_birth=${patient.dateOfBirth ?? ''}',
      'notes=${patient.notes ?? ''}',
      'resonance_frequency_bpm=${patient.resonanceFrequency ?? ''}',
      'created_at=${patient.createdAt}',
      'updated_at=${patient.updatedAt}',
      'exported_at=${DateTime.now().toIso8601String()}',
    ];
    return values.map(_csvCell).join(',');
  }

  static Map<int, _DetectedEcgRr> _ecgRrIntervalsByEntryId(
    List<EcgSampleEntry> ecgList,
  ) {
    final bySession = <int, List<EcgSampleEntry>>{};
    for (final sample in ecgList) {
      bySession.putIfAbsent(sample.sessionId, () => []).add(sample);
    }

    final result = <int, _DetectedEcgRr>{};
    for (final sessionSamples in bySession.values) {
      sessionSamples.sort((a, b) {
        final byIndex = a.sampleIndex.compareTo(b.sampleIndex);
        return byIndex != 0 ? byIndex : a.timestampMs.compareTo(b.timestampMs);
      });
      if (sessionSamples.length < 10) continue;

      final detection = EcgRPeakDetector.detect(
        sessionSamples.map((sample) => sample.ecgUv).toList(growable: false),
        sampleRate: EcgRPeakDetector.defaultSampleRate,
      );
      final peaks = detection.normalPeaks;
      if (peaks.length < 2) continue;

      final rrHistory = <double>[];
      for (var i = 1; i < peaks.length; i++) {
        final previous = peaks[i - 1];
        final current = peaks[i];
        final rrMs =
            (current.sampleIndex - previous.sampleIndex) /
            EcgRPeakDetector.defaultSampleRate *
            1000.0;
        if (!rrMs.isFinite || rrMs <= 0) continue;
        if (current.sampleIndex < 0 ||
            current.sampleIndex >= sessionSamples.length) {
          continue;
        }

        final sqi = SignalQualityIndex.classify(rrMs, rrHistory);
        rrHistory.add(rrMs);
        result[sessionSamples[current.sampleIndex].id] = _DetectedEcgRr(
          rrMs: rrMs,
          signalQuality: _sqiLabel(sqi.level),
        );
      }
    }

    return result;
  }

  static double? _stressIndexFromSummary(SessionSummary summary) {
    final raw = summary.extendedMetricsJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final psych = decoded['psych'];
      if (psych is! Map<String, dynamic>) return null;
      final stress = psych['stressIndex'];
      if (stress is num) return stress.toDouble();
    } catch (_) {}
    return null;
  }

  static ({String? rolloutStage, bool? conformancePassed, String? fingerprint})
  _rfReleaseExportFields(String protocolJson) {
    try {
      final decoded = jsonDecode(protocolJson);
      if (decoded is! Map) {
        return (rolloutStage: null, conformancePassed: null, fingerprint: null);
      }
      final release = decoded['releaseValidation'];
      if (release is! Map) {
        return (rolloutStage: null, conformancePassed: null, fingerprint: null);
      }
      final conformance = release['protocolConformance'];
      return (
        rolloutStage: release['rolloutStage'] as String?,
        conformancePassed:
            conformance is Map ? conformance['passed'] as bool? : null,
        fingerprint:
            conformance is Map
                ? conformance['configurationFingerprint'] as String?
                : null,
      );
    } catch (_) {
      return (rolloutStage: null, conformancePassed: null, fingerprint: null);
    }
  }

  static String _sqiLabel(SqiLevel level) {
    switch (level) {
      case SqiLevel.good:
        return 'good';
      case SqiLevel.warning:
        return 'warning';
      case SqiLevel.bad:
        return 'bad';
    }
  }

  static String _csvCell(Object? value) {
    if (value == null) return '';
    var text = value.toString();
    if (text.isNotEmpty && RegExp(r'^[=+\-@\t]').hasMatch(text)) {
      text = "'$text";
    }
    if (!text.contains(',') &&
        !text.contains('"') &&
        !text.contains('\n') &&
        !text.contains('\r')) {
      return text;
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  static HrvTimeDomainResult hrvEntryToResult(HrvEntry e) {
    return HrvTimeDomainResult(
      meanNN: e.meanNn ?? 0,
      sdnn: e.sdnn ?? 0,
      rmssd: e.rmssd ?? 0,
      sdsd: e.sdsd ?? 0,
      cvnn: e.cvnn ?? 0,
      cvsd: e.cvsd ?? 0,
      medianNN: e.medianNn ?? 0,
      madNN: e.madNn ?? 0,
      mcvnn: e.mcvnn ?? 0,
      iqrnn: e.iqrnn ?? 0,
      sdrmssd: e.sdrmssd ?? 0,
      prc20nn: e.prc20nn ?? 0,
      prc80nn: e.prc80nn ?? 0,
      pnn50: e.pnn50 ?? 0,
      pnn20: e.pnn20 ?? 0,
      minNN: e.minNn ?? 0,
      maxNN: e.maxNn ?? 0,
      hti: e.hti ?? 0,
      tinn: e.tinn ?? 0,
      sdann1: e.sdann1,
      sdann2: e.sdann2,
      sdann5: e.sdann5,
      sdnni1: e.sdnni1,
      sdnni2: e.sdnni2,
      sdnni5: e.sdnni5,
    );
  }
}

class _PatientExportFields {
  final int? id;
  final String? name;
  final int? age;
  final String? sex;
  final double? heightCm;
  final String? dateOfBirth;
  final String? notes;
  final double? resonanceFrequency;
  final String? createdAt;
  final String? updatedAt;

  const _PatientExportFields({
    required this.id,
    required this.name,
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.dateOfBirth,
    required this.notes,
    required this.resonanceFrequency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _PatientExportFields.from(Patient? patient) {
    return _PatientExportFields(
      id: patient?.id,
      name: patient?.name,
      age: patient?.age,
      sex: patient?.sex,
      heightCm: patient?.heightCm,
      dateOfBirth: patient?.dateOfBirth,
      notes: patient?.notes,
      resonanceFrequency: patient?.resonanceFrequency,
      createdAt: patient?.createdAt,
      updatedAt: patient?.updatedAt,
    );
  }
}

class _DetectedEcgRr {
  final double rrMs;
  final String signalQuality;

  const _DetectedEcgRr({required this.rrMs, required this.signalQuality});
}

class EcgSamplePoint {
  final int timestampMs;
  final int timestampUs;
  final int elapsedMs;
  final int elapsedUs;
  final int sampleIndex;
  final double ecgUv;

  const EcgSamplePoint({
    required this.timestampMs,
    required this.timestampUs,
    required this.elapsedMs,
    required this.elapsedUs,
    required this.sampleIndex,
    required this.ecgUv,
  });
}

class _ExportRow {
  final int? timestampUs;
  final int? timestampMs;
  final int? elapsedUs;
  final int? elapsedMs;
  final int? sampleIndex;
  final String? signalQuality;
  final double? ecgRrMs;
  final num? hrBpm;
  final num? rrBpm;
  final double? rmssd;
  final double? sdnn;
  final double? stressIndex;
  final String? psychometricScale;
  final int? psychometricScore;
  final String? psychometricSeverity;
  final String rowType;
  final Map<String, Object?> fields;
  final double? rfBpm;
  final String? rfMode;
  final String? rfProtocolVersion;
  final bool? rfQualityPassed;
  final String? rfQualityFlags;
  final bool? rfAppliedToPatient;
  final bool? rfEstimateConfirmed;
  final double? rfPeakToTroughMs;
  final double? rfScheduledBpm;
  final double? rfMeasuredRespirationBpm;
  final int? rfEctopicCorrections;
  final String? rfRolloutStage;
  final bool? rfProtocolConformancePassed;
  final String? rfProtocolFingerprint;

  const _ExportRow({
    this.timestampUs,
    this.timestampMs,
    this.elapsedUs,
    this.elapsedMs,
    this.sampleIndex,
    this.signalQuality,
    this.ecgRrMs,
    this.hrBpm,
    this.rrBpm,
    this.rmssd,
    this.sdnn,
    this.stressIndex,
    this.psychometricScale,
    this.psychometricScore,
    this.psychometricSeverity,
    required this.rowType,
    this.fields = const {},
    this.rfBpm,
    this.rfMode,
    this.rfProtocolVersion,
    this.rfQualityPassed,
    this.rfQualityFlags,
    this.rfAppliedToPatient,
    this.rfEstimateConfirmed,
    this.rfPeakToTroughMs,
    this.rfScheduledBpm,
    this.rfMeasuredRespirationBpm,
    this.rfEctopicCorrections,
    this.rfRolloutStage,
    this.rfProtocolConformancePassed,
    this.rfProtocolFingerprint,
  });

  String toCsvLine(_PatientExportFields patient) {
    final values = <String, Object?>{
      'patient_id': patient.id,
      'patient_name': patient.name,
      'patient_age': patient.age,
      'patient_sex': patient.sex,
      'patient_height_cm': patient.heightCm,
      'timestamp_us': timestampUs,
      'timestamp_ms': timestampMs,
      'elapsed_us': elapsedUs,
      'elapsed_ms': elapsedMs,
      'sample_index': sampleIndex,
      'signal_quality': signalQuality,
      'ecg_rr_ms': ecgRrMs,
      'hr_bpm': hrBpm,
      'rr_bpm': rrBpm,
      'rmssd': rmssd,
      'sdnn': sdnn,
      'stress_index': stressIndex,
      'psychometric_scale': psychometricScale,
      'psychometric_score': psychometricScore,
      'psychometric_severity': psychometricSeverity,
      'row_type': rowType,
      'rf_bpm': rfBpm,
      'rf_mode': rfMode,
      'rf_protocol_version': rfProtocolVersion,
      'rf_quality_passed': rfQualityPassed,
      'rf_quality_flags': rfQualityFlags,
      'rf_applied_to_patient': rfAppliedToPatient,
      'rf_estimate_confirmed': rfEstimateConfirmed,
      'rf_peak_to_trough_ms': rfPeakToTroughMs,
      'rf_scheduled_bpm': rfScheduledBpm,
      'rf_measured_respiration_bpm': rfMeasuredRespirationBpm,
      'rf_ectopic_corrections': rfEctopicCorrections,
      'rf_rollout_stage': rfRolloutStage,
      'rf_protocol_conformance_passed': rfProtocolConformancePassed,
      'rf_protocol_fingerprint': rfProtocolFingerprint,
      'patient_date_of_birth': patient.dateOfBirth,
      'patient_notes': patient.notes,
      'patient_resonance_frequency_bpm': patient.resonanceFrequency,
      'patient_created_at': patient.createdAt,
      'patient_updated_at': patient.updatedAt,
      ...fields,
    };

    return AppDatabase._patientExportColumns
        .map((column) => AppDatabase._csvCell(values[column]))
        .join(',');
  }
}
