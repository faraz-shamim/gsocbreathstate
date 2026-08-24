// SPDX-License-Identifier: AGPL-3.0-only
enum PeripheralEventType {
  initialized,
  advertisingStarted,
  advertisingStopped,
  centralSubscribed,
  centralUnsubscribed,
  characteristicRead,
  characteristicWrite,
  notificationSent,
  error,
}

class BlePeripheralUnsupportedException implements Exception {
  final String message;

  const BlePeripheralUnsupportedException(this.message);

  @override
  String toString() => message;
}

class BlePeripheralNotReadyException implements Exception {
  final String message;

  const BlePeripheralNotReadyException(this.message);

  @override
  String toString() => message;
}

class BleAdvertisingException implements Exception {
  final String message;

  const BleAdvertisingException(this.message);

  @override
  String toString() => message;
}

class PeripheralEvent {
  final PeripheralEventType type;
  final String message;
  final DateTime timestamp;
  final String? deviceId;
  final String? characteristicId;
  final List<int>? value;
  final bool? isSubscribed;
  final bool? isConnected;

  const PeripheralEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.deviceId,
    this.characteristicId,
    this.value,
    this.isSubscribed,
    this.isConnected,
  });
}

class GattCharacteristicSpec {
  final String uuid;
  final bool readable;
  final bool writable;
  final bool notifiable;
  final List<int> initialValue;

  const GattCharacteristicSpec({
    required this.uuid,
    this.readable = false,
    this.writable = false,
    this.notifiable = false,
    this.initialValue = const <int>[],
  });
}

class GattServiceSpec {
  final String uuid;
  final List<GattCharacteristicSpec> characteristics;

  const GattServiceSpec({required this.uuid, required this.characteristics});
}

abstract class PeripheralBackend {
  Stream<PeripheralEvent> get events;

  Future<void> initialize();

  Future<void> setServices(List<GattServiceSpec> services);

  Future<void> startAdvertising({
    required String localName,
    required List<String> serviceUuids,
  });

  Future<void> stopAdvertising();

  Future<void> notify({
    required String characteristicUuid,
    required List<int> value,
  });

  Future<void> dispose();
}
