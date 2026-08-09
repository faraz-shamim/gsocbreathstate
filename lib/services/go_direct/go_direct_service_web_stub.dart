                                                          
  
                                                                  

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'go_direct_constants.dart';

class GoDirectServiceWeb {
  final connectionState = ValueNotifier<GoDirectConnectionState>(
    GoDirectConnectionState.disconnected,
  );
  String? connectedDeviceName;

  List<GoDirectSensorInfo> get availableSensors => [];
  bool get isStreaming => false;
  bool get isConnected => false;

  Stream<GoDirectMeasurement> get measurementStream => const Stream.empty();
  Stream<double> get respirationForceStream => const Stream.empty();

  Future<bool> connect() async => false;
  Future<void> disconnect() async {}
  Future<void> startMeasurements({List<int>? sensorNumbers, int periodMs = 100}) async {}
  Future<void> stopMeasurements() async {}
  void dispose() {}
}