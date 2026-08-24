enum SimulatorPresetId {
  calmCoherent,
  stressed,
  resonanceFriendly,
  poorSignal,
  recoveryRamp,
  manual,
}

class SimulatorPreset {
  final SimulatorPresetId id;
  final String label;
  final String badge;
  final double heartRateBpm;
  final double breathRateBpm;
  final double rsaAmplitudeMs;
  final double ecgNoiseUv;
  final double packetDropPercent;
  final double motionLevel;
  final bool ectopyEnabled;

  const SimulatorPreset({
    required this.id,
    required this.label,
    required this.badge,
    required this.heartRateBpm,
    required this.breathRateBpm,
    required this.rsaAmplitudeMs,
    required this.ecgNoiseUv,
    required this.packetDropPercent,
    required this.motionLevel,
    required this.ectopyEnabled,
  });

  static const all = <SimulatorPreset>[
    SimulatorPreset(
      id: SimulatorPresetId.calmCoherent,
      label: 'Calm',
      badge: 'Stable',
      heartRateBpm: 68,
      breathRateBpm: 6,
      rsaAmplitudeMs: 80,
      ecgNoiseUv: 12,
      packetDropPercent: 0,
      motionLevel: 0.05,
      ectopyEnabled: false,
    ),
    SimulatorPreset(
      id: SimulatorPresetId.stressed,
      label: 'Stressed',
      badge: 'Fast',
      heartRateBpm: 105,
      breathRateBpm: 18,
      rsaAmplitudeMs: 15,
      ecgNoiseUv: 28,
      packetDropPercent: 0,
      motionLevel: 0.2,
      ectopyEnabled: false,
    ),
    SimulatorPreset(
      id: SimulatorPresetId.resonanceFriendly,
      label: 'Resonance',
      badge: 'Sweep',
      heartRateBpm: 72,
      breathRateBpm: 5.8,
      rsaAmplitudeMs: 110,
      ecgNoiseUv: 10,
      packetDropPercent: 0,
      motionLevel: 0.04,
      ectopyEnabled: false,
    ),
    SimulatorPreset(
      id: SimulatorPresetId.poorSignal,
      label: 'Poor Signal',
      badge: 'Noisy',
      heartRateBpm: 92,
      breathRateBpm: 13,
      rsaAmplitudeMs: 20,
      ecgNoiseUv: 95,
      packetDropPercent: 8,
      motionLevel: 0.85,
      ectopyEnabled: true,
    ),
    SimulatorPreset(
      id: SimulatorPresetId.recoveryRamp,
      label: 'Recovery',
      badge: 'Ramp',
      heartRateBpm: 88,
      breathRateBpm: 8,
      rsaAmplitudeMs: 55,
      ecgNoiseUv: 18,
      packetDropPercent: 0,
      motionLevel: 0.12,
      ectopyEnabled: false,
    ),
    SimulatorPreset(
      id: SimulatorPresetId.manual,
      label: 'Manual',
      badge: 'Live',
      heartRateBpm: 70,
      breathRateBpm: 6,
      rsaAmplitudeMs: 70,
      ecgNoiseUv: 20,
      packetDropPercent: 0,
      motionLevel: 0.1,
      ectopyEnabled: false,
    ),
  ];

  static SimulatorPreset byId(SimulatorPresetId id) {
    return all.firstWhere((preset) => preset.id == id);
  }
}
