// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';

import 'package:breath_state_ble_simulator/peripheral_backend.dart';
import 'package:breath_state_ble_simulator/polar_protocol.dart';
import 'package:breath_state_ble_simulator/simulator_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('permission denial prevents backend initialization', () async {
    final backend = _FakePeripheralBackend();
    final controller = SimulatorController(
      backend: backend,
      permissionRequester: () async => false,
      wakeLockSetter: (_) async {},
    );

    await controller.startAdvertising();

    expect(controller.status, SimulatorStatus.permissionsMissing);
    expect(backend.initializeCalls, 0);
    expect(controller.logs.first, contains('Nearby devices permission'));
    controller.dispose();
  });

  test(
    'granted permission starts Polar services and remains stoppable',
    () async {
      final backend = _FakePeripheralBackend();
      final controller = SimulatorController(
        backend: backend,
        permissionRequester: () async => true,
        wakeLockSetter: (_) async {},
      );
      await controller.initialize();

      await controller.startAdvertising();

      expect(controller.status, SimulatorStatus.advertising);
      expect(controller.canStop, isTrue);
      expect(backend.services, hasLength(2));
      expect(backend.advertisedServices, <String>[
        PolarSimUuids.heartRateService,
      ]);
      expect(
        backend.services.map((service) => service.uuid),
        contains(PolarSimUuids.pmdService),
      );

      backend.emit(
        PeripheralEvent(
          type: PeripheralEventType.centralSubscribed,
          message: 'connected',
          timestamp: DateTime.now(),
          isConnected: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.status, SimulatorStatus.connected);
      expect(controller.canStop, isTrue);

      await controller.stopAdvertising();
      expect(controller.status, SimulatorStatus.ready);
      expect(controller.canStop, isFalse);
      controller.dispose();
    },
  );

  test(
    'unsupported peripheral hardware produces a concise terminal state',
    () async {
      final backend = _FakePeripheralBackend(
        initializeError: const BlePeripheralUnsupportedException(
          'This device cannot advertise as a BLE peripheral.',
        ),
      );
      final controller = SimulatorController(
        backend: backend,
        permissionRequester: () async => true,
        wakeLockSetter: (_) async {},
      );

      await controller.startAdvertising();

      expect(controller.status, SimulatorStatus.unsupported);
      expect(controller.statusLabel, 'Unsupported device');
      expect(controller.canStart, isFalse);
      expect(controller.statusDetail, contains('cannot advertise'));
      expect(controller.logs.first, isNot(contains('Stacktrace')));
      controller.dispose();
    },
  );

  test('PMD start is acknowledged before the first ECG data frame', () async {
    final backend = _FakePeripheralBackend();
    final controller = SimulatorController(
      backend: backend,
      permissionRequester: () async => true,
      wakeLockSetter: (_) async {},
    );
    await controller.initialize();
    await controller.startAdvertising();
    backend.notifications.clear();

    backend.emit(
      PeripheralEvent(
        type: PeripheralEventType.characteristicWrite,
        message: 'start ECG',
        timestamp: DateTime.now(),
        characteristicId: PolarSimUuids.pmdControlPoint,
        value: const <int>[0x02, 0x00],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(backend.notifications, isNotEmpty);
    expect(
      backend.notifications.first.characteristicUuid,
      PolarSimUuids.pmdControlPoint,
    );
    expect(backend.notifications.first.value, <int>[0xF0, 0x02, 0x00, 0x00]);
    expect(controller.isEcgStreaming, isTrue);
    expect(controller.canStop, isTrue);
    controller.dispose();
  });
}

class _Notification {
  final String characteristicUuid;
  final List<int> value;

  const _Notification(this.characteristicUuid, this.value);
}

class _FakePeripheralBackend implements PeripheralBackend {
  final Object? initializeError;
  final StreamController<PeripheralEvent> _events =
      StreamController<PeripheralEvent>.broadcast();
  final List<_Notification> notifications = <_Notification>[];
  List<GattServiceSpec> services = <GattServiceSpec>[];
  List<String> advertisedServices = <String>[];
  int initializeCalls = 0;

  _FakePeripheralBackend({this.initializeError});

  @override
  Stream<PeripheralEvent> get events => _events.stream;

  void emit(PeripheralEvent event) => _events.add(event);

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (initializeError != null) throw initializeError!;
  }

  @override
  Future<void> setServices(List<GattServiceSpec> value) async {
    services = value;
  }

  @override
  Future<void> startAdvertising({
    required String localName,
    required List<String> serviceUuids,
  }) async {
    advertisedServices = serviceUuids;
  }

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<void> notify({
    required String characteristicUuid,
    required List<int> value,
  }) async {
    notifications.add(_Notification(characteristicUuid, List<int>.from(value)));
  }

  @override
  Future<void> dispose() async {
    await _events.close();
  }
}
