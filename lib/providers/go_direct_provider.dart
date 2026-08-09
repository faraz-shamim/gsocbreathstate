import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:breath_state/services/go_direct/go_direct_service.dart';
import 'package:breath_state/services/go_direct/go_direct_constants.dart';

import 'package:breath_state/services/go_direct/go_direct_service_web.dart'
    if (dart.library.io) 'package:breath_state/services/go_direct/go_direct_service_web_stub.dart';

class GoDirectProvider extends ChangeNotifier {
  GoDirectService? _mobileService;
  GoDirectServiceWeb? _webService;

  StreamSubscription<List<GoDirectScannedDevice>>? _scanSub;

  GoDirectProvider() {
    if (!kIsWeb) {
      _mobileService = GoDirectService();
      _mobileService!.connectionState.addListener(_onStateChanged);
      _scanSub = _mobileService!.scanResults.listen((devices) {
        lastScanResults = devices;
        notifyListeners();
      });
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

  List<GoDirectSensorInfo> get availableSensors {
    if (kIsWeb) return _webService?.availableSensors ?? [];
    return _mobileService?.availableSensors ?? [];
  }

  Stream<List<GoDirectScannedDevice>> get scanResults {
    if (kIsWeb) return const Stream.empty();
    return _mobileService?.scanResults ?? const Stream.empty();
  }

  Stream<GoDirectMeasurement> get measurementStream {
    if (kIsWeb) {
      return _webService?.measurementStream ?? const Stream.empty();
    }
    return _mobileService?.measurementStream ?? const Stream.empty();
  }

  Stream<double> get respirationForceStream {
    if (kIsWeb) {
      return _webService?.respirationForceStream ?? const Stream.empty();
    }
    return _mobileService?.respirationForceStream ?? const Stream.empty();
  }

  List<GoDirectScannedDevice> lastScanResults = [];

  Future<void> startScan() async {
    if (kIsWeb) return;
    await _mobileService?.startScan();
    notifyListeners();
  }

  Future<void> stopScan() async {
    if (kIsWeb) return;
    await _mobileService?.stopScan();
    notifyListeners();
  }

  Future<bool> connect(String deviceId) async {
    if (kIsWeb) return false;
    notifyListeners();
    final success = await _mobileService!.connect(deviceId);
    notifyListeners();
    return success;
  }

  Future<bool> connectViaBrowser() async {
    if (!kIsWeb) return false;

    _webService = GoDirectServiceWeb();
    _webService!.connectionState.addListener(_onStateChanged);
    notifyListeners();

    final success = await _webService!.connect();
    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    if (kIsWeb) {
      await _webService?.disconnect();
    } else {
      await _mobileService?.disconnect();
    }
    notifyListeners();
  }

  Future<void> startMeasurements({
    List<int>? sensorNumbers,
    int periodMs = 100,
  }) async {
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
    notifyListeners();
  }

  Future<void> stopMeasurements() async {
    if (kIsWeb) {
      await _webService?.stopMeasurements();
    } else {
      await _mobileService?.stopMeasurements();
    }
    notifyListeners();
  }

  void _onStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      _webService?.connectionState.removeListener(_onStateChanged);
      _webService?.dispose();
    } else {
      _mobileService?.connectionState.removeListener(_onStateChanged);
      _scanSub?.cancel();
      _mobileService?.dispose();
    }
    super.dispose();
  }
}
