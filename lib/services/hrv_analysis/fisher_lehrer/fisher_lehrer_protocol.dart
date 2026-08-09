                                                                      
library;

                                                                           
   
                                                                            
                                            
class FisherLehrerProtocolConfig {
  static const String referenceVersion = 'fisher_lehrer_2022_reference_v1';

  final String protocolVersion;
  final int cycleCount;
  final double startBpm;
  final double targetEndBpm;
  final double inhaleFraction;
  final double analysisWindowSeconds;
  final int ibiLowessPoints;
  final int excursionLowessPoints;
  final double referenceSampleRateHz;
  final double respirationSampleRateHz;
  final double minimumBeltCoverage;
  final double maximumBeltGapMs;
  final double maximumRrGapMs;
  final double maximumAdherenceDeltaBpm;

  const FisherLehrerProtocolConfig({
    this.protocolVersion = referenceVersion,
    this.cycleCount = 78,
    this.startBpm = 6.75,
    this.targetEndBpm = 4.25,
    this.inhaleFraction = 0.5,
    this.analysisWindowSeconds = 60,
    this.ibiLowessPoints = 41,
    this.excursionLowessPoints = 17,
    this.referenceSampleRateHz = 256,
    this.respirationSampleRateHz = 10,
    this.minimumBeltCoverage = 0.9,
    this.maximumBeltGapMs = 1000,
    this.maximumRrGapMs = 3000,
    this.maximumAdherenceDeltaBpm = 0.5,
  }) : assert(cycleCount > 0),
       assert(startBpm > 0),
       assert(targetEndBpm > 0),
       assert(inhaleFraction > 0 && inhaleFraction < 1),
       assert(analysisWindowSeconds > 0),
       assert(ibiLowessPoints > 2),
       assert(excursionLowessPoints > 2),
       assert(referenceSampleRateHz > 0),
       assert(respirationSampleRateHz > 0),
       assert(minimumBeltCoverage > 0 && minimumBeltCoverage <= 1),
       assert(maximumBeltGapMs > 0),
       assert(maximumRrGapMs > 0),
       assert(maximumAdherenceDeltaBpm >= 0);

  double get startPeriodMs => 60000 / startBpm;

  double get targetEndPeriodMs => 60000 / targetEndBpm;

                                                                         
                                 
  double get periodIncrementMs =>
      (targetEndPeriodMs - startPeriodMs) / cycleCount;

  List<ScheduledBreathCycle> buildSchedule() {
    var elapsedMs = 0.0;
    return List<ScheduledBreathCycle>.generate(cycleCount, (index) {
      final periodMs = startPeriodMs + index * periodIncrementMs;
      final cycle = ScheduledBreathCycle(
        index: index,
        startElapsedMs: elapsedMs,
        periodMs: periodMs,
        inhaleFraction: inhaleFraction,
      );
      elapsedMs += periodMs;
      return cycle;
    }, growable: false);
  }

  double get scheduledDurationMs {
    final count = cycleCount.toDouble();
    return count * startPeriodMs + periodIncrementMs * count * (count - 1) / 2;
  }

  ScheduledBreathCycle cycleAtElapsedMs(double elapsedMs) {
    final schedule = buildSchedule();
    if (elapsedMs <= 0) return schedule.first;
    if (elapsedMs >= scheduledDurationMs) return schedule.last;

    var low = 0;
    var high = schedule.length - 1;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      final cycle = schedule[middle];
      if (elapsedMs < cycle.startElapsedMs) {
        high = middle - 1;
      } else if (elapsedMs >= cycle.endElapsedMs) {
        low = middle + 1;
      } else {
        return cycle;
      }
    }
    return schedule[low.clamp(0, schedule.length - 1)];
  }

  Map<String, Object> toJson() => {
    'protocolVersion': protocolVersion,
    'cycleCount': cycleCount,
    'startBpm': startBpm,
    'targetEndBpm': targetEndBpm,
    'inhaleFraction': inhaleFraction,
    'analysisWindowSeconds': analysisWindowSeconds,
    'ibiLowessPoints': ibiLowessPoints,
    'excursionLowessPoints': excursionLowessPoints,
    'referenceSampleRateHz': referenceSampleRateHz,
    'respirationSampleRateHz': respirationSampleRateHz,
    'minimumBeltCoverage': minimumBeltCoverage,
    'maximumBeltGapMs': maximumBeltGapMs,
    'maximumRrGapMs': maximumRrGapMs,
    'maximumAdherenceDeltaBpm': maximumAdherenceDeltaBpm,
    'periodIncrementMs': periodIncrementMs,
    'scheduledDurationMs': scheduledDurationMs,
  };

  factory FisherLehrerProtocolConfig.fromJson(Map<String, Object?> json) {
    return FisherLehrerProtocolConfig(
      protocolVersion: json['protocolVersion'] as String? ?? referenceVersion,
      cycleCount: (json['cycleCount'] as num?)?.toInt() ?? 78,
      startBpm: (json['startBpm'] as num?)?.toDouble() ?? 6.75,
      targetEndBpm: (json['targetEndBpm'] as num?)?.toDouble() ?? 4.25,
      inhaleFraction: (json['inhaleFraction'] as num?)?.toDouble() ?? 0.5,
      analysisWindowSeconds:
          (json['analysisWindowSeconds'] as num?)?.toDouble() ?? 60,
      ibiLowessPoints: (json['ibiLowessPoints'] as num?)?.toInt() ?? 41,
      excursionLowessPoints:
          (json['excursionLowessPoints'] as num?)?.toInt() ?? 17,
      referenceSampleRateHz:
          (json['referenceSampleRateHz'] as num?)?.toDouble() ?? 256,
      respirationSampleRateHz:
          (json['respirationSampleRateHz'] as num?)?.toDouble() ?? 10,
      minimumBeltCoverage:
          (json['minimumBeltCoverage'] as num?)?.toDouble() ?? 0.9,
      maximumBeltGapMs: (json['maximumBeltGapMs'] as num?)?.toDouble() ?? 1000,
      maximumRrGapMs: (json['maximumRrGapMs'] as num?)?.toDouble() ?? 3000,
      maximumAdherenceDeltaBpm:
          (json['maximumAdherenceDeltaBpm'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class ScheduledBreathCycle {
  final int index;
  final double startElapsedMs;
  final double periodMs;
  final double inhaleFraction;

  const ScheduledBreathCycle({
    required this.index,
    required this.startElapsedMs,
    required this.periodMs,
    required this.inhaleFraction,
  });

  double get endElapsedMs => startElapsedMs + periodMs;
  double get inhaleMs => periodMs * inhaleFraction;
  double get exhaleMs => periodMs * (1 - inhaleFraction);
  double get scheduledBpm => 60000 / periodMs;

  Map<String, Object> toJson() => {
    'index': index,
    'startElapsedMs': startElapsedMs,
    'periodMs': periodMs,
    'inhaleMs': inhaleMs,
    'exhaleMs': exhaleMs,
    'scheduledBpm': scheduledBpm,
  };
}
