export const CANOPY_VALIDATION_CYCLE_SECONDS = 55;

function clamp01(value) {
  return Math.min(1, Math.max(0, value));
}

function smoothstep01(value) {
  const t = clamp01(value);
  return t * t * (3 - 2 * t);
}

export function canopyValidationSample(elapsedSeconds = 0) {
  const elapsed = Number.isFinite(elapsedSeconds) ? Math.max(0, elapsedSeconds) : 0;
  const cycleTime = elapsed % CANOPY_VALIDATION_CYCLE_SECONDS;
  let stage = 'sparse';
  let coherence = 0.18;

  if (cycleTime >= 8 && cycleTime < 18) {
    stage = 'growth';
    coherence = 0.18 + smoothstep01((cycleTime - 8) / 10) * 0.64;
  } else if (cycleTime >= 18 && cycleTime < 31) {
    stage = 'full-bloom';
    coherence = 1;
  } else if (cycleTime >= 31 && cycleTime < 45) {
    stage = 'wither';
    coherence = 0.18;
  } else if (cycleTime >= 45) {
    stage = 'recovery';
    coherence = 0.18 + smoothstep01((cycleTime - 45) / 10) * 0.47;
  }

  return {
    stage,
    coherence,
    cycleTime,
    cycleProgress: cycleTime / CANOPY_VALIDATION_CYCLE_SECONDS,
    cycleIndex: Math.floor(elapsed / CANOPY_VALIDATION_CYCLE_SECONDS),
  };
}
