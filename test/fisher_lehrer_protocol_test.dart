// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:convert';
import 'dart:io';

import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/fisher_lehrer_reference_vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('FisherLehrerProtocolConfig', () {
    const protocol = FisherLehrerProtocolConfig();
    final scheduleFixture = fixture['schedule'] as Map<String, dynamic>;

    test('matches the locked 78-breath reference schedule', () {
      final schedule = protocol.buildSchedule();

      expect(schedule, hasLength(scheduleFixture['cycleCount'] as int));
      expect(
        schedule.first.periodMs,
        closeTo(scheduleFixture['startPeriodMs'] as double, 1e-9),
      );
      expect(
        protocol.targetEndPeriodMs,
        closeTo(scheduleFixture['targetEndPeriodMs'] as double, 1e-9),
      );
      expect(
        protocol.periodIncrementMs,
        closeTo(scheduleFixture['periodIncrementMs'] as double, 1e-9),
      );
      expect(
        schedule.last.periodMs,
        closeTo(scheduleFixture['lastExecutedPeriodMs'] as double, 1e-9),
      );
      expect(
        schedule.last.scheduledBpm,
        closeTo(scheduleFixture['lastExecutedBpm'] as double, 1e-12),
      );
      expect(
        protocol.scheduledDurationMs,
        closeTo(scheduleFixture['scheduledDurationMs'] as double, 1e-9),
      );
    });

    test('uses equal inhale and exhale halves', () {
      for (final cycle in protocol.buildSchedule()) {
        expect(cycle.inhaleMs, closeTo(cycle.exhaleMs, 1e-9));
        expect(cycle.inhaleMs + cycle.exhaleMs, closeTo(cycle.periodMs, 1e-9));
      }
    });

    test('maps elapsed time to breath boundaries without interpolation', () {
      final schedule = protocol.buildSchedule();
      final cycle = schedule[34];

      expect(protocol.cycleAtElapsedMs(cycle.startElapsedMs).index, 34);
      expect(protocol.cycleAtElapsedMs(cycle.endElapsedMs - 0.001).index, 34);
      expect(protocol.cycleAtElapsedMs(cycle.endElapsedMs).index, 35);
      expect(protocol.cycleAtElapsedMs(protocol.scheduledDurationMs).index, 77);
    });

    test('serializes all result-defining constants', () {
      final json = protocol.toJson();

      expect(json['protocolVersion'], fixture['protocolVersion']);
      expect(json['ibiLowessPoints'], 41);
      expect(json['excursionLowessPoints'], 17);
      expect(json['periodIncrementMs'], protocol.periodIncrementMs);
      expect(json['scheduledDurationMs'], protocol.scheduledDurationMs);
    });
  });
}
