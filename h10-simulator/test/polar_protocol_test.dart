import 'package:breath_state_ble_simulator/polar_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes HR measurement with RR intervals in 1/1024 second units', () {
    final packet = PolarProtocol.heartRateMeasurement(
      heartRateBpm: 72,
      rrIntervalsMs: const [1000, 750],
    );

    expect(packet, [0x10, 72, 0x00, 0x04, 0x00, 0x03]);
  });

  test('advertises ECG and ACC as PMD available measurements', () {
    expect(PolarProtocol.availableMeasurements(), [0x0F, 0x05]);
  });

  test('encodes PMD settings response', () {
    final packet = PolarProtocol.pmdSettingsResponse(PmdMeasurementType.ecg);

    expect(packet.take(4), [0xF0, 0x01, 0x00, 0x00]);
    expect(packet.skip(4), [0x00, 0x01, 130, 0x00, 0x01, 0x01, 14, 0x00]);
  });

  test('encodes ECG frame with signed 24-bit samples', () {
    final packet = PolarProtocol.ecgFrame(
      timestampNs: 1,
      samplesUv: const [-1, 0, 1],
    );

    expect(packet[0], 0x00);
    expect(packet.sublist(1, 9), [1, 0, 0, 0, 0, 0, 0, 0]);
    expect(packet[9], 0x00);
    expect(packet.sublist(10), [0xFF, 0xFF, 0xFF, 0, 0, 0, 1, 0, 0]);
  });

  test('encodes ACC frame with int16 xyz samples', () {
    final packet = PolarProtocol.accFrame(
      timestampNs: 2,
      samples: const [AccSample(xMg: -1, yMg: 0, zMg: 1000)],
    );

    expect(packet[0], 0x02);
    expect(packet.sublist(1, 9), [2, 0, 0, 0, 0, 0, 0, 0]);
    expect(packet[9], 0x01);
    expect(packet.sublist(10), [0xFF, 0xFF, 0, 0, 0xE8, 0x03]);
  });
}
