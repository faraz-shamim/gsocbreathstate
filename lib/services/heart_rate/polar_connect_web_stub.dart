import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';

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
  final List<double> sessionRrIntervals = [];
  HrvTimeDomainResult? lastSessionHrv;
  int? latestHr;
  String? get deviceName => null;
  bool get isConnected => false;
  bool get isEcgStreaming => false;
  bool get isAccStreaming => false;
  Stream<bool> get connectionStateStream => const Stream.empty();

  Future<bool> connectToPolar() async => false;
  Future<Stream<int>> getHeartRate() async => const Stream.empty();
  Future<Stream<double>> getRrIntervals() async => const Stream.empty();
  Future<Stream<List<double>>> getRrIntervalBatches() async =>
      const Stream.empty();
  Future<Stream<List<WebPolarEcgSample>>> startEcgStreaming({
    int sampleRate = 130,
    int resolution = 14,
  }) async => const Stream.empty();
  Future<void> stopEcgStreaming() async {}
  Future<Stream<List<WebPolarAccSample>>> startAccStreaming() async =>
      const Stream.empty();
  Future<void> stopAccStreaming() async {}
  Future<void> stopHeartRateStreaming() async {}
  Future<void> stopRecording() async {}
  void dispose() {}
}
