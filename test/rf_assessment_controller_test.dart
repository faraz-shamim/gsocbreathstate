import 'dart:async';

import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RfAssessmentController preflight', () {
    test(
      'selects measured mode when Polar and moving belt are ready',
      () async {
        final polar = _FakePolarSource();
        final belt = _FakeRespirationSource();
        final controller = _controller(polar: polar, belt: belt);
        addTearDown(controller.dispose);

        await _completePreflight(controller, polar, belt: belt);

        expect(
          controller.snapshot.state,
          RfAssessmentControllerState.readyMeasured,
        );
        expect(controller.snapshot.mode, RfAcquisitionMode.measured);
        expect(controller.snapshot.polarReady, isTrue);
        expect(controller.snapshot.beltSignalDetected, isTrue);
        expect(controller.snapshot.rrCount, 1);
        expect(controller.snapshot.respirationCount, 5);
      },
    );

    test('falls back to an explicitly estimated mode without a belt', () async {
      final polar = _FakePolarSource();
      final controller = _controller(polar: polar);
      addTearDown(controller.dispose);

      await _completePreflight(controller, polar);

      expect(
        controller.snapshot.state,
        RfAssessmentControllerState.readyEstimated,
      );
      expect(controller.snapshot.mode, RfAcquisitionMode.estimated);
      expect(controller.snapshot.beltSignalDetected, isFalse);
    });

    test('reinitialization cancels the old RR subscription', () async {
      final polar = _FakePolarSource();
      final controller = _controller(polar: polar);
      addTearDown(controller.dispose);

      await _completePreflight(controller, polar);
      await _completePreflight(controller, polar);
      polar.addBatch(const [900]);
      await Future<void>.delayed(Duration.zero);

      expect(polar.startCount, 2);
      expect(controller.snapshot.rrCount, 1);
      expect(polar.batchController.hasListener, isTrue);
    });
  });

  group('RfAssessmentController acquisition', () {
    test(
      'timestamps RR batches on one continuous monotonic timeline',
      () async {
        final polar = _FakePolarSource();
        final clock = _FakeClock();
        final controller = _controller(polar: polar, clock: clock);
        addTearDown(controller.dispose);
        await _completePreflight(controller, polar);
        await controller.startAssessment();

        clock.elapsedMicrosecondsValue = 50000;
        polar.addBatch(const [10, 20]);
        await Future<void>.delayed(Duration.zero);
        clock.elapsedMicrosecondsValue = 75000;
        polar.addBatch(const [25]);
        await Future<void>.delayed(Duration.zero);

        expect(controller.rrSamples, hasLength(3));
        expect(
          controller.rrSamples.map((sample) => sample.elapsedMs),
          orderedEquals(const [30.0, 50.0, 75.0]),
        );
        expect(
          controller.rrSamples.map((sample) => sample.notificationElapsedMs),
          orderedEquals(const [50.0, 50.0, 75.0]),
        );
      },
    );

    test(
      'completes on the schedule boundary and invokes analysis once',
      () async {
        const shortProtocol = FisherLehrerProtocolConfig(
          cycleCount: 1,
          startBpm: 600,
          targetEndBpm: 600,
        );
        final polar = _FakePolarSource();
        final clock = _FakeClock();
        RfAssessmentInput? analyzedInput;
        var analysisCount = 0;
        final controller = _controller(
          polar: polar,
          clock: clock,
          protocol: shortProtocol,
          analysisRunner: (input) async {
            analysisCount++;
            analyzedInput = input;
            return _completedResult(input);
          },
        );
        addTearDown(controller.dispose);
        await _completePreflight(controller, polar);
        await controller.startAssessment();

        clock.elapsedMicrosecondsValue = 50000;
        polar.addBatch(const [20, 30]);
        await Future<void>.delayed(Duration.zero);
        clock.elapsedMicrosecondsValue = 100000;
        controller.tick();
        await _waitForState(controller, RfAssessmentControllerState.completed);
        controller.tick();

        expect(analysisCount, 1);
        expect(analyzedInput, isNotNull);
        expect(analyzedInput!.completedCycles, 1);
        expect(analyzedInput!.rrSamples, hasLength(2));
        expect(controller.snapshot.remainingMs, 0);
        expect(polar.stopCount, greaterThanOrEqualTo(2));
      },
    );

    test('aborts immediately when Polar disconnects', () async {
      final polar = _FakePolarSource();
      final controller = _controller(polar: polar);
      addTearDown(controller.dispose);
      await _completePreflight(controller, polar);
      await controller.startAssessment();

      polar.setConnected(false);
      await _waitForState(controller, RfAssessmentControllerState.aborted);

      expect(controller.snapshot.abortReason, RfAbortReason.polarDisconnected);
      expect(controller.clock.isRunning, isFalse);
    });

    test('aborts measured mode when the belt disconnects', () async {
      final polar = _FakePolarSource();
      final belt = _FakeRespirationSource();
      final controller = _controller(polar: polar, belt: belt);
      addTearDown(controller.dispose);
      await _completePreflight(controller, polar, belt: belt);
      await controller.startAssessment();

      belt.setConnected(false);
      await _waitForState(controller, RfAssessmentControllerState.aborted);

      expect(controller.snapshot.abortReason, RfAbortReason.beltDisconnected);
    });

    test(
      'downgrades to estimated if the belt disconnects before start',
      () async {
        final polar = _FakePolarSource();
        final belt = _FakeRespirationSource();
        final controller = _controller(polar: polar, belt: belt);
        addTearDown(controller.dispose);
        await _completePreflight(controller, polar, belt: belt);

        belt.setConnected(false);
        await _waitForState(
          controller,
          RfAssessmentControllerState.readyEstimated,
        );

        expect(controller.snapshot.mode, RfAcquisitionMode.estimated);
        expect(controller.snapshot.beltSignalDetected, isFalse);
      },
    );

    test('aborts when pacing ticks have a timing discontinuity', () async {
      const protocol = FisherLehrerProtocolConfig(
        cycleCount: 1,
        startBpm: 10,
        targetEndBpm: 10,
      );
      final polar = _FakePolarSource();
      final clock = _FakeClock();
      final controller = _controller(
        polar: polar,
        clock: clock,
        protocol: protocol,
      );
      addTearDown(controller.dispose);
      await _completePreflight(controller, polar);
      await controller.startAssessment();

      clock.elapsedMicrosecondsValue = 100000;
      controller.tick();
      clock.elapsedMicrosecondsValue = 2300000;
      controller.tick();
      await _waitForState(controller, RfAssessmentControllerState.aborted);

      expect(
        controller.snapshot.abortReason,
        RfAbortReason.pacerTimingDiscontinuity,
      );
    });

    test('lifecycle observer converts backgrounding into an abort', () async {
      final polar = _FakePolarSource();
      final controller = _controller(polar: polar);
      final observer = RfAssessmentLifecycleObserver(controller);
      addTearDown(observer.dispose);
      addTearDown(controller.dispose);
      await _completePreflight(controller, polar);
      await controller.startAssessment();

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await _waitForState(controller, RfAssessmentControllerState.aborted);

      expect(controller.snapshot.abortReason, RfAbortReason.appBackgrounded);
    });
  });
}

RfAssessmentController _controller({
  required _FakePolarSource polar,
  _FakeRespirationSource? belt,
  _FakeClock? clock,
  FisherLehrerProtocolConfig protocol = const FisherLehrerProtocolConfig(),
  RfAnalysisRunner? analysisRunner,
}) {
  return RfAssessmentController(
    polarSource: polar,
    respirationSource: belt,
    clock: clock ?? _FakeClock(),
    protocol: protocol,
    analysisRunner:
        analysisRunner ?? ((input) async => _completedResult(input)),
    automaticTicker: false,
    polarPreflightTimeout: const Duration(seconds: 1),
    beltPreflightTimeout: const Duration(seconds: 1),
  );
}

Future<void> _completePreflight(
  RfAssessmentController controller,
  _FakePolarSource polar, {
  _FakeRespirationSource? belt,
}) async {
  final previousPolarStarts = polar.startCount;
  final previousBeltStarts = belt?.startCount ?? 0;
  final preflight = controller.initializePreflight();
  for (
    var index = 0;
    index < 20 && polar.startCount <= previousPolarStarts;
    index++
  ) {
    await Future<void>.delayed(Duration.zero);
  }
  polar.addBatch(const [1000]);
  if (belt != null) {
    for (
      var index = 0;
      index < 20 && belt.startCount <= previousBeltStarts;
      index++
    ) {
      await Future<void>.delayed(Duration.zero);
    }
    for (final value in const [0.0, 0.1, 0.2, 0.1, 0.0]) {
      belt.add(value);
    }
  }
  await preflight;
}

Future<void> _waitForState(
  RfAssessmentController controller,
  RfAssessmentControllerState state,
) async {
  for (var index = 0; index < 100; index++) {
    if (controller.snapshot.state == state) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Expected $state, but controller remained ${controller.snapshot.state}.',
  );
}

RfAssessmentResult _completedResult(RfAssessmentInput input) {
  return RfAssessmentResult(
    protocolVersion: input.protocol.protocolVersion,
    mode: input.mode,
    status: RfResultStatus.completed,
    rfBpm: 5.5,
    rfCenterElapsedMs: input.protocol.scheduledDurationMs / 2,
    peakToTroughAmplitude: 100,
    scheduledBpmAtCenter: 5.5,
    fittedRespirationBpm: input.mode == RfAcquisitionMode.measured ? 5.5 : null,
    adherenceDeltaBpm: input.mode == RfAcquisitionMode.measured ? 0 : null,
    respirationFitError: input.mode == RfAcquisitionMode.measured ? 0 : null,
    quality: const RfQualityReport(
      protocolCompleted: true,
      fullAnalysisWindowAvailable: true,
      rrContinuityPassed: true,
      beltCoveragePassed: true,
      respirationFitConverged: true,
      breathingAdherencePassed: true,
      beltCoverage: 1,
      maximumObservedBeltGapMs: 100,
      maximumObservedRrGapMs: 1000,
      ectopicCorrections: 0,
      flags: [],
    ),
    trace: const RfAnalysisTrace(),
  );
}

class _FakeClock implements RfMonotonicClock {
  int elapsedMicrosecondsValue = 0;
  bool _running = false;

  @override
  int get elapsedMicroseconds => elapsedMicrosecondsValue;

  @override
  bool get isRunning => _running;

  @override
  void reset() => elapsedMicrosecondsValue = 0;

  @override
  void start() => _running = true;

  @override
  void stop() => _running = false;
}

class _FakePolarSource implements RfPolarAcquisitionSource {
  final StreamController<List<double>> batchController =
      StreamController<List<double>>.broadcast();
  final StreamController<bool> connectionController =
      StreamController<bool>.broadcast();
  bool connected = true;
  int startCount = 0;
  int stopCount = 0;

  @override
  bool get isConnected => connected;

  @override
  Stream<bool> get connectionStateChanges => connectionController.stream;

  @override
  Future<Stream<List<double>>> startRrBatches() async {
    startCount++;
    return batchController.stream;
  }

  @override
  Future<void> stopRrBatches() async {
    stopCount++;
  }

  void addBatch(List<double> values) => batchController.add(values);

  void setConnected(bool value) {
    connected = value;
    connectionController.add(value);
  }
}

class _FakeRespirationSource implements RfRespirationAcquisitionSource {
  final StreamController<RfRespirationReading> readingController =
      StreamController<RfRespirationReading>.broadcast();
  final StreamController<bool> connectionController =
      StreamController<bool>.broadcast();
  bool connected = true;
  bool streaming = false;
  int startCount = 0;
  int stopCount = 0;

  @override
  bool get isConnected => connected;

  @override
  bool get isStreaming => streaming;

  @override
  Stream<bool> get connectionStateChanges => connectionController.stream;

  @override
  Stream<RfRespirationReading> get readings => readingController.stream;

  @override
  Future<void> startRespiration() async {
    startCount++;
    streaming = true;
  }

  @override
  Future<void> stopRespiration() async {
    stopCount++;
    streaming = false;
  }

  void add(double value) => readingController.add(
    RfRespirationReading(sensorNumber: 1, value: value),
  );

  void setConnected(bool value) {
    connected = value;
    connectionController.add(value);
  }
}
