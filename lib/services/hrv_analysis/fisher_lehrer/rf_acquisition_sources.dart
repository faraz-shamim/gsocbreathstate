import 'dart:async';

import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';

                                                                          
abstract interface class RfPolarAcquisitionSource {
  bool get isConnected;
  Stream<bool> get connectionStateChanges;
  Future<Stream<List<double>>> startRrBatches();
  Future<void> stopRrBatches();
}

                                         
class RfRespirationReading {
  final int sensorNumber;
  final double value;

  const RfRespirationReading({required this.sensorNumber, required this.value});
}

                                                                           
abstract interface class RfRespirationAcquisitionSource {
  bool get isConnected;
  bool get isStreaming;
  Stream<bool> get connectionStateChanges;
  Stream<RfRespirationReading> get readings;
  Future<void> startRespiration();
  Future<void> stopRespiration();
}

class UnifiedPolarRfAcquisitionSource implements RfPolarAcquisitionSource {
  final UnifiedPolarConnect polar;

  const UnifiedPolarRfAcquisitionSource(this.polar);

  @override
  bool get isConnected => polar.isConnected;

  @override
  Stream<bool> get connectionStateChanges => polar.connectionStateStream;

  @override
  Future<Stream<List<double>>> startRrBatches() => polar.getRrIntervalBatches();

  @override
  Future<void> stopRrBatches() => polar.stopHeartRateStreaming();
}

class GoDirectRfRespirationSource implements RfRespirationAcquisitionSource {
  final GoDirectProvider provider;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  bool _disposed = false;

  GoDirectRfRespirationSource(this.provider) {
    provider.addListener(_onProviderChanged);
  }

  @override
  bool get isConnected => provider.isConnected;

  @override
  bool get isStreaming => provider.isStreaming;

  @override
  Stream<bool> get connectionStateChanges => _connectionController.stream;

  @override
  Stream<RfRespirationReading> get readings => provider.measurementStream.map(
    (measurement) => RfRespirationReading(
      sensorNumber: measurement.sensorNumber,
      value: measurement.value,
    ),
  );

  @override
  Future<void> startRespiration() async {
    if (!provider.isConnected) {
      throw StateError('GDX-RB is not connected.');
    }
    if (provider.isStreaming) {
      await provider.stopMeasurements();
    }
    await provider.startMeasurements(sensorNumbers: const [1], periodMs: 100);
  }

  @override
  Future<void> stopRespiration() => provider.stopMeasurements();

  void _onProviderChanged() {
    if (!_disposed && !_connectionController.isClosed) {
      _connectionController.add(provider.isConnected);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    provider.removeListener(_onProviderChanged);
    await _connectionController.close();
  }
}
