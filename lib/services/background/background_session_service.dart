import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundSessionService {
  static const MethodChannel _channel = MethodChannel(
    'breath_state/background_session',
  );

  static int _activeSessions = 0;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> start({
    required String reason,
    bool usesConnectedDevice = true,
    bool usesMicrophone = false,
  }) async {
    if (!_isAndroid) return;

    _activeSessions++;
    if (_activeSessions > 1) return;

    try {
      await _ensureNotificationPermission();
      await _channel.invokeMethod<void>('start', {
        'reason': reason,
        'usesConnectedDevice': usesConnectedDevice,
        'usesMicrophone': usesMicrophone,
      });
    } catch (e, stackTrace) {
      _activeSessions = 0;
      developer.log(
        'Background session service failed to start: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> stop() async {
    if (!_isAndroid) return;
    if (_activeSessions == 0) return;

    _activeSessions--;
    if (_activeSessions > 0) return;

    try {
      await _channel.invokeMethod<void>('stop');
    } catch (e, stackTrace) {
      developer.log(
        'Background session service failed to stop: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> forceStop() async {
    if (!_isAndroid) return;
    _activeSessions = 0;

    try {
      await _channel.invokeMethod<void>('stop');
    } catch (e, stackTrace) {
      developer.log(
        'Background session service failed to force-stop: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }
}
