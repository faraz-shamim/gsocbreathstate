// SPDX-License-Identifier: AGPL-3.0-only
                                              
   
                                                           
library;

import 'dart:async';

                        
import 'package:breath_state/services/biofeedback/realtime_hrv_engine.dart';
import 'package:breath_state/services/webxr/webxr_messages.dart';

class WebXRBridge {
  bool get isSupported => false;
  int get messagesSent => 0;
  Stream<WebXRCommand> get commands => const Stream.empty();

  void open() {}
  void sendMessage(Map<String, Object?> message) {}
  void sendData(Map<String, double> data) {}
  void sendSnapshot(RealtimeHrvSnapshot snapshot) {}
  void sendSnapshotWithBreathRate(
    RealtimeHrvSnapshot snapshot,
    double breathingRateBpm,
  ) {}
  Future<void> launchVrWindow() async {}
  void dispose() {}
}
