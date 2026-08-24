// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:breath_state/services/go_direct/go_direct_service.dart';
import 'package:breath_state/services/go_direct/go_direct_constants.dart';

import 'package:breath_state/services/go_direct/go_direct_service_web.dart'
    if (dart.library.io) 'package:breath_state/services/go_direct/go_direct_service_web_stub.dart';

class GoDirectProvider extends ChangeNotifier {
  GoDirectService? _mobileService;
  GoDirectServiceWeb? _webService;
  Future<bool>? _webConnectInFlight;
  StreamSubscription<GoDirectMeasurement>? _measurementSub;
  final _measurementController =
      StreamController<GoDirectMeasurement>.broadcast();
  int _measurementStreamGeneration = 0;
  bool _disposed = false;

  StreamSubscription<List<GoDirectScannedDevice>>? _scanSub;

  GoDirectProvider() {
    if (!kIsWeb) {
      _mobileService = GoDirectService();
      _mobileService!.connectionState.addListener(_onStateChanged);
      _scanSub = _mobileService!.scanResults.listen((devices) {
        lastScanResults = devices;
        _notifyListenersSafely();
      });
      _attachMeasurementStream(_mobileService!.measurementStream);
    }
  }

  GoDirectConnectionState get connectionState {
    if (kIsWeb) {
      return _webService?.connectionState.value ??
          GoDirectConnectionState.disconnected;
    }
    return _mobileService?.connectionState.value ??
        GoDirectConnectionState.disconnected;
  }

  bool get isConnected {
    if (kIsWeb) return _webService?.isConnected ?? false;
    return _mobileService?.isConnected ?? false;
  }

  bool get isStreaming {
    if (kIsWeb) return _webService?.isStreaming ?? false;
    return _mobileService?.isStreaming ?? false;
  }

  String? get connectedDeviceName {
    if (kIsWeb) return _webService?.connectedDeviceName;
    return _mobileService?.connectedDeviceName;
  }

  String? get lastConnectedDeviceId {
    if (kIsWeb) return null;
    return _mobileService?.lastConnectedDeviceId;
  }

  String? get lastConnectedDeviceName {
    if (kIsWeb) return _webService?.lastConnectedDeviceName;
    return _mobileService?.lastConnectedDeviceName;
  }

  bool get canReconnect {
    if (kIsWeb) return false;
    return lastConnectedDeviceId != null &&
        !isConnected &&
        connectionState != GoDirectConnectionState.connecting &&
        connectionState != GoDirectConnectionState.initializing;
  }

  String? get lastError {
    if (kIsWeb) return _webService?.lastError;
    return _mobileService?.lastError;
  }

  bool get hasCompletedScan =>
      !kIsWeb && (_mobileService?.hasCompletedScan ?? false);

  List<GoDirectSensorInfo> get availableSensors {
    if (kIsWeb) return _webService?.availableSensors ?? [];
    return _mobileService?.availableSensors ?? [];
  }

  Stream<List<GoDirectScannedDevice>> get scanResults {
    if (kIsWeb) return const Stream.empty();
    return _mobileService?.scanResults ?? const Stream.empty();
  }

  Stream<GoDirectMeasurement> get measurementStream {
    return _measurementController.stream;
  }

  Stream<double> get respirationForceStream {
    return measurementStream
        .where((m) => m.sensorNumber == 1)
        .map((m) => m.value);
  }

  List<GoDirectScannedDevice> lastScanResults = [];

  Future<void> startScan() async {
    if (_disposed || kIsWeb) return;
    await _mobileService?.startScan();
    _notifyListenersSafely();
  }

  Future<void> stopScan() async {
    if (_disposed || kIsWeb) return;
    await _mobileService?.stopScan();
    _notifyListenersSafely();
  }

  Future<bool> connect(String deviceId) async {
    if (_disposed || kIsWeb) return false;
    _notifyListenersSafely();
    final success = await _mobileService?.connect(deviceId) ?? false;
    _notifyListenersSafely();
    return success;
  }

  Future<bool> reconnect() async {
    if (_disposed) return false;
    _notifyListenersSafely();
    final bool success;
    if (kIsWeb) {
      success = await _webService?.reconnect() ?? false;
    } else {
      success = await _mobileService?.reconnect() ?? false;
    }
    _notifyListenersSafely();
    return success;
  }

  Future<bool> connectViaBrowser() {
    if (_disposed || !kIsWeb) return Future<bool>.value(false);

    final existing = _webConnectInFlight;
    if (existing != null) return existing;
    if (_webService?.isConnected ?? false) return Future<bool>.value(true);

    late final Future<bool> connectFuture;
    connectFuture = _connectViaBrowserInternal().whenComplete(() {
      if (identical(_webConnectInFlight, connectFuture)) {
        _webConnectInFlight = null;
      }
    });
    _webConnectInFlight = connectFuture;
    return connectFuture;
  }

  Future<bool> _connectViaBrowserInternal() async {
    if (_disposed) return false;

    final previousService = _webService;
    if (previousService != null) {
      previousService.connectionState.removeListener(_onStateChanged);
      await _detachMeasurementStream();
      await previousService.disconnect();
      previousService.dispose();
    }

    if (_disposed) return false;

    final service = GoDirectServiceWeb();
    _webService = service;
    service.connectionState.addListener(_onStateChanged);
    _attachMeasurementStream(service.measurementStream);
    _notifyListenersSafely();

    final success = await service.connect();
    _notifyListenersSafely();
    return success;
  }

  Future<void> disconnect() async {
    if (_disposed) return;
    if (kIsWeb) {
      await _webService?.disconnect();
    } else {
      await _mobileService?.disconnect();
    }
    _notifyListenersSafely();
  }

  Future<void> startMeasurements({
    List<int>? sensorNumbers,
    int periodMs = 100,
  }) async {
    if (_disposed) return;
    if (kIsWeb) {
      await _webService?.startMeasurements(
        sensorNumbers: sensorNumbers,
        periodMs: periodMs,
      );
    } else {
      await _mobileService?.startMeasurements(
        sensorNumbers: sensorNumbers,
        periodMs: periodMs,
      );
    }
    _notifyListenersSafely();
  }

  Future<void> stopMeasurements() async {
    if (_disposed) return;
    if (kIsWeb) {
      await _webService?.stopMeasurements();
    } else {
      await _mobileService?.stopMeasurements();
    }
    _notifyListenersSafely();
  }

  void _onStateChanged() {
    _notifyListenersSafely();
  }

  void _attachMeasurementStream(Stream<GoDirectMeasurement> stream) {
    final generation = ++_measurementStreamGeneration;
    unawaited(_measurementSub?.cancel());
    _measurementSub = stream.listen(
      (measurement) {
        if (_disposed || generation != _measurementStreamGeneration) return;
        if (!_measurementController.isClosed) {
          _measurementController.add(measurement);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed || generation != _measurementStreamGeneration) return;
        debugPrint('GoDirectProvider measurement stream error: $error');
      },
    );
  }

  Future<void> _detachMeasurementStream() async {
    _measurementStreamGeneration++;
    final subscription = _measurementSub;
    _measurementSub = null;
    await subscription?.cancel();
  }

  void _notifyListenersSafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _measurementStreamGeneration++;
    if (kIsWeb) {
      _webService?.connectionState.removeListener(_onStateChanged);
      _webService?.dispose();
    } else {
      _mobileService?.connectionState.removeListener(_onStateChanged);
      _scanSub?.cancel();
      _mobileService?.dispose();
    }
    unawaited(_measurementSub?.cancel());
    unawaited(_measurementController.close());
    super.dispose();
  }
}
