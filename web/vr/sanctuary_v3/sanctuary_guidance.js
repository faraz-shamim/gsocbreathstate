import * as THREE from 'three';

const INHALE_COLOR = new THREE.Color(0x79e6e0);
const EXHALE_COLOR = new THREE.Color(0xffd18a);
const HOLD_COLOR = new THREE.Color(0xe7d8ff);

function phaseColor(phase) {
  const value = String(phase || '').toLowerCase();
  if (value.includes('inhale')) return INHALE_COLOR;
  if (value.includes('hold')) return HOLD_COLOR;
  return EXHALE_COLOR;
}

export class SanctuaryBreathingGuide {
  constructor({ treePosition, layer = 3 } = {}) {
    this.treePosition = treePosition.clone();
    this.layer = layer;
    this.root = new THREE.Group();
    this.root.name = 'SanctuaryV3_Environmental_Breathing_Guide';
    this.root.position.copy(this.treePosition).add(new THREE.Vector3(0, 0.038, 0));
    this.root.layers.set(layer);
    this.status = 'idle';
    this.ring = null;
    this.marker = null;
    this.markerMaterial = null;
    this.currentColor = INHALE_COLOR.clone();
    this.guideOpacity = 0.35;
    this.uniforms = {
      uColor: { value: this.currentColor },
      uExpansion: { value: 0 },
      uOpacity: { value: this.guideOpacity },
      uTime: { value: 0 },
      uHighContrast: { value: 0 },
    };
  }

  initialize({ parent }) {
    if (this.status === 'ready') return this.snapshot();
    const material = new THREE.ShaderMaterial({
      uniforms: this.uniforms,
      transparent: true,
      depthWrite: false,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      toneMapped: false,
      vertexShader: `
        varying vec2 vGuideUv;
        void main() {
          vGuideUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform vec3 uColor;
        uniform float uExpansion;
        uniform float uOpacity;
        uniform float uTime;
        uniform float uHighContrast;
        varying vec2 vGuideUv;
        void main() {
          vec2 centered = (vGuideUv - 0.5) * 2.0;
          float radius = length(centered);
          float target = 0.69 + uExpansion * 0.035;
          float width = mix(0.018, 0.032, uHighContrast);
          float core = 1.0 - smoothstep(width, width * 2.25, abs(radius - target));
          float halo = 1.0 - smoothstep(width * 1.4, width * 6.5, abs(radius - target));
          float rippleTarget = 0.34 + uExpansion * 0.31;
          float ripple = 1.0 - smoothstep(0.018, 0.075, abs(radius - rippleTarget));
          float radialMask = smoothstep(0.1, 0.24, radius) * smoothstep(0.98, 0.82, radius);
          float alpha = (core * 0.74 + halo * 0.22 + ripple * 0.13)
            * radialMask * uOpacity;
          if (alpha < 0.006) discard;
          gl_FragColor = vec4(uColor, alpha);
        }
      `,
    });
    const ring = new THREE.Mesh(new THREE.PlaneGeometry(5.7, 5.7), material);
    ring.name = 'SanctuaryV3_Soft_Breathing_Ring';
    ring.rotation.x = -Math.PI / 2;
    ring.renderOrder = 4;
    ring.layers.set(this.layer);
    this.root.add(ring);
    this.ring = ring;

    const markerMaterial = new THREE.MeshBasicMaterial({
      color: INHALE_COLOR,
      transparent: true,
      opacity: 0.82,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      toneMapped: false,
    });
    const marker = new THREE.Mesh(new THREE.SphereGeometry(0.075, 12, 8), markerMaterial);
    marker.name = 'SanctuaryV3_Breath_Phase_Marker';
    marker.position.set(0, 0.045, -1.98);
    marker.renderOrder = 5;
    marker.layers.set(this.layer);
    this.root.add(marker);
    this.marker = marker;
    this.markerMaterial = markerMaterial;

    parent.add(this.root);
    this.status = 'ready';
    return this.snapshot();
  }

  update({
    breathPhase,
    breathProgress,
    comfortOptions,
    elapsedTime = 0,
    sessionActive = false,
    sessionPaused = false,
    deltaTime = 1 / 72,
  } = {}) {
    if (this.status !== 'ready') return;
    const progress = THREE.MathUtils.euclideanModulo(breathProgress || 0, 1);
    const expansion = 0.5 - Math.cos(progress * Math.PI * 2) * 0.5;
    const reducedMotion = comfortOptions?.reducedMotion === true;
    const highContrast = comfortOptions?.highContrastGuide === true;
    const targetColor = phaseColor(breathPhase);
    const colorRate = 1 - Math.exp(-4.2 * Math.min(deltaTime, 0.1));
    this.currentColor.lerp(targetColor, colorRate);
    const activeOpacity = sessionPaused ? 0.34 : sessionActive ? 0.68 : 0.3;
    const targetOpacity = highContrast ? Math.max(activeOpacity, 0.88) : activeOpacity;
    this.guideOpacity = THREE.MathUtils.lerp(
      this.guideOpacity,
      targetOpacity,
      1 - Math.exp(-3.2 * Math.min(deltaTime, 0.1)),
    );

    this.uniforms.uExpansion.value = expansion;
    this.uniforms.uOpacity.value = this.guideOpacity;
    this.uniforms.uTime.value = elapsedTime;
    this.uniforms.uHighContrast.value = highContrast ? 1 : 0;
    const scaleAmplitude = reducedMotion ? 0.018 : 0.105;
    const ringScale = 0.94 + expansion * scaleAmplitude;
    this.ring.scale.setScalar(ringScale);

    const markerAngle = progress * Math.PI * 2 - Math.PI / 2;
    const markerRadius = 1.97 * ringScale;
    this.marker.position.set(
      Math.cos(markerAngle) * markerRadius,
      0.045,
      Math.sin(markerAngle) * markerRadius,
    );
    this.markerMaterial.color.copy(this.currentColor);
    this.markerMaterial.opacity = highContrast
      ? 0.98
      : this.guideOpacity + expansion * 0.16;
    const markerScale = (highContrast ? 1.34 : 1) + expansion * (reducedMotion ? 0.08 : 0.24);
    this.marker.scale.setScalar(markerScale);
  }

  snapshot() {
    return {
      guidanceStatus: this.status,
      guidanceDrawCalls: 2,
      guideOpacity: this.guideOpacity,
    };
  }
}
