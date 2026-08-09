                                                    
  
                                                                        
                                                                 
                                                      

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:breath_state/services/ble_service/web_ble.dart';
import 'go_direct_constants.dart';
import 'go_direct_protocol.dart';

class GoDirectServiceWeb {
  WebBleDevice? _device;
  BluetoothRemoteGATTCharacteristic? _commandChar;
  BluetoothRemoteGATTCharacteristic? _responseChar;
  BluetoothRemoteGATTCharacteristic? _measurementChar;

  StreamSubscription<List<int>>? _responseSub;
  StreamSubscription<List<int>>? _measurementSub;

  final _packetBuilder = GoDirectPacketBuilder();
  final _responseParser = GoDirectResponseParser();
  Completer<GoDirectResponse>? _pendingResponse;
  bool _isStreaming = false;

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

  final _measurementController =
      StreamController<GoDirectMeasurement>.broadcast();

  Stream<GoDirectMeasurement> get measurementStream =>
      _measurementController.stream;

  Stream<double> get respirationForceStream => measurementStream
      .where((m) => m.sensorNumber == 1)
      .map((m) => m.value);

                                                                       
  static const String _primaryServiceUuid =
      'd91714ef-28b9-4f91-ba16-f0d9e7f3125c';
  static const String _commandCharUuid =
      'f4bf14a6-c7d5-4b6d-8aa8-df1a7c83adcb';
  static const String _responseCharUuid =
      'b41b1c18-3d4a-11e5-ab5e-feff819cdc9f';
  static const String _measurementCharUuid =
      'ec0a8400-3d4a-11e5-ab5e-feff819cdc9f';

                                                                             
  Future<bool> connect() async {
    connectionState.value = GoDirectConnectionState.connecting;

    try {
      _device = await requestWebBleDevice(
        serviceUuids: [_primaryServiceUuid],
      );

      if (_device == null) {
        connectionState.value = GoDirectConnectionState.disconnected;
        return false;
      }

      final connected = await connectGatt(_device!);
      if (!connected) {
        connectionState.value = GoDirectConnectionState.error;
        return false;
      }

      connectedDeviceName = _device!.name;
      connectionState.value = GoDirectConnectionState.initializing;

                                 
      final service = await getService(_device!, _primaryServiceUuid);
      if (service == null) {
        throw StateError('Go Direct primary service not found');
      }

      _commandChar = await getCharacteristic(service, _commandCharUuid);
      _responseChar = await getCharacteristic(service, _responseCharUuid);
      _measurementChar =
          await getCharacteristic(service, _measurementCharUuid);

      if (_commandChar == null ||
          _responseChar == null ||
          _measurementChar == null) {
        throw StateError('Required characteristics not found');
      }

                             
      _responseParser.reset();
      final responseStream = startNotifications(_responseChar!);
      _responseSub = responseStream.listen(_onResponseNotification);

      final measurementStream = startNotifications(_measurementChar!);
      _measurementSub =
          measurementStream.listen(_onMeasurementNotification);

                          
      await _runInitSequence();

      connectionState.value = GoDirectConnectionState.connected;
      debugPrint(
          'GoDirectServiceWeb connected to $connectedDeviceName '
          '(${_sensors.length} sensors)');
      return true;
    } catch (e) {
      debugPrint('GoDirectServiceWeb connect failed: $e');
      connectionState.value = GoDirectConnectionState.error;
      await _cleanup();
      return false;
    }
  }

  Future<void> disconnect() async {
    connectionState.value = GoDirectConnectionState.disconnecting;
    if (_isStreaming) await stopMeasurements();
    await _cleanup();
    connectionState.value = GoDirectConnectionState.disconnected;
  }

  Future<void> startMeasurements({
    List<int>? sensorNumbers,
    int periodMs = 100,
  }) async {
    if (_commandChar == null) {
      throw StateError('Not connected');
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
      throw StateError('No sensors available');
    }
    _enabledSensorNumbers.sort();

    int sensorMask = 0;
    for (final sn in _enabledSensorNumbers) {
      sensorMask |= (1 << sn);
    }

    final periodUs = periodMs * 1000;
    await _sendCommandAndWait(
        _packetBuilder.buildSetMeasurementPeriod(periodUs));
    await _sendCommandAndWait(
        _packetBuilder.buildStartMeasurements(sensorMask));

    _isStreaming = true;
    connectionState.value = GoDirectConnectionState.streaming;
  }

  Future<void> stopMeasurements() async {
    if (!_isStreaming) return;
    try {
      await _sendCommandAndWait(_packetBuilder.buildStopMeasurements());
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

    try {
      await _sendCommandAndWait(_packetBuilder.buildInit(),
          timeoutMs: 5000);
    } catch (e) {
      debugPrint('GoDirectServiceWeb INIT timeout (non-fatal): $e');
    }

    _sensors.clear();

    try {
      final sensorIdsRsp = await _sendCommandAndWait(
          _packetBuilder.buildGetAvailableSensors());
      final sensorIds = parseSensorIds(sensorIdsRsp.payload);

      for (final id in sensorIds) {
        try {
          final infoRsp = await _sendCommandAndWait(
              _packetBuilder.buildGetSensorInfo(id));
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
        _sensors[1] = const GoDirectSensorInfo(
          sensorNumber: 1,
          description: 'Sensor 1',
          units: '',
        );
      }
    }

    try {
      final maskRsp = await _sendCommandAndWait(
          _packetBuilder.buildGetDefaultSensorsMask());
      _defaultSensorMask = parseDefaultSensorsMask(maskRsp.payload);
    } catch (e) {
      if (_sensors.isNotEmpty) {
        _defaultSensorMask = 1 << _sensors.keys.first;
      }
    }
  }

  void _onResponseNotification(List<int> data) {
    final responses = _responseParser.feed(data);
    for (final rsp in responses) {
      if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
        _pendingResponse!.complete(rsp);
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
      _pendingResponse!.completeError(StateError('Superseded'));
    }

    _pendingResponse = Completer<GoDirectResponse>();
    await writeCharacteristic(_commandChar!, packet);

    return _pendingResponse!.future.timeout(
      Duration(milliseconds: timeoutMs),
      onTimeout: () => throw TimeoutException('No response within ${timeoutMs}ms'),
    );
  }

  Future<void> _cleanup() async {
    _isStreaming = false;
    _enabledSensorNumbers.clear();
    _sensors.clear();
    _responseParser.reset();
    _packetBuilder.reset();
    connectedDeviceName = null;

    if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
      _pendingResponse!.completeError(StateError('Cleanup'));
    }

    await _responseSub?.cancel();
    _responseSub = null;
    await _measurementSub?.cancel();
    _measurementSub = null;

    if (_device != null) {
      disconnectGatt(_device!);
    }
    _device = null;
    _commandChar = null;
    _responseChar = null;
    _measurementChar = null;
  }

  void dispose() {
    _responseSub?.cancel();
    _measurementSub?.cancel();
    if (!_measurementController.isClosed) _measurementController.close();
    connectionState.dispose();
    if (_device != null) disconnectGatt(_device!);
  }
}