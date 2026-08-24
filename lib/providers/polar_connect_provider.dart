// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:breath_state/services/heart_rate/polar_connect.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';

import 'package:breath_state/services/heart_rate/polar_connect_web.dart'
    if (dart.library.io) 'package:breath_state/services/heart_rate/polar_connect_web_stub.dart';

class UnifiedEcgSample {
  final double voltageUv;
  final int timestampNs;

  const UnifiedEcgSample({required this.voltageUv, required this.timestampNs});
}

class UnifiedAccSample {
  final int xMg;
  final int yMg;
  final int zMg;
  final int timestampNs;

  const UnifiedAccSample({
    required this.xMg,
    required this.yMg,
    required this.zMg,
    required this.timestampNs,
  });

  double get magnitudeMg =>
      math.sqrt((xMg * xMg + yMg * yMg + zMg * zMg).toDouble());
}

class UnifiedPolarConnect {
  final PolarConnect? mobile;
  final PolarConnectWeb? web;
  final List<double> _ecgDerivedRrIntervals = [];
  double? _ecgDerivedBpm;

  UnifiedPolarConnect.mobileDevice(PolarConnect pc) : mobile = pc, web = null;

  UnifiedPolarConnect.webDevice(PolarConnectWeb pw) : mobile = null, web = pw;

  bool get isWeb => web != null;
  bool get supportsEcg => true;
  bool get isConnected => mobile?.isDeviceReady ?? web?.isConnected ?? false;
  Stream<bool> get connectionStateStream =>
      mobile?.connectionStateStream ??
      web?.connectionStateStream ??
      const Stream.empty();

  Future<Stream<int>> getHeartRate() async {
    if (mobile != null) return mobile!.getHeartRate();
    if (web != null) return web!.getHeartRate();
    throw StateError('No polar connection');
  }

  Future<Stream<double>> getRrIntervals() async {
    if (mobile != null) return mobile!.getRrIntervals();
    if (web != null) return web!.getRrIntervals();
    throw StateError('No polar connection');
  }

  Future<Stream<List<double>>> getRrIntervalBatches() async {
    if (mobile != null) return mobile!.getRrIntervalBatches();
    if (web != null) return web!.getRrIntervalBatches();
    throw StateError('No polar connection');
  }

  Future<void> stopHeartRateStreaming() async {
    if (mobile != null) return mobile!.stopHeartRateStreaming();
    if (web != null) return web!.stopHeartRateStreaming();
  }

  Future<void> stopRecording() async {
    if (mobile != null) return mobile!.stopRecording();
    if (web != null) return web!.stopRecording();
  }

  Future<Stream<List<UnifiedEcgSample>>> startEcgStreaming() async {
    if (mobile != null) {
      final stream = await mobile!.getECG();
      return stream.map(
        (batch) =>
            batch
                .map(
                  (sample) => UnifiedEcgSample(
                    voltageUv: sample.voltage,
                    timestampNs: sample.timestampNs,
                  ),
                )
                .toList(),
      );
    }
    if (web != null) {
      final stream = await web!.startEcgStreaming();
      return stream.map(
        (batch) =>
            batch
                .map(
                  (sample) => UnifiedEcgSample(
                    voltageUv: sample.voltageUv,
                    timestampNs: sample.timestampNs,
                  ),
                )
                .toList(),
      );
    }
    throw StateError('No polar connection');
  }

  Future<void> stopEcgStreaming() async {
    if (mobile != null) return mobile!.stopEcgStreaming();
    if (web != null) return web!.stopEcgStreaming();
  }

  Future<Stream<List<UnifiedAccSample>>> startAccStreaming() async {
    if (mobile != null) {
      final stream = await mobile!.getACC();
      return stream.map(
        (batch) =>
            batch
                .map(
                  (sample) => UnifiedAccSample(
                    xMg: sample.xMg,
                    yMg: sample.yMg,
                    zMg: sample.zMg,
                    timestampNs: sample.timestampNs,
                  ),
                )
                .toList(),
      );
    }
    if (web != null) {
      final stream = await web!.startAccStreaming();
      return stream.map(
        (batch) =>
            batch
                .map(
                  (sample) => UnifiedAccSample(
                    xMg: sample.xMg,
                    yMg: sample.yMg,
                    zMg: sample.zMg,
                    timestampNs: sample.timestampNs,
                  ),
                )
                .toList(),
      );
    }
    throw StateError('No polar connection');
  }

  Future<void> stopAccStreaming() async {
    if (mobile != null) return mobile!.stopAccStreaming();
    if (web != null) return web!.stopAccStreaming();
  }

  HrvTimeDomainResult? get lastSessionHrv =>
      mobile?.lastSessionHrv ?? web?.lastSessionHrv;

  List<double> get sessionRrIntervals =>
      mobile?.sessionRrIntervals ?? web?.sessionRrIntervals ?? [];

  List<double> get ecgDerivedRrIntervals =>
      List.unmodifiable(_ecgDerivedRrIntervals);

  List<double> get bestSessionRrIntervals =>
      _ecgDerivedRrIntervals.length >= 10
          ? _ecgDerivedRrIntervals
          : sessionRrIntervals;

  int? get latestHr => mobile?.latestHr ?? web?.latestHr;

  double? get ecgDerivedBpm => _ecgDerivedBpm;

  bool get isEcgStreaming =>
      mobile?.isEcgStreaming ?? web?.isEcgStreaming ?? false;

  bool get isAccStreaming =>
      mobile?.isAccStreaming ?? web?.isAccStreaming ?? false;

  void resetEcgDerivedMetrics() {
    _ecgDerivedRrIntervals.clear();
    _ecgDerivedBpm = null;
  }

  void addEcgDerivedRrInterval(double rrMs, {double? bpm}) {
    if (!rrMs.isFinite || rrMs <= 0) return;
    _ecgDerivedRrIntervals.add(rrMs);
    _ecgDerivedBpm = bpm;
  }
}

class PolarConnectProvider extends ChangeNotifier {
  UnifiedPolarConnect? _unified;
  bool _isConnected = false;
  String? _deviceName;

  bool get isConnected {
    final web = _unified?.web;
    if (web != null) return web.isConnected;
    return _isConnected;
  }

  bool get hasDevice => _unified != null || _isConnected;

  String? get deviceName => _unified?.web?.deviceName ?? _deviceName;

  Future<bool> connectToPolarSensor(
    String identifier, {
    String? displayName,
  }) async {
    if (kIsWeb) return false;

    await _disposeCurrentMobileConnection();

    final pc = PolarConnect(
      identifier: identifier,
      onConnectionChanged: notifyListeners,
    );
    _unified = UnifiedPolarConnect.mobileDevice(pc);
    _isConnected = true;
    _deviceName =
        (displayName != null && displayName.trim().isNotEmpty)
            ? displayName.trim()
            : 'Polar H10 ($identifier)';
    notifyListeners();

    developer.log(
      'PolarConnectProvider: sensor registered ($identifier). '
      'Actual BLE connection deferred to first stream request.',
    );
    return true;
  }

  Future<bool> connectViaBrowser() async {
    if (!kIsWeb) return false;
    final existingWeb = _unified?.web;
    if (existingWeb != null) {
      final ok = await existingWeb.connectToPolar();
      if (ok) {
        _isConnected = true;
        _deviceName = existingWeb.deviceName ?? 'Polar H10';
        notifyListeners();
        return true;
      }
    }

    final pw = PolarConnectWeb();
    final ok = await pw.connectToPolar();
    if (ok) {
      _unified = UnifiedPolarConnect.webDevice(pw);
      _isConnected = true;
      _deviceName = pw.deviceName ?? 'Polar H10';
      notifyListeners();
      return true;
    }
    return false;
  }

  UnifiedPolarConnect? getPolarConnect() => _unified;

  Future<void> disconnect() async {
    await _disposeCurrentMobileConnection();
    _unified?.web?.dispose();
    _unified = null;
    _isConnected = false;
    _deviceName = null;
    notifyListeners();
  }

  Future<void> _disposeCurrentMobileConnection() async {
    final mobile = _unified?.mobile;
    if (mobile == null) return;

    developer.log(
      'PolarConnectProvider: disposing previous PolarConnect instance.',
    );
    try {
      await mobile.dispose().timeout(const Duration(seconds: 3));
    } catch (e) {
      developer.log('PolarConnect dispose warning: $e');
    }
  }
}
