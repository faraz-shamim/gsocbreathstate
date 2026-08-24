// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:typed_data';

class PolarSimUuids {
  PolarSimUuids._();

  static const heartRateService = '0000180d-0000-1000-8000-00805f9b34fb';
  static const heartRateMeasurement = '00002a37-0000-1000-8000-00805f9b34fb';

  static const pmdService = 'fb005c80-02e7-f387-1cad-8acd2d8df0c8';
  static const pmdControlPoint = 'fb005c81-02e7-f387-1cad-8acd2d8df0c8';
  static const pmdData = 'fb005c82-02e7-f387-1cad-8acd2d8df0c8';
}

enum PmdMeasurementType {
  ecg(0x00),
  acc(0x02);

  final int value;
  const PmdMeasurementType(this.value);

  static PmdMeasurementType? fromByte(int value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class AccSample {
  final int xMg;
  final int yMg;
  final int zMg;

  const AccSample({required this.xMg, required this.yMg, required this.zMg});
}

class PolarProtocol {
  PolarProtocol._();

  static const success = 0x00;
  static const invalidOpCode = 0x01;
  static const invalidMeasurementType = 0x02;
  static const invalidParameter = 0x05;
  static const alreadyInState = 0x06;

  static List<int> availableMeasurements() {
    return <int>[0x0F, (1 << PmdMeasurementType.ecg.value) | (1 << 2)];
  }

  static List<int> heartRateMeasurement({
    required int heartRateBpm,
    required List<double> rrIntervalsMs,
  }) {
    final packet = <int>[0x10, heartRateBpm.clamp(0, 255)];
    for (final rrMs in rrIntervalsMs) {
      if (!rrMs.isFinite || rrMs <= 0) continue;
      final raw = (rrMs * 1024.0 / 1000.0).round().clamp(0, 0xFFFF);
      packet
        ..add(raw & 0xFF)
        ..add((raw >> 8) & 0xFF);
    }
    return packet;
  }

  static List<int> pmdSettingsResponse(PmdMeasurementType type) {
    return pmdResponse(
      opCode: 0x01,
      measurementType: type.value,
      errorCode: success,
      parameters: switch (type) {
        PmdMeasurementType.ecg => _settings(sampleRate: 130, resolution: 14),
        PmdMeasurementType.acc => _settings(
          sampleRate: 200,
          resolution: 16,
          range: 2,
        ),
      },
    );
  }

  static List<int> pmdResponse({
    required int opCode,
    required int measurementType,
    required int errorCode,
    List<int> parameters = const <int>[],
  }) {
    return <int>[0xF0, opCode, measurementType, errorCode, ...parameters];
  }

  static List<int> ecgFrame({
    required int timestampNs,
    required List<double> samplesUv,
  }) {
    final packet = <int>[PmdMeasurementType.ecg.value];
    _appendUint64Le(packet, timestampNs);
    packet.add(0x00);
    for (final sample in samplesUv) {
      _appendInt24Le(packet, sample.round());
    }
    return packet;
  }

  static List<int> accFrame({
    required int timestampNs,
    required List<AccSample> samples,
  }) {
    final packet = <int>[PmdMeasurementType.acc.value];
    _appendUint64Le(packet, timestampNs);
    packet.add(0x01);
    for (final sample in samples) {
      _appendInt16Le(packet, sample.xMg);
      _appendInt16Le(packet, sample.yMg);
      _appendInt16Le(packet, sample.zMg);
    }
    return packet;
  }

  static List<int> _settings({
    required int sampleRate,
    required int resolution,
    int? range,
  }) {
    final result = <int>[];
    _appendSetting(result, 0x00, sampleRate);
    _appendSetting(result, 0x01, resolution);
    if (range != null) _appendSetting(result, 0x02, range);
    return result;
  }

  static void _appendSetting(List<int> bytes, int type, int value) {
    bytes
      ..add(type)
      ..add(0x01)
      ..add(value & 0xFF)
      ..add((value >> 8) & 0xFF);
  }

  static void _appendUint64Le(List<int> bytes, int value) {
    final data = ByteData(8);
    data.setUint32(0, value & 0xFFFFFFFF, Endian.little);
    data.setUint32(4, value ~/ 0x100000000, Endian.little);
    bytes.addAll(data.buffer.asUint8List());
  }

  static void _appendInt24Le(List<int> bytes, int value) {
    var raw = value.clamp(-0x800000, 0x7FFFFF);
    if (raw < 0) raw += 0x1000000;
    bytes
      ..add(raw & 0xFF)
      ..add((raw >> 8) & 0xFF)
      ..add((raw >> 16) & 0xFF);
  }

  static void _appendInt16Le(List<int> bytes, int value) {
    var raw = value.clamp(-0x8000, 0x7FFF);
    if (raw < 0) raw += 0x10000;
    bytes
      ..add(raw & 0xFF)
      ..add((raw >> 8) & 0xFF);
  }
}
