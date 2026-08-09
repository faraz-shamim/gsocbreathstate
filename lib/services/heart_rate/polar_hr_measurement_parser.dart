class PolarHeartRateMeasurement {
  final int heartRateBpm;
  final List<double> rrIntervalsMs;

  const PolarHeartRateMeasurement({
    required this.heartRateBpm,
    required this.rrIntervalsMs,
  });
}

                                                                    
   
                                                                             
                              
PolarHeartRateMeasurement? parsePolarHeartRateMeasurement(List<int> data) {
  if (data.length < 2) return null;
  final flags = data[0];
  final isUint16 = (flags & 0x01) != 0;
  final hasEnergy = (flags & 0x08) != 0;
  final hasRr = (flags & 0x10) != 0;

  var offset = 1;
  late final int heartRate;
  if (isUint16) {
    if (data.length < 3) return null;
    heartRate = data[1] | (data[2] << 8);
    offset = 3;
  } else {
    heartRate = data[1];
    offset = 2;
  }

  if (hasEnergy) {
    if (offset + 1 >= data.length) {
      return PolarHeartRateMeasurement(
        heartRateBpm: heartRate,
        rrIntervalsMs: const [],
      );
    }
    offset += 2;
  }

  final rrIntervals = <double>[];
  if (hasRr) {
    for (var index = offset; index + 1 < data.length; index += 2) {
      final raw = data[index] | (data[index + 1] << 8);
      final rrMs = raw * 1000.0 / 1024.0;
      if (rrMs.isFinite && rrMs > 0) {
        rrIntervals.add(rrMs);
      }
    }
  }
  return PolarHeartRateMeasurement(
    heartRateBpm: heartRate,
    rrIntervalsMs: List.unmodifiable(rrIntervals),
  );
}
