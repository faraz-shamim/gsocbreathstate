// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:breath_state/services/webxr/vr_resonance_sweep.dart';

void main() {
  group('VrResonanceSweepProtocol v2', () {
    test('uses the exact 78-cycle Fisher-Lehrer schedule', () {
      expect(
        VrResonanceSweepProtocol.rateAtElapsed(Duration.zero),
        closeTo(6.75, 0.001),
      );
      expect(VrResonanceSweepProtocol.config.cycleCount, 78);
      expect(
        VrResonanceSweepProtocol.defaultDuration.inMicroseconds,
        894640523,
      );
      expect(
        VrResonanceSweepProtocol.rateAtElapsed(
          VrResonanceSweepProtocol.defaultDuration,
        ),
        closeTo(
          VrResonanceSweepProtocol.config.buildSchedule().last.scheduledBpm,
          1e-9,
        ),
      );
    });

    test('uses equal inhale and exhale durations', () {
      final durations = VrResonanceSweepProtocol.durationsForRate(6.0);

      expect(durations.inhaleMs, 5000);
      expect(durations.exhaleMs, 5000);
    });

    test('emits protocol-only v2 live payload', () {
      final payload = VrResonanceSweepProtocol.livePayload(
        snapshot: _snapshot(),
        active: true,
        polarState: 'ready',
        beltState: 'ready',
      );

      expect(payload['protocolVersion'], 2);
      expect(payload['protocol'], VrBreathingProtocol.resonanceSweep);
      expect(payload['cycleIndex'], 8);
      expect(payload['cycleCount'], 78);
      expect(payload['phase'], 'exhale');
      expect(payload['scheduledBpm'], 6.2);
      expect(payload['resultMode'], 'measured');
      expect(payload['deviceStates'], {
        'polar': 'ready',
        'respirationBelt': 'ready',
      });

      for (final removed in [
        'latestComposite',
        'latestRsaAmplitude',
        'latestPhaseCoherence',
        'lfPower',
        'rmssd',
        'earlyStopTriggered',
        'currentRateBpm',
      ]) {
        expect(payload, isNot(contains(removed)));
      }
    });

    test('emits provenance and quality in result payload', () {
      final result = _result(RfAcquisitionMode.estimated);
      final payload = VrResonanceSweepProtocol.resultPayload(
        result,
        estimateConfirmationRequired: true,
      );

      expect(payload['protocolVersion'], 2);
      expect(payload['resultMode'], 'estimated');
      expect(payload['rfBpm'], 5.8);
      expect(payload['estimateConfirmationRequired'], isTrue);
      expect(payload['ectopicCorrections'], 2);
      expect(payload, isNot(contains('confidence')));
      expect(payload, isNot(contains('peakCompositeScore')));
    });

    test('keeps a read-only v1 decoder for historical payloads', () {
      final parsed = VrResonanceSweepV1Payload.tryParse({
        'version': 1,
        'optimalBreathingRateBpm': 5.9,
        'confidence': 0.8,
        'actualDurationSeconds': 300,
      });

      expect(parsed, isNotNull);
      expect(parsed!.bestRateBpm, 5.9);
      expect(parsed.confidence, 0.8);
      expect(VrResonanceSweepV1Payload.tryParse({'version': 2}), isNull);
    });

    test('WebXR consumer renders v2 pacing instead of legacy scores', () {
      final source =
          File('web/vr/webxr_biofeedback.js').readAsStringSync();

      expect(source, contains('Number(sweep.protocolVersion) === 2'));
      expect(source, contains('sweepState.cycleIndex'));
      expect(source, contains('sweepState.scheduledBpm'));
      expect(source, contains('Precise RF Assessment'));
      expect(source, isNot(contains('sweepState.latestComposite')));
      expect(source, isNot(contains('earlyStopTriggered')));
    });

    test('normalizes command protocol aliases', () {
      expect(
        VrBreathingProtocol.normalize('rf_sweep'),
        VrBreathingProtocol.resonanceSweep,
      );
      expect(
        VrBreathingProtocol.normalize('unknown'),
        VrBreathingProtocol.resonanceBreathing,
      );
    });
  });
}

RfAssessmentSnapshot _snapshot() => const RfAssessmentSnapshot(
  state: RfAssessmentControllerState.running,
  mode: RfAcquisitionMode.measured,
  cycleIndex: 8,
  cycleCount: 78,
  phase: RfBreathPhase.exhale,
  phaseProgress: 0.4,
  scheduledBpm: 6.2,
  elapsedMs: 80000,
  remainingMs: 814640.522875817,
  rrCount: 90,
  respirationCount: 800,
  polarReady: true,
  beltConnected: true,
  beltSignalDetected: true,
);

RfAssessmentResult _result(RfAcquisitionMode mode) => RfAssessmentResult(
  protocolVersion: FisherLehrerProtocolConfig.referenceVersion,
  mode: mode,
  status: RfResultStatus.completed,
  rfBpm: 5.8,
  rfCenterElapsedMs: 600000,
  peakToTroughAmplitude: 122,
  scheduledBpmAtCenter: 5.75,
  fittedRespirationBpm: mode == RfAcquisitionMode.measured ? 5.79 : null,
  adherenceDeltaBpm: mode == RfAcquisitionMode.measured ? 0.04 : null,
  respirationFitError: mode == RfAcquisitionMode.measured ? 0.02 : null,
  quality: const RfQualityReport(
    protocolCompleted: true,
    fullAnalysisWindowAvailable: true,
    rrContinuityPassed: true,
    beltCoveragePassed: true,
    respirationFitConverged: true,
    breathingAdherencePassed: true,
    beltCoverage: 1,
    maximumObservedBeltGapMs: 100,
    maximumObservedRrGapMs: 1100,
    ectopicCorrections: 2,
    flags: [],
  ),
  trace: const RfAnalysisTrace(),
);
