// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state_ble_simulator/physiology_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calmSettings = PhysiologySettings(
    heartRateBpm: 72,
    breathRateBpm: 6,
    rsaAmplitudeMs: 70,
    ecgNoiseUv: 0,
    packetDropPercent: 0,
    motionLevel: 0,
    ectopyEnabled: false,
  );

  test('generates plausible RR intervals from the shared beat schedule', () {
    final model = PhysiologyModel();

    final intervals = model.drainRrIntervals(
      const Duration(seconds: 10),
      calmSettings,
    );

    expect(intervals.length, inInclusiveRange(9, 14));
    expect(intervals.every((rr) => rr >= 300 && rr <= 2000), isTrue);
  });

  test('generates ECG samples with visible R peaks', () {
    final model = PhysiologyModel();

    final samples = model.nextEcgSamples(
      (PhysiologyModel.ecgSampleRateHz * 4).round(),
      calmSettings,
    );

    expect(samples.reduce((a, b) => a > b ? a : b), greaterThan(700));
    expect(samples.reduce((a, b) => a < b ? a : b), lessThan(-120));
  });

  test('generates accelerometer samples centered around gravity', () {
    final model = PhysiologyModel();

    final samples = model.nextAccSamples(
      (PhysiologyModel.accSampleRateHz * 2).round(),
      calmSettings,
    );

    final zValues = samples.map((sample) => sample.zMg);
    expect(zValues.every((z) => z > 980 && z < 1020), isTrue);
  });
}
