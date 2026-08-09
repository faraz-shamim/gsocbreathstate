library;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
class GoDirectUuids {
  GoDirectUuids._();

  static final Guid primaryService =
      Guid('d91714ef-28b9-4f91-ba16-f0d9e7f3125c');

  static final Guid commandChar =
      Guid('f4bf14a6-c7d5-4b6d-8aa8-df1a7c83adcb');

  static final Guid responseChar =
      Guid('b41b1c18-3d4a-11e5-ab5e-feff819cdc9f');

  static final Guid measurementChar =
      Guid('ec0a8400-3d4a-11e5-ab5e-feff819cdc9f');
}
class GoDirectProtocol {
  GoDirectProtocol._();

  static const int commandHeader = 0x58;

  static const int responseHeader = 0x5C;
}

class GoDirectCommands {
  GoDirectCommands._();

  static const int init = 0x01;
  static const int getAvailableSensors = 0x03;
  static const int getSensorInfo = 0x04;
  static const int setMeasurementPeriod = 0x07;
  static const int startMeasurements = 0x08;
  static const int stopMeasurements = 0x09;
  static const int getDeviceInfo = 0x0A;
  static const int getBatteryStatus = 0x0B;
  static const int getDefaultSensorsMask = 0x0D;
}
class GoDirectSensorInfo {
  final int sensorNumber;
  final String description;
  final String units;
  final int mutualExclusionMask;

  const GoDirectSensorInfo({
    required this.sensorNumber,
    required this.description,
    required this.units,
    this.mutualExclusionMask = 0,
  });

  @override
  String toString() => 'Sensor $sensorNumber: $description ($units)';
}

class GoDirectScannedDevice {
  final String id;
  final String name;
  final int rssi;

  const GoDirectScannedDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  @override
  String toString() => '$name [$id] rssi=$rssi';
}

class GoDirectMeasurement {
  final int sensorNumber;
  final double value;
  final DateTime timestamp;

  const GoDirectMeasurement({
    required this.sensorNumber,
    required this.value,
    required this.timestamp,
  });

  @override
  String toString() =>
      'Sensor $sensorNumber: ${value.toStringAsFixed(4)} @ $timestamp';
}

class GoDirectDeviceInfo {
  final String? name;
  final int? batteryPercent;
  final List<int> rawPayload;

  const GoDirectDeviceInfo({
    this.name,
    this.batteryPercent,
    required this.rawPayload,
  });
}

enum GoDirectConnectionState {
  disconnected,
  scanning,
  connecting,
  initializing,
  connected,
  streaming,
  disconnecting,
  error,
}

const Map<String, List<GoDirectSensorInfo>> knownGoDirectDevices = {
  'GDX-RB': [
    GoDirectSensorInfo(
      sensorNumber: 1,
      description: 'Respiration Force',
      units: 'N',
    ),
  ],
  'GDX-FOR': [
    GoDirectSensorInfo(sensorNumber: 1, description: 'Force', units: 'N'),
    GoDirectSensorInfo(
        sensorNumber: 2, description: 'X-axis acceleration', units: 'm/s²'),
    GoDirectSensorInfo(
        sensorNumber: 3, description: 'Y-axis acceleration', units: 'm/s²'),
    GoDirectSensorInfo(
        sensorNumber: 4, description: 'Z-axis acceleration', units: 'm/s²'),
  ],
  'GDX-HD': [
    GoDirectSensorInfo(sensorNumber: 1, description: 'Force', units: 'N'),
  ],
};