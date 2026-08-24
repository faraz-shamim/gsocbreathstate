import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test(
    'exports every stored entity with correct identifiers and fields',
    () async {
      final patient = await database.createPatient(
        name: 'Export Patient',
        dateOfBirth: '1990-01-02',
        age: 36,
        sex: 'X',
        heightCm: 172.5,
        notes: 'patient note',
      );
      await database.updatePatientResonanceFrequency(patient.id, 5.8);

      final sessionId = await database.createSession(
        patientId: patient.id,
        sessionType: 'recording',
      );
      await (database.update(database.sessions)
        ..where((session) => session.id.equals(sessionId))).write(
        const SessionsCompanion(
          startedAt: Value('2026-01-01T10:00:00.000Z'),
          endedAt: Value('2026-01-01T10:01:00.000Z'),
          notes: Value('session note'),
        ),
      );

      await database.insertBreathRate(
        sessionId: sessionId,
        patientId: patient.id,
        rate: 6,
        source: 'belt',
        timestamp: '2026-01-01T10:00:10.000Z',
      );
      await database.insertHeartRate(
        sessionId: sessionId,
        patientId: patient.id,
        rate: 72,
        timestamp: '2026-01-01T10:00:11.000Z',
      );
      await database.insertEcgSamples(
        sessionId: sessionId,
        patientId: patient.id,
        samples: const [
          EcgSamplePoint(
            timestampMs: 1000,
            timestampUs: 1000000,
            elapsedMs: 0,
            elapsedUs: 0,
            sampleIndex: 0,
            ecgUv: 123.45,
          ),
        ],
      );
      await database.insertHrvResult(
        sessionId: sessionId,
        patientId: patient.id,
        result: const HrvTimeDomainResult(
          meanNN: 800,
          sdnn: 40,
          rmssd: 30,
          sdsd: 20,
          cvnn: 0.05,
          cvsd: 0.04,
          medianNN: 800,
          madNN: 10,
          mcvnn: 0.01,
          iqrnn: 20,
          sdrmssd: 1.2,
          prc20nn: 780,
          prc80nn: 820,
          pnn50: 12,
          pnn20: 24,
          minNN: 700,
          maxNN: 900,
          hti: 1.1,
          tinn: 100,
          sdann1: 11,
          sdann2: 12,
          sdann5: 13,
          sdnni1: 14,
          sdnni2: 15,
          sdnni5: 16,
        ),
      );
      await database.insertPsychometricEntry(
        patientId: patient.id,
        scaleType: 'PHQ-9',
        totalScore: 7,
        severityLevel: 'mild',
        responsesJson: '{"1":2,"9":0}',
        administeredAt: '2026-01-01T10:02:00.000Z',
        administeredBy: 'clinician, one',
        requiresReview: true,
        notes: 'assessment note',
      );

      final summaryId = await database.insertSessionSummary(
        patientId: patient.id,
        sessionType: 'recording',
        startedAt: '2026-01-01T10:00:00.000Z',
        endedAt: '2026-01-01T10:01:00.000Z',
        durationSeconds: 60,
        breathRate: 6,
        breathSource: 'belt',
        avgHeartRate: 72,
        minHeartRate: 70,
        maxHeartRate: 75,
        meanNn: 800,
        pnn50: 12,
        hrReadingsJson: '[72,73]',
        extendedMetricsJson: '{"exportMarker":"summary-json"}',
      );
      final rfId = await database.insertRfAssessmentRecord(
        patientId: patient.id,
        sessionSummaryId: summaryId,
        surface: 'native',
        protocolVersion: 'rf-v1',
        mode: 'measured',
        status: 'completed',
        startedAt: '2026-01-01T10:03:00.000Z',
        endedAt: '2026-01-01T10:04:00.000Z',
        durationMs: 60000,
        completedCycles: 10,
        rfBpm: 5.8,
        rfCenterElapsedMs: 30000,
        peakToTroughAmplitude: 100,
        scheduledBpmAtCenter: 5.8,
        fittedRespirationBpm: 5.7,
        adherenceDeltaBpm: 0.1,
        respirationFitError: 0.2,
        ectopicCorrections: 1,
        qualityPassed: true,
        qualityFlagsJson: '["ok"]',
        appliedToPatient: true,
        estimateConfirmed: null,
        protocolJson: '{"protocol":"raw-protocol"}',
        resultJson: '{"result":"raw-result"}',
        rrSamplesJson: '[{"rrMs":900}]',
        respirationSamplesJson: '[{"value":1}]',
      );

      final csv = await database.generatePatientCsv(patient.id);
      final rows = _rowsByType(_parseCsv(csv));

      expect(rows['patient'], isNotNull);
      expect(rows['patient']!['patient_date_of_birth'], '1990-01-02');
      expect(rows['patient']!['patient_resonance_frequency_bpm'], '5.8');

      expect(rows['session']!['session_id'], '$sessionId');
      expect(rows['session']!['session_notes'], 'session note');
      expect(rows['ecg']!['record_id'], isNotEmpty);
      expect(rows['ecg']!['ecg_uv'], '123.45');
      expect(rows['heart_rate']!['measurement_rate_bpm'], '72');
      expect(
        rows['breath_rate']!['source_timestamp'],
        '2026-01-01T10:00:10.000Z',
      );
      expect(rows['hrv']!['hrv_sdsd'], '20.0');

      expect(
        rows['psychometric']!['psychometric_responses_json'],
        '{"1":2,"9":0}',
      );
      expect(rows['psychometric']!['psychometric_requires_review'], 'true');
      expect(rows['psychometric']!['psychometric_notes'], 'assessment note');

      expect(rows['session_summary']!['summary_id'], '$summaryId');
      expect(rows['session_summary']!['session_id'], isEmpty);
      expect(
        rows['session_summary']!['summary_extended_metrics_json'],
        '{"exportMarker":"summary-json"}',
      );

      expect(rows['rf_assessment']!['rf_assessment_id'], '$rfId');
      expect(rows['rf_assessment']!['session_summary_id'], '$summaryId');
      expect(rows['rf_assessment']!['session_id'], isEmpty);
      expect(
        rows['rf_assessment']!['rf_protocol_json'],
        '{"protocol":"raw-protocol"}',
      );
      expect(rows['rf_assessment']!['rf_rr_samples_json'], '[{"rrMs":900}]');
    },
  );

  test('preserves CSV text and neutralizes spreadsheet formulas', () async {
    final patient = await database.createPatient(
      name: '=1+1',
      notes: 'line one, "quoted"\nline two',
    );

    final rows = _rowsByType(
      _parseCsv(await database.generatePatientCsv(patient.id)),
    );

    expect(rows['patient']!['patient_name'], "'=1+1");
    expect(rows['patient']!['patient_notes'], 'line one, "quoted"\nline two');
  });
}

Map<String, Map<String, String>> _rowsByType(List<List<String>> rows) {
  final headerIndex = rows.indexWhere(
    (row) => row.isNotEmpty && row.first == 'patient_id',
  );
  expect(headerIndex, greaterThanOrEqualTo(0));
  final header = rows[headerIndex];
  final result = <String, Map<String, String>>{};
  for (final row in rows.skip(headerIndex + 1)) {
    if (row.length != header.length) continue;
    final values = <String, String>{};
    for (var i = 0; i < header.length; i++) {
      values[header[i]] = row[i];
    }
    final type = values['row_type'];
    if (type != null) result[type] = values;
  }
  return result;
}

List<List<String>> _parseCsv(String csv) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;

  for (var i = 0; i < csv.length; i++) {
    final char = csv[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < csv.length && csv[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }

    if (char == '"' && field.isEmpty) {
      quoted = true;
    } else if (char == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (char == '\n') {
      row.add(field.toString());
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else if (char != '\r') {
      field.write(char);
    }
  }

  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
