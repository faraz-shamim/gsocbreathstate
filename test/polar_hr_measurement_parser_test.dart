// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/services/heart_rate/polar_hr_measurement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePolarHeartRateMeasurement', () {
    test('parses every RR value in an 8-bit HR packet', () {
      final result = parsePolarHeartRateMeasurement([
        0x10,
        60,
        0x00,
        0x04,
        0x80,
        0x03,
      ]);

      expect(result, isNotNull);
      expect(result!.heartRateBpm, 60);
      expect(result.rrIntervalsMs, [1000.0, 875.0]);
    });

    test('uses identical offsets for 16-bit HR and energy packets', () {
      final result = parsePolarHeartRateMeasurement([
        0x19,
        0x2C,
        0x01,
        0x34,
        0x12,
        0x00,
        0x04,
      ]);

      expect(result, isNotNull);
      expect(result!.heartRateBpm, 300);
      expect(result.rrIntervalsMs, [1000.0]);
    });

    test('ignores an incomplete trailing RR byte', () {
      final result = parsePolarHeartRateMeasurement([
        0x10,
        72,
        0x00,
        0x04,
        0xFF,
      ]);

      expect(result, isNotNull);
      expect(result!.rrIntervalsMs, [1000.0]);
    });

    test('rejects truncated heart-rate payloads', () {
      expect(parsePolarHeartRateMeasurement(const []), isNull);
      expect(parsePolarHeartRateMeasurement(const [0x01, 0x2C]), isNull);
    });
  });
}
