import {
  approach,
  clamp,
  smoothstep,
  treeCoverageTargets,
  trendResponsiveCoverageTargets,
} from './sanctuary_canopy_math.js?v=25';

const VALID_SIGNAL_QUALITIES = new Set([
  'demo',
  'excellent',
  'good',
  'fair',
  'live',
  'connected',
]);

function normaliseSignalQuality(signalQuality) {
  if (typeof signalQuality === 'number') return signalQuality >= 0.35;
  if (typeof signalQuality !== 'string') return false;
  return VALID_SIGNAL_QUALITIES.has(signalQuality.trim().toLowerCase());
}

   
                                                                                 
                                                                              
   
export class SanctuaryTreeVisualState {
  constructor({ initialVitality = 0.58 } = {}) {
    this.vitality = initialVitality;
    this.targetVitality = initialVitality;
    this.lastValidTarget = initialVitality;
    const initialCoverage = treeCoverageTargets(initialVitality);
    this.leafCoverage = initialCoverage.leafCoverage;
    this.blossomCoverage = initialCoverage.blossomCoverage;
    this.canopyHealth = initialCoverage.canopyHealth;
    this.blossomHealth = initialCoverage.canopyHealth;
    this.branchWarmth = 0.5;
    this.sheddingRate = 0.03;
    this.shedImpulse = 0;
    this.vitalityTrend = 0;
    this.coherenceTrend = 0;
    this.trendDirection = 0;
    this.trendStrength = 0;
    this.trendHoldSeconds = 0;
    this.signalAccepted = true;
    this.band = 'steady';
    this.fullBloom = false;
    this.fullBloomProgress = 0;
    this.fullBloomEnterSeconds = 0;
    this.fullBloomExitSeconds = 0;
  }

  update({ coherence, treeVitality, signalQuality, deltaTime = 1 / 72 } = {}) {
    const dt = clamp(deltaTime, 1 / 240, 0.1);
    const hasCoherence = Number.isFinite(coherence);
    const normalisedCoherence = hasCoherence
      ? coherence > 1 ? coherence / 100 : coherence
      : this.lastValidTarget;
    const suppliedVitality = treeVitality?.vitality;
    const normalisedSuppliedVitality = Number.isFinite(suppliedVitality)
      ? suppliedVitality > 1 ? suppliedVitality / 100 : suppliedVitality
      : this.lastValidTarget;
    const rawTarget = clamp(
      hasCoherence ? normalisedCoherence : normalisedSuppliedVitality,
      0,
      1,
    );
    this.signalAccepted = normaliseSignalQuality(signalQuality);

    if (this.signalAccepted) {
      const acceptedDelta = rawTarget - this.lastValidTarget;
      if (Math.abs(acceptedDelta) >= 0.006) {
        this.trendDirection = Math.sign(acceptedDelta);
        this.trendStrength = clamp(Math.abs(acceptedDelta) * 6, 0.16, 1);
        this.trendHoldSeconds = 2.8;
      }
      this.lastValidTarget = rawTarget;
      const difference = rawTarget - this.targetVitality;
      if (difference > 0.012) {
        this.band = 'improving';
        this.targetVitality = rawTarget;
      } else if (difference < -0.016) {
        this.band = 'declining';
        this.targetVitality = rawTarget;
      } else if (Math.abs(difference) < 0.006) {
        this.band = 'steady';
      }
    } else {
      this.trendHoldSeconds = 0;
      this.trendDirection = 0;
      this.trendStrength = 0;
      this.coherenceTrend = approach(this.coherenceTrend, 0, 1.8, dt);
      this.vitalityTrend = approach(this.vitalityTrend, 0, 1.8, dt);
      this.shedImpulse = approach(this.shedImpulse, 0, 3.2, dt);
      this.sheddingRate = approach(this.sheddingRate, 0.012, 0.8, dt);
      this.updateFullBloomLatch(rawTarget, dt);
      return this.snapshot();
    }

    if (this.trendHoldSeconds > 0) {
      this.trendHoldSeconds = Math.max(0, this.trendHoldSeconds - dt);
    }
    const trendTarget = this.signalAccepted && this.trendHoldSeconds > 0
      ? this.trendDirection * this.trendStrength
      : 0;
    this.coherenceTrend = approach(
      this.coherenceTrend,
      trendTarget,
      trendTarget === 0 ? 0.72 : 3.2,
      dt,
    );

    const previousVitality = this.vitality;
    const improving = this.targetVitality >= this.vitality;
    const vitalityRate = improving ? 0.28 : 0.22;
    this.vitality = approach(this.vitality, this.targetVitality, vitalityRate, dt);
    const instantTrend = (this.vitality - previousVitality) / dt;
    this.vitalityTrend = approach(this.vitalityTrend, instantTrend, 0.9, dt);

    const coverageTargets = trendResponsiveCoverageTargets(
      this.vitality,
      this.coherenceTrend,
    );
    this.leafCoverage = approach(
      this.leafCoverage,
      coverageTargets.leafCoverage,
      improving ? 1.35 : 1.05,
      dt,
    );
    this.blossomCoverage = approach(
      this.blossomCoverage,
      coverageTargets.blossomCoverage,
      improving ? 1.5 : 1.15,
      dt,
    );
    this.canopyHealth = approach(
      this.canopyHealth,
      coverageTargets.canopyHealth,
      improving ? 1.25 : 1,
      dt,
    );
    this.blossomHealth = this.canopyHealth;
    this.branchWarmth = approach(
      this.branchWarmth,
      0.24 + coverageTargets.canopyHealth * 0.76,
      0.075,
      dt,
    );

    const decline = clamp(
      Math.max(-this.vitalityTrend * 12, -this.coherenceTrend),
      0,
      1,
    );
    const lowVitality = 1 - smoothstep(this.vitality, 0.16, 0.58);
    const sheddingTarget = this.signalAccepted
      ? 0.018 + decline * 0.62 + lowVitality * 0.13
      : 0.012;
    this.sheddingRate = approach(this.sheddingRate, sheddingTarget, 0.44, dt);
    const impulseTarget = this.signalAccepted
      ? clamp(Math.max(-this.vitalityTrend * 9, -this.coherenceTrend), 0, 1)
      : 0;
    this.shedImpulse = approach(this.shedImpulse, impulseTarget, 3.2, dt);

    const fullBloomCoherence = Number.isFinite(coherence) ? normalisedCoherence : rawTarget;
    this.updateFullBloomLatch(fullBloomCoherence, dt);
    return this.snapshot();
  }

  updateFullBloomLatch(coherence, deltaTime) {
    if (!this.signalAccepted) {
      this.fullBloomEnterSeconds = 0;
      this.fullBloomExitSeconds = 0;
      this.fullBloomProgress = this.fullBloom ? 1 : 0;
      return;
    }

    if (!this.fullBloom) {
      this.fullBloomExitSeconds = 0;
      this.fullBloomEnterSeconds = coherence >= 0.95
        ? this.fullBloomEnterSeconds + deltaTime
        : 0;
      if (this.fullBloomEnterSeconds >= 5) {
        this.fullBloom = true;
        this.fullBloomEnterSeconds = 5;
      }
    } else {
      this.fullBloomEnterSeconds = 5;
      this.fullBloomExitSeconds = coherence < 0.88
        ? this.fullBloomExitSeconds + deltaTime
        : 0;
      if (this.fullBloomExitSeconds >= 3) {
        this.fullBloom = false;
        this.fullBloomEnterSeconds = 0;
        this.fullBloomExitSeconds = 0;
      }
    }
    this.fullBloomProgress = this.fullBloom
      ? 1
      : clamp(this.fullBloomEnterSeconds / 5);
  }

  snapshot() {
    return {
      vitality: this.vitality,
      targetVitality: this.targetVitality,
      leafCoverage: this.leafCoverage,
      blossomCoverage: this.blossomCoverage,
      canopyHealth: this.canopyHealth,
      blossomHealth: this.blossomHealth,
      branchWarmth: this.branchWarmth,
      sheddingRate: this.sheddingRate,
      shedImpulse: this.shedImpulse,
      vitalityTrend: this.vitalityTrend,
      coherenceTrend: this.coherenceTrend,
      trendHoldSeconds: this.trendHoldSeconds,
      signalAccepted: this.signalAccepted,
      band: this.band,
      fullBloom: this.fullBloom,
      fullBloomProgress: this.fullBloomProgress,
    };
  }
}
