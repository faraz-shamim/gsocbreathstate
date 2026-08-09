export const SANCTUARY_PERFORMANCE_LEVELS = Object.freeze([
  { name: 'full', scale: 1 },
  { name: 'balanced', scale: 0.76 },
  { name: 'protected', scale: 0.52 },
]);

const DETAIL_ABUNDANCE = Object.freeze({
  rock: Object.freeze({ full: 1, balanced: 0.82, protected: 0.55 }),
  flower: Object.freeze({ full: 1, balanced: 0.64, protected: 0.36 }),
  glow: Object.freeze({ full: 1, balanced: 0.7, protected: 0.42 }),
  bush: Object.freeze({ full: 1, balanced: 0.6, protected: 0.32 }),
});

const PROTECTED_DETAIL_ASSETS = new Set(['bush3', 'bush4', 'bush5', 'rock_pack']);

function clamp01(value) {
  return Math.min(1, Math.max(0, value));
}

export function quantizePerformanceScale(performanceScale = 1, steps = 50) {
  const safeSteps = Number.isFinite(steps) && steps > 0 ? Math.round(steps) : 50;
  const scale = Number.isFinite(performanceScale) ? performanceScale : 1;
  return Math.round(Math.min(1, Math.max(0.52, scale)) * safeSteps) / safeSteps;
}

function interpolateTierValue(profile, performanceScale) {
  const scale = Math.min(1, Math.max(0.52, performanceScale));
  if (scale >= 0.76) {
    const progress = clamp01((1 - scale) / (1 - 0.76));
    return profile.full + (profile.balanced - profile.full) * progress;
  }
  const progress = clamp01((0.76 - scale) / (0.76 - 0.52));
  return profile.balanced + (profile.protected - profile.balanced) * progress;
}

export function grassZoneAbundance() {
  return 1;
}

export function detailAssetAbundance(kind, name, performanceScale = 1) {
  const scale = Math.min(1, Math.max(0.52, performanceScale));
  if (name === 'bush3' && scale < 0.9) return 0;
  if (scale <= 0.58 && PROTECTED_DETAIL_ASSETS.has(name)) return 0;
  return interpolateTierValue(DETAIL_ABUNDANCE[kind] || DETAIL_ABUNDANCE.flower, scale);
}

function resolveForcedLevel(forcedLevel) {
  if (typeof forcedLevel !== 'string') return null;
  const requested = forcedLevel.trim().toLowerCase();
  return SANCTUARY_PERFORMANCE_LEVELS.find((level) => level.name === requested) || null;
}

                                                                                     
export class SanctuaryPerformanceGovernor {
  constructor({ quality = 'quest', forcedLevel = 'auto' } = {}) {
    this.enabled = quality === 'quest';
    this.forcedLevel = resolveForcedLevel(forcedLevel);
    this.levelIndex = this.forcedLevel
      ? SANCTUARY_PERFORMANCE_LEVELS.indexOf(this.forcedLevel)
      : 0;
    this.averageFrameMs = 11.8;
    this.sampleCount = 0;
    this.slowScore = 0;
    this.fastScore = 0;
    this.qualityChanges = 0;
  }

  update({ deltaTime, xrPresenting } = {}) {
    if (this.forcedLevel) return this.snapshot();
    if (!this.enabled || !xrPresenting || !Number.isFinite(deltaTime) || deltaTime <= 0) {
      return this.snapshot();
    }
    const frameMs = Math.min(deltaTime * 1000, 50);
    this.sampleCount += 1;
    this.averageFrameMs += (frameMs - this.averageFrameMs) * 0.035;
    if (this.sampleCount < 120) return this.snapshot();

    const slow = this.averageFrameMs > 12.5;
    const fast = this.averageFrameMs < 11.4;
    this.slowScore = slow ? Math.min(120, this.slowScore + 1) : Math.max(0, this.slowScore - 2);
    this.fastScore = fast ? Math.min(1200, this.fastScore + 1) : Math.max(0, this.fastScore - 3);

    if (this.slowScore >= 60 && this.levelIndex < SANCTUARY_PERFORMANCE_LEVELS.length - 1) {
      this.levelIndex += 1;
      this.slowScore = 0;
      this.fastScore = 0;
      this.qualityChanges += 1;
    } else if (this.fastScore >= 900 && this.levelIndex > 0) {
      this.levelIndex -= 1;
      this.slowScore = 0;
      this.fastScore = 0;
      this.qualityChanges += 1;
    }
    return this.snapshot();
  }

  snapshot() {
    const level = SANCTUARY_PERFORMANCE_LEVELS[this.levelIndex];
    return {
      adaptiveQualityEnabled: this.enabled,
      adaptiveQualityLevel: level.name,
      performanceScale: level.scale,
      averageFrameMs: this.averageFrameMs,
      targetFrameTimeMs: 12.5,
      targetRefreshRateHz: 80,
      preferredRefreshRateHz: 90,
      qualityChanges: this.qualityChanges,
      performanceTierForced: this.forcedLevel?.name || null,
    };
  }
}
