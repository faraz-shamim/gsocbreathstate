import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:breath_state/services/heart_rate/polar_pmd_protocol.dart';
import 'package:breath_state/services/heart_rate/polar_hr_measurement_parser.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PolarEcgSample {
  final double voltage;
  final int timestampNs;
  final DateTime timeStamp;

  PolarEcgSample({required this.voltage, required this.timestampNs})
    : timeStamp = DateTime.fromMicrosecondsSinceEpoch(timestampNs ~/ 1000);
}

class PolarAccelerometerSample {
  final int xMg;
  final int yMg;
  final int zMg;
  final int timestampNs;
  final DateTime timeStamp;

  PolarAccelerometerSample({
    required this.xMg,
    required this.yMg,
    required this.zMg,
    required this.timestampNs,
  }) : timeStamp = DateTime.fromMicrosecondsSinceEpoch(timestampNs ~/ 1000);

  double get magnitudeMg =>
      math.sqrt((xMg * xMg + yMg * yMg + zMg * zMg).toDouble());
}

class PolarConnect {
  static final Guid _heartRateServiceUuid = Guid(
    '0000180d-0000-1000-8000-00805f9b34fb',
  );
  static final Guid _heartRateMeasurementUuid = Guid(
    '00002a37-0000-1000-8000-00805f9b34fb',
  );
  static final Guid _pmdServiceUuid = Guid(PolarPmdUuids.service);
  static final Guid _pmdControlPointUuid = Guid(PolarPmdUuids.controlPoint);
  static final Guid _pmdDataUuid = Guid(PolarPmdUuids.data);

  final String identifier;
  final void Function()? onConnectionChanged;

  StreamSubscription<List<int>>? hrSubscription;
  StreamSubscription<List<int>>? ecgSubscription;

  StreamController<int>? hrController;
  StreamController<double>? _rrController;
  StreamController<List<double>>? _rrBatchController;
  StreamController<List<PolarEcgSample>>? ecgController;
  StreamController<List<PolarAccelerometerSample>>? accController;
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  int? latestHr;
  final List<double> sessionRrIntervals = [];
  HrvTimeDomainResult? lastSessionHrv;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _hrCharacteristic;
  BluetoothCharacteristic? _pmdControlCharacteristic;
  BluetoothCharacteristic? _pmdDataCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _pmdControlSubscription;
  List<BluetoothService> _services = const [];

  Future<void>? _connectFuture;
  Completer<void>? _firstHrPacket;
  Completer<void>? _firstEcgFrame;
  Completer<void>? _firstAccFrame;
  Completer<PmdControlPointResponse>? _pendingPmdResponse;
  List<PolarEcgSample>? _lastEcgBatch;
  List<PolarAccelerometerSample>? _lastAccBatch;

  bool _isDeviceReady = false;
  bool _manualDisconnect = false;
  bool _ecgStreaming = false;
  bool _accStreaming = false;

  bool get isDeviceReady => _isDeviceReady;
  bool get isEcgStreaming => _ecgStreaming;
  bool get isAccStreaming => _accStreaming;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  PolarConnect({required this.identifier, this.onConnectionChanged});

  Future<void> connectToPolar() async {
    if (_isDeviceReady && (_device?.isConnected ?? false)) return;
    _connectFuture ??= _connectImpl().whenComplete(() {
      _connectFuture = null;
    });
    await _connectFuture;
  }

  Future<void> _connectImpl() async {
    developer.log('Connecting to Polar device $identifier using BLE GATT');

    try {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      _manualDisconnect = false;
      _device = await _resolveDevice();

      await _connectionSubscription?.cancel();
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      if (_device!.isDisconnected) {
        await _device!.connect(
          timeout: const Duration(seconds: 20),
          autoConnect: false,
          mtu: 232,
        );
      }

      _services = await _device!.discoverServices(
        subscribeToServicesChanged: false,
        timeout: 20,
      );
      _hrCharacteristic = _findCharacteristic(
        _services,
        _heartRateServiceUuid,
        _heartRateMeasurementUuid,
      );

      if (_hrCharacteristic == null) {
        throw StateError('Heart Rate Measurement characteristic not found.');
      }

      _isDeviceReady = true;
      _emitConnectionState(true);
      onConnectionChanged?.call();
      developer.log('Polar BLE GATT connected and services discovered.');
    } catch (e) {
      _isDeviceReady = false;
      _emitConnectionState(false);
      _clearGattHandles();
      onConnectionChanged?.call();
      developer.log('Polar BLE connection failed: $e');
      rethrow;
    }
  }

  Future<BluetoothDevice> _resolveDevice() async {
    try {
      final systemDevices = await FlutterBluePlus.systemDevices([
        _heartRateServiceUuid,
      ]).timeout(const Duration(seconds: 2));
      for (final device in systemDevices) {
        if (_matchesIdentifier(device.remoteId.str)) {
          developer.log('Polar found in system-connected devices.');
          return device;
        }
      }
    } catch (e) {
      developer.log('System connected device lookup skipped: $e');
    }

    return BluetoothDevice.fromId(identifier);
  }

  Future<void> ensureHeartRateReady() => connectToPolar();

  Future<void> ensureOnlineStreamingReady() async {
    await connectToPolar();
    await _ensurePmdCharacteristics();
  }

  void getPolarBatteryLevel() {
                                                                
  }

  Future<Stream<int>> getHeartRate() async {
    await _stopHeartRateNotifications(closeController: true);

    hrController = StreamController<int>.broadcast();
    _rrController = StreamController<double>.broadcast();
    _rrBatchController = StreamController<List<double>>.broadcast();
    sessionRrIntervals.clear();
    lastSessionHrv = null;
    latestHr = null;

    await connectToPolar();
    await _startHeartRateNotifications();
    return hrController!.stream;
  }

  Future<Stream<double>> getRrIntervals() async {
    if (_rrController == null ||
        (_rrController?.isClosed ?? true) ||
        hrSubscription == null) {
      await getHeartRate();
    }
    return _rrController!.stream;
  }

  Future<Stream<List<double>>> getRrIntervalBatches() async {
    if (_rrBatchController == null ||
        (_rrBatchController?.isClosed ?? true) ||
        hrSubscription == null) {
      await getHeartRate();
    }
    return _rrBatchController!.stream;
  }

  Future<void> _startHeartRateNotifications() async {
    final characteristic = _hrCharacteristic;
    if (characteristic == null) {
      throw StateError('Heart Rate Measurement characteristic not available.');
    }

    _firstHrPacket = Completer<void>();
    hrSubscription = characteristic.onValueReceived.listen(
      _onHeartRateMeasurement,
      onError: (Object e, StackTrace st) {
        if (!(hrController?.isClosed ?? true)) {
          hrController!.addError(e, st);
        }
      },
    );

    await characteristic.setNotifyValue(true, timeout: 8);
    unawaited(
      _firstHrPacket!.future.timeout(const Duration(seconds: 10)).catchError((
        Object e,
        StackTrace st,
      ) {
        if (!(hrController?.isClosed ?? true) && latestHr == null) {
          hrController!.addError(
            StateError('No Polar HR packets found after starting BLE notify.'),
            st,
          );
        }
      }),
    );
  }

  void _onHeartRateMeasurement(List<int> data) {
    final measurement = parsePolarHeartRateMeasurement(data);
    if (measurement == null) return;

    latestHr = measurement.heartRateBpm;
    if (!(_firstHrPacket?.isCompleted ?? true)) {
      _firstHrPacket!.complete();
    }
    if (!(hrController?.isClosed ?? true)) {
      hrController!.add(measurement.heartRateBpm);
    }

    final rrBatch = measurement.rrIntervalsMs;
    if (rrBatch.isEmpty) return;
    sessionRrIntervals.addAll(rrBatch);
    if (!(_rrBatchController?.isClosed ?? true)) {
      _rrBatchController!.add(List.unmodifiable(rrBatch));
    }
    if (!(_rrController?.isClosed ?? true)) {
      for (final rr in rrBatch) {
        _rrController!.add(rr);
      }
    }
  }

  Future<Stream<List<PolarEcgSample>>> getECG() async {
    await stopEcgStreaming(closeController: true);

    ecgController = StreamController<List<PolarEcgSample>>.broadcast(
      onListen: () {
        final batch = _lastEcgBatch;
        if (batch == null || batch.isEmpty) return;
        scheduleMicrotask(() {
          if (!(ecgController?.isClosed ?? true) &&
              (ecgController?.hasListener ?? false)) {
            ecgController!.add(batch);
          }
        });
      },
    );

    await connectToPolar();
    await _startEcgOnConnected();
    return ecgController!.stream;
  }

  Future<Stream<List<PolarAccelerometerSample>>> getACC() async {
    await stopAccStreaming(closeController: true);

    accController = StreamController<List<PolarAccelerometerSample>>.broadcast(
      onListen: () {
        final batch = _lastAccBatch;
        if (batch == null || batch.isEmpty) return;
        scheduleMicrotask(() {
          if (!(accController?.isClosed ?? true) &&
              (accController?.hasListener ?? false)) {
            accController!.add(batch);
          }
        });
      },
    );

    await connectToPolar();
    await _startAccOnConnected();
    return accController!.stream;
  }

  Future<void> _startEcgOnConnected() async {
    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      _firstEcgFrame = Completer<void>();
      try {
        await _startPmdEcgOnce();
        await _firstEcgFrame!.future.timeout(const Duration(seconds: 8));
        return;
      } catch (e) {
        lastError = e;
        developer.log('Polar ECG start attempt $attempt failed: $e');
        await _stopPmdEcgMeasurement(disableNotifications: true);
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    throw StateError(
      'No Polar ECG samples received after starting PMD stream: '
      '$lastError',
    );
  }

  Future<void> _startPmdEcgOnce() async {
    await _ensurePmdCharacteristics();

    await _ensurePmdNotifications();

    await _assertEcgAvailable();
    await _queryEcgSettingsForLog();

    final response = await _sendPmdCommand(
      PmdCommandBuilder.startMeasurement(PmdMeasurementType.ecg),
      timeoutMs: 8000,
    );

    if (!response.isSuccess &&
        response.errorCode != PmdResponseCode.alreadyInState) {
      throw StateError(
        'PMD start ECG failed: ${response.errorMessage} '
        '(code ${response.errorCode})',
      );
    }

    _ecgStreaming = true;
    developer.log('Polar PMD ECG streaming started.');
  }

  Future<void> _startAccOnConnected() async {
    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      _firstAccFrame = Completer<void>();
      try {
        await _startPmdAccOnce();
        await _firstAccFrame!.future.timeout(const Duration(seconds: 8));
        return;
      } catch (e) {
        lastError = e;
        developer.log('Polar ACC start attempt $attempt failed: $e');
        await _stopPmdAccMeasurement(disableNotifications: !_ecgStreaming);
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    throw StateError(
      'No Polar ACC samples received after starting PMD stream: '
      '$lastError',
    );
  }

  Future<void> _startPmdAccOnce() async {
    await _ensurePmdCharacteristics();
    await _ensurePmdNotifications();

    await _assertMeasurementAvailable(PmdMeasurementType.acc, 'ACC');
    await _querySettingsForLog(PmdMeasurementType.acc, 'ACC');

    final response = await _sendPmdCommand(
      PmdCommandBuilder.startAccMeasurement(),
      timeoutMs: 8000,
    );

    if (!response.isSuccess &&
        response.errorCode != PmdResponseCode.alreadyInState) {
      throw StateError(
        'PMD start ACC failed: ${response.errorMessage} '
        '(code ${response.errorCode})',
      );
    }

    _accStreaming = true;
    developer.log('Polar PMD ACC streaming started.');
  }

  Future<void> _ensurePmdNotifications() async {
    if (_pmdControlSubscription == null) {
      _pmdControlSubscription = _pmdControlCharacteristic!.onValueReceived
          .listen(
            _onPmdControlResponse,
            onError: _completePendingPmdResponseError,
          );
      await _pmdControlCharacteristic!.setNotifyValue(true, timeout: 8);
    }

    if (ecgSubscription == null) {
      ecgSubscription = _pmdDataCharacteristic!.onValueReceived.listen(
        _onPmdDataNotification,
        onError: (Object e, StackTrace st) {
          if (!(ecgController?.isClosed ?? true)) {
            ecgController!.addError(e, st);
          }
          if (!(accController?.isClosed ?? true)) {
            accController!.addError(e, st);
          }
        },
      );
      await _pmdDataCharacteristic!.setNotifyValue(true, timeout: 8);
    }
  }

  Future<void> _ensurePmdCharacteristics() async {
    await connectToPolar();
    if (_pmdControlCharacteristic != null && _pmdDataCharacteristic != null) {
      return;
    }

    if (_services.isEmpty) {
      _services = await _device!.discoverServices(
        subscribeToServicesChanged: false,
        timeout: 20,
      );
    }

    _pmdControlCharacteristic = _findCharacteristic(
      _services,
      _pmdServiceUuid,
      _pmdControlPointUuid,
    );
    _pmdDataCharacteristic = _findCharacteristic(
      _services,
      _pmdServiceUuid,
      _pmdDataUuid,
    );

    if (_pmdControlCharacteristic == null || _pmdDataCharacteristic == null) {
      throw StateError('Polar PMD control/data characteristics not found.');
    }
  }

  Future<void> _assertEcgAvailable() async {
    await _assertMeasurementAvailable(PmdMeasurementType.ecg, 'ECG');
  }

  Future<void> _assertMeasurementAvailable(
    PmdMeasurementType type,
    String label,
  ) async {
    try {
      final raw = await _pmdControlCharacteristic!.read(timeout: 6);
      final available = PmdAvailableMeasurements.parse(raw);
      if (!available.contains(type)) {
        throw StateError('$label is not advertised by this Polar device.');
      }
      developer.log('Polar PMD measurements available: $available');
    } on StateError {
      rethrow;
    } catch (e) {
      developer.log('Polar PMD measurement read skipped: $e');
    }
  }

  Future<void> _queryEcgSettingsForLog() async {
    await _querySettingsForLog(PmdMeasurementType.ecg, 'ECG');
  }

  Future<void> _querySettingsForLog(
    PmdMeasurementType type,
    String label,
  ) async {
    try {
      final rsp = await _sendPmdCommand(
        PmdCommandBuilder.getSettings(type),
        timeoutMs: 5000,
      );
      if (rsp.isSuccess) {
        developer.log(
          'Polar $label settings: ${PmdAvailableSettings.parse(rsp.parameters)}',
        );
      }
    } catch (e) {
      developer.log('Polar $label settings query skipped: $e');
    }
  }

  void _onPmdControlResponse(List<int> data) {
    final response = PmdControlPointResponse.parse(data);
    if (!(_pendingPmdResponse?.isCompleted ?? true)) {
      _pendingPmdResponse!.complete(response);
    }
  }

  void _onPmdDataNotification(List<int> data) {
    if (_ecgStreaming || (_firstEcgFrame?.isCompleted == false)) {
      final frame = PmdDataParser.parseEcgNotification(data);
      if (frame != null) {
        final samples =
            frame.samplesUv
                .map(
                  (uv) => PolarEcgSample(
                    voltage: uv,
                    timestampNs: frame.timestampNs,
                  ),
                )
                .toList();
        if (samples.isNotEmpty) {
          _lastEcgBatch = samples;
          if (!(_firstEcgFrame?.isCompleted ?? true)) {
            _firstEcgFrame!.complete();
          }
          if (!(ecgController?.isClosed ?? true) &&
              (ecgController?.hasListener ?? false)) {
            ecgController!.add(samples);
          }
        }
      }
    }

    if (_accStreaming || (_firstAccFrame?.isCompleted == false)) {
      final frame = PmdDataParser.parseAccNotification(data);
      if (frame == null) return;
      final samples =
          frame.samples
              .map(
                (sample) => PolarAccelerometerSample(
                  xMg: sample.xMg,
                  yMg: sample.yMg,
                  zMg: sample.zMg,
                  timestampNs: frame.timestampNs,
                ),
              )
              .toList();
      if (samples.isEmpty) return;

      _lastAccBatch = samples;
      if (!(_firstAccFrame?.isCompleted ?? true)) {
        _firstAccFrame!.complete();
      }
      if (!(accController?.isClosed ?? true) &&
          (accController?.hasListener ?? false)) {
        accController!.add(samples);
      }
    }
  }

  Future<PmdControlPointResponse> _sendPmdCommand(
    Uint8List command, {
    int timeoutMs = 5000,
  }) async {
    final characteristic = _pmdControlCharacteristic;
    if (characteristic == null) {
      throw StateError('PMD control point not available.');
    }

    _completePendingPmdResponseError(StateError('Superseded PMD command.'));

    final completer = Completer<PmdControlPointResponse>();
    _pendingPmdResponse = completer;

    try {
      await characteristic.write(
        command,
        withoutResponse: false,
        timeout: (timeoutMs / 1000).ceil(),
      );
      return await completer.future.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout:
            () =>
                throw TimeoutException(
                  'No PMD control response within ${timeoutMs}ms',
                ),
      );
    } finally {
      if (identical(_pendingPmdResponse, completer)) {
        _pendingPmdResponse = null;
      }
    }
  }

  Future<void> stopEcgStreaming({bool closeController = true}) async {
    try {
      await _stopPmdEcgMeasurement(disableNotifications: !_accStreaming);
      if (closeController) {
        await ecgController?.close();
        ecgController = null;
        _lastEcgBatch = null;
      }
    } catch (e) {
      developer.log('Error stopping ECG stream: $e');
    }
  }

  Future<void> stopAccStreaming({bool closeController = true}) async {
    try {
      await _stopPmdAccMeasurement(disableNotifications: !_ecgStreaming);
      if (closeController) {
        await accController?.close();
        accController = null;
        _lastAccBatch = null;
      }
    } catch (e) {
      developer.log('Error stopping ACC stream: $e');
    }
  }

  Future<void> _stopPmdEcgMeasurement({
    required bool disableNotifications,
  }) async {
    final shouldSendStop =
        _ecgStreaming &&
        _pmdControlCharacteristic != null &&
        _pmdControlSubscription != null &&
        (_device?.isConnected ?? false);
    _ecgStreaming = false;

    if (shouldSendStop) {
      try {
        final response = await _sendPmdCommand(
          PmdCommandBuilder.stopMeasurement(PmdMeasurementType.ecg),
          timeoutMs: 3000,
        );
        developer.log('Polar PMD ECG stop response: ${response.errorMessage}');
      } catch (e) {
        developer.log('Polar PMD ECG stop warning: $e');
      }
    }

    if (disableNotifications && !_accStreaming) {
      try {
        await _pmdDataCharacteristic?.setNotifyValue(false, timeout: 3);
      } catch (_) {}
      try {
        await _pmdControlCharacteristic?.setNotifyValue(false, timeout: 3);
      } catch (_) {}
    }

    if (disableNotifications && !_accStreaming) {
      await ecgSubscription?.cancel();
      ecgSubscription = null;
      await _pmdControlSubscription?.cancel();
      _pmdControlSubscription = null;
      _completePendingPmdResponseError(StateError('PMD stream stopped.'));
    }
  }

  Future<void> _stopPmdAccMeasurement({
    required bool disableNotifications,
  }) async {
    final shouldSendStop =
        _accStreaming &&
        _pmdControlCharacteristic != null &&
        _pmdControlSubscription != null &&
        (_device?.isConnected ?? false);
    _accStreaming = false;

    if (shouldSendStop) {
      try {
        final response = await _sendPmdCommand(
          PmdCommandBuilder.stopMeasurement(PmdMeasurementType.acc),
          timeoutMs: 3000,
        );
        developer.log('Polar PMD ACC stop response: ${response.errorMessage}');
      } catch (e) {
        developer.log('Polar PMD ACC stop warning: $e');
      }
    }

    if (disableNotifications && !_ecgStreaming) {
      try {
        await _pmdDataCharacteristic?.setNotifyValue(false, timeout: 3);
      } catch (_) {}
      try {
        await _pmdControlCharacteristic?.setNotifyValue(false, timeout: 3);
      } catch (_) {}
      await ecgSubscription?.cancel();
      ecgSubscription = null;
      await _pmdControlSubscription?.cancel();
      _pmdControlSubscription = null;
      _completePendingPmdResponseError(StateError('PMD stream stopped.'));
    }
  }

  Future<void> _stopHeartRateNotifications({
    required bool closeController,
  }) async {
    try {
      await _hrCharacteristic?.setNotifyValue(false, timeout: 3);
    } catch (_) {}

    await hrSubscription?.cancel();
    hrSubscription = null;
    if (!(_firstHrPacket?.isCompleted ?? true)) {
      _firstHrPacket!.completeError(StateError('Heart rate stream stopped.'));
    }
    _firstHrPacket = null;

    if (closeController) {
      await hrController?.close();
      await _rrController?.close();
      await _rrBatchController?.close();
      hrController = null;
      _rrController = null;
      _rrBatchController = null;
    }
  }

  Future<void> stopHeartRateStreaming() =>
      _stopHeartRateNotifications(closeController: true);

  Future<void> stopRecording() async {
    try {
      await _stopHeartRateNotifications(closeController: true);
      await stopEcgStreaming(closeController: true);
      await stopAccStreaming(closeController: true);

      if (sessionRrIntervals.length >= 10) {
        try {
          lastSessionHrv = HrvTimeDomain.compute(sessionRrIntervals);
          developer.log(
            'HRV computed: RMSSD='
            '${lastSessionHrv!.rmssd.toStringAsFixed(1)} ms',
          );
        } catch (e) {
          developer.log('Error computing HRV: $e');
        }
      } else {
        developer.log(
          'Not enough RR intervals for HRV: ${sessionRrIntervals.length}',
        );
      }

      developer.log('Polar BLE streams cancelled; device remains connected.');
    } catch (e) {
      developer.log('Error stopping recording: $e');
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    try {
      await stopRecording();
      _isDeviceReady = false;
      _emitConnectionState(false);
      onConnectionChanged?.call();
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      if (_device?.isConnected ?? false) {
        await _device!.disconnect(timeout: 5, queue: false, androidDelay: 200);
      }
      developer.log('Polar BLE device disconnected.');
    } catch (e) {
      developer.log('Error disconnecting Polar BLE device: $e');
    } finally {
      _isDeviceReady = false;
      _clearGattHandles();
      onConnectionChanged?.call();
    }
  }

  Future<void> dispose() async {
    await disconnect();
    sessionRrIntervals.clear();
    lastSessionHrv = null;
    latestHr = null;
    await _connectionStateController.close();
  }

  void _handleDisconnection() {
    _isDeviceReady = false;
    _emitConnectionState(false);
    _clearGattHandles(keepDevice: true);
    onConnectionChanged?.call();

    if (_manualDisconnect) return;

    final error = StateError('Polar BLE device disconnected.');
    if (!(hrController?.isClosed ?? true)) {
      hrController!.addError(error);
    }
    if (!(_rrController?.isClosed ?? true)) {
      _rrController!.addError(error);
    }
    if (!(_rrBatchController?.isClosed ?? true)) {
      _rrBatchController!.addError(error);
    }
    if (!(ecgController?.isClosed ?? true)) {
      ecgController!.addError(error);
    }
    if (!(accController?.isClosed ?? true)) {
      accController!.addError(error);
    }
  }

  void _emitConnectionState(bool connected) {
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(connected);
    }
  }

  BluetoothCharacteristic? _findCharacteristic(
    List<BluetoothService> services,
    Guid serviceUuid,
    Guid characteristicUuid,
  ) {
    for (final service in services) {
      if (service.uuid != serviceUuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == characteristicUuid) {
          return characteristic;
        }
      }
    }
    return null;
  }

  void _completePendingPmdResponseError(Object error, [StackTrace? st]) {
    if (!(_pendingPmdResponse?.isCompleted ?? true)) {
      _pendingPmdResponse!.completeError(error, st);
    }
    _pendingPmdResponse = null;
  }

  void _clearGattHandles({bool keepDevice = false}) {
    _services = const [];
    _hrCharacteristic = null;
    _pmdControlCharacteristic = null;
    _pmdDataCharacteristic = null;
    _ecgStreaming = false;
    _accStreaming = false;
    _lastEcgBatch = null;
    _lastAccBatch = null;
    if (!keepDevice) _device = null;
  }

  bool _matchesIdentifier(String eventIdentifier) {
    final eventId = _normaliseIdentifier(eventIdentifier);
    final targetId = _normaliseIdentifier(identifier);
    if (eventId.isEmpty || targetId.isEmpty) return false;
    return eventId == targetId ||
        eventId.endsWith(targetId) ||
        targetId.endsWith(eventId);
  }

  String _normaliseIdentifier(String value) =>
      value.replaceAll(':', '').replaceAll('-', '').toUpperCase();
}
