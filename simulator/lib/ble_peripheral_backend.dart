import 'dart:async';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart';

import 'peripheral_backend.dart';

class BlePeripheralBackend implements PeripheralBackend {
  final StreamController<PeripheralEvent> _events =
      StreamController<PeripheralEvent>.broadcast();
  final Map<String, List<int>> _valuesByCharacteristic = {};
  Completer<void>? _serviceAddCompleter;
  Completer<void>? _advertisingStartCompleter;
  Completer<void>? _advertisingStopCompleter;
  bool _initialized = false;

  @override
  Stream<PeripheralEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await BlePeripheral.initialize();
      final supported = await BlePeripheral.isSupported();
      if (!supported) {
        throw const BlePeripheralUnsupportedException(
          'This device cannot advertise as a BLE peripheral. Use a physical '
          'Android phone that supports BLE peripheral advertising.',
        );
      }
    } catch (error) {
      throw _friendlyPlatformError(error);
    }
    _wireCallbacks();
    _initialized = true;
    _emit(PeripheralEventType.initialized, 'BLE peripheral initialized.');
  }

  @override
  Future<void> setServices(List<GattServiceSpec> services) async {
    await stopAdvertising();
    await BlePeripheral.clearServices();
    _valuesByCharacteristic.clear();

    for (final service in services) {
      final completer = Completer<void>();
      _serviceAddCompleter = completer;
      try {
        await BlePeripheral.addService(_toBleService(service));
        await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException(
            'Android did not confirm service ${_shortUuid(service.uuid)}.',
          ),
        );
      } finally {
        if (identical(_serviceAddCompleter, completer)) {
          _serviceAddCompleter = null;
        }
      }
      _emit(
        PeripheralEventType.initialized,
        'Service added: ${_shortUuid(service.uuid)}.',
      );
    }
  }

  @override
  Future<void> startAdvertising({
    required String localName,
    required List<String> serviceUuids,
  }) async {
    final completer = Completer<void>();
    _advertisingStartCompleter = completer;
    try {
      await BlePeripheral.startAdvertising(
        services: serviceUuids,
        localName: localName,
      );
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException(
          'Android did not confirm that BLE advertising started.',
        ),
      );
    } catch (error) {
      throw _friendlyPlatformError(error);
    } finally {
      if (identical(_advertisingStartCompleter, completer)) {
        _advertisingStartCompleter = null;
      }
    }
  }

  @override
  Future<void> stopAdvertising() async {
    if (!_initialized || await BlePeripheral.isAdvertising() != true) return;

    final completer = Completer<void>();
    _advertisingStopCompleter = completer;
    try {
      await BlePeripheral.stopAdvertising();
      await completer.future.timeout(const Duration(seconds: 5));
    } finally {
      if (identical(_advertisingStopCompleter, completer)) {
        _advertisingStopCompleter = null;
      }
    }
  }

  @override
  Future<void> notify({
    required String characteristicUuid,
    required List<int> value,
  }) async {
    final key = _normalize(characteristicUuid);
    _valuesByCharacteristic[key] = List<int>.from(value);
    await BlePeripheral.updateCharacteristic(
      characteristicId: characteristicUuid,
      value: Uint8List.fromList(value),
    );
    _events.add(
      PeripheralEvent(
        type: PeripheralEventType.notificationSent,
        message:
            'Notify ${_shortUuid(characteristicUuid)} (${value.length} B).',
        timestamp: DateTime.now(),
        characteristicId: characteristicUuid,
        value: List<int>.from(value),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising().catchError((_) {});
    await _events.close();
  }

  BleService _toBleService(GattServiceSpec service) {
    return BleService(
      uuid: service.uuid,
      primary: true,
      characteristics: service.characteristics
          .map(_toBleCharacteristic)
          .toList(),
    );
  }

  BleCharacteristic _toBleCharacteristic(GattCharacteristicSpec spec) {
    _valuesByCharacteristic[_normalize(spec.uuid)] = List<int>.from(
      spec.initialValue,
    );

    final properties = <int>[];
    final permissions = <int>[];

    if (spec.readable) {
      properties.add(CharacteristicProperties.read.index);
      permissions.add(AttributePermissions.readable.index);
    }
    if (spec.writable) {
      properties
        ..add(CharacteristicProperties.write.index)
        ..add(CharacteristicProperties.writeWithoutResponse.index);
      permissions.add(AttributePermissions.writeable.index);
    }
    if (spec.notifiable) {
      properties.add(CharacteristicProperties.notify.index);
    }

    return BleCharacteristic(
      uuid: spec.uuid,
      properties: properties,
      permissions: permissions,
      value: spec.initialValue.isEmpty
          ? null
          : Uint8List.fromList(spec.initialValue),
    );
  }

  void _wireCallbacks() {
    BlePeripheral.setAdvertisingStatusUpdateCallback((advertising, error) {
      if (error != null && error.isNotEmpty) {
        final failure = _friendlyPlatformError(error);
        final pending = _advertisingStartCompleter;
        if (pending != null && !pending.isCompleted) {
          pending.completeError(failure);
        } else {
          _emit(PeripheralEventType.error, 'Advertising error: $failure');
        }
        return;
      }
      final pending = advertising
          ? _advertisingStartCompleter
          : _advertisingStopCompleter;
      if (pending != null && !pending.isCompleted) pending.complete();
      _emit(
        advertising
            ? PeripheralEventType.advertisingStarted
            : PeripheralEventType.advertisingStopped,
        advertising ? 'Advertising started.' : 'Advertising stopped.',
      );
    });

    BlePeripheral.setConnectionStateChangeCallback((deviceId, connected) {
      _events.add(
        PeripheralEvent(
          type: connected
              ? PeripheralEventType.centralSubscribed
              : PeripheralEventType.centralUnsubscribed,
          message: connected
              ? 'Central connected: $deviceId.'
              : 'Central disconnected: $deviceId.',
          timestamp: DateTime.now(),
          deviceId: deviceId,
          isConnected: connected,
        ),
      );
    });

    BlePeripheral.setCharacteristicSubscriptionChangeCallback((
      deviceId,
      characteristicId,
      isSubscribed,
      name,
    ) {
      _events.add(
        PeripheralEvent(
          type: isSubscribed
              ? PeripheralEventType.centralSubscribed
              : PeripheralEventType.centralUnsubscribed,
          message: isSubscribed
              ? 'Subscribed ${_shortUuid(characteristicId)}.'
              : 'Unsubscribed ${_shortUuid(characteristicId)}.',
          timestamp: DateTime.now(),
          deviceId: deviceId,
          characteristicId: characteristicId,
          isSubscribed: isSubscribed,
        ),
      );
    });

    BlePeripheral.setReadRequestCallback((
      deviceId,
      characteristicId,
      offset,
      value,
    ) {
      final key = _normalize(characteristicId);
      final fullValue = _valuesByCharacteristic[key] ?? const <int>[];
      final sliced = offset >= fullValue.length
          ? const <int>[]
          : fullValue.sublist(offset);
      _events.add(
        PeripheralEvent(
          type: PeripheralEventType.characteristicRead,
          message: 'Read ${_shortUuid(characteristicId)}.',
          timestamp: DateTime.now(),
          deviceId: deviceId,
          characteristicId: characteristicId,
          value: sliced,
        ),
      );
      return ReadRequestResult(value: Uint8List.fromList(sliced));
    });

    BlePeripheral.setWriteRequestCallback((
      deviceId,
      characteristicId,
      offset,
      value,
    ) {
      final payload = value == null ? const <int>[] : List<int>.from(value);
      _valuesByCharacteristic[_normalize(characteristicId)] = payload;
      _events.add(
        PeripheralEvent(
          type: PeripheralEventType.characteristicWrite,
          message:
              'Write ${_shortUuid(characteristicId)} (${payload.length} B).',
          timestamp: DateTime.now(),
          deviceId: deviceId,
          characteristicId: characteristicId,
          value: payload,
        ),
      );
      return WriteRequestResult(status: 0);
    });

    BlePeripheral.setMtuChangeCallback((deviceId, mtu) {
      _emit(PeripheralEventType.initialized, 'MTU changed: $mtu.');
    });

    BlePeripheral.setServiceAddedCallback((serviceId, error) {
      final pending = _serviceAddCompleter;
      if (pending == null || pending.isCompleted) return;
      if (error != null && error.isNotEmpty) {
        pending.completeError(
          BlePeripheralNotReadyException(
            'Could not register service ${_shortUuid(serviceId)}: $error',
          ),
        );
      } else {
        pending.complete();
      }
    });
  }

  void _emit(PeripheralEventType type, String message) {
    _events.add(
      PeripheralEvent(type: type, message: message, timestamp: DateTime.now()),
    );
  }

  String _normalize(String uuid) => uuid.toLowerCase();

  String _shortUuid(String uuid) {
    if (uuid.length <= 8) return uuid;
    return uuid.substring(0, 8).toUpperCase();
  }

  Object _friendlyPlatformError(Object error) {
    if (error is BlePeripheralUnsupportedException ||
        error is BlePeripheralNotReadyException ||
        error is BleAdvertisingException) {
      return error;
    }

    final normalized = error.toString().toLowerCase();
    if (normalized.contains('advertising not supported') ||
        normalized.contains('multiple advertisement')) {
      return const BlePeripheralUnsupportedException(
        'This device cannot advertise as a BLE peripheral. Use a physical '
        'Android phone that supports BLE peripheral advertising.',
      );
    }
    if (normalized.contains('bluetooth is not enabled') ||
        normalized.contains('bluetooth adapter is not turned on') ||
        normalized.contains('gattserver is null')) {
      return const BlePeripheralNotReadyException(
        'Bluetooth is unavailable. Turn Bluetooth on, then press Start again.',
      );
    }
    if (normalized.contains('data too large')) {
      return const BleAdvertisingException(
        'The BLE advertisement exceeded this phone\'s packet limit.',
      );
    }
    return error;
  }
}
