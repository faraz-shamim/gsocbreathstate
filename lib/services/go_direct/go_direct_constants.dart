library;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GoDirectUuids {
  GoDirectUuids._();

  static final Guid primaryService = Guid(
    'd91714ef-28b9-4f91-ba16-f0d9a604f112',
  );

  static final Guid commandChar = Guid('f4bf14a6-c7d5-4b6d-8aa8-df1a7c83adcb');

  static final Guid responseChar = Guid('b41e6675-a329-40e0-aa01-44d2f444babe');
}

class GoDirectProtocol {
  GoDirectProtocol._();

  static const int commandHeader = 0x58;

  static const int responseHeader = 0x58;

  static const int measurementResponse = 0x20;
}

class GoDirectMeasurementType {
  GoDirectMeasurementType._();

  static const int normalReal32 = 0x06;
  static const int wideReal32 = 0x07;
  static const int singleChannelReal32 = 0x08;
  static const int singleChannelInt32 = 0x09;
  static const int aperiodicReal32 = 0x0A;
  static const int aperiodicInt32 = 0x0B;
  static const int startTime = 0x0C;
  static const int dropped = 0x0D;
  static const int period = 0x0E;
}

class GoDirectCommands {
  GoDirectCommands._();

  static const int getStatus = 0x10;
  static const int startMeasurements = 0x18;
  static const int stopMeasurements = 0x19;
  static const int init = 0x1A;
  static const int setMeasurementPeriod = 0x1B;
  static const int getSensorInfo = 0x50;
  static const int getAvailableSensors = 0x51;
  static const int disconnect = 0x54;
  static const int getDeviceInfo = 0x55;
  static const int getDefaultSensorsMask = 0x56;

  static const int getBatteryStatus = getStatus;
}

class GoDirectSensorInfo {
  final int sensorNumber;
  final int? sensorId;
  final String description;
  final String units;
  final double? minimumPeriodMs;
  final double? typicalPeriodMs;
  final int mutualExclusionMask;

  const GoDirectSensorInfo({
    required this.sensorNumber,
    this.sensorId,
    required this.description,
    required this.units,
    this.minimumPeriodMs,
    this.typicalPeriodMs,
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

bool isGoDirectDeviceName(String name) {
  final upper = name.trim().toUpperCase();
  return upper.startsWith('GDX-') || upper.startsWith('GDX');
}

bool isGoDirectRespirationBeltName(String name) =>
    name.trim().toUpperCase().startsWith('GDX-RB');

bool isGoDirectCandidate({
  required String name,
  required List<Guid> serviceUuids,
}) {
  if (isGoDirectDeviceName(name)) return true;
  return serviceUuids.contains(GoDirectUuids.primaryService);
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

enum GoDirectStage {
  idle,
  scanning,
  connecting,
  discoveringGatt,
  subscribingNotifications,
  init,
  getStatus,
  getDeviceInfo,
  getDefaultSensors,
  getSensorIds,
  getSensorInfo,
  ready,
  configuringMeasurement,
  streaming,
  disconnecting,
  error,
}

const Map<String, List<GoDirectSensorInfo>> knownGoDirectDevices = {
  'GDX-RB': [
    GoDirectSensorInfo(sensorNumber: 1, description: 'Force', units: 'N'),
    GoDirectSensorInfo(
      sensorNumber: 2,
      description: 'Respiration Rate',
      units: 'BPM',
    ),
    GoDirectSensorInfo(sensorNumber: 3, description: 'Steps', units: 'steps'),
    GoDirectSensorInfo(sensorNumber: 4, description: 'Step Rate', units: 'SPM'),
  ],
  'GDX-FOR': [
    GoDirectSensorInfo(sensorNumber: 1, description: 'Force', units: 'N'),
    GoDirectSensorInfo(
      sensorNumber: 2,
      description: 'X-axis acceleration',
      units: 'm/s²',
    ),
    GoDirectSensorInfo(
      sensorNumber: 3,
      description: 'Y-axis acceleration',
      units: 'm/s²',
    ),
    GoDirectSensorInfo(
      sensorNumber: 4,
      description: 'Z-axis acceleration',
      units: 'm/s²',
    ),
  ],
  'GDX-HD': [
    GoDirectSensorInfo(sensorNumber: 1, description: 'Force', units: 'N'),
  ],
};
