import 'dart:math' as math;

import 'polar_protocol.dart';

class PhysiologySettings {
  final double heartRateBpm;
  final double breathRateBpm;
  final double rsaAmplitudeMs;
  final double ecgNoiseUv;
  final double packetDropPercent;
  final double motionLevel;
  final bool ectopyEnabled;

  const PhysiologySettings({
    required this.heartRateBpm,
    required this.breathRateBpm,
    required this.rsaAmplitudeMs,
    required this.ecgNoiseUv,
    required this.packetDropPercent,
    required this.motionLevel,
    required this.ectopyEnabled,
  });
}

class PhysiologyModel {
  static const double ecgSampleRateHz = 130.0;
  static const double accSampleRateHz = 200.0;

  final math.Random _random = math.Random();
  final List<_BeatEvent> _beats = <_BeatEvent>[];
  double _rrClockSec = 0;
  double _lastBeatSec = -0.75;
  double _nextBeatSec = 0.25;
  double? _pendingCompensatoryPauseMs;
  int _beatCount = 0;
  int _ecgSampleIndex = 0;
  int _accSampleIndex = 0;

  void reset() {
    _beats.clear();
    _rrClockSec = 0;
    _lastBeatSec = -0.75;
    _nextBeatSec = 0.25;
    _pendingCompensatoryPauseMs = null;
    _beatCount = 0;
    _ecgSampleIndex = 0;
    _accSampleIndex = 0;
  }

  List<double> drainRrIntervals(Duration elapsed, PhysiologySettings settings) {
    final startSec = _rrClockSec;
    final endSec = _rrClockSec + elapsed.inMilliseconds / 1000.0;
    _ensureBeatScheduleUntil(endSec, settings);
    _rrClockSec = endSec;
    _trimOldBeats();
    return _beats
        .where((beat) => beat.timeSec > startSec && beat.timeSec <= endSec)
        .map((beat) => beat.rrMs)
        .toList(growable: false);
  }

  List<double> nextEcgSamples(int count, PhysiologySettings settings) {
    final samples = <double>[];
    final endSec = (_ecgSampleIndex + count + 1) / ecgSampleRateHz;
    _ensureBeatScheduleUntil(endSec + 0.7, settings);

    for (var i = 0; i < count; i++) {
      final t = _ecgSampleIndex / ecgSampleRateHz;
      samples.add(_ecgUvAt(t, settings));
      _ecgSampleIndex++;
    }
    _trimOldBeats();
    return samples;
  }

  List<AccSample> nextAccSamples(int count, PhysiologySettings settings) {
    final samples = <AccSample>[];
    final breathHz = settings.breathRateBpm / 60.0;
    for (var i = 0; i < count; i++) {
      final t = _accSampleIndex / accSampleRateHz;
      final breath = math.sin(2 * math.pi * breathHz * t);
      final motionBurst = settings.motionLevel > 0.5
          ? math.sin(2 * math.pi * 2.4 * t) * 90.0 * settings.motionLevel
          : 0.0;
      samples.add(
        AccSample(
          xMg: (18 * breath + _noise(10 * settings.motionLevel)).round(),
          yMg:
              (8 * math.sin(2 * math.pi * breathHz * t + 0.8) +
                      motionBurst +
                      _noise(12 * settings.motionLevel))
                  .round(),
          zMg:
              (1000 +
                      10 * breath +
                      motionBurst * 0.35 +
                      _noise(8 * settings.motionLevel))
                  .round(),
        ),
      );
      _accSampleIndex++;
    }
    return samples;
  }

  bool shouldDropPacket(double dropPercent) {
    if (dropPercent <= 0) return false;
    return _random.nextDouble() < dropPercent / 100.0;
  }

  void _ensureBeatScheduleUntil(double endSec, PhysiologySettings settings) {
    while (_nextBeatSec <= endSec) {
      final actualRr = ((_nextBeatSec - _lastBeatSec) * 1000.0).clamp(
        300.0,
        2000.0,
      );
      final nominalRr = _rrMsAt(_nextBeatSec, settings);
      final isPremature = actualRr < nominalRr * 0.85;
      final isPauseBeat = actualRr > nominalRr * 1.15;
      final breathHz = settings.breathRateBpm.clamp(1.0, 60.0) / 60.0;
      final breath = math.sin(2 * math.pi * breathHz * _nextBeatSec);

      _beats.add(
        _BeatEvent(
          timeSec: _nextBeatSec,
          rrMs: actualRr,
          amplitudeScale:
              (1.0 + 0.10 * breath) *
              (isPremature
                  ? 0.72
                  : isPauseBeat
                  ? 1.05
                  : 1.0),
        ),
      );

      _lastBeatSec = _nextBeatSec;
      final nextIntervalMs = _nextIntervalMs(nominalRr, settings);
      _nextBeatSec += nextIntervalMs / 1000.0;
      _beatCount++;
    }
  }

  double _nextIntervalMs(double nominalRr, PhysiologySettings settings) {
    final pause = _pendingCompensatoryPauseMs;
    if (pause != null) {
      _pendingCompensatoryPauseMs = null;
      return pause;
    }

    if (settings.ectopyEnabled && _beatCount % 17 == 12) {
      _pendingCompensatoryPauseMs = (nominalRr * 1.28).clamp(300.0, 2000.0);
      return (nominalRr * 0.72).clamp(300.0, 2000.0);
    }

    return nominalRr;
  }

  double _rrMsAt(double t, PhysiologySettings settings) {
    final base = 60000.0 / settings.heartRateBpm.clamp(30.0, 220.0);
    final breathHz = settings.breathRateBpm.clamp(1.0, 60.0) / 60.0;
    final rsa = settings.rsaAmplitudeMs * math.sin(2 * math.pi * breathHz * t);
    final drift = 12 * math.sin(2 * math.pi * 0.015 * t);
    return (base + rsa + drift + _noise(4)).clamp(300.0, 2000.0);
  }

  double _ecgUvAt(double t, PhysiologySettings settings) {
    final breathHz = settings.breathRateBpm.clamp(1.0, 60.0) / 60.0;
    final breath = math.sin(2 * math.pi * breathHz * t);
    final baseline = 70 * breath + 18 * math.sin(2 * math.pi * 0.035 * t + 0.4);
    var waveform = baseline;

    for (final beat in _beats) {
      final dt = t - beat.timeSec;
      if (dt < -0.22 || dt > 0.46) continue;

      final scale = beat.amplitudeScale;
      waveform += 55 * scale * _gaussian(dt, -0.12, 0.034);
      waveform += -115 * scale * _gaussian(dt, -0.018, 0.010);
      waveform += 1080 * scale * _gaussian(dt, 0.000, 0.009);
      waveform += -260 * scale * _gaussian(dt, 0.024, 0.014);
      waveform += 175 * scale * _gaussian(dt, 0.205, 0.068);
    }

    return waveform + _noise(settings.ecgNoiseUv);
  }

  double _gaussian(double x, double mean, double sigma) {
    final z = (x - mean) / sigma;
    return math.exp(-0.5 * z * z);
  }

  double _noise(double amplitude) {
    if (amplitude <= 0) return 0;
    return (_random.nextDouble() * 2 - 1) * amplitude;
  }

  void _trimOldBeats() {
    final ecgTimeSec = _ecgSampleIndex / ecgSampleRateHz;
    final keepAfterSec = math.min(_rrClockSec, ecgTimeSec) - 4.0;
    while (_beats.length > 4 && _beats.first.timeSec < keepAfterSec) {
      _beats.removeAt(0);
    }
  }
}

class _BeatEvent {
  final double timeSec;
  final double rrMs;
  final double amplitudeScale;

  const _BeatEvent({
    required this.timeSec,
    required this.rrMs,
    required this.amplitudeScale,
  });
}
