import 'dart:math' as math;

import 'fisher_lehrer_models.dart';
import 'fisher_lehrer_protocol.dart';
import 'reference_lowess.dart';

                                                                   
Map<String, Object?> analyzeFisherLehrerAssessment(
  Map<String, Object?> serializedInput,
) {
  final input = RfAssessmentInput.fromJson(serializedInput);
  return const FisherLehrerRfAnalyzer().analyze(input).toJson();
}

                                                                 
class FisherLehrerRfAnalyzer {
  static const double _breathFilterGain = 1.000312225;
  static const double _breathFilterFeedback = 0.9993757454;
  static const double _displayScale = 150;
  static const double _displayScaleFraction = 0.98;
  static const int _maximumFitPasses = 100;

  const FisherLehrerRfAnalyzer();

  RfAssessmentResult analyze(RfAssessmentInput input) {
    final protocol = input.protocol;
    final flags = <RfQualityFlag>[];
    final protocolCompleted = input.completedCycles == protocol.cycleCount;
    if (!protocolCompleted) {
      flags.add(RfQualityFlag.protocolIncomplete);
    }

    final validRr = <RfBeatSample>[];
    var rejectedRr = false;
    for (final sample in input.rrSamples) {
      if (!sample.elapsedMs.isFinite ||
          !sample.rrMs.isFinite ||
          sample.elapsedMs < 0 ||
          sample.rrMs <= 0) {
        rejectedRr = true;
      } else {
        validRr.add(sample);
      }
    }
    validRr.sort((a, b) => a.elapsedMs.compareTo(b.elapsedMs));
    if (rejectedRr) flags.add(RfQualityFlag.invalidRr);
    if (validRr.length < protocol.ibiLowessPoints) {
      flags.add(RfQualityFlag.insufficientRr);
      return _invalidResult(
        input: input,
        flags: flags,
        protocolCompleted: protocolCompleted,
        trace: RfAnalysisTrace(
          originalRr:
              validRr
                  .map((sample) => RfTimedValue(sample.elapsedMs, sample.rrMs))
                  .toList(),
        ),
      );
    }

    final correction = correctEctopicBeats(
      validRr,
      referenceSampleRateHz: protocol.referenceSampleRateHz,
    );
    final correctedRr = correction.correctedSamples;
    final rrTimes = correctedRr.map((sample) => sample.elapsedMs).toList();
    final rrValues = correctedRr.map((sample) => sample.rrMs).toList();
    final baseline = fisherLehrerLowess(
      rrTimes,
      rrValues,
      protocol.ibiLowessPoints,
    );
    final detrended = List<double>.generate(
      rrValues.length,
      (index) => baseline[index] - rrValues[index],
      growable: false,
    );
    final extrema = findAlternatingExtrema(rrTimes, detrended);
    final excursions = <RfTimedValue>[];
    for (var index = 0; index + 1 < extrema.length; index++) {
      excursions.add(
        RfTimedValue(
          extrema[index].elapsedMs,
          (extrema[index].value - extrema[index + 1].value).abs(),
        ),
      );
    }

    final baseTrace = RfAnalysisTrace(
      originalRr:
          validRr
              .map((sample) => RfTimedValue(sample.elapsedMs, sample.rrMs))
              .toList(),
      correctedRr:
          correctedRr
              .map((sample) => RfTimedValue(sample.elapsedMs, sample.rrMs))
              .toList(),
      ibiBaseline: List<RfTimedValue>.generate(
        baseline.length,
        (index) => RfTimedValue(rrTimes[index], baseline[index]),
      ),
      detrendedIbi: List<RfTimedValue>.generate(
        detrended.length,
        (index) => RfTimedValue(rrTimes[index], detrended[index]),
      ),
      extrema: extrema,
      peakToTrough: excursions,
      ectopicCorrections: correction.corrections,
    );

    if (excursions.length < protocol.excursionLowessPoints) {
      flags.add(RfQualityFlag.insufficientExtrema);
      return _invalidResult(
        input: input,
        flags: flags,
        protocolCompleted: protocolCompleted,
        trace: baseTrace,
        ectopicCorrectionCount: correction.corrections.length,
      );
    }

    final excursionTimes = excursions
        .map((point) => point.elapsedMs)
        .toList(growable: false);
    final excursionValues = excursions
        .map((point) => point.value)
        .toList(growable: false);
    final smoothedExcursions = fisherLehrerLowess(
      excursionTimes,
      excursionValues,
      protocol.excursionLowessPoints,
    );
    var maximumIndex = 0;
    for (var index = 1; index < smoothedExcursions.length; index++) {
      if (smoothedExcursions[index] > smoothedExcursions[maximumIndex]) {
        maximumIndex = index;
      }
    }

    final centerMs = excursionTimes[maximumIndex];
    final peakAmplitude = smoothedExcursions[maximumIndex];
    final scheduledBpm = protocol.cycleAtElapsedMs(centerMs).scheduledBpm;
    final halfWindowMs = protocol.analysisWindowSeconds * 500;
    final windowStartMs = centerMs - halfWindowMs;
    final windowEndMs = centerMs + halfWindowMs;
    final fullWindow =
        windowStartMs >= 0 && windowEndMs <= protocol.scheduledDurationMs;
    if (!fullWindow) flags.add(RfQualityFlag.analysisWindowUnavailable);

    final maximumRrGapMs = _maximumGap(
      correctedRr
          .where(
            (sample) =>
                sample.elapsedMs >= windowStartMs &&
                sample.elapsedMs <= windowEndMs,
          )
          .map((sample) => sample.elapsedMs)
          .toList(),
    );
    final rrContinuityPassed = maximumRrGapMs <= protocol.maximumRrGapMs;
    if (!rrContinuityPassed) flags.add(RfQualityFlag.rrGap);

    final smoothedTrace = List<RfTimedValue>.generate(
      smoothedExcursions.length,
      (index) => RfTimedValue(excursionTimes[index], smoothedExcursions[index]),
    );

    if (input.mode == RfAcquisitionMode.estimated) {
      final trace = RfAnalysisTrace(
        originalRr: baseTrace.originalRr,
        correctedRr: baseTrace.correctedRr,
        ibiBaseline: baseTrace.ibiBaseline,
        detrendedIbi: baseTrace.detrendedIbi,
        extrema: baseTrace.extrema,
        peakToTrough: baseTrace.peakToTrough,
        smoothedPeakToTrough: smoothedTrace,
        ectopicCorrections: baseTrace.ectopicCorrections,
      );
      final quality = RfQualityReport(
        protocolCompleted: protocolCompleted,
        fullAnalysisWindowAvailable: fullWindow,
        rrContinuityPassed: rrContinuityPassed,
        beltCoveragePassed: false,
        respirationFitConverged: false,
        breathingAdherencePassed: false,
        beltCoverage: 0,
        maximumObservedBeltGapMs: 0,
        maximumObservedRrGapMs: maximumRrGapMs,
        ectopicCorrections: correction.corrections.length,
        flags: List.unmodifiable(flags),
      );
      return RfAssessmentResult(
        protocolVersion: protocol.protocolVersion,
        mode: input.mode,
        status:
            flags.isEmpty ? RfResultStatus.completed : RfResultStatus.invalid,
        rfBpm: flags.isEmpty ? scheduledBpm : null,
        rfCenterElapsedMs: centerMs,
        peakToTroughAmplitude: peakAmplitude,
        scheduledBpmAtCenter: scheduledBpm,
        fittedRespirationBpm: null,
        adherenceDeltaBpm: null,
        respirationFitError: null,
        quality: quality,
        trace: trace,
      );
    }

    final respiration = _analyzeRespiration(
      samples: input.respirationSamples,
      protocol: protocol,
      centerMs: centerMs,
      windowStartMs: windowStartMs,
      windowEndMs: windowEndMs,
    );
    flags.addAll(respiration.flags);
    final fit = respiration.fit;
    final fittedBpm = fit?.bpm;
    final adherenceDelta =
        fittedBpm == null ? null : (fittedBpm - scheduledBpm).abs();
    final adherencePassed =
        adherenceDelta != null &&
        adherenceDelta <= protocol.maximumAdherenceDeltaBpm;
    if (fit != null && fit.converged && fittedBpm != null && !adherencePassed) {
      flags.add(RfQualityFlag.nonAdherent);
    }

    final trace = RfAnalysisTrace(
      originalRr: baseTrace.originalRr,
      correctedRr: baseTrace.correctedRr,
      ibiBaseline: baseTrace.ibiBaseline,
      detrendedIbi: baseTrace.detrendedIbi,
      extrema: baseTrace.extrema,
      peakToTrough: baseTrace.peakToTrough,
      smoothedPeakToTrough: smoothedTrace,
      respirationWindow: respiration.window,
      fittedRespiration: fit?.fittedWave ?? const [],
      ectopicCorrections: baseTrace.ectopicCorrections,
    );
    final quality = RfQualityReport(
      protocolCompleted: protocolCompleted,
      fullAnalysisWindowAvailable: fullWindow && respiration.fullWindow,
      rrContinuityPassed: rrContinuityPassed,
      beltCoveragePassed: respiration.coveragePassed,
      respirationFitConverged: fit?.converged ?? false,
      breathingAdherencePassed: adherencePassed,
      beltCoverage: respiration.coverage,
      maximumObservedBeltGapMs: respiration.maximumGapMs,
      maximumObservedRrGapMs: maximumRrGapMs,
      ectopicCorrections: correction.corrections.length,
      flags: List.unmodifiable(flags.toSet()),
    );

    return RfAssessmentResult(
      protocolVersion: protocol.protocolVersion,
      mode: input.mode,
      status: flags.isEmpty ? RfResultStatus.completed : RfResultStatus.invalid,
      rfBpm: flags.isEmpty ? fittedBpm : null,
      rfCenterElapsedMs: centerMs,
      peakToTroughAmplitude: peakAmplitude,
      scheduledBpmAtCenter: scheduledBpm,
      fittedRespirationBpm: fittedBpm,
      adherenceDeltaBpm: adherenceDelta,
      respirationFitError: fit?.meanAbsoluteError,
      quality: quality,
      trace: trace,
    );
  }

  ({List<RfBeatSample> correctedSamples, List<RfEctopicCorrection> corrections})
  correctEctopicBeats(
    List<RfBeatSample> samples, {
    double referenceSampleRateHz = 256,
  }) {
    if (samples.isEmpty) {
      return (correctedSamples: const [], corrections: const []);
    }

    final ordered = List<RfBeatSample>.from(samples)
      ..sort((a, b) => a.elapsedMs.compareTo(b.elapsedMs));
    final samplesPerMs = referenceSampleRateHz / 1000;
    final intervalSamples =
        ordered.map((sample) => (sample.rrMs * samplesPerMs).round()).toList();
    final correctedIntervalMs = ordered
        .map((sample) => sample.rrMs)
        .toList(growable: false);
    final corrections = <RfEctopicCorrection>[];

    var changed = true;
    while (changed) {
      changed = false;
      for (var index = 3; index < intervalSamples.length; index++) {
        final delta1 = intervalSamples[index - 2] - intervalSamples[index - 3];
        final delta2 = intervalSamples[index - 1] - intervalSamples[index - 2];
        final delta3 = intervalSamples[index] - intervalSamples[index - 1];
        if (delta1 < 0 &&
            delta2 > 0 &&
            delta3 < 0 &&
            (delta2 + delta1 + delta3).abs() < delta2 * 0.1) {
          final firstIndex = index - 2;
          final secondIndex = index - 1;
          final originalFirstMs = ordered[firstIndex].rrMs;
          final originalSecondMs = ordered[secondIndex].rrMs;
          final totalSamples =
              intervalSamples[firstIndex] + intervalSamples[secondIndex];
          final correctedFirstSamples = totalSamples ~/ 2;
          final correctedSecondSamples = totalSamples - correctedFirstSamples;
          intervalSamples[firstIndex] = correctedFirstSamples;
          intervalSamples[secondIndex] = correctedSecondSamples;
          correctedIntervalMs[firstIndex] =
              correctedFirstSamples / samplesPerMs;
          correctedIntervalMs[secondIndex] =
              correctedSecondSamples / samplesPerMs;
          corrections.add(
            RfEctopicCorrection(
              firstIntervalIndex: firstIndex,
              secondIntervalIndex: secondIndex,
              originalFirstMs: originalFirstMs,
              originalSecondMs: originalSecondMs,
              correctedFirstMs: correctedFirstSamples / samplesPerMs,
              correctedSecondMs: correctedSecondSamples / samplesPerMs,
            ),
          );
          changed = true;
          break;
        }
      }
    }

    final firstEndMs = ordered.first.elapsedMs;
    var elapsedMs = firstEndMs - correctedIntervalMs.first;
    final corrected = <RfBeatSample>[];
    for (var index = 0; index < correctedIntervalMs.length; index++) {
      final rrMs = correctedIntervalMs[index];
      elapsedMs += rrMs;
      corrected.add(
        RfBeatSample(
          elapsedMs: elapsedMs,
          rrMs: rrMs,
          notificationElapsedMs: ordered[index].notificationElapsedMs,
        ),
      );
    }
    return (
      correctedSamples: List.unmodifiable(corrected),
      corrections: List.unmodifiable(corrections),
    );
  }

  List<RfExtremum> findAlternatingExtrema(
    List<double> elapsedMs,
    List<double> values,
  ) {
    if (elapsedMs.length != values.length) {
      throw ArgumentError('elapsedMs and values must have the same length');
    }
    final peaks = <RfExtremum>[];
    var currentIndex = 0;
    while (currentIndex < values.length) {
      var localMaximum = -double.infinity;
      var maximumTime = 0.0;
      var crossedNegative = false;
      while (currentIndex < values.length) {
        final current = values[currentIndex];
        if (current > localMaximum) {
          localMaximum = current;
          maximumTime = elapsedMs[currentIndex];
        }
        currentIndex++;
        if (current < 0) {
          crossedNegative = true;
          break;
        }
      }
      if (!crossedNegative || currentIndex >= values.length) break;
      peaks.add(
        RfExtremum(
          elapsedMs: maximumTime,
          value: localMaximum,
          kind: RfExtremumKind.maximum,
        ),
      );

      var localMinimum = double.infinity;
      var minimumTime = 0.0;
      var crossedPositive = false;
      while (currentIndex < values.length) {
        final current = values[currentIndex];
        if (current < localMinimum) {
          localMinimum = current;
          minimumTime = elapsedMs[currentIndex];
        }
        currentIndex++;
        if (current > 0) {
          crossedPositive = true;
          break;
        }
      }
      if (!crossedPositive || currentIndex >= values.length) break;
      peaks.add(
        RfExtremum(
          elapsedMs: minimumTime,
          value: localMinimum,
          kind: RfExtremumKind.minimum,
        ),
      );
    }
    return List.unmodifiable(peaks);
  }

  RfSineFit fitRespirationWindow(
    List<RfTimedValue> window, {
    double sampleRateHz = 256,
  }) {
    if (window.length < 3) {
      return const RfSineFit(
        bpm: 0,
        phase: 0,
        omegaRadiansPerSample: 0,
        amplitude: 0,
        offset: 0,
        meanAbsoluteError: double.infinity,
        converged: false,
        fittedWave: [],
      );
    }
    final values = window.map((point) => point.value).toList(growable: false);
    final maximum = values.reduce(math.max);
    final minimum = values.reduce(math.min);
    var amplitude = (maximum - minimum) / 2;
    var offset = (maximum + minimum) / 2;
    if (amplitude == 0 || !amplitude.isFinite || !offset.isFinite) {
      return const RfSineFit(
        bpm: 0,
        phase: 0,
        omegaRadiansPerSample: 0,
        amplitude: 0,
        offset: 0,
        meanAbsoluteError: double.infinity,
        converged: false,
        fittedWave: [],
      );
    }

    var minimumError = double.infinity;
    var phase = 0.0;
    var omega = 0.0;
    for (var halfBpm = 7; halfBpm <= 14; halfBpm++) {
      final bpm = halfBpm / 2;
      final candidateOmega = 2 * math.pi / 60 * bpm / sampleRateHz;
      for (var phaseIndex = 0; phaseIndex <= 1; phaseIndex++) {
        final candidatePhase = math.pi * phaseIndex;
        final error = _absoluteSineError(
          values,
          candidatePhase,
          candidateOmega,
          amplitude,
          offset,
        );
        if (error < minimumError) {
          minimumError = error;
          phase = candidatePhase;
          omega = candidateOmega;
        }
      }
    }

    var converged = false;
    for (var pass = 0; pass < _maximumFitPasses; pass++) {
      var corrections = 0;
      var lastError = _absoluteSineError(
        values,
        phase,
        omega,
        amplitude,
        offset,
      );

      var phaseStep = math.pi / 100;
      if (lastError <
          _absoluteSineError(
            values,
            phase + phaseStep,
            omega,
            amplitude,
            offset,
          )) {
        phaseStep = -phaseStep;
      }
      for (var index = 0; index < 200; index++) {
        phase += phaseStep;
        final error = _absoluteSineError(
          values,
          phase,
          omega,
          amplitude,
          offset,
        );
        if (lastError < error) break;
        lastError = error;
        corrections++;
      }
      phase -= phaseStep;

      lastError = _absoluteSineError(values, phase, omega, amplitude, offset);
      var omegaScale = 1.001;
      if (lastError <
          _absoluteSineError(
            values,
            phase,
            omega * omegaScale,
            amplitude,
            offset,
          )) {
        omegaScale = 1 / omegaScale;
      }
      for (var index = 0; index < 400; index++) {
        omega *= omegaScale;
        final error = _absoluteSineError(
          values,
          phase,
          omega,
          amplitude,
          offset,
        );
        if (lastError < error) break;
        lastError = error;
        corrections++;
      }
      omega /= omegaScale;

      lastError = _absoluteSineError(values, phase, omega, amplitude, offset);
      var offsetStep = 1.0;
      if (lastError <
          _absoluteSineError(
            values,
            phase,
            omega,
            amplitude,
            offset + offsetStep,
          )) {
        offsetStep = -offsetStep;
      }
      for (var index = 0; index < 200; index++) {
        offset += offsetStep;
        final error = _absoluteSineError(
          values,
          phase,
          omega,
          amplitude,
          offset,
        );
        if (lastError < error) break;
        lastError = error;
        corrections++;
      }
      offset -= offsetStep;

      lastError = _absoluteSineError(values, phase, omega, amplitude, offset);
      var amplitudeScale = 1.005;
                                                                          
      if (lastError <
          _absoluteSineError(
            values,
            phase,
            omega,
            amplitude * amplitudeScale,
            offset + offsetStep,
          )) {
        amplitudeScale = 1 / amplitudeScale;
      }
      for (var index = 0; index < 999; index++) {
        amplitude *= amplitudeScale;
        final error = _absoluteSineError(
          values,
          phase,
          omega,
          amplitude,
          offset,
        );
        if (lastError < error) break;
        lastError = error;
        corrections++;
      }
      amplitude /= amplitudeScale;

      if (corrections == 0) {
        converged = true;
        break;
      }
    }

    final fitted = <RfTimedValue>[];
    var fittedPhase = phase;
    for (final point in window) {
      fitted.add(
        RfTimedValue(
          point.elapsedMs,
          amplitude * math.cos(fittedPhase) + offset,
        ),
      );
      fittedPhase += omega;
    }
    final error =
        _absoluteSineError(values, phase, omega, amplitude, offset) /
        values.length;
    return RfSineFit(
      bpm: omega / (2 * math.pi) * 60 * sampleRateHz,
      phase: phase,
      omegaRadiansPerSample: omega,
      amplitude: amplitude,
      offset: offset,
      meanAbsoluteError: error,
      converged: converged,
      fittedWave: List.unmodifiable(fitted),
    );
  }

  RfAssessmentResult _invalidResult({
    required RfAssessmentInput input,
    required List<RfQualityFlag> flags,
    required bool protocolCompleted,
    required RfAnalysisTrace trace,
    int ectopicCorrectionCount = 0,
  }) {
    return RfAssessmentResult(
      protocolVersion: input.protocol.protocolVersion,
      mode: input.mode,
      status: RfResultStatus.invalid,
      rfBpm: null,
      rfCenterElapsedMs: null,
      peakToTroughAmplitude: null,
      scheduledBpmAtCenter: null,
      fittedRespirationBpm: null,
      adherenceDeltaBpm: null,
      respirationFitError: null,
      quality: RfQualityReport(
        protocolCompleted: protocolCompleted,
        fullAnalysisWindowAvailable: false,
        rrContinuityPassed: false,
        beltCoveragePassed: false,
        respirationFitConverged: false,
        breathingAdherencePassed: false,
        beltCoverage: 0,
        maximumObservedBeltGapMs: 0,
        maximumObservedRrGapMs: 0,
        ectopicCorrections: ectopicCorrectionCount,
        flags: List.unmodifiable(flags.toSet()),
      ),
      trace: trace,
    );
  }

  _RespirationAnalysis _analyzeRespiration({
    required List<RfRespirationSample> samples,
    required FisherLehrerProtocolConfig protocol,
    required double centerMs,
    required double windowStartMs,
    required double windowEndMs,
  }) {
    final flags = <RfQualityFlag>[];
    final valid =
        samples
            .where(
              (sample) =>
                  sample.sensorNumber == 1 &&
                  sample.elapsedMs.isFinite &&
                  sample.value.isFinite,
            )
            .toList()
          ..sort((a, b) => a.elapsedMs.compareTo(b.elapsedMs));
    if (valid.isEmpty) {
      return const _RespirationAnalysis(
        flags: [RfQualityFlag.respirationMissing],
      );
    }

    final inWindow =
        valid
            .where(
              (sample) =>
                  sample.elapsedMs >= windowStartMs &&
                  sample.elapsedMs <= windowEndMs,
            )
            .toList();
    final expectedCount =
        protocol.analysisWindowSeconds * protocol.respirationSampleRateHz;
    final coverage = math.min(1.0, inWindow.length / expectedCount);
    final coveragePassed = coverage >= protocol.minimumBeltCoverage;
    if (!coveragePassed) flags.add(RfQualityFlag.respirationCoverageLow);

    final maximumGapMs = _maximumGap(
      inWindow.map((sample) => sample.elapsedMs).toList(),
    );
    if (maximumGapMs > protocol.maximumBeltGapMs) {
      flags.add(RfQualityFlag.respirationGap);
    }

    final hasStartBracket =
        valid.first.elapsedMs <= windowStartMs &&
        valid.any((sample) => sample.elapsedMs >= windowStartMs);
    final hasEndBracket =
        valid.last.elapsedMs >= windowEndMs &&
        valid.any((sample) => sample.elapsedMs <= windowEndMs);
    final fullWindow = windowStartMs >= 0 && hasStartBracket && hasEndBracket;
    if (!fullWindow) flags.add(RfQualityFlag.analysisWindowUnavailable);
    if (flags.isNotEmpty) {
      return _RespirationAnalysis(
        coverage: coverage,
        maximumGapMs: maximumGapMs,
        coveragePassed: coveragePassed,
        fullWindow: fullWindow,
        flags: flags,
      );
    }

    final resampled = _linearResample(
      valid,
      sampleRateHz: protocol.referenceSampleRateHz,
    );
    final filtered = _filterAndScaleRespiration(resampled);
    if (filtered == null) {
      flags.add(RfQualityFlag.respirationFlat);
      return _RespirationAnalysis(
        coverage: coverage,
        maximumGapMs: maximumGapMs,
        coveragePassed: coveragePassed,
        fullWindow: fullWindow,
        flags: flags,
      );
    }

    final window =
        filtered
            .where(
              (point) =>
                  point.elapsedMs >= windowStartMs &&
                  point.elapsedMs <= windowEndMs,
            )
            .toList();
    if (window.length < protocol.analysisWindowSeconds * 250) {
      flags.add(RfQualityFlag.analysisWindowUnavailable);
      return _RespirationAnalysis(
        coverage: coverage,
        maximumGapMs: maximumGapMs,
        coveragePassed: coveragePassed,
        fullWindow: false,
        window: window,
        flags: flags,
      );
    }

    final fit = fitRespirationWindow(
      window,
      sampleRateHz: protocol.referenceSampleRateHz,
    );
    if (!fit.converged) flags.add(RfQualityFlag.respirationFitFailed);
    if (fit.bpm < protocol.targetEndBpm || fit.bpm > protocol.startBpm) {
      flags.add(RfQualityFlag.respirationOutOfRange);
    }
    return _RespirationAnalysis(
      coverage: coverage,
      maximumGapMs: maximumGapMs,
      coveragePassed: coveragePassed,
      fullWindow: fullWindow,
      fit: fit,
      window: List.unmodifiable(window),
      flags: flags,
    );
  }

  List<RfTimedValue> _linearResample(
    List<RfRespirationSample> samples, {
    required double sampleRateHz,
  }) {
    final stepMs = 1000 / sampleRateHz;
    final firstMs = samples.first.elapsedMs;
    final lastMs = samples.last.elapsedMs;
    final count = ((lastMs - firstMs) / stepMs).floor() + 1;
    final output = <RfTimedValue>[];
    var sourceIndex = 0;
    for (var index = 0; index < count; index++) {
      final elapsedMs = firstMs + index * stepMs;
      while (sourceIndex + 1 < samples.length &&
          samples[sourceIndex + 1].elapsedMs < elapsedMs) {
        sourceIndex++;
      }
      final left = samples[sourceIndex];
      if (sourceIndex + 1 >= samples.length) {
        output.add(RfTimedValue(elapsedMs, left.value));
        continue;
      }
      final right = samples[sourceIndex + 1];
      final span = right.elapsedMs - left.elapsedMs;
      final fraction = span <= 0 ? 0.0 : (elapsedMs - left.elapsedMs) / span;
      output.add(
        RfTimedValue(
          elapsedMs,
          left.value + (right.value - left.value) * fraction,
        ),
      );
    }
    return output;
  }

  List<RfTimedValue>? _filterAndScaleRespiration(List<RfTimedValue> samples) {
    if (samples.isEmpty) return null;
    var previousInput = samples.first.value;
    var previousOutput = 0.0;
    final filtered = <RfTimedValue>[];
    for (final sample in samples) {
      final currentInput = sample.value / _breathFilterGain;
      final currentOutput =
          currentInput - previousInput + _breathFilterFeedback * previousOutput;
      filtered.add(RfTimedValue(sample.elapsedMs, currentOutput));
      previousInput = currentInput;
      previousOutput = currentOutput;
    }

    var maximum = filtered.map((point) => point.value).reduce(math.max);
    final minimum = filtered.map((point) => point.value).reduce(math.min);
    if (maximum < -minimum) maximum = -minimum;
    if (!maximum.isFinite || maximum.abs() < 1e-12) return null;
    final scale = _displayScale / maximum * _displayScaleFraction;
    return filtered
        .map((point) => RfTimedValue(point.elapsedMs, point.value * scale))
        .toList(growable: false);
  }

  double _absoluteSineError(
    List<double> values,
    double phase,
    double omega,
    double amplitude,
    double offset,
  ) {
    var error = 0.0;
    var runningPhase = phase;
    for (final value in values) {
      error += (amplitude * math.cos(runningPhase) + offset - value).abs();
      runningPhase += omega;
    }
    return error;
  }

  double _maximumGap(List<double> elapsedMs) {
    if (elapsedMs.length < 2) return 0;
    elapsedMs.sort();
    var maximumGap = 0.0;
    for (var index = 1; index < elapsedMs.length; index++) {
      maximumGap = math.max(
        maximumGap,
        elapsedMs[index] - elapsedMs[index - 1],
      );
    }
    return maximumGap;
  }
}

class _RespirationAnalysis {
  final double coverage;
  final double maximumGapMs;
  final bool coveragePassed;
  final bool fullWindow;
  final RfSineFit? fit;
  final List<RfTimedValue> window;
  final List<RfQualityFlag> flags;

  const _RespirationAnalysis({
    this.coverage = 0,
    this.maximumGapMs = 0,
    this.coveragePassed = false,
    this.fullWindow = false,
    this.fit,
    this.window = const [],
    this.flags = const [],
  });
}
