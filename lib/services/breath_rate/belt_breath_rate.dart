library;
class BeltBreathResult {
  final double bpm;
  final List<int> peakIndices;
  final List<double> smoothedValues;

  const BeltBreathResult({
    required this.bpm,
    required this.peakIndices,
    required this.smoothedValues,
  });
}

BeltBreathResult estimateBreathRateFromForce(
  List<double> values, {
  double sampleRateHz = 10.0,
  double? durationSeconds,
}) {
  if (values.isEmpty) {
    return const BeltBreathResult(
      bpm: 0,
      peakIndices: [],
      smoothedValues: [],
    );
  }

  const int windowSize = 10;
  final smoothed = List<double>.filled(values.length, 0);

  for (int i = 0; i < values.length; i++) {
    final start = (i - windowSize ~/ 2).clamp(0, values.length - 1);
    final end = (i + windowSize ~/ 2).clamp(0, values.length - 1);
    double sum = 0;
    int count = 0;
    for (int j = start; j <= end; j++) {
      sum += values[j];
      count++;
    }
    smoothed[i] = sum / count;
  }

  final double mean =
      smoothed.reduce((a, b) => a + b) / smoothed.length;

  final int minGap = (sampleRateHz * 1.0).round().clamp(5, 200);

  int peakCount = 0;
  bool above = false;
  int lastPeakIndex = -minGap;
  final peakIndices = <int>[];

  for (int i = 0; i < smoothed.length; i++) {
    if (!above && smoothed[i] > mean) {
      if (i - lastPeakIndex >= minGap) {
        peakCount++;
        lastPeakIndex = i;
        peakIndices.add(i);
      }
      above = true;
    } else if (above && smoothed[i] < mean) {
      above = false;
    }
  }

  final double seconds =
      durationSeconds ?? (values.length / sampleRateHz);
  final double bpm = seconds > 0 ? peakCount * (60.0 / seconds) : 0;

  return BeltBreathResult(
    bpm: bpm,
    peakIndices: peakIndices,
    smoothedValues: smoothed,
  );
}
