library;

import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';

class VrBreathingProtocol {
  static const String resonanceBreathing = 'resonance_breathing';
  static const String resonanceSweep = 'resonance_sweep';

  static const Set<String> supported = {resonanceBreathing, resonanceSweep};

  static String normalize(Object? value) {
    final raw = value?.toString().trim();
    if (raw == resonanceSweep || raw == 'sweep' || raw == 'rf_sweep') {
      return resonanceSweep;
    }
    return resonanceBreathing;
  }

  static String label(String protocol) {
    return protocol == resonanceSweep ? 'Precise RF' : 'Resonance';
  }
}

class VrBreathDurations {
  final int inhaleMs;
  final int exhaleMs;

  const VrBreathDurations({required this.inhaleMs, required this.exhaleMs});
}

                                                              
   
                                                                              
                                                                                
                                      
class VrResonanceSweepProtocol {
  static const int bridgeProtocolVersion = 2;
  static const FisherLehrerProtocolConfig config = FisherLehrerProtocolConfig();

  static Duration get defaultDuration =>
      Duration(microseconds: (config.scheduledDurationMs * 1000).round());

  static double rateAtElapsed(Duration elapsed) {
    return config.cycleAtElapsedMs(elapsed.inMicroseconds / 1000).scheduledBpm;
  }

  static VrBreathDurations durationsForRate(double rateBpm) {
    final cycleMs = (60000 / rateBpm).round();
    final inhaleMs = (cycleMs / 2).round();
    return VrBreathDurations(inhaleMs: inhaleMs, exhaleMs: cycleMs - inhaleMs);
  }

  static Map<String, Object?> idlePayload({
    required String polarState,
    required String beltState,
    String status = 'idle',
  }) {
    final first = config.buildSchedule().first;
    return {
      'protocolVersion': bridgeProtocolVersion,
      'methodVersion': config.protocolVersion,
      'protocol': VrBreathingProtocol.resonanceSweep,
      'cycleIndex': 0,
      'cycleCount': config.cycleCount,
      'phase': RfBreathPhase.inhale.name,
      'phaseProgress': 0.0,
      'scheduledBpm': first.scheduledBpm,
      'halfPeriodMs': first.inhaleMs,
      'elapsedMs': 0.0,
      'remainingMs': config.scheduledDurationMs,
      'resultMode': null,
      'deviceStates': {'polar': polarState, 'respirationBelt': beltState},
      'status': status,
      'active': false,
    };
  }

  static Map<String, Object?> livePayload({
    required RfAssessmentSnapshot snapshot,
    required bool active,
    required String polarState,
    required String beltState,
  }) {
    final cycle = config.cycleAtElapsedMs(snapshot.elapsedMs);
    return {
      'protocolVersion': bridgeProtocolVersion,
      'methodVersion': config.protocolVersion,
      'protocol': VrBreathingProtocol.resonanceSweep,
                                                                
      'cycleIndex': snapshot.cycleIndex,
      'cycleCount': snapshot.cycleCount,
      'phase': snapshot.phase.name,
      'phaseProgress': snapshot.phaseProgress,
      'scheduledBpm': snapshot.scheduledBpm,
      'halfPeriodMs': cycle.inhaleMs,
      'elapsedMs': snapshot.elapsedMs,
      'remainingMs': snapshot.remainingMs,
      'resultMode': snapshot.mode?.name,
      'deviceStates': {'polar': polarState, 'respirationBelt': beltState},
      'status': snapshot.state.name,
      'active': active,
      if (snapshot.message != null) 'message': snapshot.message,
      if (snapshot.abortReason != null)
        'abortReason': snapshot.abortReason!.name,
      if (snapshot.result != null) 'result': resultPayload(snapshot.result!),
    };
  }

  static Map<String, Object?> resultPayload(
    RfAssessmentResult result, {
    double? appliedPatientFrequencyBpm,
    bool estimateConfirmationRequired = false,
  }) {
    return {
      'protocolVersion': bridgeProtocolVersion,
      'methodVersion': result.protocolVersion,
      'protocol': VrBreathingProtocol.resonanceSweep,
      'status': result.status.name,
      'resultMode': result.mode.name,
      'rfBpm': result.rfBpm,
      'rfHz': result.rfHz,
      'rfCenterElapsedMs': result.rfCenterElapsedMs,
      'peakToTroughAmplitudeMs': result.peakToTroughAmplitude,
      'scheduledBpmAtCenter': result.scheduledBpmAtCenter,
      'fittedRespirationBpm': result.fittedRespirationBpm,
      'adherenceDeltaBpm': result.adherenceDeltaBpm,
      'respirationFitError': result.respirationFitError,
      'ectopicCorrections': result.quality.ectopicCorrections,
      'quality': result.quality.toJson(),
      'estimateConfirmationRequired': estimateConfirmationRequired,
      if (appliedPatientFrequencyBpm != null)
        'appliedPatientFrequencyBpm': appliedPatientFrequencyBpm,
    };
  }
}

                                                                  
class VrResonanceSweepV1Payload {
  final double? bestRateBpm;
  final double? confidence;
  final double? actualDurationSeconds;
  final String? warning;

  const VrResonanceSweepV1Payload({
    required this.bestRateBpm,
    required this.confidence,
    required this.actualDurationSeconds,
    required this.warning,
  });

  static VrResonanceSweepV1Payload? tryParse(Map<Object?, Object?> payload) {
    final version = payload['version'];
    if (version is! num || version.toInt() != 1) return null;
    double? number(String key) => (payload[key] as num?)?.toDouble();
    return VrResonanceSweepV1Payload(
      bestRateBpm: number('optimalBreathingRateBpm') ?? number('bestRateBpm'),
      confidence: number('confidence'),
      actualDurationSeconds: number('actualDurationSeconds'),
      warning: payload['warning'] as String?,
    );
  }
}
