// SPDX-License-Identifier: AGPL-3.0-only
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'go_direct_constants.dart';
import 'go_direct_protocol.dart';

class GoDirectService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _responseChar;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
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
  Future<void>? _scanInFlight;
  Future<bool>? _connectInFlight;
  Future<void>? _disconnectInFlight;
  Future<void>? _cleanupInFlight;
  int _scanGeneration = 0;
  int _sessionGeneration = 0;
  bool _manualDisconnect = false;
  bool _isStreaming = false;
  bool _disposed = false;
  bool _initComplete = false;
  bool _notificationsEnabled = false;
  int _measurementPeriodMs = 100;
  int _negotiatedMtu = 23;
  GoDirectStage _stage = GoDirectStage.idle;
  GoDirectWriteMode? _writeMode;
  String _commandProperties = 'unavailable';
  String _responseProperties = 'unavailable';
  List<int>? _lastReassembledPacket;

  final Map<int, GoDirectSensorInfo> _sensors = {};
  final Map<String, String> _scannedDeviceNames = {};
  final Map<String, GoDirectScannedDevice> _scannedDevices = {};
  final Map<String, DateTime> _scannedDeviceLastSeen = {};
  final List<int> _enabledSensorNumbers = [];
  int _defaultSensorMask = 0;
  Timer? _pruneTimer;
  static const Duration _deviceRetentionDuration = Duration(seconds: 15);

  final connectionState = ValueNotifier<GoDirectConnectionState>(
    GoDirectConnectionState.disconnected,
  );
  String? connectedDeviceName;
  String? lastError;
  String? _lastConnectedDeviceId;
  String? _lastConnectedDeviceName;
  bool hasCompletedScan = false;

  String? get lastConnectedDeviceId => _lastConnectedDeviceId;
  String? get lastConnectedDeviceName =>
      _lastConnectedDeviceName ?? connectedDeviceName;
  bool get isInitComplete => _initComplete;

  List<GoDirectSensorInfo> get availableSensors => List.unmodifiable(
    _sensors.values.toList()
      ..sort((a, b) => a.sensorNumber.compareTo(b.sensorNumber)),
  );

  bool get isStreaming => _isStreaming;

  bool get isConnected =>
      connectionState.value == GoDirectConnectionState.connected ||
      connectionState.value == GoDirectConnectionState.streaming;

  final _scanResultsController =
      StreamController<List<GoDirectScannedDevice>>.broadcast();
  final _measurementController =
      StreamController<GoDirectMeasurement>.broadcast();

  Stream<List<GoDirectScannedDevice>> get scanResults =>
      _scanResultsController.stream;

  Stream<GoDirectMeasurement> get measurementStream =>
      _measurementController.stream;

  Stream<double> get respirationForceStream =>
      measurementStream.where((m) => m.sensorNumber == 1).map((m) => m.value);

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) {
    if (_disposed) return Future<void>.value();
    final existing = _scanInFlight;
    if (existing != null) return existing;

    final state = connectionState.value;
    if (state == GoDirectConnectionState.connecting ||
        state == GoDirectConnectionState.initializing ||
        state == GoDirectConnectionState.connected ||
        state == GoDirectConnectionState.streaming ||
        state == GoDirectConnectionState.disconnecting) {
      return Future<void>.value();
    }

    late final Future<void> scanFuture;
    scanFuture = _startScanInternal(timeout).whenComplete(() {
      if (identical(_scanInFlight, scanFuture)) _scanInFlight = null;
    });
    _scanInFlight = scanFuture;
    return scanFuture;
  }

  Future<void> _startScanInternal(Duration timeout) async {
    final scanGeneration = ++_scanGeneration;

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _pruneTimer?.cancel();
    _pruneTimer = null;

    if (_disposed || scanGeneration != _scanGeneration) return;

    _scannedDeviceNames.clear();
    _scannedDevices.clear();
    _scannedDeviceLastSeen.clear();
    lastError = null;
    hasCompletedScan = false;
    connectionState.value = GoDirectConnectionState.scanning;
    _setStage(GoDirectStage.scanning);
    if (!_scanResultsController.isClosed) {
      _scanResultsController.add(const []);
    }

    _pruneTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pruneExpiredDevices(scanGeneration);
    });

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (_disposed || scanGeneration != _scanGeneration) return;
        final now = DateTime.now();

        for (final result in results) {
          final advertisementName = result.advertisementData.advName.trim();
          final platformName = result.device.platformName.trim();
          final name =
              advertisementName.isNotEmpty ? advertisementName : platformName;
          final serviceUuids = result.advertisementData.serviceUuids;

          if (!isGoDirectCandidate(name: name, serviceUuids: serviceUuids)) {
            continue;
          }

          final id = result.device.remoteId.str;
          final displayName = name.isNotEmpty ? name : 'Go Direct device';
          _scannedDeviceNames[id] = displayName;
          _scannedDeviceLastSeen[id] = now;
          _scannedDevices[id] = GoDirectScannedDevice(
            id: id,
            name: displayName,
            rssi: result.rssi,
          );
        }

        _pruneExpiredDevices(scanGeneration);
      },
      onError: (Object e) {
        if (_disposed || scanGeneration != _scanGeneration) return;
        debugPrint('GoDirectService scan error: $e');
        lastError = _friendlyBleError('Bluetooth scan failed', e);
        connectionState.value = GoDirectConnectionState.error;
        _setStage(GoDirectStage.error);
      },
    );

    try {
      if (!await FlutterBluePlus.isSupported) {
        throw StateError(
          'Bluetooth Low Energy is not supported on this device',
        );
      }
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        throw StateError('Bluetooth is turned off');
      }

      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidCheckLocationServices: false,
      );

      await FlutterBluePlus.isScanning
          .where((isScanning) => !isScanning)
          .first
          .timeout(timeout + const Duration(seconds: 3));
    } catch (e, st) {
      debugPrint('GoDirectService startScan failed: $e');
      debugPrintStack(stackTrace: st);
      if (!_disposed && scanGeneration == _scanGeneration) {
        lastError = _friendlyBleError(
          'Unable to scan for Go Direct devices',
          e,
        );
        connectionState.value = GoDirectConnectionState.error;
        _setStage(GoDirectStage.error);
      }
    } finally {
      if (scanGeneration == _scanGeneration) {
        _pruneTimer?.cancel();
        _pruneTimer = null;
        if (FlutterBluePlus.isScanningNow) {
          try {
            await FlutterBluePlus.stopScan();
          } catch (_) {}
        }
        await _scanSubscription?.cancel();
        _scanSubscription = null;
        hasCompletedScan = true;
        if (connectionState.value == GoDirectConnectionState.scanning) {
          connectionState.value = GoDirectConnectionState.disconnected;
          _setStage(GoDirectStage.idle);
        }
      }
    }
  }

  void _pruneExpiredDevices(int scanGeneration) {
    if (_disposed || scanGeneration != _scanGeneration) return;
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final entry in _scannedDeviceLastSeen.entries) {
      if (now.difference(entry.value) > _deviceRetentionDuration) {
        expiredIds.add(entry.key);
      }
    }

    if (expiredIds.isNotEmpty) {
      for (final id in expiredIds) {
        _scannedDeviceLastSeen.remove(id);
        _scannedDevices.remove(id);
      }
    }

    final devices =
        _scannedDevices.values.toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
    if (!_scanResultsController.isClosed) {
      _scanResultsController.add(devices);
    }
  }

  Future<void> stopScan() async {
    _scanGeneration++;
    _pruneTimer?.cancel();
    _pruneTimer = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (connectionState.value == GoDirectConnectionState.scanning) {
      connectionState.value = GoDirectConnectionState.disconnected;
      _setStage(GoDirectStage.idle);
    }
  }

  Future<bool> connect(String deviceId) {
    if (_disposed) return Future<bool>.value(false);
    final existing = _connectInFlight;
    if (existing != null) return existing;

    late final Future<bool> connectFuture;
    connectFuture = _connectInternal(deviceId).whenComplete(() {
      if (identical(_connectInFlight, connectFuture)) _connectInFlight = null;
    });
    _connectInFlight = connectFuture;
    return connectFuture;
  }

  Future<bool> _connectInternal(String deviceId) async {
    await stopScan();

    final disconnectFuture = _disconnectInFlight;
    if (disconnectFuture != null) await disconnectFuture;
    final cleanupFuture = _cleanupInFlight;
    if (cleanupFuture != null) await cleanupFuture;

    if (isConnected &&
        _device?.isConnected == true &&
        _device?.remoteId.str == deviceId) {
      lastError = null;
      return true;
    }
    if (_device != null ||
        _connectionStateSub != null ||
        _responseSub != null ||
        isConnected) {
      await disconnect();
    }

    _manualDisconnect = false;
    _initComplete = false;
    lastError = null;
    final session = ++_sessionGeneration;
    connectionState.value = GoDirectConnectionState.connecting;
    _setStage(GoDirectStage.connecting);

    try {
      final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
      _device = device;

      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
        mtu: null,
      );

      connectedDeviceName =
          device.platformName.isNotEmpty
              ? device.platformName
              : (_scannedDeviceNames[deviceId] ?? deviceId);
      _negotiatedMtu = device.mtuNow;
      _gdxLog(
        'CONNECT',
        'GDX CONNECTED name=$connectedDeviceName id=$deviceId '
            'MTU current: $_negotiatedMtu (fixed 20-byte GDX writes)',
      );

      if (_disposed ||
          _manualDisconnect ||
          session != _sessionGeneration ||
          !identical(_device, device)) {
        throw StateError('Go Direct connection was cancelled');
      }

      await _connectionStateSub?.cancel();
      _connectionStateSub = device.connectionState.listen((state) {
        if (!identical(_device, device)) return;
        final appState = connectionState.value;
        if (state == BluetoothConnectionState.disconnected &&
            device.isDisconnected &&
            _initComplete &&
            (appState == GoDirectConnectionState.connected ||
                appState == GoDirectConnectionState.streaming)) {
          _handleUnexpectedDisconnection();
        }
      });

      connectionState.value = GoDirectConnectionState.initializing;
      _setStage(GoDirectStage.discoveringGatt);

      final services = await device.discoverServices();
      final gdService = services.firstWhere(
        (s) => s.uuid == GoDirectUuids.primaryService,
        orElse:
            () =>
                throw StateError(
                  'Go Direct primary service not found on $deviceId',
                ),
      );
      _gdxLog('GATT', 'GDX SERVICE DISCOVERED uuid=${gdService.uuid}');

      _commandChar = gdService.characteristics.firstWhere(
        (c) => c.uuid == GoDirectUuids.commandChar,
        orElse:
            () =>
                throw StateError(
                  'Go Direct command characteristic (${GoDirectUuids.commandChar}) not found',
                ),
      );
      _responseChar = gdService.characteristics.firstWhere(
        (c) => c.uuid == GoDirectUuids.responseChar,
        orElse:
            () =>
                throw StateError(
                  'Go Direct response characteristic (${GoDirectUuids.responseChar}) not found',
                ),
      );

      _commandProperties = _propertiesText(_commandChar!.properties);
      _responseProperties = _propertiesText(_responseChar!.properties);
      _gdxLog('GATT', 'GDX COMMAND PROPERTIES: $_commandProperties');
      _gdxLog('GATT', 'GDX COMMAND CHAR properties=$_commandProperties');
      _gdxLog('GATT', 'GDX RESPONSE CHAR properties=$_responseProperties');

      _writeMode = selectGoDirectWriteMode(
        supportsWrite: _commandChar!.properties.write,
        supportsWriteWithoutResponse:
            _commandChar!.properties.writeWithoutResponse,
      );
      _gdxLog('GATT', 'GDX WRITE MODE: $_writeModeName');
      if (_writeMode == GoDirectWriteMode.withResponse) {
        _gdxLog(
          'GATT',
          'Command characteristic does not expose writeWithoutResponse; '
              'falling back explicitly to write-with-response',
        );
      }
      if (!_responseChar!.properties.notify &&
          !_responseChar!.properties.indicate) {
        throw StateError(
          'Go Direct response characteristic supports neither notify nor indicate',
        );
      }

      _responseParser.reset();
      _lastRawNotification = null;
      _lastReassembledPacket = null;
      await _responseSub?.cancel();
      _responseSub = _responseChar!.onValueReceived.listen(
        _onResponseNotification,
        onError: (Object error, StackTrace stackTrace) {
          _gdxLog('ERROR', 'notification error: $error');
          if (_initComplete) {
            _handleUnexpectedDisconnection();
          }
        },
      );
      _gdxLog('NOTIFY', 'GDX RESPONSE LISTENER ATTACHED');
      _setStage(GoDirectStage.subscribingNotifications);
      await runGoDirectAfterNotificationSetup<void>(
        enableNotifications: () => _responseChar!.setNotifyValue(true),
        notificationsAreEnabled: () => _responseChar!.isNotifying,
        runWhenReady: () async {
          _notificationsEnabled = true;
          _gdxLog('NOTIFY', 'GDX NOTIFICATIONS ENABLED');
          _gdxLog('GATT', 'GDX READY FOR INIT');
          await _runInitSequence();
        },
      );

      if (_disposed ||
          _manualDisconnect ||
          session != _sessionGeneration ||
          !identical(_device, device)) {
        throw StateError('Go Direct connection was lost during initialization');
      }

      _initComplete = true;
      _lastConnectedDeviceId = deviceId;
      _lastConnectedDeviceName = connectedDeviceName;
      connectionState.value = GoDirectConnectionState.connected;
      _setStage(GoDirectStage.ready);
      _gdxLog(
        'STATE',
        'GDX READY name=$connectedDeviceName sensors=${_sensors.length}',
      );
      return true;
    } catch (e, st) {
      final failedStage = _stage;
      _setStage(GoDirectStage.error);
      _gdxLog('ERROR', 'connect failed at ${failedStage.name}: $e\n$st');
      final interrupted =
          _manualDisconnect ||
          session != _sessionGeneration ||
          connectionState.value == GoDirectConnectionState.disconnected;
      if (!interrupted && !_disposed) {
        lastError = _friendlyBleError(
          'Unable to connect to the respiration belt',
          e,
          stage: failedStage,
        );
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
    final deviceId = _lastConnectedDeviceId;
    if (deviceId == null) return false;
    if (_disposed) return false;

    _gdxLog('CONNECT', 'attempting clean reconnect to $deviceId');
    lastError = null;

    await _cleanup();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return connect(deviceId);
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
      _setStage(GoDirectStage.disconnecting);
    }

    try {
      final session = _sessionGeneration;
      await _measurementQueue.enqueue(
        () => _stopMeasurementsInternal(force: true, session: session),
      );
      if (_commandChar != null && (_device?.isConnected ?? false)) {
        try {
          final response = await _sendCommandAndWait(
            _packetBuilder.buildDisconnect(),
            timeoutMs: 2000,
          );
          _logCommandStatus(response, 'DISCONNECT');
        } catch (e) {
          _gdxLog('ERROR', 'DISCONNECT warning: $e');
        }
      }
    } finally {
      await _cleanup();
      if (!_disposed) {
        connectionState.value = GoDirectConnectionState.disconnected;
      }
      _gdxLog('STATE', 'disconnected');
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
    if (_device == null || _commandChar == null) {
      throw StateError('Not connected to a Go Direct device');
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
      throw StateError('No sensors available to enable');
    }
    _enabledSensorNumbers.sort();

    int sensorMask = 0;
    for (final sn in _enabledSensorNumbers) {
      sensorMask |= (1 << sn);
    }

    _setStage(GoDirectStage.configuringMeasurement);
    final normalizedPeriodMs = _validMeasurementPeriodMs(
      periodMs,
      _enabledSensorNumbers,
    );
    final int periodUs = normalizedPeriodMs * 1000;
    try {
      await _sendCommandAndWait(
        _packetBuilder.buildSetMeasurementPeriod(periodUs),
        timeoutMs: 3000,
      );

      final startResponse = await _sendCommandAndWait(
        _packetBuilder.buildStartMeasurements(sensorMask),
        timeoutMs: 3000,
      );
      _requireSuccessfulCommand(startResponse, 'START_MEASUREMENTS');
    } catch (_) {
      _isStreaming = false;
      _enabledSensorNumbers.clear();
      _setStage(GoDirectStage.ready);
      rethrow;
    }

    _isStreaming = true;
    _measurementPeriodMs = normalizedPeriodMs;
    connectionState.value = GoDirectConnectionState.streaming;
    _setStage(GoDirectStage.streaming);

    final enabledNames = _enabledSensorNumbers
        .map((sn) => _sensors[sn]?.description ?? 'Sensor $sn')
        .join(', ');
    _gdxLog('STATE', 'streaming [$enabledNames] @ ${normalizedPeriodMs}ms');
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
      if (_commandChar != null && (_device?.isConnected ?? false)) {
        final stopResponse = await _sendCommandAndWait(
          _packetBuilder.buildStopMeasurements(),
          timeoutMs: 3000,
        );
        _logCommandStatus(stopResponse, 'STOP_MEASUREMENTS');
      }
    } catch (e) {
      _gdxLog('ERROR', 'STOP_MEASUREMENTS warning: $e');
    }
    _isStreaming = false;
    _enabledSensorNumbers.clear();
    if (connectionState.value == GoDirectConnectionState.streaming) {
      connectionState.value = GoDirectConnectionState.connected;
    }
    if (_initComplete) _setStage(GoDirectStage.ready);
  }

  Future<void> _runInitSequence() async {
    _packetBuilder.reset();

    _setStage(GoDirectStage.init);
    final initResponse = await _sendCommandAndWait(
      _packetBuilder.buildInit(),
      timeoutMs: 4000,
    );
    _logCommandStatus(initResponse, 'INIT');

    _setStage(GoDirectStage.getStatus);
    final statusResponse = await _sendCommandAndWait(
      _packetBuilder.buildGetBatteryStatus(),
      timeoutMs: 3000,
    );
    _gdxLog(
      'PACKET',
      'GET_STATUS payloadLen=${statusResponse.payload.length} '
          'hex=${_hex(statusResponse.payload)}',
    );

    _setStage(GoDirectStage.getDeviceInfo);
    final deviceInfoResponse = await _sendCommandAndWait(
      _packetBuilder.buildGetDeviceInfo(),
      timeoutMs: 3000,
    );
    _gdxLog(
      'PACKET',
      'GET_DEVICE_INFO payloadLen=${deviceInfoResponse.payload.length} '
          'hex=${_hex(deviceInfoResponse.payload)}',
    );

    _sensors.clear();
    _defaultSensorMask = 0;

    _setStage(GoDirectStage.getDefaultSensors);
    final maskRsp = await _sendCommandAndWait(
      _packetBuilder.buildGetDefaultSensorsMask(),
      timeoutMs: 3000,
    );
    _defaultSensorMask = parseDefaultSensorsMask(maskRsp.payload);
    _gdxLog(
      'PACKET',
      'DEFAULT MASK: 0x${_defaultSensorMask.toRadixString(16).padLeft(8, '0')}',
    );

    _setStage(GoDirectStage.getSensorIds);
    final sensorIdsRsp = await _sendCommandAndWait(
      _packetBuilder.buildGetAvailableSensors(),
      timeoutMs: 3000,
    );
    final availableMask = parseSensorMask(sensorIdsRsp.payload);
    final sensorIds = parseSensorIds(sensorIdsRsp.payload);
    _gdxLog(
      'PACKET',
      'AVAILABLE MASK: 0x${availableMask.toRadixString(16).padLeft(8, '0')} '
          'channels=$sensorIds',
    );

    for (final id in sensorIds) {
      _setStage(GoDirectStage.getSensorInfo);
      final infoRsp = await _sendCommandAndWait(
        _packetBuilder.buildGetSensorInfo(id),
        timeoutMs: 3000,
      );
      final info = parseSensorInfo(infoRsp.payload);
      if (info == null) {
        _gdxLog(
          'ERROR',
          'GET_SENSOR_INFO sensor=$id malformed payloadLen='
              '${infoRsp.payload.length} hex=${_hex(infoRsp.payload)}',
        );
        continue;
      }
      _sensors[info.sensorNumber] = info;
      _gdxLog(
        'PACKET',
        'SENSOR ${info.sensorNumber} id=${info.sensorId ?? 'unknown'} '
            'name=${info.description} unit=${info.units} '
            'typicalPeriod=${info.typicalPeriodMs ?? 'unknown'}ms '
            'minimumPeriod=${info.minimumPeriodMs ?? 'unknown'}ms',
      );
    }

    var sensorsDiscovered = _sensors.isNotEmpty;

    if (!sensorsDiscovered) {
      final name = connectedDeviceName ?? '';

      for (final entry in knownGoDirectDevices.entries) {
        if (name.startsWith(entry.key)) {
          for (final sensor in entry.value) {
            _sensors[sensor.sensorNumber] = sensor;
          }
          _gdxLog(
            'STATE',
            'using fallback config for "${entry.key}" '
                '(${entry.value.length} sensors)',
          );
          sensorsDiscovered = true;
          break;
        }
      }

      if (!sensorsDiscovered) {
        final rbSensors = knownGoDirectDevices['GDX-RB']!;
        for (final sensor in rbSensors) {
          _sensors[sensor.sensorNumber] = sensor;
        }
        _gdxLog(
          'STATE',
          'using GDX-RB degraded profile for "$name" '
              '(${rbSensors.length} sensors)',
        );
        sensorsDiscovered = true;
      }
    }

    _setStage(GoDirectStage.ready);
  }

  void _onResponseNotification(List<int> data) {
    final rawHex = data
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    _gdxLog('RX', 'RX NOTIFY len=${data.length} hex=$rawHex');

    final responses = _responseParser.feed(data);
    _lastRawNotification = data;

    for (final rsp in responses) {
      _lastReassembledPacket = rsp.packet;
      _gdxLog(
        'PACKET',
        'RX PACKET declaredLen=${rsp.packet[1]} actualLen=${rsp.packet.length} '
            'hex=${_hex(rsp.packet)}',
      );
      if (rsp.isMeasurement) {
        final type = rsp.packet.length > 4 ? rsp.packet[4] : -1;
        if (!_isKnownMeasurementType(type)) {
          _gdxLog(
            'ERROR',
            'Unknown measurement type=0x${type.toRadixString(16)} ignored',
          );
        } else {
          _gdxLog(
            'RX',
            'measurement type=0x${type.toRadixString(16).padLeft(2, '0')}',
          );
        }
        _onMeasurementPacket(rsp.packet);
        continue;
      }

      final rspHex = rsp.packet
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      _gdxLog('PACKET', 'RX REASSEMBLED: $rspHex');

      _lastCompletedResponse = rsp;

      final pending = _pendingResponse;
      final matchesPending =
          pending != null &&
          !pending.isCompleted &&
          goDirectResponseMatches(
            rsp,
            commandId: _pendingCommandId,
            counter: _pendingCounter,
          );

      _gdxLog(
        'RX',
        'RX RESPONSE: '
            'cmdId=0x${rsp.commandId.toRadixString(16).padLeft(2, '0')}, '
            'counter=0x${rsp.counter.toRadixString(16).padLeft(2, '0')}, '
            'payload=${rsp.payload}, '
            'matchedPending=$matchesPending',
      );

      if (matchesPending) {
        _gdxLog(
          'MATCH',
          'MATCH cmd=${rsp.commandId.toRadixString(16).padLeft(2, '0')} '
              'counter=${rsp.counter.toRadixString(16).padLeft(2, '0')}',
        );
        pending.complete(rsp);
      } else {
        _gdxLog('MATCH', 'unexpected response ignored: $rsp');
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
    _gdxLog(
      'TX',
      'TX CMD: '
          'cmdId=0x${_pendingCommandId?.toRadixString(16).padLeft(2, '0') ?? "??"}, '
          'counter=0x${_pendingCounter?.toRadixString(16).padLeft(2, '0') ?? "??"}, '
          'checksum=0x${packet.length > 3 ? packet[3].toRadixString(16).padLeft(2, "0") : "??"}, '
          'packet=[$hexPacket]',
    );

    final commandChar = _commandChar!;
    final writeMode = _writeMode;
    if (writeMode == null) {
      throw StateError(
        'Go Direct write mode was not selected during GATT setup',
      );
    }
    try {
      _gdxLog(
        'TX',
        'cmd=0x${_pendingCommandId?.toRadixString(16).padLeft(2, '0')} '
            'counter=${_pendingCounter?.toRadixString(16).padLeft(2, '0')} '
            'checksum=${packet[3].toRadixString(16).padLeft(2, '0')} '
            'mode=$_writeModeName packet=${_hex(packet)}',
      );
      await writeGoDirectBlePacket(
        packet: packet,
        mode: writeMode,
        writeChunk: (chunk, index, count, withoutResponse) async {
          if (session != _sessionGeneration) {
            throw StateError('Go Direct connection changed during command');
          }
          _gdxLog(
            'TX-CHUNK',
            'TX CHUNK ${index + 1}/$count mode=$_writeModeName '
                'len=${chunk.length} hex=${_hex(chunk)}',
          );
          await commandChar.write(
            chunk,
            withoutResponse: withoutResponse,
            allowLongWrite: false,
          );
        },
      );

      return await pending.future.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout: () {
          final lastRaw = _lastRawNotification;
          final lastRsp = _lastCompletedResponse;
          _gdxLog(
            'ERROR',
            'GoDirectTimeout(stage=${_stage.name}, '
                'device=$connectedDeviceName, id=${_device?.remoteId.str}, '
                'connection=${connectionState.value.name}, '
                'gattConnected=${_device?.isConnected}, mtu=$_negotiatedMtu, '
                'commandProperties=$_commandProperties, '
                'responseProperties=$_responseProperties, '
                'notifications=$_notificationsEnabled, '
                'writeMode=$_writeModeName, '
                'cmd=0x${_pendingCommandId?.toRadixString(16).padLeft(2, '0') ?? "??"}, '
                'counter=0x${_pendingCounter?.toRadixString(16).padLeft(2, '0') ?? "??"}, '
                'tx=${_hex(packet)}, '
                'lastRawRx=${lastRaw == null ? "null" : _hex(lastRaw)}, '
                'lastPacket=${_lastReassembledPacket == null ? "null" : _hex(_lastReassembledPacket!)}, '
                'lastResponse=${lastRsp ?? "null"})',
          );
          throw TimeoutException(
            'GoDirectTimeout(stage=${_stage.name}, '
            'cmd=0x${packet.length > 4 ? packet[4].toRadixString(16) : "??"}, '
            'counter=0x${packet.length > 2 ? packet[2].toRadixString(16) : "??"}, '
            'writeMode=$_writeModeName, notifications=$_notificationsEnabled)',
          );
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
      _gdxLog('ERROR', '$command status note ($status)');
    }
  }

  void _handleUnexpectedDisconnection() {
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
    _gdxLog('ERROR', 'unexpected disconnection');
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
    _notificationsEnabled = false;
    _writeMode = null;
    _commandProperties = 'unavailable';
    _responseProperties = 'unavailable';
    _negotiatedMtu = 23;
    _responseParser.reset();
    _packetBuilder.reset();
    connectedDeviceName = null;

    final pending = _pendingResponse;
    _pendingResponse = null;
    _pendingCommandId = null;
    _pendingCounter = null;
    _lastRawNotification = null;
    _lastCompletedResponse = null;
    _lastReassembledPacket = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError('Cleanup: pending response cancelled'));
    }

    final responseSub = _responseSub;
    final connectionStateSub = _connectionStateSub;
    final responseChar = _responseChar;
    final device = _device;
    _responseSub = null;
    _connectionStateSub = null;
    _device = null;
    _commandChar = null;
    _responseChar = null;

    await responseSub?.cancel();
    await connectionStateSub?.cancel();

    try {
      await responseChar?.setNotifyValue(false);
    } catch (_) {}

    try {
      await device?.disconnect(timeout: 5, queue: false, androidDelay: 2000);
    } catch (_) {}

    if (!_disposed) _setStage(GoDirectStage.idle);
  }

  int _validMeasurementPeriodMs(int requestedMs, List<int> sensorNumbers) {
    var minimumMs = 10;
    for (final sensorNumber in sensorNumbers) {
      final sensorMinimum = _sensors[sensorNumber]?.minimumPeriodMs;
      if (sensorMinimum != null && sensorMinimum.isFinite) {
        final rounded = sensorMinimum.ceil();
        if (rounded > minimumMs) minimumMs = rounded;
      }
    }
    final selected = requestedMs.clamp(minimumMs, 0x7FFFFFFF).toInt();
    if (selected != requestedMs) {
      _gdxLog(
        'STATE',
        'Measurement period adjusted from ${requestedMs}ms to ${selected}ms '
            'using sensor minimum metadata',
      );
    }
    return selected;
  }

  String get _writeModeName => switch (_writeMode) {
    GoDirectWriteMode.withoutResponse => 'withoutResponse',
    GoDirectWriteMode.withResponse => 'withResponse',
    null => 'unselected',
  };

  static String _propertiesText(CharacteristicProperties properties) {
    return 'write=${properties.write}, '
        'writeWithoutResponse=${properties.writeWithoutResponse}, '
        'read=${properties.read}, notify=${properties.notify}, '
        'indicate=${properties.indicate}';
  }

  static String _hex(List<int> bytes) => bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  static bool _isKnownMeasurementType(int type) {
    return type >= GoDirectMeasurementType.normalReal32 &&
        type <= GoDirectMeasurementType.period;
  }

  void _setStage(GoDirectStage stage) {
    if (_stage == stage) return;
    _stage = stage;
    _gdxLog('STATE', stage.name);
  }

  static void _gdxLog(String area, String message) {
    if (kDebugMode) debugPrint('[GDX][$area] $message');
  }

  String _friendlyBleError(
    String prefix,
    Object error, {
    GoDirectStage? stage,
  }) {
    final detail = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = detail.toLowerCase();
    if (lower.contains('permission') || lower.contains('not authorized')) {
      return '$prefix. Bluetooth permission was denied.';
    }
    if (lower.contains('location')) {
      return '$prefix. Location services are required on Android 11 or older.';
    }
    if (lower.contains('turned off') || lower.contains('adapter')) {
      return '$prefix. Turn Bluetooth on and try again.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      final failedStage = stage ?? _stage;
      if (failedStage == GoDirectStage.subscribingNotifications) {
        return '$prefix. Enabling response notifications timed out.';
      }
      return '$prefix. The belt timed out during ${failedStage.name}.';
    }
    return detail.isEmpty ? prefix : '$prefix: $detail';
  }

  void dispose() {
    _disposed = true;
    _manualDisconnect = true;
    _scanGeneration++;
    _pruneTimer?.cancel();
    _pruneTimer = null;
    unawaited(FlutterBluePlus.stopScan());
    unawaited(_scanSubscription?.cancel());
    unawaited(_cleanup());

    if (!_scanResultsController.isClosed) {
      _scanResultsController.close();
    }
    if (!_measurementController.isClosed) {
      _measurementController.close();
    }

    connectionState.dispose();
  }
}
