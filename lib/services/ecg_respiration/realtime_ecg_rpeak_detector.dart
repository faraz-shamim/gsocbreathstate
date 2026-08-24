// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/services/biofeedback/signal_quality_index.dart';
import 'package:breath_state/services/ecg_respiration/ecg_rpeak_detector.dart';

class RealtimeEcgRPeakEvent {
  final int globalSampleIndex;
  final double timeSec;
  final double amplitudeUv;
  final double? rrMs;
  final double? bpm;
  final SqiResult? sqi;
  final double signalQuality;

  const RealtimeEcgRPeakEvent({
    required this.globalSampleIndex,
    required this.timeSec,
    required this.amplitudeUv,
    required this.rrMs,
    required this.bpm,
    required this.sqi,
    required this.signalQuality,
  });
}

class RealtimeEcgRPeakDetector {
  final double sampleRate;
  final int bufferSeconds;
  final int bpmSmoothingWindow;

  final List<double> _buffer = [];
  final List<double> _rrHistory = [];
  final List<double> _recentRrs = [];

  late final int _maxBufferSamples;
  int _bufferStartGlobalIndex = 0;
  int? _lastPeakGlobalIndex;

  RealtimeEcgRPeakDetector({
    this.sampleRate = EcgRPeakDetector.defaultSampleRate,
    this.bufferSeconds = 30,
    this.bpmSmoothingWindow = 2,
  }) {
    _maxBufferSamples = (sampleRate * bufferSeconds).round();
  }

  List<double> get rrIntervals => List.unmodifiable(_rrHistory);
  int get rPeakCount =>
      _lastPeakGlobalIndex == null ? 0 : _rrHistory.length + 1;

  void reset() {
    _buffer.clear();
    _rrHistory.clear();
    _recentRrs.clear();
    _bufferStartGlobalIndex = 0;
    _lastPeakGlobalIndex = null;
  }

  List<RealtimeEcgRPeakEvent> addBatch(Iterable<double> samples) {
    var added = 0;
    for (final sample in samples) {
      if (!sample.isFinite) continue;
      _buffer.add(sample);
      added++;
    }
    if (added == 0) return const [];

    if (_buffer.length > _maxBufferSamples) {
      final removeCount = _buffer.length - _maxBufferSamples;
      _buffer.removeRange(0, removeCount);
      _bufferStartGlobalIndex += removeCount;
    }

    final minSamples = (sampleRate * 2.0).round();
    if (_buffer.length < minSamples) return const [];

    final detection = EcgRPeakDetector.detect(
      _buffer,
      sampleRate: sampleRate,
      refractoryMs: 300,
    );
    final peaks = detection.normalPeaks;
    if (peaks.isEmpty) return const [];

    final events = <RealtimeEcgRPeakEvent>[];
    for (final peak in peaks) {
      final globalIndex = _bufferStartGlobalIndex + peak.sampleIndex;
      final lastGlobal = _lastPeakGlobalIndex;
      if (lastGlobal != null && globalIndex <= lastGlobal) continue;

      double? rrMs;
      double? bpm;
      SqiResult? sqi;
      if (lastGlobal != null) {
        rrMs = (globalIndex - lastGlobal) / sampleRate * 1000.0;
        if (rrMs < 300 || rrMs > 2000) {
          _lastPeakGlobalIndex = globalIndex;
          continue;
        }

        sqi = SignalQualityIndex.classify(rrMs, _rrHistory);
        _rrHistory.add(rrMs);
        _recentRrs.add(rrMs);
        if (_recentRrs.length > bpmSmoothingWindow) {
          _recentRrs.removeAt(0);
        }
        final avgRr = _recentRrs.reduce((a, b) => a + b) / _recentRrs.length;
        bpm = 60000.0 / avgRr;
      }

      _lastPeakGlobalIndex = globalIndex;
      events.add(
        RealtimeEcgRPeakEvent(
          globalSampleIndex: globalIndex,
          timeSec: globalIndex / sampleRate,
          amplitudeUv: peak.amplitudeUv,
          rrMs: rrMs,
          bpm: bpm,
          sqi: sqi,
          signalQuality: detection.signalQuality,
        ),
      );
    }

    return events;
  }
}
