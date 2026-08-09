                                      
   
                                                                  
                                                                           
library;

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'package:breath_state/services/biofeedback/realtime_hrv_engine.dart';
import 'package:breath_state/services/hrv_analysis/hrv_psychophysiological_indices.dart';
import 'package:breath_state/services/webxr/webxr_messages.dart';

                                                                 

@JS('BroadcastChannel')
extension type _JsBroadcastChannel._(JSObject _) implements JSObject {
  external factory _JsBroadcastChannel(String name);
  external void postMessage(JSAny? message);
  external void close();
  external set onmessage(JSFunction? handler);
}

                                                                 

class WebXRBridge {
  _JsBroadcastChannel? _channel;
  JSFunction? _messageHandler;
  final StreamController<WebXRCommand> _commandController =
      StreamController<WebXRCommand>.broadcast();
  int _messagesSent = 0;

                                                          
  bool get isSupported => true;

                                                  
  int get messagesSent => _messagesSent;

                                        
  Stream<WebXRCommand> get commands => _commandController.stream;

                                             
  void open() {
    if (_channel != null) return;

    final channel = _JsBroadcastChannel('breathstate_hrv_vr');
    _messageHandler =
        ((web.MessageEvent event) {
          final decoded = event.data.dartify();
          final command = WebXRCommand.tryParse(decoded);
          if (command != null && !_commandController.isClosed) {
            _commandController.add(command);
          }
        }).toJS;
    channel.onmessage = _messageHandler;
    _channel = channel;
  }

                                                  
  void sendMessage(Map<String, Object?> message) {
    open();
    _channel?.postMessage(message.jsify());
    _messagesSent++;
  }

                                                                 
                                             
  void sendData(Map<String, double> data) {
    sendMessage(
      WebXRMessage.build(
        WebXRMessageType.biofeedbackSnapshot,
        metrics: data.map((key, value) => MapEntry(key, value)),
      ),
    );
  }

                                                                  
                           
  void sendSnapshot(RealtimeHrvSnapshot snapshot) {
    if (snapshot.windowRRs.length < 10) return;

                         
    double stressIndex = 150;
    try {
      final psychResult = PsychophysiologicalAnalyzer.compute(
        rrIntervalsMs: snapshot.windowRRs,
        rmssd: snapshot.timeDomain?.rmssd ?? 40,
        meanNN: snapshot.timeDomain?.meanNN ?? 800,
      );
      stressIndex = psychResult.stressIndex.value ?? 150;
    } catch (_) {}

    sendMessage(
      WebXRMessage.build(
        WebXRMessageType.biofeedbackSnapshot,
        metrics: {
          'rmssd': snapshot.timeDomain?.rmssd ?? 40,
          'stressIndex': stressIndex,
          'coherence': snapshot.coherence.clamp(0.0, 100.0).toDouble(),
          'heartRate': snapshot.instantHR,
          'sdnn': snapshot.timeDomain?.sdnn ?? 30,
          'breathingRate': 6.0,
        },
      ),
    );
  }

                                                            
                          
  void sendSnapshotWithBreathRate(
    RealtimeHrvSnapshot snapshot,
    double breathingRateBpm,
  ) {
    if (snapshot.windowRRs.length < 10) return;

    double stressIndex = 150;
    try {
      final psychResult = PsychophysiologicalAnalyzer.compute(
        rrIntervalsMs: snapshot.windowRRs,
        rmssd: snapshot.timeDomain?.rmssd ?? 40,
        meanNN: snapshot.timeDomain?.meanNN ?? 800,
      );
      stressIndex = psychResult.stressIndex.value ?? 150;
    } catch (_) {}

    sendMessage(
      WebXRMessage.build(
        WebXRMessageType.biofeedbackSnapshot,
        metrics: {
          'rmssd': snapshot.timeDomain?.rmssd ?? 40,
          'stressIndex': stressIndex,
          'coherence': snapshot.coherence.clamp(0.0, 100.0).toDouble(),
          'heartRate': snapshot.instantHR,
          'sdnn': snapshot.timeDomain?.sdnn ?? 30,
          'breathingRate': breathingRateBpm,
        },
      ),
    );
  }

                                                   
     
                                                                
                                             
  Future<void> launchVrWindow() async {
    web.window.open('vr/webxr_scene.html', 'breathstate_vr');
  }

                                     
  void dispose() {
    try {
      _channel?.onmessage = null;
      _channel?.close();
    } catch (_) {}
    _channel = null;
    _messageHandler = null;
    _commandController.close();
  }
}
