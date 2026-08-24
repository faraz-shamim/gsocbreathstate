// SPDX-License-Identifier: AGPL-3.0-only
enum BreathingPhase { inhale, hold, exhale, emptyHold }

extension BreathingPhaseLabel on BreathingPhase {
  String get label {
    switch (this) {
      case BreathingPhase.inhale:
        return 'Inhale';
      case BreathingPhase.hold:
        return 'Hold';
      case BreathingPhase.exhale:
        return 'Exhale';
      case BreathingPhase.emptyHold:
        return 'Hold Empty';
    }
  }
}

class BreathingProtocol {
  final Duration inhaleDuration;
  final Duration holdDuration;
  final Duration exhaleDuration;
  final Duration emptyHoldDuration;

  BreathingProtocol({
    required this.inhaleDuration,
    required this.holdDuration,
    required this.exhaleDuration,
    this.emptyHoldDuration = Duration.zero,
  }) {
    final durations = [
      inhaleDuration,
      holdDuration,
      exhaleDuration,
      emptyHoldDuration,
    ];
    if (durations.any((duration) => duration.isNegative)) {
      throw ArgumentError.value(
        durations,
        'durations',
        'Breathing phase durations cannot be negative.',
      );
    }
    if (durations.every((duration) => duration == Duration.zero)) {
      throw ArgumentError.value(
        durations,
        'durations',
        'At least one breathing phase must have a duration.',
      );
    }
  }

  factory BreathingProtocol.fromRatios({
    required double inhale,
    required double hold,
    required double exhale,
    required double emptyHold,
    required Duration cycleDuration,
  }) {
    final weights = [inhale, hold, exhale, emptyHold];
    if (weights.any((weight) => !weight.isFinite || weight < 0)) {
      throw ArgumentError.value(
        weights,
        'ratios',
        'Breathing ratios must be finite and nonnegative.',
      );
    }
    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);
    if (totalWeight <= 0) {
      throw ArgumentError.value(
        weights,
        'ratios',
        'At least one breathing ratio must be greater than zero.',
      );
    }
    if (cycleDuration <= Duration.zero) {
      throw ArgumentError.value(
        cycleDuration,
        'cycleDuration',
        'Cycle duration must be greater than zero.',
      );
    }

    final cycleMicroseconds = cycleDuration.inMicroseconds;
    final allocations = [
      for (final weight in weights)
        (cycleMicroseconds * weight / totalWeight).round(),
    ];
    final lastActiveIndex = weights.lastIndexWhere((weight) => weight > 0);
    final allocatedMicroseconds = allocations.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    allocations[lastActiveIndex] += cycleMicroseconds - allocatedMicroseconds;

    return BreathingProtocol(
      inhaleDuration: Duration(microseconds: allocations[0]),
      holdDuration: Duration(microseconds: allocations[1]),
      exhaleDuration: Duration(microseconds: allocations[2]),
      emptyHoldDuration: Duration(microseconds: allocations[3]),
    );
  }

  Duration durationFor(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inhale:
        return inhaleDuration;
      case BreathingPhase.hold:
        return holdDuration;
      case BreathingPhase.exhale:
        return exhaleDuration;
      case BreathingPhase.emptyHold:
        return emptyHoldDuration;
    }
  }

  List<BreathingPhase> get activePhases => [
    for (final phase in BreathingPhase.values)
      if (durationFor(phase) > Duration.zero) phase,
  ];

  BreathingPhase get firstPhase => activePhases.first;

  BreathingPhase nextPhase(BreathingPhase current) {
    final phases = activePhases;
    final currentIndex = phases.indexOf(current);
    if (currentIndex < 0) return phases.first;
    return phases[(currentIndex + 1) % phases.length];
  }

  Duration get cycleDuration =>
      inhaleDuration + holdDuration + exhaleDuration + emptyHoldDuration;

  Duration phaseStart(BreathingPhase phase) {
    var elapsed = Duration.zero;
    for (final candidate in BreathingPhase.values) {
      if (candidate == phase) return elapsed;
      elapsed += durationFor(candidate);
    }
    return Duration.zero;
  }

  double fractionFor(BreathingPhase phase) =>
      durationFor(phase).inMicroseconds / cycleDuration.inMicroseconds;

  double startFractionFor(BreathingPhase phase) =>
      phaseStart(phase).inMicroseconds / cycleDuration.inMicroseconds;
}
