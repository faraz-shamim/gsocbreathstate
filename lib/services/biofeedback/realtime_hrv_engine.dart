// SPDX-License-Identifier: AGPL-3.0-only
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';
import 'package:breath_state/services/hrv_analysis/hrv_frequency_domain.dart';
import 'package:breath_state/services/biofeedback/signal_quality_index.dart';

class RealtimeHrvSnapshot {
  final DateTime timestamp;

  final List<double> windowRRs;

  final List<SqiResult> sqiResults;

  final HrvTimeDomainResult? timeDomain;

  final HrvFrequencyDomainResult? freqDomain;

  final double coherence;

  final double? coherencePeakFrequencyHz;
  final double? coherenceWindowLowHz;
  final double? coherenceWindowHighHz;

  final double instantHR;

  final double meanHR;

  final double latestRR;

  final int totalIntervalsReceived;

  final double windowDurationSec;

  const RealtimeHrvSnapshot({
    required this.timestamp,
    required this.windowRRs,
    required this.sqiResults,
    this.timeDomain,
    this.freqDomain,
    required this.coherence,
    this.coherencePeakFrequencyHz,
    this.coherenceWindowLowHz,
    this.coherenceWindowHighHz,
    required this.instantHR,
    required this.meanHR,
    required this.latestRR,
    required this.totalIntervalsReceived,
    required this.windowDurationSec,
  });
}

class RealtimeHrvEngine {
  final int windowDurationSec;

  final int updateIntervalMs;

  final List<_TimestampedRR> _buffer = [];

  int _totalReceived = 0;

  final StreamController<RealtimeHrvSnapshot> _controller =
      StreamController<RealtimeHrvSnapshot>.broadcast();

  Timer? _updateTimer;

  bool _running = false;

  final List<double> _coherenceHistory = [];

  double? _currentBreathingRateBpm;

  RealtimeHrvEngine({
    this.windowDurationSec = 60,
    this.updateIntervalMs = 5000,
  });

  Stream<RealtimeHrvSnapshot> get snapshots => _controller.stream;

  bool get isRunning => _running;

  int get windowSize => _buffer.length;

  int get effectiveWindowDurationSec {
    final bpm = _currentBreathingRateBpm;
    if (bpm == null || !bpm.isFinite || bpm <= 0) return windowDurationSec;
    final seconds = (60.0 / bpm) * 5.5;
    return seconds.round().clamp(30, 90).toInt();
  }

  void start() {
    if (_running) return;
    _running = true;
    _updateTimer = Timer.periodic(
      Duration(milliseconds: updateIntervalMs),
      (_) => _computeAndEmit(),
    );
  }

  void stop() {
    _running = false;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  void addRR(double rrMs) {
    _buffer.add(_TimestampedRR(DateTime.now(), rrMs));
    _totalReceived++;
    _pruneWindow();
  }

  void addRRBatch(List<double> rrIntervals) {
    final now = DateTime.now();
    for (int i = 0; i < rrIntervals.length; i++) {
      _buffer.add(
        _TimestampedRR(now.add(Duration(milliseconds: i)), rrIntervals[i]),
      );
    }
    _totalReceived += rrIntervals.length;
    _pruneWindow();
  }

  void setBreathingRateBpm(double? bpm) {
    if (bpm == null || !bpm.isFinite || bpm <= 0) {
      _currentBreathingRateBpm = null;
    } else {
      _currentBreathingRateBpm = bpm;
    }
    _pruneWindow();
  }

  void _pruneWindow() {
    final cutoff = DateTime.now().subtract(
      Duration(seconds: effectiveWindowDurationSec),
    );
    _buffer.removeWhere((r) => r.timestamp.isBefore(cutoff));
  }

  void _computeAndEmit() {
    if (_controller.isClosed) return;
    _pruneWindow();

    final rrList = _buffer.map((r) => r.rr).toList();
    if (rrList.isEmpty) return;

    final sqiResults = SignalQualityIndex.classifyAll(rrList);

    final double latestRR = rrList.last;
    final double instantHR = latestRR > 0 ? 60000.0 / latestRR : 0;
    final double meanRR = rrList.reduce((a, b) => a + b) / rrList.length;
    final double meanHR = meanRR > 0 ? 60000.0 / meanRR : 0;

    final double windowDur = rrList.reduce((a, b) => a + b) / 1000.0;

    HrvTimeDomainResult? timeDomain;
    if (rrList.length >= 5) {
      try {
        timeDomain = HrvTimeDomain.compute(rrList);
      } catch (_) {}
    }

    HrvFrequencyDomainResult? freqDomain;
    if (rrList.length >= 30 && windowDur >= 15) {
      try {
        freqDomain = HrvFrequencyDomainAnalyzer.analyze(rrList);
      } catch (_) {}
    }

    final coherenceResult = _computeClinicalCoherence(freqDomain);
    final coherence = coherenceResult.score;

    _coherenceHistory.add(coherence);
    if (_coherenceHistory.length > 12) {
      _coherenceHistory.removeAt(0);
    }
    final double smoothedCoherence =
        _coherenceHistory.isNotEmpty
            ? _coherenceHistory.reduce((a, b) => a + b) /
                _coherenceHistory.length
            : coherence;

    final snapshot = RealtimeHrvSnapshot(
      timestamp: DateTime.now(),
      windowRRs: List<double>.from(rrList),
      sqiResults: sqiResults,
      timeDomain: timeDomain,
      freqDomain: freqDomain,
      coherence: smoothedCoherence.clamp(0.0, 100.0).toDouble(),
      coherencePeakFrequencyHz: coherenceResult.peakFrequencyHz,
      coherenceWindowLowHz: coherenceResult.windowLowHz,
      coherenceWindowHighHz: coherenceResult.windowHighHz,
      instantHR: instantHR,
      meanHR: meanHR,
      latestRR: latestRR,
      totalIntervalsReceived: _totalReceived,
      windowDurationSec: windowDur,
    );

    _controller.add(snapshot);
  }

  _CoherenceResult _computeClinicalCoherence(
    HrvFrequencyDomainResult? freqDomain,
  ) {
    if (freqDomain == null ||
        freqDomain.frequencies.length != freqDomain.psd.length ||
        freqDomain.frequencies.length < 2 ||
        freqDomain.totalPower <= 0) {
      return const _CoherenceResult(score: 0);
    }

    const lfLow = 0.04;
    const lfHigh = 0.15;
    const halfWindowHz = 0.015;
    final freq = freqDomain.frequencies;
    final psd = freqDomain.psd;

    int? peakIndex;
    for (var i = 0; i < freq.length; i++) {
      final f = freq[i];
      if (f < lfLow || f > lfHigh) continue;
      if (peakIndex == null || psd[i] > psd[peakIndex]) {
        peakIndex = i;
      }
    }
    if (peakIndex == null) return const _CoherenceResult(score: 0);

    final peakFrequency = freq[peakIndex];
    final low = math.max(lfLow, peakFrequency - halfWindowHz);
    final high = math.min(lfHigh, peakFrequency + halfWindowHz);
    final peakPower = _integrateBand(freq, psd, low, high);
    final remainingPower = math.max(freqDomain.totalPower - peakPower, 0);

    if (peakPower <= 0 || remainingPower <= 0) {
      return _CoherenceResult(
        score: peakPower > 0 ? 100 : 0,
        peakFrequencyHz: peakFrequency,
        windowLowHz: low,
        windowHighHz: high,
      );
    }

    final ratio = peakPower / remainingPower;
    return _CoherenceResult(
      score: (ratio * 100).clamp(0.0, 100.0).toDouble(),
      peakFrequencyHz: peakFrequency,
      windowLowHz: low,
      windowHighHz: high,
    );
  }

  double _integrateBand(
    List<double> frequencies,
    List<double> psd,
    double lowHz,
    double highHz,
  ) {
    double sum = 0;
    for (var i = 0; i < frequencies.length - 1; i++) {
      final f0 = frequencies[i];
      final f1 = frequencies[i + 1];
      if (f1 < lowHz || f0 > highHz) continue;

      final clippedLow = math.max(f0, lowHz);
      final clippedHigh = math.min(f1, highHz);
      if (clippedHigh <= clippedLow) continue;

      final p0 = _linearAt(f0, psd[i], f1, psd[i + 1], clippedLow);
      final p1 = _linearAt(f0, psd[i], f1, psd[i + 1], clippedHigh);
      sum += (clippedHigh - clippedLow) * (p0 + p1) * 0.5;
    }
    return sum;
  }

  double _linearAt(double x0, double y0, double x1, double y1, double x) {
    if ((x1 - x0).abs() < 1e-12) return y0;
    final t = (x - x0) / (x1 - x0);
    return y0 + (y1 - y0) * t;
  }

  void forceUpdate() => _computeAndEmit();

  void reset() {
    _buffer.clear();
    _coherenceHistory.clear();
    _totalReceived = 0;
    _currentBreathingRateBpm = null;
  }
}

class _TimestampedRR {
  final DateTime timestamp;
  final double rr;
  const _TimestampedRR(this.timestamp, this.rr);
}

class _CoherenceResult {
  final double score;
  final double? peakFrequencyHz;
  final double? windowLowHz;
  final double? windowHighHz;

  const _CoherenceResult({
    required this.score,
    this.peakFrequencyHz,
    this.windowLowHz,
    this.windowHighHz,
  });
}
