// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'package:breath_state/services/ble_service/web_ble.dart';
import 'go_direct_constants.dart';
import 'go_direct_protocol.dart';

class GoDirectServiceWeb {
  WebBleDevice? _device;
  BluetoothRemoteGATTCharacteristic? _commandChar;
  BluetoothRemoteGATTCharacteristic? _responseChar;
  JSFunction? _disconnectListener;

  StreamSubscription<List<int>>? _responseSub;

  final _packetBuilder = GoDirectPacketBuilder();
  final _responseParser = GoDirectResponseParser();
  final _commandQueue = GoDirectSerialQueue();
  final _measurementQueue = GoDirectSerialQueue();
  Completer<GoDirectResponse>? _pendingResponse;
  int? _pendingCommandId;
  int? _pendingCounter;
  List<int>? _lastRawNotification;
  GoDirectResponse? _lastCompletedResponse;
  Future<bool>? _connectInFlight;
  Future<void>? _disconnectInFlight;
  Future<void>? _cleanupInFlight;
  int _sessionGeneration = 0;
  bool _manualDisconnect = false;
  bool _disposed = false;
  bool _isStreaming = false;
  bool _initComplete = false;
  int _measurementPeriodMs = 100;

  final Map<int, GoDirectSensorInfo> _sensors = {};
  final List<int> _enabledSensorNumbers = [];
  int _defaultSensorMask = 0;

  final connectionState = ValueNotifier<GoDirectConnectionState>(
    GoDirectConnectionState.disconnected,
  );
  String? connectedDeviceName;
  String? lastError;
  String? _lastConnectedDeviceName;

  bool get isInitComplete => _initComplete;
  String? get lastConnectedDeviceName =>
      _lastConnectedDeviceName ?? connectedDeviceName;

  List<GoDirectSensorInfo> get availableSensors => List.unmodifiable(
    _sensors.values.toList()
      ..sort((a, b) => a.sensorNumber.compareTo(b.sensorNumber)),
  );

  bool get isStreaming => _isStreaming;

  bool get isConnected =>
      connectionState.value == GoDirectConnectionState.connected ||
      connectionState.value == GoDirectConnectionState.streaming;

  final _measurementController =
      StreamController<GoDirectMeasurement>.broadcast();

  Stream<GoDirectMeasurement> get measurementStream =>
      _measurementController.stream;

  Stream<double> get respirationForceStream =>
      measurementStream.where((m) => m.sensorNumber == 1).map((m) => m.value);

  static const String _primaryServiceUuid =
      'd91714ef-28b9-4f91-ba16-f0d9a604f112';
  static const String _commandCharUuid = 'f4bf14a6-c7d5-4b6d-8aa8-df1a7c83adcb';
  static const String _responseCharUuid =
      'b41e6675-a329-40e0-aa01-44d2f444babe';

  Future<bool> connect() {
    if (_disposed) return Future<bool>.value(false);
    final existing = _connectInFlight;
    if (existing != null) return existing;

    late final Future<bool> connectFuture;
    connectFuture = _connectInternal().whenComplete(() {
      if (identical(_connectInFlight, connectFuture)) _connectInFlight = null;
    });
    _connectInFlight = connectFuture;
    return connectFuture;
  }

  Future<bool> _connectInternal() async {
    if (_device != null && _device!.gatt.connected && _responseChar != null) {
      lastError = null;
      if (!_isStreaming) {
        connectionState.value = GoDirectConnectionState.connected;
      }
      return true;
    }
    final cleanupFuture = _cleanupInFlight;
    if (cleanupFuture != null) await cleanupFuture;
    if (_device != null || _responseSub != null) {
      await disconnect();
    }

    _manualDisconnect = false;
    _initComplete = false;
    lastError = null;
    final session = ++_sessionGeneration;
    connectionState.value = GoDirectConnectionState.connecting;

    try {
      if (!isWebBluetoothSupported) {
        throw StateError(
          'Web Bluetooth is unavailable. Use Chrome or Edge on a supported device.',
        );
      }
      final device = await requestWebBleDevice(
        serviceUuids: [_primaryServiceUuid],
        namePrefix: 'GDX-RB',
      );

      if (device == null) {
        connectionState.value = GoDirectConnectionState.disconnected;
        return false;
      }
      if (_disposed || _manualDisconnect || session != _sessionGeneration) {
        disconnectGatt(device);
        return false;
      }
      _device = device;
      _disconnectListener = addGattDisconnectedListener(
        device,
        _handleGattDisconnected,
      );

      final connected = await connectGatt(device);
      if (!connected) {
        throw StateError('Web BLE GATT connection failed');
      }
      if (_disposed ||
          _manualDisconnect ||
          session != _sessionGeneration ||
          !identical(_device, device)) {
        throw StateError('Web BLE connection was cancelled');
      }

      connectedDeviceName = device.name;
      connectionState.value = GoDirectConnectionState.initializing;

      final service = await getService(device, _primaryServiceUuid);
      if (service == null) {
        throw StateError('Go Direct primary service not found');
      }

      _commandChar = await getCharacteristic(service, _commandCharUuid);
      _responseChar = await getCharacteristic(service, _responseCharUuid);

      if (_commandChar == null || _responseChar == null) {
        throw StateError('Required characteristics not found');
      }

      _responseParser.reset();
      final responseStream = await startNotificationsReady(_responseChar!);
      _responseSub = responseStream.listen(
        _onResponseNotification,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('GoDirectServiceWeb notification error: $error');
          if (_initComplete) {
            _handleGattDisconnected();
          }
        },
      );

      await _runInitSequence();

      if (_disposed ||
          _manualDisconnect ||
          session != _sessionGeneration ||
          !identical(_device, device)) {
        throw StateError('Web BLE connection was lost during initialization');
      }

      _initComplete = true;
      _lastConnectedDeviceName = connectedDeviceName;
      connectionState.value = GoDirectConnectionState.connected;
      debugPrint(
        'GoDirectServiceWeb connected to $connectedDeviceName '
        '(${_sensors.length} sensors)',
      );
      return true;
    } catch (e) {
      debugPrint('GoDirectServiceWeb connect failed: $e');
      final interrupted =
          _manualDisconnect ||
          session != _sessionGeneration ||
          connectionState.value == GoDirectConnectionState.disconnected;
      if (!interrupted && !_disposed) {
        lastError = 'Unable to connect to the respiration belt: $e';
        connectionState.value = GoDirectConnectionState.error;
      }
      await _cleanup();
      if (interrupted && !_disposed) {
        connectionState.value = GoDirectConnectionState.disconnected;
      }
      return false;
    }
  }

  Future<bool> reconnect() async {
    if (_disposed) return false;
    await _cleanup();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return connect();
  }

  Future<void> disconnect() {
    final existing = _disconnectInFlight;
    if (existing != null) return existing;

    late final Future<void> disconnectFuture;
    disconnectFuture = _disconnectInternal().whenComplete(() {
      if (identical(_disconnectInFlight, disconnectFuture)) {
        _disconnectInFlight = null;
      }
    });
    _disconnectInFlight = disconnectFuture;
    return disconnectFuture;
  }

  Future<void> _disconnectInternal() async {
    _manualDisconnect = true;
    lastError = null;
    if (!_disposed) {
      connectionState.value = GoDirectConnectionState.disconnecting;
    }

    try {
      final session = _sessionGeneration;
      await _measurementQueue.enqueue(
        () => _stopMeasurementsInternal(force: true, session: session),
      );
      if (_commandChar != null && (_device?.gatt.connected ?? false)) {
        try {
          final response = await _sendCommandAndWait(
            _packetBuilder.buildDisconnect(),
            timeoutMs: 2000,
          );
          _logCommandStatus(response, 'DISCONNECT');
        } catch (e) {
          debugPrint('GoDirectServiceWeb DISCONNECT warning: $e');
        }
      }
    } finally {
      await _cleanup();
      if (!_disposed) {
        connectionState.value = GoDirectConnectionState.disconnected;
      }
    }
  }

  Future<void> startMeasurements({
    List<int>? sensorNumbers,
    int periodMs = 100,
  }) {
    final session = _sessionGeneration;
    return _measurementQueue.enqueue(
      () => _startMeasurementsInternal(
        sensorNumbers: sensorNumbers,
        periodMs: periodMs,
        session: session,
      ),
    );
  }

  Future<void> _startMeasurementsInternal({
    required List<int>? sensorNumbers,
    required int periodMs,
    required int session,
  }) async {
    if (session != _sessionGeneration) {
      throw StateError('Go Direct connection changed before streaming started');
    }
    if (_commandChar == null) {
      throw StateError('Not connected');
    }

    if (_isStreaming) {
      await _stopMeasurementsInternal(force: false, session: session);
    }

    _enabledSensorNumbers.clear();
    if (sensorNumbers != null && sensorNumbers.isNotEmpty) {
      _enabledSensorNumbers.addAll(
        sensorNumbers.where((sn) => sn >= 0 && sn < 32).toSet(),
      );
    } else if (_defaultSensorMask > 0) {
      for (final sn in _sensors.keys) {
        if (_defaultSensorMask & (1 << sn) != 0) {
          _enabledSensorNumbers.add(sn);
        }
      }
    }
    if (_enabledSensorNumbers.isEmpty && _sensors.isNotEmpty) {
      _enabledSensorNumbers.add(_sensors.keys.first);
    }
    if (_enabledSensorNumbers.isEmpty) {
      throw StateError('No sensors available');
    }
    _enabledSensorNumbers.sort();

    int sensorMask = 0;
    for (final sn in _enabledSensorNumbers) {
      sensorMask |= (1 << sn);
    }

    final normalizedPeriodMs = periodMs.clamp(10, 0x7FFFFFFF).toInt();
    final periodUs = normalizedPeriodMs * 1000;
    try {
      await _sendCommandAndWait(
        _packetBuilder.buildSetMeasurementPeriod(periodUs),
      );
      final startResponse = await _sendCommandAndWait(
        _packetBuilder.buildStartMeasurements(sensorMask),
      );
      _requireSuccessfulCommand(startResponse, 'START_MEASUREMENTS');
    } catch (_) {
      _isStreaming = false;
      _enabledSensorNumbers.clear();
      rethrow;
    }

    _isStreaming = true;
    _measurementPeriodMs = normalizedPeriodMs;
    connectionState.value = GoDirectConnectionState.streaming;
  }

  Future<void> stopMeasurements() {
    final session = _sessionGeneration;
    return _measurementQueue.enqueue(
      () => _stopMeasurementsInternal(force: false, session: session),
    );
  }

  Future<void> _stopMeasurementsInternal({
    required bool force,
    required int session,
  }) async {
    if (session != _sessionGeneration) return;
    if (!force && !_isStreaming) return;
    try {
      if (_commandChar != null && (_device?.gatt.connected ?? false)) {
        final stopResponse = await _sendCommandAndWait(
          _packetBuilder.buildStopMeasurements(),
        );
        _logCommandStatus(stopResponse, 'STOP_MEASUREMENTS');
      }
    } catch (e) {
      debugPrint('GoDirectServiceWeb stopMeasurements warning: $e');
    }
    _isStreaming = false;
    _enabledSensorNumbers.clear();
    if (connectionState.value == GoDirectConnectionState.streaming) {
      connectionState.value = GoDirectConnectionState.connected;
    }
  }

  Future<void> _runInitSequence() async {
    _packetBuilder.reset();

    await _sendCommandAndWait(_packetBuilder.buildInit(), timeoutMs: 4000);
    await _sendCommandAndWait(
      _packetBuilder.buildGetBatteryStatus(),
      timeoutMs: 3000,
    );
    await _sendCommandAndWait(
      _packetBuilder.buildGetDeviceInfo(),
      timeoutMs: 3000,
    );

    _sensors.clear();
    _defaultSensorMask = 0;

    final maskRsp = await _sendCommandAndWait(
      _packetBuilder.buildGetDefaultSensorsMask(),
    );
    _defaultSensorMask = parseDefaultSensorsMask(maskRsp.payload);

    try {
      final sensorIdsRsp = await _sendCommandAndWait(
        _packetBuilder.buildGetAvailableSensors(),
      );
      final sensorIds = parseSensorIds(sensorIdsRsp.payload);

      for (final id in sensorIds) {
        try {
          final infoRsp = await _sendCommandAndWait(
            _packetBuilder.buildGetSensorInfo(id),
          );
          final info = parseSensorInfo(infoRsp.payload);
          if (info != null) _sensors[info.sensorNumber] = info;
        } catch (e) {
          debugPrint('GoDirectServiceWeb getSensorInfo($id) failed: $e');
        }
      }
    } catch (e) {
      debugPrint('GoDirectServiceWeb sensor discovery failed: $e');
    }

    if (_sensors.isEmpty) {
      final name = connectedDeviceName ?? '';
      for (final entry in knownGoDirectDevices.entries) {
        if (name.startsWith(entry.key)) {
          for (final sensor in entry.value) {
            _sensors[sensor.sensorNumber] = sensor;
          }
          break;
        }
      }
      if (_sensors.isEmpty) {
        final rbSensors = knownGoDirectDevices['GDX-RB']!;
        for (final sensor in rbSensors) {
          _sensors[sensor.sensorNumber] = sensor;
        }
      }
    }
  }

  void _onResponseNotification(List<int> data) {
    final rawHex = data
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    debugPrint('GoDirectServiceWeb RX NOTIFY: [$rawHex]');

    final responses = _responseParser.feed(data);
    _lastRawNotification = data;

    for (final rsp in responses) {
      if (rsp.isMeasurement) {
        _onMeasurementPacket(rsp.packet);
        continue;
      }

      final rspHex = rsp.packet
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      debugPrint('GoDirectServiceWeb RX REASSEMBLED: [$rspHex]');

      _lastCompletedResponse = rsp;

      final pending = _pendingResponse;
      final matchesPending =
          pending != null &&
          !pending.isCompleted &&
          rsp.commandId == _pendingCommandId &&
          rsp.counter == _pendingCounter;

      debugPrint(
        'GoDirectServiceWeb RX RESPONSE: '
        'cmdId=0x${rsp.commandId.toRadixString(16).padLeft(2, '0')}, '
        'counter=0x${rsp.counter.toRadixString(16).padLeft(2, '0')}, '
        'payload=${rsp.payload}, '
        'matchedPending=$matchesPending',
      );

      if (matchesPending) {
        pending.complete(rsp);
      } else {
        debugPrint('GoDirectServiceWeb unsolicited response: $rsp');
      }
    }
  }

  void _onMeasurementPacket(List<int> packet) {
    if (!_isStreaming || _enabledSensorNumbers.isEmpty) return;
    if (_measurementController.isClosed) return;

    final now = DateTime.now();
    final parsed = parseMeasurementData(packet, _enabledSensorNumbers);

    for (final entry in parsed.entries) {
      if (!_enabledSensorNumbers.contains(entry.key)) continue;
      for (var index = 0; index < entry.value.length; index++) {
        final value = entry.value[index];
        if (value.isNaN || value.abs() > 1e10) continue;
        final samplesAfterThis = entry.value.length - index - 1;
        _measurementController.add(
          GoDirectMeasurement(
            sensorNumber: entry.key,
            value: value,
            timestamp: now.subtract(
              Duration(milliseconds: samplesAfterThis * _measurementPeriodMs),
            ),
          ),
        );
      }
    }
  }

  Future<GoDirectResponse> _sendCommandAndWait(
    Uint8List packet, {
    int timeoutMs = 3000,
  }) {
    final session = _sessionGeneration;
    return _commandQueue.enqueue(
      () => _sendCommandAndWaitInternal(
        packet,
        timeoutMs: timeoutMs,
        session: session,
      ),
    );
  }

  Future<GoDirectResponse> _sendCommandAndWaitInternal(
    Uint8List packet, {
    required int timeoutMs,
    required int session,
  }) async {
    if (session != _sessionGeneration) {
      throw StateError('Go Direct connection changed before command was sent');
    }
    if (_commandChar == null) {
      throw StateError('Command characteristic not available');
    }

    if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
      throw StateError('Another Go Direct command is already in progress');
    }

    final pending = Completer<GoDirectResponse>();
    _pendingResponse = pending;
    _pendingCommandId = packet.length > 4 ? packet[4] : null;
    _pendingCounter = packet.length > 2 ? packet[2] : null;

    final hexPacket = packet
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    debugPrint(
      'GoDirectServiceWeb TX CMD: '
      'cmdId=0x${_pendingCommandId?.toRadixString(16).padLeft(2, '0') ?? "??"}, '
      'counter=0x${_pendingCounter?.toRadixString(16).padLeft(2, '0') ?? "??"}, '
      'checksum=0x${packet.length > 3 ? packet[3].toRadixString(16).padLeft(2, "0") : "??"}, '
      'packet=[$hexPacket]',
    );

    const maxWriteLength = 20;
    try {
      for (var offset = 0; offset < packet.length; offset += maxWriteLength) {
        if (session != _sessionGeneration) {
          throw StateError('Go Direct connection changed during command');
        }
        final end = (offset + maxWriteLength).clamp(0, packet.length).toInt();
        final chunk = packet.sublist(offset, end);
        final chunkHex = chunk
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(' ');
        debugPrint('GoDirectServiceWeb TX CHUNK[$offset..$end]: [$chunkHex]');
        await writeCharacteristic(_commandChar!, chunk);
      }

      return await pending.future.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout: () {
          final lastRaw = _lastRawNotification;
          final lastRsp = _lastCompletedResponse;
          debugPrint(
            'GoDirectServiceWeb TIMEOUT: '
            'expected cmdId=0x${_pendingCommandId?.toRadixString(16).padLeft(2, '0') ?? "??"}, '
            'expected counter=0x${_pendingCounter?.toRadixString(16).padLeft(2, '0') ?? "??"}, '
            'lastRawNotification=${lastRaw != null ? "[${lastRaw.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}]" : "none"}, '
            'lastCompletedResponse=${lastRsp ?? "none"}',
          );
          throw TimeoutException('No response within ${timeoutMs}ms');
        },
      );
    } finally {
      if (identical(_pendingResponse, pending)) {
        _pendingResponse = null;
        _pendingCommandId = null;
        _pendingCounter = null;
      }
    }
  }

  void _requireSuccessfulCommand(GoDirectResponse response, String command) {
    if (response.payload.isNotEmpty && response.payload.first != 0) {
      final status = 'status 0x${response.payload.first.toRadixString(16)}';
      throw StateError('Go Direct $command failed ($status)');
    }
  }

  void _logCommandStatus(GoDirectResponse response, String command) {
    if (response.payload.isNotEmpty && response.payload.first != 0) {
      final status = 'status 0x${response.payload.first.toRadixString(16)}';
      debugPrint('GoDirectServiceWeb $command status note ($status)');
    }
  }

  void _handleGattDisconnected() {
    final state = connectionState.value;
    if (_disposed ||
        _manualDisconnect ||
        !_initComplete ||
        _cleanupInFlight != null ||
        state == GoDirectConnectionState.connecting ||
        state == GoDirectConnectionState.initializing ||
        state == GoDirectConnectionState.disconnecting ||
        state == GoDirectConnectionState.disconnected ||
        state == GoDirectConnectionState.error) {
      return;
    }

    debugPrint('GoDirectServiceWeb unexpected disconnection');
    lastError =
        'The respiration belt disconnected unexpectedly. '
        'Wake the belt and reconnect.';
    connectionState.value = GoDirectConnectionState.disconnected;
    unawaited(_cleanup());
  }

  Future<void> _cleanup() {
    final existing = _cleanupInFlight;
    if (existing != null) return existing;

    final cleanupFuture = _cleanupInternal();
    _cleanupInFlight = cleanupFuture;
    unawaited(
      cleanupFuture.then<void>(
        (_) {
          if (identical(_cleanupInFlight, cleanupFuture)) {
            _cleanupInFlight = null;
          }
        },
        onError: (Object _, StackTrace __) {
          if (identical(_cleanupInFlight, cleanupFuture)) {
            _cleanupInFlight = null;
          }
        },
      ),
    );
    return cleanupFuture;
  }

  Future<void> _cleanupInternal() async {
    _sessionGeneration++;
    _isStreaming = false;
    _initComplete = false;
    _enabledSensorNumbers.clear();
    _sensors.clear();
    _defaultSensorMask = 0;
    _measurementPeriodMs = 100;
    _responseParser.reset();
    _packetBuilder.reset();
    connectedDeviceName = null;

    final pending = _pendingResponse;
    _pendingResponse = null;
    _pendingCommandId = null;
    _pendingCounter = null;
    _lastRawNotification = null;
    _lastCompletedResponse = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError('Cleanup'));
    }

    final responseSub = _responseSub;
    final device = _device;
    final disconnectListener = _disconnectListener;
    _responseSub = null;
    _disconnectListener = null;
    _device = null;
    _commandChar = null;
    _responseChar = null;

    await responseSub?.cancel();
    if (device != null && disconnectListener != null) {
      removeGattDisconnectedListener(device, disconnectListener);
    }

    if (device != null) {
      disconnectGatt(device);
    }
  }

  void dispose() {
    _disposed = true;
    _manualDisconnect = true;
    unawaited(_cleanup());
    if (!_measurementController.isClosed) _measurementController.close();
    connectionState.dispose();
  }
}
