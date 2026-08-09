import test from 'node:test';
import assert from 'node:assert/strict';

import {
  SanctuaryPerformanceGovernor,
  detailAssetAbundance,
  grassZoneAbundance,
  quantizePerformanceScale,
} from '../web/vr/sanctuary_v3/sanctuary_performance.js';

test('performance scale updates are stable inside two-percent buckets', () => {
  assert.equal(quantizePerformanceScale(1), 1);
  assert.equal(quantizePerformanceScale(0.991), 1);
  assert.equal(quantizePerformanceScale(0.989), 0.98);
  assert.equal(quantizePerformanceScale(0.755), 0.76);
  assert.equal(quantizePerformanceScale(0.2), 0.52);
  assert.equal(quantizePerformanceScale(Number.NaN), 1);
});

test('grass density remains constant across adaptive performance tiers', () => {
  for (const zone of ['near', 'mid', 'far']) {
    const full = grassZoneAbundance(zone, 1);
    const balanced = grassZoneAbundance(zone, 0.76);
    const protectedValue = grassZoneAbundance(zone, 0.52);
    assert.equal(full, 1);
    assert.equal(balanced, 1);
    assert.equal(protectedValue, 1);
  }
});

test('protected detail policy removes only optional expensive assets', () => {
  assert.equal(detailAssetAbundance('bush', 'bush3', 0.76), 0);
  assert.equal(detailAssetAbundance('bush', 'bush5', 0.52), 0);
  assert.ok(detailAssetAbundance('rock', 'rock1', 0.52) > 0);
  assert.ok(detailAssetAbundance('glow', 'glowing_plants', 0.52) > 0);
});

test('forced performance tiers are deterministic outside immersive XR', () => {
  const governor = new SanctuaryPerformanceGovernor({
    quality: 'quest',
    forcedLevel: 'protected',
  });
  const snapshot = governor.update({ deltaTime: 1 / 30, xrPresenting: false });
  assert.equal(snapshot.adaptiveQualityLevel, 'protected');
  assert.equal(snapshot.performanceScale, 0.52);
  assert.equal(snapshot.performanceTierForced, 'protected');
});

test('Quest governor protects the scene after sustained slow XR frames', () => {
  const governor = new SanctuaryPerformanceGovernor({ quality: 'quest' });
  for (let frame = 0; frame < 900; frame++) {
    governor.update({ deltaTime: 1 / 45, xrPresenting: true });
  }
  assert.equal(governor.snapshot().adaptiveQualityLevel, 'protected');
  assert.equal(governor.snapshot().qualityChanges, 2);
});
