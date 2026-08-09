import test from 'node:test';
import assert from 'node:assert/strict';

import { CanopyTransitionProfiler } from '../web/vr/sanctuary_v3/sanctuary_canopy_profiler.js';
import {
  CANOPY_VALIDATION_CYCLE_SECONDS,
  canopyValidationSample,
} from '../web/vr/sanctuary_v3/sanctuary_validation_cycle.js';

test('validation cycle deterministically covers every canopy state', () => {
  assert.equal(canopyValidationSample(0).stage, 'sparse');
  assert.equal(canopyValidationSample(13).stage, 'growth');
  assert.equal(canopyValidationSample(13).coherence, 0.5);
  assert.equal(canopyValidationSample(22).stage, 'full-bloom');
  assert.equal(canopyValidationSample(22).coherence, 1);
  assert.equal(canopyValidationSample(36).stage, 'wither');
  assert.equal(canopyValidationSample(50).stage, 'recovery');
  assert.deepEqual(
    canopyValidationSample(CANOPY_VALIDATION_CYCLE_SECONDS + 13),
    { ...canopyValidationSample(13), cycleIndex: 1 },
  );
});

test('validation cycle remains bounded for malformed elapsed values', () => {
  for (const elapsed of [-20, Number.NaN, Number.POSITIVE_INFINITY, 1e6]) {
    const sample = canopyValidationSample(elapsed);
    assert.ok(sample.coherence >= 0 && sample.coherence <= 1);
    assert.ok(sample.cycleProgress >= 0 && sample.cycleProgress < 1);
  }
});

test('transition profiler counts only active canopy transition frames', () => {
  const profiler = new CanopyTransitionProfiler();
  profiler.update({ deltaTime: 1 / 72, transitioning: false, xrPresenting: true });
  profiler.update({
    deltaTime: 1 / 72,
    transitioning: true,
    xrPresenting: true,
    reason: 'growth',
  });
  profiler.update({
    deltaTime: 0.02,
    transitioning: true,
    xrPresenting: true,
    reason: 'growth',
  });
  profiler.update({ deltaTime: 1 / 72, transitioning: false, xrPresenting: true });
  profiler.update({
    deltaTime: 1 / 90,
    transitioning: true,
    xrPresenting: false,
    reason: 'full-bloom',
  });

  const snapshot = profiler.snapshot();
  assert.equal(snapshot.canopyTransitionStarts, 2);
  assert.equal(snapshot.canopyTransitionFrames, 3);
  assert.equal(snapshot.canopyXrTransitionFrames, 2);
  assert.equal(snapshot.canopySlowTransitionFrames, 1);
  assert.equal(snapshot.canopyLastTransitionReason, 'full-bloom');
  assert.ok(snapshot.canopyMaxTransitionFrameMs >= 20);
});
