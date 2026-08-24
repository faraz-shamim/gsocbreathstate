// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:math' as math;

import 'package:breath_state/services/hrv_analysis/signal_processing.dart'
    show CubicSpline;

class SynchronizedSensorFrame {
  final DateTime timestamp;
  final double rrMs;
  final double respiration;

  const SynchronizedSensorFrame({
    required this.timestamp,
    required this.rrMs,
    required this.respiration,
  });
}

class SensorSynchronizer {
  final double sampleRateHz;
  final Duration retention;
  final List<_TimedValue> _rrBuffer = [];
  final List<_TimedValue> _respBuffer = [];

  SensorSynchronizer({
    this.sampleRateHz = 4.0,
    this.retention = const Duration(seconds: 120),
  });

  void addRrInterval(double rrMs, {DateTime? timestamp}) {
    if (!rrMs.isFinite || rrMs <= 0) return;
    _rrBuffer.add(_TimedValue(timestamp ?? DateTime.now(), rrMs));
    _prune();
  }

  void addRespiration(double value, {DateTime? timestamp}) {
    if (!value.isFinite) return;
    _respBuffer.add(_TimedValue(timestamp ?? DateTime.now(), value));
    _prune();
  }

  List<SynchronizedSensorFrame> alignedFrames({
    Duration minOverlap = const Duration(seconds: 10),
  }) {
    _prune();
    if (_rrBuffer.length < 2 || _respBuffer.length < 2) return const [];

    final start = _latest(
      _rrBuffer.first.timestamp,
      _respBuffer.first.timestamp,
    );
    final end = _earliest(_rrBuffer.last.timestamp, _respBuffer.last.timestamp);
    if (end.difference(start) < minOverlap) return const [];

    final (rrTimes, rrValues) = _seriesForWindow(_rrBuffer, start, end);
    final (respTimes, respValues) = _seriesForWindow(_respBuffer, start, end);
    if (rrTimes.length < 2 || respTimes.length < 2) return const [];

    final durationSec = end.difference(start).inMicroseconds / 1e6;
    final count = math.max(2, (durationSec * sampleRateHz).floor() + 1);
    final stepSec = 1.0 / sampleRateHz;
    final uniformTimes = List<double>.generate(count, (i) => i * stepSec);
    final rrUniform = _interpolateToGrid(rrTimes, rrValues, uniformTimes);
    final respUniform = _interpolateToGrid(respTimes, respValues, uniformTimes);

    return List<SynchronizedSensorFrame>.generate(count, (index) {
      return SynchronizedSensorFrame(
        timestamp: start.add(
          Duration(milliseconds: (uniformTimes[index] * 1000).round()),
        ),
        rrMs: rrUniform[index],
        respiration: respUniform[index],
      );
    });
  }

  void clear() {
    _rrBuffer.clear();
    _respBuffer.clear();
  }

  List<double> _interpolateToGrid(
    List<double> times,
    List<double> values,
    List<double> grid,
  ) {
    if (times.length < 3) return _linearInterpolateToGrid(times, values, grid);
    try {
      return CubicSpline(times, values).evaluateList(grid);
    } catch (_) {
      return _linearInterpolateToGrid(times, values, grid);
    }
  }

  List<double> _linearInterpolateToGrid(
    List<double> times,
    List<double> values,
    List<double> grid,
  ) {
    var j = 0;
    return grid.map((t) {
      while (j < times.length - 2 && times[j + 1] < t) {
        j++;
      }
      if (j >= times.length - 1) return values.last;
      final span = times[j + 1] - times[j];
      final fraction = span.abs() < 1e-12 ? 0.0 : (t - times[j]) / span;
      return values[j] + fraction * (values[j + 1] - values[j]);
    }).toList();
  }

  (List<double>, List<double>) _seriesForWindow(
    List<_TimedValue> points,
    DateTime start,
    DateTime end,
  ) {
    final window = <_TimedValue>[];
    _TimedValue? beforeStart;
    _TimedValue? afterEnd;

    for (final point in points) {
      if (point.timestamp.isBefore(start)) {
        beforeStart = point;
      } else if (point.timestamp.isAfter(end)) {
        afterEnd ??= point;
        break;
      } else {
        window.add(point);
      }
    }

    if (beforeStart != null) window.insert(0, beforeStart);
    if (afterEnd != null) window.add(afterEnd);

    final times = <double>[];
    final values = <double>[];
    for (final point in window) {
      final t = point.timestamp.difference(start).inMicroseconds / 1e6;
      if (times.isNotEmpty && (t - times.last).abs() < 1e-6) {
        values[values.length - 1] = point.value;
        continue;
      }
      times.add(t);
      values.add(point.value);
    }
    return (times, values);
  }

  void _prune() {
    final cutoff = DateTime.now().subtract(retention);
    _rrBuffer.removeWhere((point) => point.timestamp.isBefore(cutoff));
    _respBuffer.removeWhere((point) => point.timestamp.isBefore(cutoff));
  }

  DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  DateTime _earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

class _TimedValue {
  final DateTime timestamp;
  final double value;

  const _TimedValue(this.timestamp, this.value);
}
