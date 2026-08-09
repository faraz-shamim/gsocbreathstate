library;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'go_direct_constants.dart';
import 'go_direct_protocol.dart';

class GoDirectService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _responseChar;
  BluetoothCharacteristic? _measurementChar;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  StreamSubscription<List<int>>? _responseSub;
  StreamSubscription<List<int>>? _measurementSub;

  final _packetBuilder = GoDirectPacketBuilder();
  final _responseParser = GoDirectResponseParser();
  Completer<GoDirectResponse>? _pendingResponse;
  bool _isStreaming = false;
  bool _disposed = false;

  final Map<int, GoDirectSensorInfo> _sensors = {};
  final List<int> _enabledSensorNumbers = [];
  int _defaultSensorMask = 0;

  final connectionState = ValueNotifier<GoDirectConnectionState>(
    GoDirectConnectionState.disconnected,
  );
  String? connectedDeviceName;

  List<GoDirectSensorInfo> get availableSensors =>
      List.unmodifiable(_sensors.values.toList()
        ..sort((a, b) => a.sensorNumber.compareTo(b.sensorNumber)));

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

  Stream<double> get respirationForceStream => measurementStream
      .where((m) => m.sensorNumber == 1)
      .map((m) => m.value);

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_disposed) return;
    connectionState.value = GoDirectConnectionState.scanning;

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        final devices = results
            .map((r) => GoDirectScannedDevice(
                  id: r.device.remoteId.str,
                  name: r.advertisementData.advName.isNotEmpty
                      ? r.advertisementData.advName
                      : 'Go Direct Device',
                  rssi: r.rssi,
                ))
            .toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
        if (!_scanResultsController.isClosed) {
          _scanResultsController.add(devices);
        }
      },
      onError: (Object e) {
        debugPrint('GoDirectService scan error: $e');
        connectionState.value = GoDirectConnectionState.error;
      },
    );

    try {
      await FlutterBluePlus.startScan(
        withServices: [GoDirectUuids.primaryService],
        timeout: timeout,
      );
    } catch (e) {
      debugPrint('GoDirectService startScan failed: $e');
      connectionState.value = GoDirectConnectionState.error;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (connectionState.value == GoDirectConnectionState.scanning) {
      connectionState.value = GoDirectConnectionState.disconnected;
    }
  }

  Future<bool> connect(String deviceId) async {
    if (_disposed) return false;
    await stopScan();
    connectionState.value = GoDirectConnectionState.connecting;

    try {
      _device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));

      _connectionStateSub?.cancel();
      _connectionStateSub = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleUnexpectedDisconnection();
        }
      });

      await _device!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      final services = await _device!.discoverServices();
      final gdService = services.firstWhere(
        (s) => s.uuid == GoDirectUuids.primaryService,
        orElse: () => throw StateError(
            'Go Direct primary service not found on $deviceId'),
      );

      _commandChar = gdService.characteristics.firstWhere(
        (c) => c.uuid == GoDirectUuids.commandChar,
        orElse: () =>
            throw StateError('Command characteristic not found'),
      );
      _responseChar = gdService.characteristics.firstWhere(
        (c) => c.uuid == GoDirectUuids.responseChar,
        orElse: () =>
            throw StateError('Response characteristic not found'),
      );
      _measurementChar = gdService.characteristics.firstWhere(
        (c) => c.uuid == GoDirectUuids.measurementChar,
        orElse: () =>
            throw StateError('Measurement characteristic not found'),
      );

      _responseParser.reset();
      await _responseSub?.cancel();
      _responseSub = _responseChar!.onValueReceived.listen(
        _onResponseNotification,
      );
      await _responseChar!.setNotifyValue(true);

      await _measurementSub?.cancel();
      _measurementSub = _measurementChar!.onValueReceived.listen(
        _onMeasurementNotification,
      );
      await _measurementChar!.setNotifyValue(true);

      connectionState.value = GoDirectConnectionState.initializing;
      connectedDeviceName = _device!.platformName.isNotEmpty
          ? _device!.platformName
          : deviceId;

      await _runInitSequence();

      connectionState.value = GoDirectConnectionState.connected;
      debugPrint(
          'GoDirectService connected to $connectedDeviceName '
          '(${_sensors.length} sensors)');
      return true;
    } catch (e, st) {
      debugPrint('GoDirectService connect failed: $e\n$st');
      connectionState.value = GoDirectConnectionState.error;
      await _cleanup();
      return false;
    }
  }

  Future<void> disconnect() async {
    connectionState.value = GoDirectConnectionState.disconnecting;
    if (_isStreaming) {
      await stopMeasurements();
    }
    await _cleanup();
    connectionState.value = GoDirectConnectionState.disconnected;
    debugPrint('GoDirectService disconnected');
  }
  Future<void> startMeasurements({
    List<int>? sensorNumbers,
    int periodMs = 100,
  }) async {
    if (_device == null || _commandChar == null) {
      throw StateError('Not connected to a Go Direct device');
    }

    _enabledSensorNumbers.clear();
    if (sensorNumbers != null && sensorNumbers.isNotEmpty) {
      _enabledSensorNumbers.addAll(sensorNumbers);
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

    final int periodUs = periodMs * 1000;
    await _sendCommandAndWait(
      _packetBuilder.buildSetMeasurementPeriod(periodUs),
      timeoutMs: 3000,
    );

    await _sendCommandAndWait(
      _packetBuilder.buildStartMeasurements(sensorMask),
      timeoutMs: 3000,
    );

    _isStreaming = true;
    connectionState.value = GoDirectConnectionState.streaming;

    final enabledNames = _enabledSensorNumbers
        .map((sn) => _sensors[sn]?.description ?? 'Sensor $sn')
        .join(', ');
    debugPrint(
      'GoDirectService streaming [$enabledNames] @ ${periodMs}ms',
    );
  }

  Future<void> stopMeasurements() async {
    if (!_isStreaming) return;
    try {
      await _sendCommandAndWait(
        _packetBuilder.buildStopMeasurements(),
        timeoutMs: 3000,
      );
    } catch (e) {
      debugPrint('GoDirectService stopMeasurements warning: $e');
    }
    _isStreaming = false;
    _enabledSensorNumbers.clear();
    if (connectionState.value == GoDirectConnectionState.streaming) {
      connectionState.value = GoDirectConnectionState.connected;
    }
  }

  Future<void> _runInitSequence() async {
    _packetBuilder.reset();

    try {
      await _sendCommandAndWait(
        _packetBuilder.buildInit(),
        timeoutMs: 5000,
      );
    } catch (e) {
      debugPrint('GoDirectService INIT response timeout (non-fatal): $e');
    }

    _sensors.clear();
    bool sensorsDiscovered = false;

    try {
      final sensorIdsRsp = await _sendCommandAndWait(
        _packetBuilder.buildGetAvailableSensors(),
        timeoutMs: 3000,
      );
      final sensorIds = parseSensorIds(sensorIdsRsp.payload);
      debugPrint('GoDirectService sensor IDs: $sensorIds');

      for (final id in sensorIds) {
        try {
          final infoRsp = await _sendCommandAndWait(
            _packetBuilder.buildGetSensorInfo(id),
            timeoutMs: 3000,
          );
          final info = parseSensorInfo(infoRsp.payload);
          if (info != null) {
            _sensors[info.sensorNumber] = info;
            debugPrint('  discovered: $info');
          }
        } catch (e) {
          debugPrint(
              'GoDirectService GET_SENSOR_INFO($id) failed: $e');
        }
      }
      if (_sensors.isNotEmpty) sensorsDiscovered = true;
    } catch (e) {
      debugPrint(
          'GoDirectService sensor discovery failed: $e — '
          'falling back to known-device table');
    }

    if (!sensorsDiscovered) {
      final name = connectedDeviceName ?? '';
      GoDirectSensorInfo? fallbackMatch;

      for (final entry in knownGoDirectDevices.entries) {
        if (name.startsWith(entry.key)) {
          for (final sensor in entry.value) {
            _sensors[sensor.sensorNumber] = sensor;
          }
          debugPrint(
              'GoDirectService using fallback config for '
              '"${entry.key}" (${entry.value.length} sensors)');
          sensorsDiscovered = true;
          break;
        }
      }

      if (!sensorsDiscovered) {
        _sensors[1] = const GoDirectSensorInfo(
          sensorNumber: 1,
          description: 'Sensor 1',
          units: '',
        );
        debugPrint(
            'GoDirectService no known config for "$name" — '
            'assuming sensor 1 exists');
      }
    }

    try {
      final maskRsp = await _sendCommandAndWait(
        _packetBuilder.buildGetDefaultSensorsMask(),
        timeoutMs: 3000,
      );
      _defaultSensorMask = parseDefaultSensorsMask(maskRsp.payload);
      debugPrint(
          'GoDirectService default mask: '
          '0x${_defaultSensorMask.toRadixString(16)}');
    } catch (e) {
      if (_sensors.isNotEmpty) {
        _defaultSensorMask = 1 << _sensors.keys.first;
      }
      debugPrint(
          'GoDirectService GET_DEFAULT_SENSORS_MASK failed: $e — '
          'using mask 0x${_defaultSensorMask.toRadixString(16)}');
    }
  }

  void _onResponseNotification(List<int> data) {
    final responses = _responseParser.feed(data);
    for (final rsp in responses) {
      if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
        _pendingResponse!.complete(rsp);
      } else {
        debugPrint('GoDirectService unsolicited response: $rsp');
      }
    }
  }

  void _onMeasurementNotification(List<int> data) {
    if (!_isStreaming || _enabledSensorNumbers.isEmpty) return;
    if (_measurementController.isClosed) return;

    final now = DateTime.now();
    final parsed = parseMeasurementData(data, _enabledSensorNumbers);

    for (final entry in parsed.entries) {
      for (final value in entry.value) {
        if (value.isNaN || value.abs() > 1e10) continue;

        _measurementController.add(GoDirectMeasurement(
          sensorNumber: entry.key,
          value: value,
          timestamp: now,
        ));
      }
    }
  }

  Future<GoDirectResponse> _sendCommandAndWait(
    Uint8List packet, {
    int timeoutMs = 3000,
  }) async {
    if (_commandChar == null) {
      throw StateError('Command characteristic not available');
    }

    if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
      _pendingResponse!.completeError(
          StateError('Superseded by new command'));
    }

    _pendingResponse = Completer<GoDirectResponse>();

    await _commandChar!.write(packet, withoutResponse: false);

    final response = await _pendingResponse!.future.timeout(
      Duration(milliseconds: timeoutMs),
      onTimeout: () => throw TimeoutException(
        'No response for cmd 0x${packet.length >= 4 ? packet[3].toRadixString(16) : "??"} '
        'within ${timeoutMs}ms',
      ),
    );

    return response;
  }

  void _handleUnexpectedDisconnection() {
    if (connectionState.value == GoDirectConnectionState.disconnecting ||
        connectionState.value == GoDirectConnectionState.disconnected) {
      return; 
    }
    debugPrint('GoDirectService unexpected disconnection');
    _isStreaming = false;
    _enabledSensorNumbers.clear();
    _sensors.clear();
    _responseParser.reset();
    _packetBuilder.reset();
    connectedDeviceName = null;

    _responseSub?.cancel();
    _measurementSub?.cancel();
    _connectionStateSub?.cancel();
    _responseSub = null;
    _measurementSub = null;
    _connectionStateSub = null;
    _device = null;
    _commandChar = null;
    _responseChar = null;
    _measurementChar = null;

    if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
      _pendingResponse!.completeError(
          StateError('Device disconnected unexpectedly'));
    }

    connectionState.value = GoDirectConnectionState.disconnected;
  }

  Future<void> _cleanup() async {
    _isStreaming = false;
    _enabledSensorNumbers.clear();
    _sensors.clear();
    _responseParser.reset();
    _packetBuilder.reset();
    connectedDeviceName = null;

    if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
      _pendingResponse!.completeError(
          StateError('Cleanup: pending response cancelled'));
    }

    await _responseSub?.cancel();
    _responseSub = null;

    await _measurementSub?.cancel();
    _measurementSub = null;

    await _connectionStateSub?.cancel();
    _connectionStateSub = null;

    try {
      await _responseChar?.setNotifyValue(false);
    } catch (_) {}
    try {
      await _measurementChar?.setNotifyValue(false);
    } catch (_) {}

    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _commandChar = null;
    _responseChar = null;
    _measurementChar = null;
  }

  void dispose() {
    _disposed = true;
    _scanSubscription?.cancel();
    _responseSub?.cancel();
    _measurementSub?.cancel();
    _connectionStateSub?.cancel();

    if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
      _pendingResponse!.completeError(
          StateError('Service disposed'));
    }

    if (!_scanResultsController.isClosed) {
      _scanResultsController.close();
    }
    if (!_measurementController.isClosed) {
      _measurementController.close();
    }

    connectionState.dispose();

    try {
      _device?.disconnect();
    } catch (_) {}
  }
}