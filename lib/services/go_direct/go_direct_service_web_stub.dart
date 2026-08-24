// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'go_direct_constants.dart';

class GoDirectServiceWeb {
  final connectionState = ValueNotifier<GoDirectConnectionState>(
    GoDirectConnectionState.disconnected,
  );
  String? connectedDeviceName;
  String? lastError;
  String? get lastConnectedDeviceName => connectedDeviceName;

  List<GoDirectSensorInfo> get availableSensors => [];
  bool get isStreaming => false;
  bool get isConnected => false;

  Stream<GoDirectMeasurement> get measurementStream => const Stream.empty();
  Stream<double> get respirationForceStream => const Stream.empty();

  Future<bool> connect() async => false;
  Future<bool> reconnect() async => false;
  Future<void> disconnect() async {}
  Future<void> startMeasurements({
    List<int>? sensorNumbers,
    int periodMs = 100,
  }) async {}
  Future<void> stopMeasurements() async {}
  void dispose() {}
}
