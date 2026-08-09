import 'dart:math' as math;

import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const protocol = FisherLehrerProtocolConfig();
  const analyzer = FisherLehrerRfAnalyzer();

  test(
    'identifies a synthetic cardiac excursion maximum in estimated mode',
    () {
      final targetCycle = protocol.buildSchedule().reduce(
        (a, b) =>
            (a.scheduledBpm - 5.5).abs() < (b.scheduledBpm - 5.5).abs() ? a : b,
      );
      final targetCenterMs =
          targetCycle.startElapsedMs + targetCycle.periodMs / 2;
      final rrSamples = _syntheticRr(protocol, targetCenterMs);

      final result = analyzer.analyze(
        RfAssessmentInput(
          rrSamples: rrSamples,
          mode: RfAcquisitionMode.estimated,
        ),
      );

      expect(result.status, RfResultStatus.completed);
      expect(result.quality.flags, isEmpty);
      expect(result.rfCenterElapsedMs, closeTo(targetCenterMs, 90000));
      expect(result.rfBpm, result.scheduledBpmAtCenter);
      expect(result.fittedRespirationBpm, isNull);
      expect(result.trace.smoothedPeakToTrough, isNotEmpty);
    },
  );

  test('rejects an incomplete protocol', () {
    final rrSamples = _syntheticRr(protocol, 450000);

    final result = analyzer.analyze(
      RfAssessmentInput(
        rrSamples: rrSamples,
        mode: RfAcquisitionMode.estimated,
        completedCycles: 77,
      ),
    );

    expect(result.status, RfResultStatus.invalid);
    expect(result.quality.flags, contains(RfQualityFlag.protocolIncomplete));
    expect(result.rfBpm, isNull);
  });

  test('measured mode requires respiration rather than synthesizing it', () {
    final rrSamples = _syntheticRr(protocol, 450000);

    final result = analyzer.analyze(
      RfAssessmentInput(rrSamples: rrSamples, mode: RfAcquisitionMode.measured),
    );

    expect(result.status, RfResultStatus.invalid);
    expect(result.quality.flags, contains(RfQualityFlag.respirationMissing));
    expect(result.fittedRespirationBpm, isNull);
  });

  test('completes measured mode with an adherent belt waveform', () {
    final targetCycle = protocol.buildSchedule().reduce(
      (a, b) =>
          (a.scheduledBpm - 5.5).abs() < (b.scheduledBpm - 5.5).abs() ? a : b,
    );
    final targetCenterMs =
        targetCycle.startElapsedMs + targetCycle.periodMs / 2;
    final rrSamples = _syntheticRr(protocol, targetCenterMs);
    final respiration = _syntheticRespiration(protocol, 5.5);

    final result = analyzer.analyze(
      RfAssessmentInput(
        rrSamples: rrSamples,
        respirationSamples: respiration,
        mode: RfAcquisitionMode.measured,
      ),
    );

    expect(result.status, RfResultStatus.completed);
    expect(result.quality.flags, isEmpty);
    expect(result.quality.beltCoveragePassed, isTrue);
    expect(result.quality.respirationFitConverged, isTrue);
    expect(result.fittedRespirationBpm, closeTo(5.5, 0.05));
    expect(result.rfBpm, result.fittedRespirationBpm);
    expect(result.trace.respirationWindow, isNotEmpty);
    expect(result.trace.fittedRespiration, isNotEmpty);
  });

  test('invalidates a measured result when breathing is non-adherent', () {
    final targetCycle = protocol.buildSchedule().reduce(
      (a, b) =>
          (a.scheduledBpm - 5.5).abs() < (b.scheduledBpm - 5.5).abs() ? a : b,
    );
    final targetCenterMs =
        targetCycle.startElapsedMs + targetCycle.periodMs / 2;

    final result = analyzer.analyze(
      RfAssessmentInput(
        rrSamples: _syntheticRr(protocol, targetCenterMs),
        respirationSamples: _syntheticRespiration(protocol, 6.5),
        mode: RfAcquisitionMode.measured,
      ),
    );

    expect(result.status, RfResultStatus.invalid);
    expect(result.quality.flags, contains(RfQualityFlag.nonAdherent));
    expect(result.fittedRespirationBpm, closeTo(6.5, 0.05));
    expect(result.rfBpm, isNull);
  });

  test('invalidates a measured result with a critical belt gap', () {
    final targetCycle = protocol.buildSchedule().reduce(
      (a, b) =>
          (a.scheduledBpm - 5.5).abs() < (b.scheduledBpm - 5.5).abs() ? a : b,
    );
    final targetCenterMs =
        targetCycle.startElapsedMs + targetCycle.periodMs / 2;
    final respiration =
        _syntheticRespiration(protocol, 5.5)
            .where(
              (sample) =>
                  sample.elapsedMs < targetCenterMs - 1000 ||
                  sample.elapsedMs > targetCenterMs + 1000,
            )
            .toList();

    final result = analyzer.analyze(
      RfAssessmentInput(
        rrSamples: _syntheticRr(protocol, targetCenterMs),
        respirationSamples: respiration,
        mode: RfAcquisitionMode.measured,
      ),
    );

    expect(result.status, RfResultStatus.invalid);
    expect(result.quality.flags, contains(RfQualityFlag.respirationGap));
    expect(result.rfBpm, isNull);
  });

  test('input and isolate entry-point serialization preserve provenance', () {
    final input = RfAssessmentInput(
      rrSamples: _syntheticRr(protocol, 450000),
      mode: RfAcquisitionMode.estimated,
    );

    final serialized = analyzeFisherLehrerAssessment(input.toJson());

    expect(serialized['protocolVersion'], protocol.protocolVersion);
    expect(serialized['mode'], RfAcquisitionMode.estimated.name);
    expect(serialized['status'], RfResultStatus.completed.name);
    expect(serialized['quality'], isA<Map<String, Object>>());
  });

  test('background isolate runner reconstructs the complete result', () async {
    final input = RfAssessmentInput(
      rrSamples: _syntheticRr(protocol, 450000),
      mode: RfAcquisitionMode.estimated,
    );

    final result = await analyzeFisherLehrerInBackground(input);

    expect(result.protocolVersion, protocol.protocolVersion);
    expect(result.mode, RfAcquisitionMode.estimated);
    expect(result.status, RfResultStatus.completed);
    expect(result.trace.smoothedPeakToTrough, isNotEmpty);
    expect(result.quality.flags, isEmpty);
  });
}

List<RfBeatSample> _syntheticRr(
  FisherLehrerProtocolConfig protocol,
  double amplitudeCenterMs,
) {
  final samples = <RfBeatSample>[];
  var elapsedMs = 0.0;
  var phase = 0.0;
  while (elapsedMs < protocol.scheduledDurationMs) {
    final cycle = protocol.cycleAtElapsedMs(elapsedMs);
    final sigmaMs = 70000.0;
    final distance = (elapsedMs - amplitudeCenterMs) / sigmaMs;
    final amplitude = 18 + 115 * math.exp(-(distance * distance));
    final rrMs = 900 - amplitude * math.sin(phase);
    elapsedMs += rrMs;
    phase += 2 * math.pi * cycle.scheduledBpm / 60 * rrMs / 1000;
    samples.add(RfBeatSample(elapsedMs: elapsedMs, rrMs: rrMs));
  }
  return samples;
}

List<RfRespirationSample> _syntheticRespiration(
  FisherLehrerProtocolConfig protocol,
  double bpm,
) {
  final samples = <RfRespirationSample>[];
  const samplePeriodMs = 100.0;
  var elapsedMs = 0.0;
  var phase = 0.0;
  final phaseStep = 2 * math.pi * bpm / 60 * samplePeriodMs / 1000;
  while (elapsedMs <= protocol.scheduledDurationMs) {
    samples.add(
      RfRespirationSample(
        elapsedMs: elapsedMs,
        value: 1200 + 300 * math.cos(phase),
      ),
    );
    elapsedMs += samplePeriodMs;
    phase += phaseStep;
  }
  return samples;
}
