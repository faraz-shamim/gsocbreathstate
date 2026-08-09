                                                 

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:breath_state/services/ble_service/web_ble.dart';
import 'package:breath_state/services/heart_rate/polar_pmd_protocol.dart';
import 'package:breath_state/services/heart_rate/polar_hr_measurement_parser.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';

const String _heartRateServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';
const String _heartRateMeasurementCharUuid =
    '00002a37-0000-1000-8000-00805f9b34fb';

class WebPolarEcgSample {
  final double voltageUv;
  final int timestampNs;
  WebPolarEcgSample({required this.voltageUv, required this.timestampNs});
}

class WebPolarAccSample {
  final int xMg;
  final int yMg;
  final int zMg;
  final int timestampNs;
  WebPolarAccSample({
    required this.xMg,
    required this.yMg,
    required this.zMg,
    required this.timestampNs,
  });
}

class PolarConnectWeb {
  static const int _maxReconnectAttempts = 3;

  WebBleDevice? _device;
  JSFunction? _disconnectListener;
  Future<bool>? _connectInFlight;
  Future<void>? _reconnectInFlight;
  bool _disposed = false;
  bool _manualDisconnect = false;

       
  BluetoothRemoteGATTCharacteristic? _hrChar;
  StreamSubscription<List<int>>? _hrNotifSub;
  StreamController<int>? _hrController;
  StreamController<double>? _rrController;
  StreamController<List<double>>? _rrBatchController;
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

              
  BluetoothRemoteGATTCharacteristic? _pmdControlChar;
  BluetoothRemoteGATTCharacteristic? _pmdDataChar;
  StreamSubscription<List<int>>? _pmdControlSub;
  StreamSubscription<List<int>>? _pmdDataSub;
  StreamController<List<WebPolarEcgSample>>? _ecgController;
  StreamController<List<WebPolarAccSample>>? _accController;
  Completer<PmdControlPointResponse>? _pendingPmdResponse;
  bool _ecgStreaming = false;
  bool _accStreaming = false;
  int _ecgSampleRate = 130;
  int _ecgResolution = 14;

  final List<double> sessionRrIntervals = [];
  HrvTimeDomainResult? lastSessionHrv;
  int? latestHr;

  String? get deviceName => _device?.name;
  bool get isConnected => _device != null && _device!.gatt.connected;
  bool get isEcgStreaming => _ecgStreaming;
  bool get isAccStreaming => _accStreaming;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  bool get _hasOpenHrStream =>
      _hrController != null && !_hrController!.isClosed;
  bool get _hasOpenEcgStream =>
      _ecgController != null && !_ecgController!.isClosed;
  bool get _hasOpenAccStream =>
      _accController != null && !_accController!.isClosed;

                                                            
     
                                                                        
                                                                               
  Future<bool> connectToPolar() {
    if (_disposed) return Future.value(false);
    if (isConnected) return Future.value(true);

    final pending = _connectInFlight;
    if (pending != null) return pending;

    _connectInFlight = _connectToPolarInternal().whenComplete(() {
      _connectInFlight = null;
    });
    return _connectInFlight!;
  }

  Future<bool> _connectToPolarInternal() async {
    try {
      if (_device == null) {
        final selected = await requestWebBleDevice(
          serviceUuids: [_heartRateServiceUuid, PolarPmdUuids.service],
          namePrefix: 'Polar',
        );
        if (selected == null) {
          developer.log('Web Polar: user cancelled or no device');
          return false;
        }
        _replaceDevice(selected);
      }

      _manualDisconnect = false;
      _clearGattHandles();

      final connected = await connectGatt(_device!);
      if (!connected) {
        developer.log('Web Polar: GATT connect failed');
        return false;
      }

      developer.log('Web Polar: connected to ${_device!.name}');
      _emitConnectionState(true);
      return true;
    } catch (e) {
      developer.log('Web Polar: connection error: $e');
      return false;
    }
  }

  void _replaceDevice(WebBleDevice device) {
    final oldDevice = _device;
    final oldListener = _disconnectListener;
    if (oldDevice != null && oldListener != null) {
      removeGattDisconnectedListener(oldDevice, oldListener);
    }

    _device = device;
    _disconnectListener = addGattDisconnectedListener(
      device,
      _handleGattDisconnected,
    );
  }

  void _handleGattDisconnected() {
    if (_disposed || _manualDisconnect) return;
    unawaited(_handleGattDisconnectedAsync());
  }

  Future<void> _handleGattDisconnectedAsync() async {
    final restartHr = _hasOpenHrStream;
    final restartEcg = _ecgStreaming && _hasOpenEcgStream;
    final hadAcc = _accStreaming && _hasOpenAccStream;

    developer.log('Web Polar: GATT disconnected');
    _emitConnectionState(false);
    _ecgStreaming = false;
    _accStreaming = false;
    _completePendingPmdResponseError(StateError('Polar disconnected'));
    await _cancelGattSubscriptions();
    _clearGattHandles();

    if (restartHr || restartEcg) {
      _scheduleReconnect(restartHr: restartHr, restartEcg: restartEcg);
    }
    if (hadAcc && _hasOpenAccStream) {
      _accController!.addError(StateError('Polar ACC stream disconnected.'));
    }
  }

  void _scheduleReconnect({required bool restartHr, required bool restartEcg}) {
    _reconnectInFlight ??= _reconnectAndResume(
      restartHr: restartHr,
      restartEcg: restartEcg,
    ).whenComplete(() {
      _reconnectInFlight = null;
    });
  }

  Future<void> _reconnectAndResume({
    required bool restartHr,
    required bool restartEcg,
  }) async {
    for (var attempt = 1; attempt <= _maxReconnectAttempts; attempt++) {
      if (_disposed || _manualDisconnect) return;

      await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      developer.log('Web Polar: reconnect attempt $attempt');

      final connected = await connectToPolar();
      if (!connected) continue;

      try {
        if (restartHr && _hasOpenHrStream) {
          await _startHeartRateNotifications();
        }
        if (restartEcg && _hasOpenEcgStream) {
          await _startEcgOnConnected(
            sampleRate: _ecgSampleRate,
            resolution: _ecgResolution,
            querySettings: false,
          );
        }
        developer.log('Web Polar: reconnected and streams resumed');
        return;
      } catch (e) {
        developer.log('Web Polar: resume after reconnect failed: $e');
        _ecgStreaming = false;
        _completePendingPmdResponseError(e);
        await _cancelGattSubscriptions();
        _clearGattHandles();
      }
    }

    final error = StateError(
      'Polar disconnected and could not be reconnected automatically.',
    );
    if (_hasOpenHrStream) _hrController!.addError(error);
    if (_hasOpenEcgStream) _ecgController!.addError(error);
  }

  void _clearGattHandles() {
    _hrChar = null;
    _pmdControlChar = null;
    _pmdDataChar = null;
  }

  Future<void> _cancelGattSubscriptions() async {
    await _hrNotifSub?.cancel();
    _hrNotifSub = null;
    await _pmdDataSub?.cancel();
    _pmdDataSub = null;
    await _pmdControlSub?.cancel();
    _pmdControlSub = null;
  }

               

  Future<Stream<int>> getHeartRate() async {
    await _hrNotifSub?.cancel();
    _hrNotifSub = null;
    _hrController?.close();
    _rrController?.close();
    _rrBatchController?.close();

    _hrController = StreamController<int>.broadcast();
    _rrController = StreamController<double>.broadcast();
    _rrBatchController = StreamController<List<double>>.broadcast();
    sessionRrIntervals.clear();
    lastSessionHrv = null;

    final ok = await connectToPolar();
    if (!ok) throw StateError('Failed to connect to Polar on web');

    await _startHeartRateNotifications();
    return _hrController!.stream;
  }

  Future<Stream<double>> getRrIntervals() async {
    if (_rrController == null ||
        (_rrController?.isClosed ?? true) ||
        _hrNotifSub == null) {
      await getHeartRate();
    }
    return _rrController!.stream;
  }

  Future<Stream<List<double>>> getRrIntervalBatches() async {
    if (_rrBatchController == null ||
        (_rrBatchController?.isClosed ?? true) ||
        _hrNotifSub == null) {
      await getHeartRate();
    }
    return _rrBatchController!.stream;
  }

  Future<void> _startHeartRateNotifications() async {
    if (_device == null || !_device!.gatt.connected) {
      throw StateError('Polar is not connected');
    }

    await _hrNotifSub?.cancel();
    _hrNotifSub = null;

    final service = await getService(_device!, _heartRateServiceUuid);
    if (service == null) throw StateError('HR service not found');

    _hrChar = await getCharacteristic(service, _heartRateMeasurementCharUuid);
    if (_hrChar == null) throw StateError('HR characteristic not found');

    final notifStream = await startNotificationsReady(_hrChar!);
    _hrNotifSub = notifStream.listen(
      _parseHeartRateMeasurement,
      onError: (Object e, StackTrace st) {
        if (_hasOpenHrStream) _hrController!.addError(e, st);
      },
    );
  }

  void _parseHeartRateMeasurement(List<int> data) {
    final measurement = parsePolarHeartRateMeasurement(data);
    if (measurement == null) return;
    latestHr = measurement.heartRateBpm;
    if (_hasOpenHrStream) _hrController!.add(measurement.heartRateBpm);

    final rrBatch = measurement.rrIntervalsMs;
    if (rrBatch.isNotEmpty) {
      sessionRrIntervals.addAll(rrBatch);
      if (!(_rrBatchController?.isClosed ?? true)) {
        _rrBatchController!.add(rrBatch);
      }
      if (!(_rrController?.isClosed ?? true)) {
        for (final rrMs in rrBatch) {
          _rrController!.add(rrMs);
        }
      }
    }
  }

                

  Future<Stream<List<WebPolarEcgSample>>> startEcgStreaming({
    int sampleRate = 130,
    int resolution = 14,
  }) async {
    if (_ecgStreaming) await stopEcgStreaming();

    await _pmdDataSub?.cancel();
    await _pmdControlSub?.cancel();
    _ecgController?.close();
    _ecgController = StreamController<List<WebPolarEcgSample>>.broadcast();
    _ecgSampleRate = sampleRate;
    _ecgResolution = resolution;

    final ok = await connectToPolar();
    if (!ok) throw StateError('Failed to connect to Polar on web');

    try {
      await _startEcgOnConnected(
        sampleRate: sampleRate,
        resolution: resolution,
      );
      return _ecgController!.stream;
    } catch (e) {
      developer.log('Web Polar: ECG start failed, retrying once: $e');
      _ecgStreaming = false;
      await _cancelPmdSubscriptions();
      _completePendingPmdResponseError(StateError('PMD start retry'));
      try {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final connected = await connectToPolar();
        if (!connected) throw StateError('Failed to reconnect Polar on web');
        await _startEcgOnConnected(
          sampleRate: sampleRate,
          resolution: resolution,
          querySettings: false,
        );
        return _ecgController!.stream;
      } catch (retryError) {
        _ecgStreaming = false;
        await _cancelPmdSubscriptions();
        if (_hasOpenEcgStream) _ecgController!.addError(retryError);
        throw StateError('ECG start failed: $retryError');
      }
    }
  }

  Future<void> _startEcgOnConnected({
    required int sampleRate,
    required int resolution,
    bool querySettings = true,
  }) async {
    if (_device == null || !_device!.gatt.connected) {
      throw StateError('Polar is not connected');
    }

    await _cancelPmdSubscriptions();
    _completePendingPmdResponseError(StateError('PMD stream restarted'));
    _ecgStreaming = false;

    final pmdService = await getService(_device!, PolarPmdUuids.service);
    if (pmdService == null) {
      throw StateError('PMD service not found - device may not support ECG');
    }

    _pmdControlChar = await getCharacteristic(
      pmdService,
      PolarPmdUuids.controlPoint,
    );
    _pmdDataChar = await getCharacteristic(pmdService, PolarPmdUuids.data);
    if (_pmdControlChar == null || _pmdDataChar == null) {
      throw StateError('PMD characteristics not found');
    }

    final controlStream = await startNotificationsReady(_pmdControlChar!);
    _pmdControlSub = controlStream.listen(
      _onPmdControlResponse,
      onError: (Object e, StackTrace st) {
        if (_hasOpenEcgStream) _ecgController!.addError(e, st);
      },
    );

    final dataStream = await startNotificationsReady(_pmdDataChar!);
    _pmdDataSub = dataStream.listen(
      _onPmdDataNotification,
      onError: (Object e, StackTrace st) {
        if (_hasOpenEcgStream) _ecgController!.addError(e, st);
      },
    );

    if (querySettings) {
      try {
        final rsp = await _sendPmdCommand(
          PmdCommandBuilder.getSettings(PmdMeasurementType.ecg),
        );
        if (rsp.isSuccess) {
          developer.log(
            'Web Polar ECG settings: '
            '${PmdAvailableSettings.parse(rsp.parameters)}',
          );
        }
      } catch (e) {
        developer.log('Web Polar: settings query failed (non-fatal): $e');
      }
    }

    final response = await _sendPmdCommand(
      PmdCommandBuilder.startMeasurement(
        PmdMeasurementType.ecg,
        sampleRate: sampleRate,
        resolution: resolution,
      ),
    );
    if (!response.isSuccess &&
        response.errorCode == PmdResponseCode.alreadyInState) {
      developer.log('Web Polar: ECG stream was already active; attaching');
    } else if (!response.isSuccess) {
      throw StateError(
        'PMD start ECG failed: ${response.errorMessage} '
        '(code ${response.errorCode})',
      );
    }

    _ecgStreaming = true;
    developer.log(
      'Web Polar: ECG streaming @ ${sampleRate}Hz, $resolution-bit',
    );
  }

  Future<void> stopEcgStreaming() async {
    final shouldSendStop =
        _ecgStreaming && isConnected && _pmdControlChar != null;
    _ecgStreaming = false;

    if (shouldSendStop) {
      try {
        await _sendPmdCommand(
          PmdCommandBuilder.stopMeasurement(PmdMeasurementType.ecg),
        );
      } catch (e) {
        developer.log('Web Polar: stop ECG warning: $e');
      }
    }

    if (!_accStreaming) {
      await _cancelPmdSubscriptions();
      _completePendingPmdResponseError(StateError('PMD stream stopped'));
    }
    _ecgController?.close();
    _ecgController = null;
    developer.log('Web Polar: ECG streaming stopped');
  }

  Future<Stream<List<WebPolarAccSample>>> startAccStreaming() async {
    if (_accStreaming) await stopAccStreaming();

    _accController?.close();
    _accController = StreamController<List<WebPolarAccSample>>.broadcast();

    final ok = await connectToPolar();
    if (!ok) throw StateError('Failed to connect to Polar on web');

    if (_pmdControlChar == null || _pmdDataChar == null) {
      final pmdService = await getService(_device!, PolarPmdUuids.service);
      if (pmdService == null) {
        throw StateError('PMD service not found - device may not support ACC');
      }
      _pmdControlChar = await getCharacteristic(
        pmdService,
        PolarPmdUuids.controlPoint,
      );
      _pmdDataChar = await getCharacteristic(pmdService, PolarPmdUuids.data);
    }
    if (_pmdControlChar == null || _pmdDataChar == null) {
      throw StateError('PMD characteristics not found');
    }

    if (_pmdControlSub == null) {
      final controlStream = await startNotificationsReady(_pmdControlChar!);
      _pmdControlSub = controlStream.listen(
        _onPmdControlResponse,
        onError: (Object e, StackTrace st) {
          if (_hasOpenAccStream) _accController!.addError(e, st);
        },
      );
    }
    if (_pmdDataSub == null) {
      final dataStream = await startNotificationsReady(_pmdDataChar!);
      _pmdDataSub = dataStream.listen(
        _onPmdDataNotification,
        onError: (Object e, StackTrace st) {
          if (_hasOpenEcgStream) _ecgController!.addError(e, st);
          if (_hasOpenAccStream) _accController!.addError(e, st);
        },
      );
    }

    final response = await _sendPmdCommand(
      PmdCommandBuilder.startAccMeasurement(),
    );
    if (!response.isSuccess &&
        response.errorCode != PmdResponseCode.alreadyInState) {
      throw StateError(
        'PMD start ACC failed: ${response.errorMessage} '
        '(code ${response.errorCode})',
      );
    }

    _accStreaming = true;
    developer.log('Web Polar: ACC streaming @ 200Hz, 16-bit, +/-2g');
    return _accController!.stream;
  }

  Future<void> stopAccStreaming() async {
    final shouldSendStop =
        _accStreaming && isConnected && _pmdControlChar != null;
    _accStreaming = false;

    if (shouldSendStop) {
      try {
        await _sendPmdCommand(
          PmdCommandBuilder.stopMeasurement(PmdMeasurementType.acc),
        );
      } catch (e) {
        developer.log('Web Polar: stop ACC warning: $e');
      }
    }

    if (!_ecgStreaming) {
      await _cancelPmdSubscriptions();
      _completePendingPmdResponseError(StateError('PMD stream stopped'));
    }
    _accController?.close();
    _accController = null;
    developer.log('Web Polar: ACC streaming stopped');
  }

  Future<void> _cancelPmdSubscriptions() async {
    await _pmdDataSub?.cancel();
    _pmdDataSub = null;
    await _pmdControlSub?.cancel();
    _pmdControlSub = null;
    _pmdControlChar = null;
    _pmdDataChar = null;
  }

  void _onPmdControlResponse(List<int> data) {
    final rsp = PmdControlPointResponse.parse(data);
    if (_pendingPmdResponse != null && !_pendingPmdResponse!.isCompleted) {
      _pendingPmdResponse!.complete(rsp);
    }
  }

  void _onPmdDataNotification(List<int> data) {
    if (_ecgStreaming && _hasOpenEcgStream) {
      final frame = PmdDataParser.parseEcgNotification(data);
      if (frame != null) {
        final samples =
            frame.samplesUv
                .map(
                  (uv) => WebPolarEcgSample(
                    voltageUv: uv,
                    timestampNs: frame.timestampNs,
                  ),
                )
                .toList();
        if (samples.isNotEmpty) _ecgController!.add(samples);
      }
    }

    if (_accStreaming && _hasOpenAccStream) {
      final frame = PmdDataParser.parseAccNotification(data);
      if (frame == null) return;
      final samples =
          frame.samples
              .map(
                (sample) => WebPolarAccSample(
                  xMg: sample.xMg,
                  yMg: sample.yMg,
                  zMg: sample.zMg,
                  timestampNs: frame.timestampNs,
                ),
              )
              .toList();
      if (samples.isNotEmpty) _accController!.add(samples);
    }
  }

  Future<PmdControlPointResponse> _sendPmdCommand(
    Uint8List command, {
    int timeoutMs = 5000,
  }) async {
    if (_pmdControlChar == null) {
      throw StateError('PMD control point not available');
    }
    _completePendingPmdResponseError(StateError('Superseded'));

    final completer = Completer<PmdControlPointResponse>();
    _pendingPmdResponse = completer;

    try {
      await writeCharacteristic(_pmdControlChar!, command);
      return await completer.future.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout:
            () =>
                throw TimeoutException('No PMD response within ${timeoutMs}ms'),
      );
    } finally {
      if (identical(_pendingPmdResponse, completer)) {
        _pendingPmdResponse = null;
      }
    }
  }

  void _completePendingPmdResponseError(Object error) {
    final pending = _pendingPmdResponse;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(error);
    }
    _pendingPmdResponse = null;
  }

                   

  Future<void> stopRecording() async {
    if (_ecgStreaming) await stopEcgStreaming();
    if (_accStreaming) await stopAccStreaming();

    await _hrNotifSub?.cancel();
    _hrNotifSub = null;
    _hrChar = null;
    _hrController?.close();
    _hrController = null;
    _rrController?.close();
    _rrController = null;
    _rrBatchController?.close();
    _rrBatchController = null;

    if (sessionRrIntervals.length >= 10) {
      try {
        lastSessionHrv = HrvTimeDomain.compute(sessionRrIntervals);
        developer.log(
          'Web Polar HRV: RMSSD='
          '${lastSessionHrv!.rmssd.toStringAsFixed(1)} ms',
        );
      } catch (e) {
        developer.log('Web Polar HRV error: $e');
      }
    }

    developer.log('Web Polar: stopped, device still connected');
  }

  Future<void> stopHeartRateStreaming() async {
    await _hrNotifSub?.cancel();
    _hrNotifSub = null;
    _hrChar = null;
    await _hrController?.close();
    await _rrController?.close();
    await _rrBatchController?.close();
    _hrController = null;
    _rrController = null;
    _rrBatchController = null;
  }

  void dispose() {
    _disposed = true;
    _manualDisconnect = true;
    _ecgStreaming = false;
    _accStreaming = false;
    _completePendingPmdResponseError(StateError('Polar connection disposed'));

    unawaited(_hrNotifSub?.cancel() ?? Future<void>.value());
    unawaited(_pmdControlSub?.cancel() ?? Future<void>.value());
    unawaited(_pmdDataSub?.cancel() ?? Future<void>.value());
    unawaited(_hrController?.close() ?? Future<void>.value());
    unawaited(_rrController?.close() ?? Future<void>.value());
    unawaited(_rrBatchController?.close() ?? Future<void>.value());
    unawaited(_ecgController?.close() ?? Future<void>.value());
    unawaited(_accController?.close() ?? Future<void>.value());

    final listener = _disconnectListener;
    final device = _device;
    if (device != null && listener != null) {
      removeGattDisconnectedListener(device, listener);
    }
    _disconnectListener = null;

    if (device != null) {
      try {
        disconnectGatt(device);
      } catch (_) {}
    }
    _device = null;
    _clearGattHandles();
    _emitConnectionState(false);
    unawaited(_connectionStateController.close());
  }

  void _emitConnectionState(bool connected) {
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(connected);
    }
  }
}
