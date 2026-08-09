import test from 'node:test';
import assert from 'node:assert/strict';

import {
  CANOPY_QUALITY_PROFILES,
  advanceCanopyCount,
  advanceClinicalDetachmentAllowance,
  advanceFullBloomBlend,
  canopyIntegrityIssue,
  clinicalShedEventRate,
  didEnterFullBloom,
  extractConnectedTriangleComponents,
  fullBloomPulseValue,
  isClinicalDetachment,
  shouldUseAnchorFallback,
  stratifyCanopyAnchors,
  treeCoverageTargets,
  trendResponsiveCoverageTargets,
} from '../web/vr/sanctuary_v3/sanctuary_canopy_math.js';
import { SanctuaryTreeVisualState } from '../web/vr/sanctuary_v3/sanctuary_tree_state.js';

test('coverage mappings are monotonic and retain a calm leaf floor', () => {
  const low = treeCoverageTargets(0);
  const middle = treeCoverageTargets(0.55);
  const high = treeCoverageTargets(1);
  assert.equal(low.leafCoverage, 0.12);
  assert.equal(low.blossomCoverage, 0.04);
  assert.equal(high.leafCoverage, 1);
  assert.equal(high.blossomCoverage, 1);
  assert.ok(middle.leafCoverage > low.leafCoverage);
  assert.ok(high.canopyHealth > middle.canopyHealth);
});

test('blossom coverage is forgiving, monotonic, and visibly responsive', () => {
  const samples = [0, 0.25, 0.5, 0.7, 0.85, 0.95, 1]
    .map((value) => treeCoverageTargets(value).blossomCoverage);
  for (let index = 1; index < samples.length; index++) {
    assert.ok(samples[index] >= samples[index - 1]);
  }
  assert.equal(samples[0], 0.04);
  assert.ok(samples[2] > 0.3);
  assert.ok(samples[3] > 0.7);
  assert.ok(samples[4] > 0.95);
  assert.equal(samples.at(-1), 1);
});

test('accepted direct coherence is not double-filtered through legacy vitality', () => {
  const state = new SanctuaryTreeVisualState({ initialVitality: 0.2 });
  state.update({
    coherence: 80,
    treeVitality: { vitality: 0.1 },
    signalQuality: 'good',
    deltaTime: 1 / 72,
  });
  assert.equal(state.snapshot().targetVitality, 0.8);
});

test('accepted coherence direction immediately biases blossom coverage', () => {
  const steady = trendResponsiveCoverageTargets(0.48, 0).blossomCoverage;
  const rising = trendResponsiveCoverageTargets(0.48, 0.7).blossomCoverage;
  const falling = trendResponsiveCoverageTargets(0.48, -0.7).blossomCoverage;
  assert.ok(rising > steady);
  assert.ok(falling < steady);

  const state = new SanctuaryTreeVisualState({ initialVitality: 0.42 });
  for (let frame = 0; frame < 72; frame++) {
    state.update({ coherence: 42, signalQuality: 'good', deltaTime: 1 / 72 });
  }
  const beforeRise = state.snapshot().blossomCoverage;
  for (let frame = 0; frame < 72; frame++) {
    state.update({ coherence: 52, signalQuality: 'good', deltaTime: 1 / 72 });
  }
  const afterRise = state.snapshot();
  assert.ok(afterRise.coherenceTrend > 0);
  assert.ok(afterRise.blossomCoverage > beforeRise);

  for (let frame = 0; frame < 72; frame++) {
    state.update({ coherence: 38, signalQuality: 'good', deltaTime: 1 / 72 });
  }
  const afterFall = state.snapshot();
  assert.ok(afterFall.coherenceTrend < 0);
  assert.ok(afterFall.blossomCoverage < afterRise.blossomCoverage);
});

test('full bloom latches after five seconds and exits after three seconds', () => {
  const state = new SanctuaryTreeVisualState();
  for (let frame = 0; frame < 361; frame++) {
    state.update({ coherence: 100, signalQuality: 'excellent', deltaTime: 1 / 72 });
  }
  assert.equal(state.snapshot().fullBloom, true);
  for (let frame = 0; frame < 217; frame++) {
    state.update({ coherence: 87, signalQuality: 'excellent', deltaTime: 1 / 72 });
  }
  assert.equal(state.snapshot().fullBloom, false);
});

test('signal loss freezes the last accepted target and never unlatches full bloom', () => {
  const state = new SanctuaryTreeVisualState();
  state.update({ coherence: 82, signalQuality: 'good', deltaTime: 1 / 72 });
  const acceptedTarget = state.snapshot().targetVitality;
  for (let frame = 0; frame < 360; frame++) {
    state.update({ coherence: 4, signalQuality: 'poor', deltaTime: 1 / 72 });
  }
  assert.equal(state.snapshot().targetVitality, acceptedTarget);
  assert.equal(state.snapshot().signalAccepted, false);
  assert.ok(state.snapshot().shedImpulse < 0.02);
});

test('growth limits are frame-rate independent', () => {
  const simulate = (steps) => steps.reduce(
    (count, deltaTime) => advanceCanopyCount(count, 900, 900, deltaTime),
    0,
  );
  const at72Hz = simulate(new Array(72).fill(1 / 72));
  const at90Hz = simulate(new Array(90).fill(1 / 90));
  const irregular = simulate([0.1, 0.04, 0.08, 0.13, 0.02, 0.19, 0.11, 0.17, 0.16]);
  assert.ok(Math.abs(at72Hz - 90) < 0.0001);
  assert.ok(Math.abs(at90Hz - 90) < 0.0001);
  assert.ok(Math.abs(irregular - 90) < 0.0001);
});

test('full-bloom reveal enters in four seconds and retires in three', () => {
  const simulate = (start, active, frameRate, seconds) => {
    let value = start;
    for (let frame = 0; frame < frameRate * seconds; frame++) {
      value = advanceFullBloomBlend(value, active, 1 / frameRate);
    }
    return value;
  };
  assert.ok(Math.abs(simulate(0, true, 72, 4) - 1) < 0.000001);
  assert.ok(Math.abs(simulate(0, true, 90, 2) - 0.5) < 0.000001);
  assert.ok(Math.abs(simulate(1, false, 72, 3)) < 0.000001);
});

test('full-bloom light pulse is a bounded four-second one-shot curve', () => {
  assert.equal(fullBloomPulseValue(-0.1), 0);
  assert.equal(fullBloomPulseValue(0), 0);
  assert.ok(Math.abs(fullBloomPulseValue(2) - 1) < 0.000001);
  assert.ok(fullBloomPulseValue(3) > 0);
  assert.equal(fullBloomPulseValue(4), 0);
  assert.equal(fullBloomPulseValue(40), 0);
  assert.equal(didEnterFullBloom(true, false), true);
  assert.equal(didEnterFullBloom(true, true), false);
  assert.equal(didEnterFullBloom(false, true), false);
});

test('full-bloom canopy growth can fill a tier in four seconds', () => {
  let count = 0;
  for (let frame = 0; frame < 72 * 4; frame++) {
    count = advanceCanopyCount(count, 900, 900, 1 / 72, { growthRate: 0.25 });
  }
  assert.ok(Math.abs(count - 900) < 0.000001);
});

test('shedding events require an accepted clinical decline', () => {
  assert.equal(clinicalShedEventRate({
    shedImpulse: 0.9,
    signalAccepted: true,
    coverageDelta: 0,
  }), 0);
  assert.equal(clinicalShedEventRate({
    shedImpulse: 0.9,
    signalAccepted: false,
    coverageDelta: -0.2,
  }), 0);
  assert.equal(clinicalShedEventRate({
    shedImpulse: 0.01,
    signalAccepted: true,
    coverageDelta: -0.2,
  }), 0);
  assert.ok(clinicalShedEventRate({
    shedImpulse: 0.8,
    signalAccepted: true,
    coverageDelta: -0.02,
  }) > 20);
});

test('adaptive-quality thinning never masquerades as clinical shedding', () => {
  const base = {
    clinicalRenderBoundary: 500,
    shedEventsPerSecond: 20,
    shedEventBudget: 2,
    clinicalDetachmentAllowance: 2,
  };
  assert.equal(isClinicalDetachment({ ...base, instanceIndex: 620 }), true);
  assert.equal(isClinicalDetachment({ ...base, instanceIndex: 500 }), true);
  assert.equal(isClinicalDetachment({ ...base, instanceIndex: 499 }), false);
  assert.equal(isClinicalDetachment({
    ...base,
    clinicalRenderBoundary: Math.round(500 * 0.76),
    instanceIndex: 380,
  }), true);
  assert.equal(isClinicalDetachment({
    ...base,
    clinicalRenderBoundary: Math.round(500 * 0.76),
    instanceIndex: 379,
  }), false);
  assert.equal(isClinicalDetachment({
    ...base,
    instanceIndex: 620,
    shedEventsPerSecond: 0,
  }), false);
  assert.equal(isClinicalDetachment({
    ...base,
    instanceIndex: 620,
    shedEventBudget: 0.8,
  }), false);
  assert.equal(isClinicalDetachment({
    ...base,
    instanceIndex: 620,
    clinicalDetachmentAllowance: 0.8,
  }), false);

  const adaptiveOnly = advanceClinicalDetachmentAllowance({
    currentAllowance: 0,
    previousClinicalTarget: 600,
    currentClinicalTarget: 600,
    previousPerformanceScale: 1,
    clinicalDeclineActive: true,
    deltaTime: 1 / 72,
  });
  const clinicalAtProtectedQuality = advanceClinicalDetachmentAllowance({
    currentAllowance: 0,
    previousClinicalTarget: 600,
    currentClinicalTarget: 590,
    previousPerformanceScale: 0.52,
    clinicalDeclineActive: true,
    deltaTime: 1 / 72,
  });
  assert.equal(adaptiveOnly, 0);
  assert.ok(Math.abs(clinicalAtProtectedQuality - 5.2) < 0.000001);
});

test('a complete coherence cycle blooms, unlatches, and begins a gentle wither', () => {
  const state = new SanctuaryTreeVisualState();
  for (let frame = 0; frame < 72 * 8; frame++) {
    state.update({ coherence: 100, signalQuality: 'excellent', deltaTime: 1 / 72 });
  }
  const peak = state.snapshot();
  assert.equal(peak.fullBloom, true);

  let maximumShedImpulse = 0;
  for (let frame = 0; frame < 72 * 12; frame++) {
    const snapshot = state.update({
      coherence: 20,
      signalQuality: 'excellent',
      deltaTime: 1 / 72,
    });
    maximumShedImpulse = Math.max(maximumShedImpulse, snapshot.shedImpulse);
  }
  const withered = state.snapshot();
  assert.equal(withered.fullBloom, false);
  assert.ok(withered.blossomCoverage < peak.blossomCoverage);
  assert.ok(withered.canopyHealth < peak.canopyHealth);
  assert.ok(maximumShedImpulse > 0.025);
});

test('canopy integrity rejects invalid runtime counts and uniforms', () => {
  const healthy = {
    activeLeafCount: 400,
    activeBlossomCount: 320,
    targetLeafCount: 500,
    targetBlossomCount: 360,
    maxLeaves: 900,
    maxBlossoms: 720,
    fullBloomBlend: 0.4,
    materialHealth: 0.72,
  };
  assert.equal(canopyIntegrityIssue(healthy), null);
  assert.equal(
    canopyIntegrityIssue({ ...healthy, activeLeafCount: 901 }),
    'active leaves out of range',
  );
  assert.equal(
    canopyIntegrityIssue({ ...healthy, fullBloomBlend: Number.NaN }),
    'full-bloom reveal out of range',
  );
});

test('indexed and non-indexed cards form deterministic disconnected components', () => {
  const indexedPositions = new Float32Array([
    0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0,
    3, 0, 0, 4, 0, 0, 4, 1, 0, 3, 1, 0,
  ]);
  const indices = new Uint16Array([0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7]);
  const indexed = extractConnectedTriangleComponents({ positions: indexedPositions, indices });
  assert.equal(indexed.length, 2);
  assert.deepEqual(indexed.map((component) => component.triangleIndices.length), [2, 2]);

  const nonIndexedPositions = new Float32Array([
    0, 0, 0, 1, 0, 0, 1, 1, 0,
    0, 0, 0, 1, 1, 0, 0, 1, 0,
    3, 0, 0, 4, 0, 0, 4, 1, 0,
    3, 0, 0, 4, 1, 0, 3, 1, 0,
  ]);
  const nonIndexed = extractConnectedTriangleComponents({ positions: nonIndexedPositions });
  assert.equal(nonIndexed.length, 2);
});

test('spatial growth order and quality capacities are stable', () => {
  const anchors = Array.from({ length: 48 }, (_, index) => ({
    position: { x: index % 4, y: Math.floor(index / 16), z: Math.floor(index / 4) % 4 },
  }));
  assert.deepEqual(
    stratifyCanopyAnchors(anchors, { preferTips: true }),
    stratifyCanopyAnchors(anchors, { preferTips: true }),
  );
  assert.equal(new Set(stratifyCanopyAnchors(anchors)).size, anchors.length);
  assert.equal(CANOPY_QUALITY_PROFILES.quest.maxLeaves, 900);
  assert.equal(CANOPY_QUALITY_PROFILES.quest.maxBlossoms, 720);
  assert.equal(CANOPY_QUALITY_PROFILES.high.maxLeaves, 1400);
  assert.equal(CANOPY_QUALITY_PROFILES.high.maxBlossoms, 1080);
  assert.equal(shouldUseAnchorFallback(399), true);
  assert.equal(shouldUseAnchorFallback(400), false);
});
