const SLOW_TRANSITION_FRAME_MS = 17.2;

export class CanopyTransitionProfiler {
  constructor() {
    this.transitionActive = false;
    this.transitionStarts = 0;
    this.transitionFrames = 0;
    this.xrTransitionFrames = 0;
    this.averageTransitionFrameMs = 0;
    this.maxTransitionFrameMs = 0;
    this.slowTransitionFrames = 0;
    this.lastTransitionReason = 'steady';
  }

  update({ deltaTime, transitioning = false, xrPresenting = false, reason = 'steady' } = {}) {
    if (transitioning && !this.transitionActive) this.transitionStarts++;
    this.transitionActive = transitioning;
    this.lastTransitionReason = transitioning ? reason : 'steady';
    if (!transitioning || !Number.isFinite(deltaTime) || deltaTime <= 0) {
      return this.snapshot();
    }

    const frameMs = Math.min(deltaTime * 1000, 50);
    this.transitionFrames++;
    if (xrPresenting) this.xrTransitionFrames++;
    const alpha = this.transitionFrames === 1 ? 1 : 0.08;
    this.averageTransitionFrameMs += (
      frameMs - this.averageTransitionFrameMs
    ) * alpha;
    this.maxTransitionFrameMs = Math.max(this.maxTransitionFrameMs, frameMs);
    if (frameMs > SLOW_TRANSITION_FRAME_MS) this.slowTransitionFrames++;
    return this.snapshot();
  }

  snapshot() {
    return {
      canopyTransitionActive: this.transitionActive,
      canopyTransitionStarts: this.transitionStarts,
      canopyTransitionFrames: this.transitionFrames,
      canopyXrTransitionFrames: this.xrTransitionFrames,
      canopyAverageTransitionFrameMs: this.averageTransitionFrameMs,
      canopyMaxTransitionFrameMs: this.maxTransitionFrameMs,
      canopySlowTransitionFrames: this.slowTransitionFrames,
      canopyLastTransitionReason: this.lastTransitionReason,
    };
  }
}
