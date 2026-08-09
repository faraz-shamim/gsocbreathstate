import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/fisher_lehrer_reference_vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  const analyzer = FisherLehrerRfAnalyzer();

  test('LOWESS reproduces the locked linear conformance vector', () {
    final vector = fixture['lowessLinear'] as Map<String, dynamic>;
    final actual = fisherLehrerLowess(
      (vector['x'] as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList(),
      (vector['y'] as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList(),
      vector['neighborhoodPoints'] as int,
    );
    final expected =
        (vector['expected'] as List)
            .cast<num>()
            .map((value) => value.toDouble())
            .toList();

    for (var index = 0; index < expected.length; index++) {
      expect(actual[index], closeTo(expected[index], 1e-9));
    }
  });

  test('LOWESS preserves the archived endpoint trimming behavior', () {
    final vector = fixture['lowessEndpointTrim'] as Map<String, dynamic>;
    final actual = fisherLehrerLowess(
      (vector['x'] as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList(),
      (vector['y'] as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList(),
      vector['neighborhoodPoints'] as int,
    );
    final expected =
        (vector['expected'] as List)
            .cast<num>()
            .map((value) => value.toDouble())
            .toList();

    for (var index = 0; index < expected.length; index++) {
      expect(actual[index], closeTo(expected[index], 1e-12));
    }
  });

  test('corrects the exact negative-positive-negative reference pattern', () {
    final vector = fixture['ectopicCorrection'] as Map<String, dynamic>;
    final intervals =
        (vector['inputIntervalMs'] as List)
            .cast<num>()
            .map((value) => value.toDouble())
            .toList();
    var elapsedMs = 0.0;
    final samples = <RfBeatSample>[];
    for (final interval in intervals) {
      elapsedMs += interval;
      samples.add(RfBeatSample(elapsedMs: elapsedMs, rrMs: interval));
    }

    final result = analyzer.correctEctopicBeats(samples);
    final expected =
        (vector['correctedIntervalMs'] as List)
            .cast<num>()
            .map((value) => value.toDouble())
            .toList();

    expect(result.corrections, hasLength(1));
    expect(result.corrections.single.firstIntervalIndex, 1);
    expect(result.corrections.single.secondIntervalIndex, 2);
    for (var index = 0; index < expected.length; index++) {
      expect(
        result.correctedSamples[index].rrMs,
        closeTo(expected[index], 1e-9),
      );
    }
  });

  test('leaves a near-miss ectopic pattern unchanged', () {
    final intervals = [1000.0, 500.0, 1500.0, 1100.0];
    var elapsedMs = 0.0;
    final samples =
        intervals.map((interval) {
          elapsedMs += interval;
          return RfBeatSample(elapsedMs: elapsedMs, rrMs: interval);
        }).toList();

    final result = analyzer.correctEctopicBeats(samples);

    expect(result.corrections, isEmpty);
    expect(
      result.correctedSamples.map((sample) => sample.rrMs),
      orderedEquals(intervals),
    );
  });

  test('finds alternating extrema using reference zero crossings', () {
    final vector = fixture['extrema'] as Map<String, dynamic>;
    final extrema = analyzer.findAlternatingExtrema(
      (vector['elapsedMs'] as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList(),
      (vector['values'] as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList(),
    );
    final expectedTimes =
        (vector['expectedTimesMs'] as List).cast<num>().toList();
    final expectedValues =
        (vector['expectedValues'] as List).cast<num>().toList();

    expect(extrema, hasLength(expectedTimes.length));
    for (var index = 0; index < extrema.length; index++) {
      expect(extrema[index].elapsedMs, expectedTimes[index]);
      expect(extrema[index].value, expectedValues[index]);
      expect(
        extrema[index].kind,
        index.isEven ? RfExtremumKind.maximum : RfExtremumKind.minimum,
      );
    }
  });

  test('recovers a noiseless reference-grid respiration frequency', () {
    const sampleRateHz = 256.0;
    const bpm = 5.5;
    const durationSeconds = 60;
    final omega = 2 * math.pi * bpm / 60 / sampleRateHz;
    final window = List<RfTimedValue>.generate(
      durationSeconds * sampleRateHz.toInt() + 1,
      (index) => RfTimedValue(
        index * 1000 / sampleRateHz,
        92 * math.cos(0.37 + omega * index) - 4,
      ),
    );

    final fit = analyzer.fitRespirationWindow(
      window,
      sampleRateHz: sampleRateHz,
    );

    expect(fit.converged, isTrue);
    expect(fit.bpm, closeTo(bpm, 0.02));
    expect(fit.meanAbsoluteError, lessThan(1.0));
  });
}
