                                           
                                                         

import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { FBXLoader } from 'three/addons/loaders/FBXLoader.js';
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
import { KTX2Loader } from 'three/addons/loaders/KTX2Loader.js';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';
import { EXRLoader } from 'three/addons/loaders/EXRLoader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { VRButton } from 'three/addons/webxr/VRButton.js';
import {
  SANCTUARY_LAYERS,
  SanctuarySceneV3,
} from './sanctuary_v3/sanctuary_scene.js?v=25';
import { canopyValidationSample } from './sanctuary_v3/sanctuary_validation_cycle.js?v=25';

window.__breathStateVrBoot?.mark('Initializing renderer...');

const TEAL = new THREE.Color(0x2dd4bf);
const BLUE = new THREE.Color(0x38bdf8);
const EMERALD = new THREE.Color(0x4ade80);
const LEAF_LOW = new THREE.Color(0x8b6c4f);
const LEAF_HIGH = new THREE.Color(0xffbdd2);
const GRASS_LOW = new THREE.Color(0x355d44);
const GRASS_HIGH = new THREE.Color(0x6fb85a);
const BARK = new THREE.Color(0x6b4a32);
const BARK_GLOW = new THREE.Color(0xd8b06a);
const CANOPY_LIGHT_LOW = new THREE.Color(0xffb9c9);
const CANOPY_LIGHT_HIGH = new THREE.Color(0xfff2f6);
const SKY_TOP = new THREE.Color(0x142b34);
const SKY_HORIZON = new THREE.Color(0x1f3438);
const SKY_LOW = new THREE.Color(0x09141f);
const SKY_WARM_TOP = new THREE.Color(0x253d42);
const SKY_WARM_HORIZON = new THREE.Color(0x5f5362);
const SKY_COHERENT_TOP = new THREE.Color(0x1b3146);
const SKY_COHERENT_HORIZON = new THREE.Color(0x3b5360);
const SKY_COHERENT_LOW = new THREE.Color(0x111a27);
const FOG_LOW = new THREE.Color(0x09141f);
const FOG_COHERENT = new THREE.Color(0x241d34);
const GUIDE_CONTRAST_IN = new THREE.Color(0xffffff);
const GUIDE_CONTRAST_OUT = new THREE.Color(0x7dd3fc);

const TWO_PI = Math.PI * 2;
const TREE_POS = new THREE.Vector3(0, 0, -6.8);
const MOON_POS = new THREE.Vector3(12.4, 11.8, -25.5);
const MOON_DIAMETER = 2.42;
const MOON_TEXTURE_ANISOTROPY = 16;
const SANCTUARY_CENTER = new THREE.Vector3(TREE_POS.x, 0, TREE_POS.z + 1.5);
const SCENE_V2_BASE = 'assets/scene_v2/';
const GRASS_ASSET_BASE = 'assets/new/';
const NEW_ASSET_BASE = 'assets/new/';
const GRASS_FBX_GROUP_NAME = 'Grass_Animation:grassWindWide1MeshGroup';
const GRASS_FBX_MAIN_NAME = 'Grass_Animation:grassWindWide1Main';
const SCENE_LIB_BASE = 'libs/';
const urlParams = new URLSearchParams(window.location.search);
const requestedSceneVersion = (urlParams.get('scene') || 'v3').toLowerCase();
const activeSceneVersion = requestedSceneVersion === 'v2' ? 'v2' : 'v3';
const useLegacyScene = activeSceneVersion === 'v2';
const canopyValidationMode = activeSceneVersion === 'v3'
  && (urlParams.get('canopyTest') || '').toLowerCase() === 'cycle';
const requestedPerformanceTier = (urlParams.get('perfTier') || 'auto').toLowerCase();
const performanceTier = ['full', 'balanced', 'protected'].includes(requestedPerformanceTier)
  ? requestedPerformanceTier
  : 'auto';
const debugProfileEnabled = ['1', 'true', 'profile'].includes(
  (urlParams.get('debug') || '').toLowerCase(),
) || ['1', 'true'].includes((urlParams.get('profile') || '').toLowerCase())
  || canopyValidationMode;

const visualSettings = {
  sceneVersion: activeSceneVersion,
  visualQuality: urlParams.get('quality') === 'high' ? 'high' : 'quest',
  debugProfile: debugProfileEnabled,
  canopyValidationMode,
  performanceTier,
  assetStatus: 'loading',
  assetProfile: 'source',
  textureProfile: 'source',
  activeTreeLod: 'source',
  skyProfile: 'procedural',
  grassProfile: 'procedural',
  landscapeProfile: 'pending',
  forestProfile: 'pending',
  atmosphereProfile: 'coherence-fog',
  fogDensity: 0.036,
  assetLoadMs: 0,
};

const sceneAssets = {
  oakGroup: null,
  oakLeaves: [],
  oakLeavesLod0: null,
  oakLeavesLod1: null,
  treeModel: null,
  treeBaseScale: new THREE.Vector3(1, 1, 1),
  treeBasePosition: TREE_POS.clone(),
  blossomMeshes: [],
  barkMeshes: [],
  leafMaterial: null,
  blossomMaterial: null,
  barkMaterial: null,
  moon: null,
  moonHalo: null,
  moonModel: null,
  aurora: null,
  auroraModel: null,
  starsModel: null,
  bushGroup: null,
  bushSourceFiles: [],
  bushClusterCount: 0,
  groundDetailGroup: null,
  groundDetailSourceFiles: [],
  groundDetailProfile: 'pending',
  rockCount: 0,
  flowerPatchCount: 0,
  bushCount: 0,
  petalPatchCount: 0,
  sanctuaryGroup: null,
  sanctuarySourceFiles: [],
  sanctuaryPineCount: 0,
  sanctuaryHillCount: 0,
  moonbeamCone: null,
  skyModel: null,
  skyTexture: null,
  nightSkyTexture: null,
  assetProfile: 'source',
  textureProfile: 'source',
  activeTreeLod: 'source',
  skyProfile: 'procedural',
  grassProfile: 'procedural',
  forestProfile: 'pending',
  groundDetailProfile: 'pending',
  atmosphereProfile: 'coherence-fog',
  assetLoadMs: 0,
  grassGroup: null,
  grassMixers: [],
  grassActions: [],
  grassSourceFiles: [],
  grassPatchCount: 0,
  treeLods: {
    lod0: null,
    lod1: null,
    source: null,
  },
  blossomMaterials: [],
  barkMaterials: [],
  uniforms: {
    uTime: { value: 0 },
    uTreeVitality: { value: 0.5 },
    uWitherAmount: { value: 0.25 },
    uWindStrength: { value: 0.035 },
    uAuroraIntensity: { value: 0.65 },
  },
};

function setAssetStatus(status, label) {
  visualSettings.assetStatus = status;
  const loadingStatus = document.getElementById('loadingStatus');
  if (loadingStatus) loadingStatus.textContent = label || status;
  window.__breathStateVrBoot?.mark(label || status);
}

let loadingWatchdog = null;

function hideLoadingOverlay() {
  if (loadingWatchdog) {
    clearTimeout(loadingWatchdog);
    loadingWatchdog = null;
  }
  const el = document.getElementById('loading');
  if (el) el.classList.add('hidden');
}

loadingWatchdog = setTimeout(() => {
  const loading = document.getElementById('loading');
  if (!loading || loading.classList.contains('hidden')) return;
  const sanctuary = window.BreathStateSanctuaryV3;
  if (sanctuary?.snapshot().initialized) {
    console.warn('Sanctuary assets exceeded the startup budget; opening the partial scene.');
    setAssetStatus('partial-fallback', 'Opening scene; remaining assets continue loading');
    hideLoadingOverlay();
  } else {
    window.__breathStateVrBoot?.fail(
      new Error('Renderer did not initialize within 25 seconds'),
    );
  }
}, 25000);

const state = {
  rmssd: 40,
  stressIndex: 150,
  coherence: 0.5,
  heartRate: 70,
  sdnn: 35,
  breathingRate: 6.0,
  signalQuality: 'demo',
};

const sessionState = {
  active: false,
  paused: false,
  live: false,
  demo: true,
  protocol: 'resonance_breathing',
  durationSeconds: 300,
  elapsedSeconds: 0,
  remainingSeconds: 300,
  mode: 'patient',
};

const comfortState = {
  displayMode: 'patient',
  seatedMode: true,
  reducedMotion: false,
  reducedParticles: false,
  highContrastGuide: true,
  largerText: false,
};

const breathState = {
  phase: 'ready',
  phaseLabel: 'Ready',
  phaseProgress: 0,
  cycleProgress: 0,
  secondsRemaining: 0,
  inhaleMs: 5000,
  exhaleMs: 5000,
  targetBpm: 6.0,
};

const sweepState = {
  protocolVersion: 2,
  active: false,
  cycleIndex: 0,
  cycleCount: 78,
  phase: 'inhale',
  phaseProgress: 0,
  scheduledBpm: 6.75,
  halfPeriodMs: 4444.444,
  elapsedMs: 0,
  remainingMs: 894640.523,
  resultMode: null,
  status: 'idle',
  deviceStates: {
    polar: 'disconnected',
    respirationBelt: 'disconnected',
  },
  result: null,
};

let lastResult = null;
let resultSummaryUntil = 0;
const progressState = {
  treeVitalityScore: 50,
  vitalityDelta: 0,
  sessionScore: 0,
  completion: 0,
  averageCoherence: 0,
  unlockedAmbientTier: 1,
  unlockedVisuals: ['single_tree', 'richer_canopy'],
  currentStreaks: {
    building40: 0,
    high70: 0,
    peak85: 0,
    breathSync: 0,
  },
  bestStreaks: {
    building40: 0,
    high70: 0,
    peak85: 0,
    breathSync: 0,
  },
};
const smooth = { ...state };
let demoMode = true;
let demoPhase = 0;
let lastDataTime = 0;
let lastHostMessageTime = -Infinity;
let refreshVrCommandControls = () => {};
const primarySessionCommands = new Set(['start', 'pause', 'resume', 'stop']);
const commandUiState = {
  pending: null,
  message: 'Aim at a control and press the trigger',
  tone: 'neutral',
  until: 0,
};
const canopyValidationState = {
  enabled: canopyValidationMode,
  elapsedSeconds: 0,
  startedAtMs: null,
  stage: canopyValidationMode ? 'sparse' : 'disabled',
  cycleProgress: 0,
  cycleIndex: 0,
  coherence: state.coherence,
};
window.BreathStateCanopyValidation = canopyValidationState;

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function clamp01(value) {
  return clamp(Number.isFinite(value) ? value : 0, 0, 1);
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function smoothstep(edge0, edge1, value) {
  const t = clamp01((value - edge0) / (edge1 - edge0));
  return t * t * (3 - 2 * t);
}

function easeInOut(value) {
  return 0.5 - 0.5 * Math.cos(clamp01(value) * Math.PI);
}

class TreeVitalityState {
  constructor() {
    this.rollingCoherence = 0.5;
    this.vitality = 0.5;
    this.leafDensity = 0.66;
    this.greenSaturation = 0.62;
    this.canopyFullness = 0.86;
    this.trunkGlow = 0.22;
    this.groundSoftness = 0.44;
    this.fallingLeaves = 0.12;
  }

  update(coherence, dt) {
    const c = clamp01(coherence);
    const rollingAlpha = 1 - Math.exp(-dt * 0.18);
    this.rollingCoherence = lerp(this.rollingCoherence, c, rollingAlpha);

    const calm = smoothstep(0.18, 0.92, this.rollingCoherence);
    const strong = smoothstep(0.55, 0.95, this.rollingCoherence);
    const low = smoothstep(0.5, 0.14, this.rollingCoherence);

    this._approach('vitality', 0.22 + calm * 0.78, dt, 0.42, 0.18);
    this._approach('leafDensity', 0.34 + calm * 0.62, dt, 0.36, 0.13);
    this._approach('greenSaturation', 0.34 + calm * 0.56, dt, 0.48, 0.2);
    this._approach('canopyFullness', 0.72 + calm * 0.24, dt, 0.32, 0.12);
    this._approach('trunkGlow', 0.08 + strong * 0.46, dt, 0.58, 0.2);
    this._approach('groundSoftness', 0.18 + calm * 0.58, dt, 0.44, 0.16);
    this._approach('fallingLeaves', 0.04 + low * 0.48, dt, 0.22, 0.34);
  }

  _approach(key, target, dt, upRate, downRate) {
    const current = this[key];
    const rate = target >= current ? upRate : downRate;
    const alpha = 1 - Math.exp(-dt * rate);
    this[key] = lerp(current, target, alpha);
  }

  snapshot() {
    return {
      rollingCoherence: this.rollingCoherence,
      vitality: this.vitality,
      leafDensity: this.leafDensity,
      greenSaturation: this.greenSaturation,
      canopyFullness: this.canopyFullness,
      trunkGlow: this.trunkGlow,
      groundSoftness: this.groundSoftness,
      fallingLeaves: this.fallingLeaves,
    };
  }
}

const treeVitality = new TreeVitalityState();
window.BreathStateTreeVitality = treeVitality;

                                                                                 
class SakuraLeafCloud {
  constructor(canopyOrigin, nMax) {
    this.N_MAX = nMax;
    this.N_ACTIVE = 0;
    this.canopyOrigin = canopyOrigin.clone();
    this._birthTimers = new Float32Array(nMax);
    this._deathTimers = new Float32Array(nMax);
    this._leafScales = new Float32Array(nMax);
    this._leafPhases = new Float32Array(nMax);
    this._basePos = [];
    this._dummy = new THREE.Object3D();
    this._HIDDEN = new THREE.Matrix4().makeScale(0, 0, 0);
    this._burstPending = 0;
    this._peakBloomTimer = 0;
    this._peakActive = false;
    this._lushColor = new THREE.Color(0xffb8ce);
    this._witheredColor = new THREE.Color(0xc8926a);
    this._tempColor = new THREE.Color();
    this._buildPositions();
    this._buildMesh();
  }

  _buildPositions() {
    const goldenRatio = (1 + Math.sqrt(5)) / 2;
    for (let i = 0; i < this.N_MAX; i++) {
      const theta = 2 * Math.PI * i / goldenRatio;
      const cosP = 1 - (i + 0.5) / this.N_MAX;
      const sinP = Math.sqrt(Math.max(0, 1 - cosP * cosP));
      const r = 0.82 + Math.pow(Math.random(), 0.44) * 1.32;
      this._basePos.push(new THREE.Vector3(
        r * sinP * Math.cos(theta),
        Math.abs(r * cosP) * 0.88 + 0.38 + Math.random() * 0.28,
        r * sinP * Math.sin(theta),
      ));
      this._leafScales[i] = 0.62 + Math.random() * 0.72;
      this._leafPhases[i] = Math.random() * Math.PI * 2;
      this._birthTimers[i] = -1;
      this._deathTimers[i] = -1;
    }
  }

  _buildMesh() {
    const mat = new THREE.MeshStandardMaterial({
      color: new THREE.Color(0xffb8ce),
      emissive: new THREE.Color(0xffd0df),
      emissiveIntensity: 0.022,
      roughness: 0.88,
      metalness: 0,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.9,
      alphaTest: 0.04,
      depthWrite: false,
    });
    this.mesh = new THREE.InstancedMesh(
      new THREE.PlaneGeometry(0.074, 0.074),
      mat,
      this.N_MAX,
    );
    this.mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    this.mesh.count = 0;
    this.mesh.frustumCulled = false;
    this.mesh.renderOrder = 3;
    this.mesh.name = 'SakuraLeafCloud';
    for (let i = 0; i < this.N_MAX; i++) {
      this.mesh.setMatrixAt(i, this._HIDDEN);
    }
    this.mesh.instanceMatrix.needsUpdate = true;
  }

  setTexture(texture) {
    if (texture) {
      this.mesh.material.map = texture;
      this.mesh.material.needsUpdate = true;
    }
  }

  update(targetDensity, dt, time, vitality) {
    const targetActive = Math.floor(clamp01(targetDensity) * this.N_MAX);
    const growRate = Math.ceil(this.N_MAX * 0.005);
    const witherRate = Math.ceil(this.N_MAX * 0.008);

    if (this.N_ACTIVE < targetActive) {
      const toAdd = Math.min(growRate, targetActive - this.N_ACTIVE);
      for (let k = 0; k < toAdd; k++) {
        const i = this.N_ACTIVE + k;
        if (i >= this.N_MAX) break;
        this._birthTimers[i] = 0;
        this._deathTimers[i] = -1;
      }
      this.N_ACTIVE = Math.min(this.N_ACTIVE + toAdd, this.N_MAX);
    } else if (this.N_ACTIVE > targetActive) {
      const toRemove = Math.min(witherRate, this.N_ACTIVE - targetActive);
      if (toRemove >= 20) this._burstPending += toRemove;
      for (let k = 0; k < toRemove; k++) {
        const i = this.N_ACTIVE - 1 - k;
        if (i < 0) break;
        this._deathTimers[i] = 0;
      }
      this.N_ACTIVE = Math.max(0, this.N_ACTIVE - toRemove);
    }

    const isPeak = vitality >= 0.94;
    if (isPeak) {
      if (!this._peakActive) { this._peakBloomTimer = 0; this._peakActive = true; }
      this._peakBloomTimer += dt;
      this.mesh.material.emissiveIntensity = 0.042 + Math.abs(Math.sin(this._peakBloomTimer * 1.57)) * 0.028;
    } else {
      this._peakActive = false;
      this.mesh.material.emissiveIntensity = 0.016 + vitality * 0.032;
    }
    this._tempColor.copy(this._lushColor).lerp(this._witheredColor, 1 - vitality);
    this.mesh.material.color.copy(this._tempColor);

    let anyUpdate = false;
    for (let i = 0; i < this.N_MAX; i++) {
      const alive = i < this.N_ACTIVE;
      const born = this._birthTimers[i] >= 0;
      const dying = this._deathTimers[i] >= 0;
      if (!alive && !born && !dying) continue;

      if (born) this._birthTimers[i] += dt;
      if (dying) {
        this._deathTimers[i] += dt;
        if (this._deathTimers[i] > 0.48) {
          this._deathTimers[i] = -1;
          this.mesh.setMatrixAt(i, this._HIDDEN);
          anyUpdate = true;
          continue;
        }
      }
      const birthT = born ? Math.min(this._birthTimers[i] / 0.55, 1) : 1;
      const deathT = dying ? this._deathTimers[i] / 0.48 : 0;
      const scale = this._leafScales[i] * birthT * (1 - deathT * deathT);
      if (scale < 0.001) { this.mesh.setMatrixAt(i, this._HIDDEN); anyUpdate = true; continue; }

      const base = this._basePos[i];
      const swayX = Math.sin(time * 0.68 + this._leafPhases[i]) * 0.058;
      const swayZ = Math.cos(time * 0.51 + this._leafPhases[i] * 0.8) * 0.044;
      this._dummy.position.set(
        this.canopyOrigin.x + base.x + swayX,
        this.canopyOrigin.y + base.y + Math.sin(time * 0.38 + this._leafPhases[i]) * 0.035,
        this.canopyOrigin.z + base.z + swayZ,
      );
      this._dummy.rotation.set(
        this._leafPhases[i] + time * 0.11,
        this._leafPhases[i] * 2.1 + time * 0.07,
        this._leafPhases[i] * 0.55,
      );
      this._dummy.scale.setScalar(scale);
      this._dummy.updateMatrix();
      this.mesh.setMatrixAt(i, this._dummy.matrix);
      anyUpdate = true;
    }
    if (anyUpdate) this.mesh.instanceMatrix.needsUpdate = true;
    this.mesh.count = this.N_ACTIVE;
  }

  takeBurst() {
    const n = this._burstPending;
    this._burstPending = 0;
    return n;
  }
}

let sakuraLeafCloud = null;

const profileState = {
  enabled: visualSettings.debugProfile,
  sceneVersion: visualSettings.sceneVersion,
  startedAt: performance.now(),
  sampleCount: 0,
  frameMs: 0,
  avgFrameMs: 0,
  fps: 0,
  minFps: 0,
  maxFrameMs: 0,
  droppedFrameHints: 0,
  drawCalls: 0,
  triangles: 0,
  geometries: 0,
  textures: 0,
  programs: 0,
  assetLoadMs: 0,
  assetStatus: visualSettings.assetStatus,
  assetProfile: visualSettings.assetProfile,
  textureProfile: visualSettings.textureProfile,
  activeTreeLod: visualSettings.activeTreeLod,
  skyProfile: visualSettings.skyProfile,
  grassProfile: visualSettings.grassProfile,
  landscapeProfile: visualSettings.landscapeProfile,
  forestProfile: visualSettings.forestProfile,
  groundDetailProfile: visualSettings.groundDetailProfile,
  atmosphereProfile: visualSettings.atmosphereProfile,
  fogDensity: visualSettings.fogDensity,
  grassPatchCount: 0,
  grassTriangleCount: 0,
  rockCount: 0,
  flowerPatchCount: 0,
  bushCount: 0,
  detailDrawCallCount: 0,
  grassShadingProfile: 'unknown',
  detailShadingProfile: 'unknown',
  grassRangeUpdateCount: 0,
  detailRangeUpdateCount: 0,
  atmosphereRangeUpdateCount: 0,
  petalBufferUpdateCount: 0,
  fallingRenderer: 'none',
  petalPatchCount: 0,
  starCount: 0,
  fireflyCount: 0,
  adaptiveQualityLevel: 'full',
  performanceScale: 1,
  rendererPixelRatio: 0,
  framebufferScale: 1,
  foveation: 0,
  contextLosses: 0,
  contextRestores: 0,
  sanctuaryPineCount: 0,
  sanctuaryHillCount: 0,
  visualQuality: visualSettings.visualQuality,
  xrPresenting: false,
  canopyMode: 'pending',
  canopyStatus: 'pending',
  canopyValidationStage: canopyValidationState.stage,
  canopyValidationElapsedSeconds: 0,
  activeLeafCount: 0,
  activeBlossomCount: 0,
  canopyTransitionFrames: 0,
  canopyAverageTransitionFrameMs: 0,
  canopyMaxTransitionFrameMs: 0,
  canopySlowTransitionFrames: 0,
  canopyIntegrityFailures: 0,
};
window.BreathStateVrProfile = profileState;
window.BreathStateVrVisualSettings = visualSettings;

let channel = null;
try {
  channel = new BroadcastChannel('breathstate_hrv_vr');
  channel.onmessage = (event) => {
    if (event.data && typeof event.data === 'object') {
      applyHostMessage(event.data);
    }
  };
} catch (e) {
  console.warn('BroadcastChannel not available:', e);
}

const nativeBridgeToken = urlParams.get('bridgeToken');
let nativeSocket = null;
let nativeReconnectTimer = null;

function connectNativeBridge() {
  if (!nativeBridgeToken || nativeSocket?.readyState === WebSocket.OPEN) return;
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const endpoint = new URL('/bridge', `${protocol}//${window.location.host}`);
  endpoint.searchParams.set('token', nativeBridgeToken);

  try {
    nativeSocket = new WebSocket(endpoint);
    nativeSocket.onopen = () => {
      commandUiState.message = 'Connected to BreathState';
      commandUiState.tone = 'success';
      commandUiState.until = performance.now() + 2400;
      refreshVrCommandControls();
    };
    nativeSocket.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        if (message && typeof message === 'object') applyHostMessage(message);
      } catch (error) {
        console.warn('Ignored malformed native bridge message:', error);
      }
    };
    nativeSocket.onclose = () => {
      nativeSocket = null;
      clearTimeout(nativeReconnectTimer);
      nativeReconnectTimer = setTimeout(connectNativeBridge, 1000);
    };
    nativeSocket.onerror = () => nativeSocket?.close();
  } catch (error) {
    console.warn('Native WebXR bridge connection failed:', error);
    clearTimeout(nativeReconnectTimer);
    nativeReconnectTimer = setTimeout(connectNativeBridge, 1000);
  }
}

connectNativeBridge();
window.addEventListener('beforeunload', () => {
  clearTimeout(nativeReconnectTimer);
  nativeSocket?.close();
});

function normalizeCoherence(value) {
  if (!Number.isFinite(value)) return state.coherence;
  return value > 1 ? clamp01(value / 100) : clamp01(value);
}

function applyMetrics(metrics = {}) {
  if (Number.isFinite(metrics.rmssd)) state.rmssd = metrics.rmssd;
  if (Number.isFinite(metrics.stressIndex)) state.stressIndex = metrics.stressIndex;
  if (Number.isFinite(metrics.coherence)) state.coherence = normalizeCoherence(metrics.coherence);
  if (Number.isFinite(metrics.heartRate)) state.heartRate = metrics.heartRate;
  if (Number.isFinite(metrics.sdnn)) state.sdnn = metrics.sdnn;
  if (Number.isFinite(metrics.breathingRate)) state.breathingRate = metrics.breathingRate;
  if (typeof metrics.signalQuality === 'string') state.signalQuality = metrics.signalQuality;
  if (metrics.resonanceSweep) applySweep(metrics.resonanceSweep);
}

function applyBreath(breath = {}) {
  Object.assign(breathState, breath);
  if (Number.isFinite(breath.targetBpm)) {
    state.breathingRate = breath.targetBpm;
  }
}

function applySweep(sweep = {}) {
  if (!sweep || typeof sweep !== 'object') return;
  if (Number(sweep.protocolVersion) === 2) {
    for (const key of [
      'protocolVersion',
      'cycleIndex',
      'cycleCount',
      'phaseProgress',
      'scheduledBpm',
      'halfPeriodMs',
      'elapsedMs',
      'remainingMs',
    ]) {
      if (Number.isFinite(sweep[key])) sweepState[key] = sweep[key];
    }
    for (const key of ['phase', 'resultMode', 'status', 'message', 'abortReason']) {
      if (typeof sweep[key] === 'string') sweepState[key] = sweep[key];
    }
    if (typeof sweep.active === 'boolean') sweepState.active = sweep.active;
    if (sweep.deviceStates && typeof sweep.deviceStates === 'object') {
      sweepState.deviceStates = { ...sweepState.deviceStates, ...sweep.deviceStates };
    }
    if (sweep.result && typeof sweep.result === 'object') {
      sweepState.result = sweep.result;
    }
    state.breathingRate = sweepState.scheduledBpm;
    breathState.phase = sweepState.phase;
    breathState.phaseLabel = sweepState.phase === 'exhale' ? 'Exhale' : 'Inhale';
    breathState.phaseProgress = sweepState.phaseProgress;
    breathState.targetBpm = sweepState.scheduledBpm;
    breathState.inhaleMs = sweepState.halfPeriodMs;
    breathState.exhaleMs = sweepState.halfPeriodMs;
    breathState.secondsRemaining = Math.max(
      0,
      Math.ceil((sweepState.halfPeriodMs * (1 - sweepState.phaseProgress)) / 1000),
    );
    sessionState.elapsedSeconds = sweepState.elapsedMs / 1000;
    sessionState.remainingSeconds = sweepState.remainingMs / 1000;
    return;
  }

                                                      
  const legacyRate = Number(sweep.optimalBreathingRateBpm || sweep.bestRateBpm || sweep.currentRateBpm);
  if (Number.isFinite(legacyRate) && legacyRate > 0) {
    sweepState.scheduledBpm = legacyRate;
    state.breathingRate = legacyRate;
  }
}

function applyComfortOptions(options = {}) {
  const mode = options.displayMode || options.mode;
  if (mode === 'patient' || mode === 'clinician') {
    comfortState.displayMode = mode;
  }
  for (const key of [
    'seatedMode',
    'reducedMotion',
    'reducedParticles',
    'highContrastGuide',
    'largerText',
  ]) {
    if (typeof options[key] === 'boolean') comfortState[key] = options[key];
  }
}

function sendComfortOptions(extra = {}) {
  applyComfortOptions(extra);
  sendCommand('set_comfort_options', { ...comfortState, ...extra });
  updateDomControls();
}

function applyTreeProgress(tree = {}) {
  if (Number.isFinite(tree.treeVitalityScore)) {
    progressState.treeVitalityScore = clamp(tree.treeVitalityScore, 0, 100);
  }
  if (Number.isFinite(tree.vitalityDelta)) progressState.vitalityDelta = tree.vitalityDelta;
  if (Number.isFinite(tree.sessionScore)) progressState.sessionScore = clamp(tree.sessionScore, 0, 100);
  if (Number.isFinite(tree.completion)) progressState.completion = clamp01(tree.completion);
  if (Number.isFinite(tree.averageCoherence)) progressState.averageCoherence = clamp(tree.averageCoherence, 0, 100);
  if (Number.isFinite(tree.unlockedAmbientTier)) {
    progressState.unlockedAmbientTier = clamp(Math.round(tree.unlockedAmbientTier), 0, 4);
  }
  if (Array.isArray(tree.unlockedVisuals)) {
    progressState.unlockedVisuals = tree.unlockedVisuals.map(String);
  }
  if (tree.currentStreaks && typeof tree.currentStreaks === 'object') {
    Object.assign(progressState.currentStreaks, tree.currentStreaks);
  }
  if (tree.bestStreaks && typeof tree.bestStreaks === 'object') {
    Object.assign(progressState.bestStreaks, tree.bestStreaks);
  }
  if (tree.progress && typeof tree.progress === 'object') {
    let progressTier = progressState.unlockedAmbientTier;
    if (Number.isFinite(tree.progress.unlockedAmbientTier)) {
      progressTier = clamp(Math.round(tree.progress.unlockedAmbientTier), 0, 4);
      progressState.unlockedAmbientTier = Math.max(
        progressState.unlockedAmbientTier,
        progressTier,
      );
    }
    if (Array.isArray(tree.progress.unlockedVisuals) && progressTier >= progressState.unlockedAmbientTier) {
      progressState.unlockedVisuals = tree.progress.unlockedVisuals.map(String);
    }
  }
}

function applyHostMessage(message) {
  if (message.source === 'webxr') return;
  lastHostMessageTime = performance.now();

  if (message.version === 1 && typeof message.type === 'string') {
    if (message.session) Object.assign(sessionState, message.session);
    if (message.session?.resonanceSweep) applySweep(message.session.resonanceSweep);
    if (message.session?.comfortOptions) {
      applyComfortOptions({
        ...message.session.comfortOptions,
        displayMode: message.session.displayMode || message.session.mode,
      });
    } else if (message.session?.displayMode || message.session?.mode) {
      applyComfortOptions({
        displayMode: message.session.displayMode || message.session.mode,
      });
    }
    if (message.metrics) applyMetrics(message.metrics);
    if (message.breath) applyBreath(message.breath);
    if (message.tree) applyTreeProgress(message.tree);
    if (message.type === 'session_result') {
      lastResult = message.result || null;
      if (message.result?.resonanceSweep) applySweep(message.result.resonanceSweep);
      if (message.tree) applyTreeProgress(message.tree);
      resultSummaryUntil = performance.now() + 24000;
      resultPanel.visible = true;
      renderResultText();
    }
    if (message.type === 'error') {
      sessionState.lastError = message.error?.message || 'Host error';
      commandUiState.pending = null;
      commandUiState.message = sessionState.lastError;
      commandUiState.tone = 'error';
      commandUiState.until = performance.now() + 9000;
    } else if (message.session) {
      const pending = commandUiState.pending;
      const acknowledged = pending === 'start'
        ? sessionState.starting || sessionState.active
        : pending === 'pause'
          ? sessionState.active && sessionState.paused
          : pending === 'resume'
            ? sessionState.active && !sessionState.paused
            : pending === 'stop'
              ? !sessionState.active && !sessionState.starting
              : false;
      if (acknowledged) {
        commandUiState.pending = null;
        commandUiState.message = `${pending[0].toUpperCase()}${pending.slice(1)} confirmed`;
        commandUiState.tone = 'success';
        commandUiState.until = performance.now() + 2200;
        sessionState.lastError = null;
      }
    }
  } else {
    applyMetrics(message);
  }

  demoMode = !sessionState.active && !sessionState.live;
  lastDataTime = performance.now();
  updateStatusIndicator(demoMode);
  updateDomControls();
}

function setCommandFeedback(message, tone = 'neutral', durationMs = 2600) {
  commandUiState.message = message;
  commandUiState.tone = tone;
  commandUiState.until = performance.now() + durationMs;
  refreshVrCommandControls();
}

function applyDemoSessionCommand(command) {
  if (command === 'start' && !sessionState.active) {
    sessionState.active = true;
    sessionState.paused = false;
    sessionState.starting = false;
    sessionState.live = false;
    sessionState.demo = true;
    sessionState.elapsedSeconds = 0;
    sessionState.remainingSeconds = sessionState.durationSeconds || 300;
    sessionState.lastError = null;
    setCommandFeedback('Demo session started', 'success');
  } else if (command === 'pause' && sessionState.active && !sessionState.paused) {
    sessionState.paused = true;
    setCommandFeedback('Session paused', 'success');
  } else if (command === 'resume' && sessionState.active && sessionState.paused) {
    sessionState.paused = false;
    setCommandFeedback('Session resumed', 'success');
  } else if (command === 'stop' && sessionState.active) {
    sessionState.active = false;
    sessionState.paused = false;
    breathState.phase = 'ready';
    breathState.phaseLabel = 'Ready';
    breathState.phaseProgress = 0;
    breathState.secondsRemaining = 0;
    setCommandFeedback('Demo session complete', 'success');
  } else {
    setCommandFeedback('That control is not available right now', 'warning');
  }
  updateDomControls();
}

function sendCommand(command, payload = {}) {
  const message = {
    version: 1,
    source: 'webxr',
    type: 'command',
    command,
    payload,
    timestamp: new Date().toISOString(),
  };
  try {
    channel?.postMessage(message);
  } catch (error) {
    console.warn('Unable to post WebXR command:', error);
  }
  const nativeConnected = nativeSocket?.readyState === WebSocket.OPEN;
  if (nativeConnected) {
    nativeSocket.send(JSON.stringify(message));
  }
  const hostRecentlySeen = performance.now() - lastHostMessageTime < 12000;
  if (primarySessionCommands.has(command)) {
    if (!nativeConnected && !hostRecentlySeen) {
      applyDemoSessionCommand(command);
      return false;
    }
    if (command === 'start') sessionState.lastError = null;
    commandUiState.pending = command;
    setCommandFeedback(
      `${command[0].toUpperCase()}${command.slice(1)} requested...`,
      'pending',
      7000,
    );
  }
  return nativeConnected || hostRecentlySeen;
}

function updateStatusIndicator(isDemo) {
  const dot = document.getElementById('statusDot');
  const text = document.getElementById('statusText');
  if (!dot || !text) return;
  if (isDemo) {
    dot.className = 'dot demo';
    text.textContent = 'Demo mode';
  } else {
    dot.className = 'dot live';
    text.textContent = `Live - HR ${Math.round(state.heartRate)} bpm`;
  }
}

const domControls = document.createElement('div');
Object.assign(domControls.style, {
  position: 'fixed',
  left: '50%',
  bottom: '18px',
  transform: 'translateX(-50%)',
  display: 'flex',
  flexWrap: 'wrap',
  justifyContent: 'center',
  gap: '8px',
  width: 'calc(100% - 32px)',
  maxWidth: '960px',
  boxSizing: 'border-box',
  maxHeight: '42vh',
  overflowY: 'auto',
  padding: '10px',
  border: '1px solid rgba(74,222,128,0.3)',
  borderRadius: '14px',
  background: 'rgba(8,19,25,0.76)',
  backdropFilter: 'blur(10px)',
  zIndex: '60',
});
document.body.appendChild(domControls);

const protocolSelect = document.createElement('select');
for (const [value, label] of [
  ['resonance_breathing', 'Resonance'],
  ['resonance_sweep', 'Precise RF (78 breaths)'],
]) {
  const option = document.createElement('option');
  option.value = value;
  option.textContent = label;
  protocolSelect.appendChild(option);
}
Object.assign(protocolSelect.style, {
  border: '0',
  borderRadius: '10px',
  padding: '8px 10px',
  background: 'rgba(2,6,23,0.86)',
  color: '#e2e8f0',
});
protocolSelect.onchange = () => {
  sendCommand('set_protocol', { protocol: protocolSelect.value });
};
domControls.appendChild(protocolSelect);

const durationSelect = document.createElement('select');
for (const minutes of [3, 5, 10, 15]) {
  const option = document.createElement('option');
  option.value = String(minutes);
  option.textContent = `${minutes} min`;
  if (minutes === 5) option.selected = true;
  durationSelect.appendChild(option);
}
Object.assign(durationSelect.style, {
  border: '0',
  borderRadius: '10px',
  padding: '8px 10px',
  background: 'rgba(2,6,23,0.86)',
  color: '#e2e8f0',
});
durationSelect.onchange = () => {
  sendCommand('set_duration', { minutes: Number(durationSelect.value) });
};
domControls.appendChild(durationSelect);

const domButtons = {};
for (const [label, command, color] of [
  ['Start', 'start', '#4ade80'],
  ['Pause', 'pause', '#fbbf24'],
  ['Resume', 'resume', '#38bdf8'],
  ['Stop', 'stop', '#fb7185'],
]) {
  const button = document.createElement('button');
  button.textContent = label;
  Object.assign(button.style, {
    border: '0',
    borderRadius: '10px',
    padding: '8px 12px',
    font: '600 13px system-ui, sans-serif',
    color: '#07111f',
    background: color,
  });
  button.onclick = () => sendCommand(command);
  domButtons[command] = button;
  domControls.appendChild(button);
}

const modeSelect = document.createElement('select');
for (const [value, label] of [
  ['patient', 'Patient'],
  ['clinician', 'Clinician'],
]) {
  const option = document.createElement('option');
  option.value = value;
  option.textContent = label;
  modeSelect.appendChild(option);
}
Object.assign(modeSelect.style, {
  border: '0',
  borderRadius: '10px',
  padding: '8px 10px',
  background: 'rgba(2,6,23,0.86)',
  color: '#e2e8f0',
});
modeSelect.onchange = () => {
  sendComfortOptions({ displayMode: modeSelect.value });
};
domControls.appendChild(modeSelect);

const recenterButton = document.createElement('button');
recenterButton.textContent = 'Recenter';
Object.assign(recenterButton.style, {
  border: '0',
  borderRadius: '10px',
  padding: '8px 10px',
  font: '600 12px system-ui, sans-serif',
  color: '#07111f',
  background: '#d8fff0',
});
recenterButton.onclick = () => recenterExperience(true);
domControls.appendChild(recenterButton);

function updateDomControls() {
  const durationMinutes = Math.round((sessionState.durationSeconds || 300) / 60);
  if (!sessionState.active && ['3', '5', '10', '15'].includes(String(durationMinutes))) {
    durationSelect.value = String(durationMinutes);
  }
  protocolSelect.value = sessionState.protocol || 'resonance_breathing';
  modeSelect.value = comfortState.displayMode;
  domButtons.start.disabled = sessionState.active;
  domButtons.pause.disabled = !sessionState.active || sessionState.paused;
  domButtons.resume.disabled = !sessionState.active || !sessionState.paused;
  domButtons.stop.disabled = !sessionState.active;
  durationSelect.disabled = sessionState.active || sessionState.protocol === 'resonance_sweep';
  protocolSelect.disabled = sessionState.active;
  for (const button of Object.values(domButtons)) {
    button.style.opacity = button.disabled ? '0.42' : '1';
  }
  durationSelect.style.opacity = durationSelect.disabled ? '0.42' : '1';
  protocolSelect.style.opacity = protocolSelect.disabled ? '0.42' : '1';
  refreshVrCommandControls();
}

updateDomControls();

const scene = new THREE.Scene();
scene.background = SKY_LOW;
scene.fog = new THREE.FogExp2(FOG_LOW.getHex(), 0.036);

const legacySceneRoot = new THREE.Group();
legacySceneRoot.name = 'LegacySceneV2_Root';
legacySceneRoot.visible = useLegacyScene;
scene.add(legacySceneRoot);

function addLegacyVisual(object) {
  legacySceneRoot.add(object);
  return object;
}

const camera = new THREE.PerspectiveCamera(
  70,
  window.innerWidth / window.innerHeight,
  0.1,
  100,
);
camera.position.set(0, 1.62, 1.8);
camera.lookAt(TREE_POS.x, 1.95, TREE_POS.z);
camera.layers.enableAll();

const questRendererPolicy = visualSettings.visualQuality === 'quest';
const rendererPolicy = Object.freeze({
  pixelRatioCap: questRendererPolicy ? 1.25 : 1.75,
  framebufferScale: questRendererPolicy ? 0.78 : 1,
  foveation: questRendererPolicy ? 0.78 : 0.18,
});

const renderer = new THREE.WebGLRenderer({
  antialias: !questRendererPolicy,
  alpha: false,
  depth: true,
  stencil: false,
  powerPreference: 'high-performance',
});
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, rendererPolicy.pixelRatioCap));
renderer.xr.enabled = true;
renderer.xr.setFramebufferScaleFactor(rendererPolicy.framebufferScale);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.16;
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.shadowMap.enabled = visualSettings.visualQuality === 'high';
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
document.body.appendChild(renderer.domElement);

const vrDiagnostics = {
  version: 2,
  sceneVersion: activeSceneVersion,
  quality: visualSettings.visualQuality,
  startedAt: new Date().toISOString(),
  renderer: {
    pixelRatio: renderer.getPixelRatio(),
    framebufferScale: rendererPolicy.framebufferScale,
    foveation: rendererPolicy.foveation,
    requestedFrameRate: null,
    webgl2: renderer.capabilities.isWebGL2,
    maxTextureSize: renderer.capabilities.maxTextureSize,
    maxAnisotropy: renderer.capabilities.getMaxAnisotropy(),
  },
  contextLosses: 0,
  contextRestores: 0,
  xrSessionStarts: 0,
  xrSessionEnds: 0,
  events: [],
};

function recordVrDiagnostic(type, detail = '') {
  vrDiagnostics.events.push({
    type,
    detail: String(detail || ''),
    elapsedMs: Math.round(performance.now()),
  });
  if (vrDiagnostics.events.length > 24) vrDiagnostics.events.shift();
}

window.BreathStateVrDiagnostics = vrDiagnostics;
window.getBreathStateVrDiagnostics = () => {
  const snapshot = window.BreathStateSanctuaryV3?.snapshot();
  const sanctuary = snapshot ? {
    sceneVersion: snapshot.sceneVersion,
    quality: snapshot.quality,
    assetStatus: snapshot.assetStatus,
    treeStatus: snapshot.treeStatus,
    landscapeStatus: snapshot.landscapeStatus,
    grassStatus: snapshot.grassStatus,
    detailStatus: snapshot.detailStatus,
    petalStatus: snapshot.petalStatus,
    atmosphereStatus: snapshot.atmosphereStatus,
    moonStatus: snapshot.moonStatus,
    auroraStatus: snapshot.auroraStatus,
    adaptiveQualityLevel: snapshot.adaptiveQualityLevel,
    appliedPerformanceScale: snapshot.appliedPerformanceScale,
    performanceTierForced: snapshot.performanceTierForced,
    activeGrassInstances: snapshot.activeGrassInstances,
    activeGrassTriangles: snapshot.activeGrassTriangles,
    activeDetailDrawCalls: snapshot.activeDetailDrawCalls,
    activeDetailMeshInstances: snapshot.activeDetailMeshInstances,
    fallingRenderer: snapshot.fallingRenderer,
    activeStarCount: snapshot.activeStarCount,
    activeFireflies: snapshot.activeFireflies,
    assetLoadMs: snapshot.assetLoadMs,
    canopyMode: snapshot.canopyMode,
    canopyStatus: snapshot.canopyStatus,
    activeLeafCount: snapshot.activeLeafCount,
    activeBlossomCount: snapshot.activeBlossomCount,
    targetLeafCount: snapshot.targetLeafCount,
    targetBlossomCount: snapshot.targetBlossomCount,
    fullBloom: snapshot.treeVisualState?.fullBloom === true,
    fullBloomBlend: snapshot.fullBloomBlend,
    canopyTransitionFrames: snapshot.canopyTransitionFrames,
    canopyAverageTransitionFrameMs: snapshot.canopyAverageTransitionFrameMs,
    canopyMaxTransitionFrameMs: snapshot.canopyMaxTransitionFrameMs,
    canopySlowTransitionFrames: snapshot.canopySlowTransitionFrames,
    canopyIntegrityFailures: snapshot.canopyIntegrityFailures,
    canopyLastIntegrityIssue: snapshot.canopyLastIntegrityIssue,
  } : null;
  return {
    ...vrDiagnostics,
    renderer: { ...vrDiagnostics.renderer },
    events: vrDiagnostics.events.map((event) => ({ ...event })),
    sanctuary,
    canopyValidation: {
      ...canopyValidationState,
      liveDataAuthoritative: !demoMode,
    },
  };
};

renderer.domElement.addEventListener('webglcontextlost', (event) => {
  event.preventDefault();
  vrDiagnostics.contextLosses += 1;
  recordVrDiagnostic('webgl-context-lost');
  const loading = document.getElementById('loading');
  loading?.classList.remove('hidden', 'error');
  setAssetStatus('recovering', 'Graphics paused; restoring VR renderer...');
});

renderer.domElement.addEventListener('webglcontextrestored', () => {
  vrDiagnostics.contextRestores += 1;
  recordVrDiagnostic('webgl-context-restored');
  renderer.resetState();
  scene.traverse((object) => {
    const materials = Array.isArray(object.material) ? object.material : [object.material];
    for (const material of materials) {
      if (material) material.needsUpdate = true;
    }
  });
  setAssetStatus('ready', 'VR renderer restored');
  setTimeout(hideLoadingOverlay, 450);
});

renderer.domElement.addEventListener('webglcontextcreationerror', (event) => {
  const detail = event.statusMessage || 'WebGL context creation failed';
  recordVrDiagnostic('webgl-context-creation-error', detail);
  window.__breathStateVrBoot?.fail(new Error(detail));
});

const vrButton = VRButton.createButton(renderer);
vrButton.style.borderRadius = '14px';
vrButton.style.fontFamily = 'system-ui, sans-serif';
vrButton.style.fontWeight = '600';
document.body.appendChild(vrButton);

function layoutDomOverlays() {
  const controlsHeight = domControls.getBoundingClientRect().height;
  vrButton.style.bottom = `${Math.ceil(controlsHeight + 28)}px`;
}
requestAnimationFrame(layoutDomOverlays);

const sanctuarySceneV3 = useLegacyScene
  ? null
  : new SanctuarySceneV3({
      quality: visualSettings.visualQuality,
      performanceTier,
    });

function applySanctuarySnapshot(snapshot) {
  if (!snapshot) return;
  visualSettings.assetStatus = snapshot.assetStatus;
  visualSettings.assetProfile = 'sanctuary-v3-yoshino';
  visualSettings.textureProfile = !snapshot.treeSource
    ? 'pending'
    : snapshot.treeSource.includes('source')
      ? 'embedded-source'
      : 'embedded-webp';
  visualSettings.activeTreeLod = snapshot.activeTreeLod || 'none';
  visualSettings.assetLoadMs = snapshot.assetLoadMs || 0;
  visualSettings.landscapeProfile = snapshot.activeLandscapeLod || 'none';
  visualSettings.grassProfile = snapshot.grassStatus === 'ready'
    ? `v3-instanced-${snapshot.grassInstances || 0}`
    : 'none';
  visualSettings.groundDetailProfile = snapshot.detailStatus === 'ready'
    ? `v3-organic-${snapshot.detailInstances || 0}`
    : 'none';
  visualSettings.skyProfile = snapshot.atmosphereStatus === 'ready'
    ? `v3-procedural-stars-${snapshot.starCount || 0}`
    : 'foundation';
  visualSettings.atmosphereProfile = snapshot.atmosphereStatus === 'ready'
    ? `v3-moon-aurora-fireflies-${snapshot.fireflyCount || 0}`
    : 'foundation-fog';
  visualSettings.fogDensity = snapshot.fogDensity || scene.fog?.density || 0;
}

if (sanctuarySceneV3) {
  const snapshot = sanctuarySceneV3.initialize({ scene, camera, renderer });
  applySanctuarySnapshot(snapshot);
  visualSettings.skyProfile = 'foundation';
  visualSettings.grassProfile = 'none';
  visualSettings.forestProfile = 'none';
  visualSettings.groundDetailProfile = 'none';
  visualSettings.atmosphereProfile = 'foundation-fog';
  visualSettings.fogDensity = scene.fog?.density || 0;
  window.BreathStateSanctuaryV3 = sanctuarySceneV3;
}

const profileDom = document.createElement('pre');
if (profileState.enabled) {
  Object.assign(profileDom.style, {
    position: 'fixed',
    top: '12px',
    right: '12px',
    zIndex: '30',
    margin: '0',
    padding: '10px 12px',
    minWidth: '250px',
    borderRadius: '12px',
    border: '1px solid rgba(167, 243, 208, 0.32)',
    background: 'rgba(4, 12, 18, 0.76)',
    color: '#d8fff0',
    font: '12px/1.45 ui-monospace, SFMono-Regular, Consolas, monospace',
    pointerEvents: 'none',
    whiteSpace: 'pre',
  });
  profileDom.textContent = 'Quest Profile\nwarming up...';
  document.body.appendChild(profileDom);
}

const hemiLight = new THREE.HemisphereLight(0xe2fff2, 0x182719, 1.22);
addLegacyVisual(hemiLight);

const moonLight = new THREE.DirectionalLight(0xe6f8ff, 1.62);
moonLight.position.set(MOON_POS.x, MOON_POS.y, 2.6);
moonLight.castShadow = visualSettings.visualQuality === 'high';
addLegacyVisual(moonLight);

const warmFillLight = new THREE.DirectionalLight(0xffdfb0, 0.48);
warmFillLight.position.set(3.2, 2.4, 4.4);
addLegacyVisual(warmFillLight);

const canopyLight = new THREE.PointLight(0x74f0a6, 1.1, 7);
canopyLight.position.set(TREE_POS.x, 2.8, TREE_POS.z + 0.1);
addLegacyVisual(canopyLight);

const groundLight = new THREE.PointLight(0x9ee6c0, 0.55, 5);
groundLight.position.set(TREE_POS.x, 0.22, TREE_POS.z + 0.1);
addLegacyVisual(groundLight);

const skyGeo = new THREE.SphereGeometry(60, 40, 20);
const skyMat = new THREE.ShaderMaterial({
  uniforms: {
    topColor: { value: SKY_TOP.clone() },
    horizonColor: { value: SKY_HORIZON.clone() },
    lowColor: { value: SKY_LOW.clone() },
    skyMap: { value: null },
    useSkyMap: { value: 0 },
    uTime: { value: 0 },
  },
  vertexShader: `
    varying vec3 vWorldPos;
    void main() {
      vWorldPos = (modelMatrix * vec4(position, 1.0)).xyz;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    uniform vec3 topColor;
    uniform vec3 horizonColor;
    uniform vec3 lowColor;
    uniform sampler2D skyMap;
    uniform float useSkyMap;
    uniform float uTime;
    varying vec3 vWorldPos;
    float sky_hash(vec2 p) {
      return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
    }
    void main() {
      vec3 dir = normalize(vWorldPos);
      float h = dir.y * 0.5 + 0.5;
      vec3 lower = mix(lowColor, horizonColor, smoothstep(0.0, 0.58, h));
      vec3 color = mix(lower, topColor, smoothstep(0.48, 1.0, h));
      float u = atan(dir.z, dir.x) / 6.28318530718 + 0.5;
      float v = asin(clamp(dir.y, -1.0, 1.0)) / 3.14159265359 + 0.5;
      vec3 mapped = texture2D(skyMap, vec2(u, 1.0 - v)).rgb;
      color = mix(color, mapped, useSkyMap * 0.0);
      float zenith = smoothstep(0.06, 0.92, dir.y);
      float horizonMist = 1.0 - smoothstep(0.02, 0.22, abs(dir.y));
      color = mix(color, horizonColor, horizonMist * 0.26);
      color *= 0.48 + zenith * 0.44;
      gl_FragColor = vec4(color, 1.0);
    }
  `,
  side: THREE.BackSide,
  depthWrite: false,
});
const skyDome = new THREE.Mesh(skyGeo, skyMat);
addLegacyVisual(skyDome);

const starCount = useLegacyScene
  ? (visualSettings.visualQuality === 'high' ? 14000 : 9000)
  : 0;
const starPositions = new Float32Array(starCount * 3);
const starSeeds = new Float32Array(starCount);
const starSizes = new Float32Array(starCount);
for (let i = 0; i < starCount; i++) {
  const theta = Math.random() * TWO_PI;
  const y = 6 + Math.pow(Math.random(), 0.55) * 42;
  const radius = 38 + Math.random() * 22;
  starPositions[i * 3] = Math.cos(theta) * radius;
  starPositions[i * 3 + 1] = y;
  starPositions[i * 3 + 2] = Math.sin(theta) * radius;
  starSeeds[i] = Math.random();
  starSizes[i] = 1.0 + Math.random() * 1.45;
}
const starGeo = new THREE.BufferGeometry();
starGeo.setAttribute('position', new THREE.BufferAttribute(starPositions, 3));
starGeo.setAttribute('starSeed', new THREE.BufferAttribute(starSeeds, 1));
starGeo.setAttribute('starSize', new THREE.BufferAttribute(starSizes, 1));
const starMat = new THREE.ShaderMaterial({
  uniforms: {
    uTime: sceneAssets.uniforms.uTime,
    uReducedMotion: { value: 0 },
    uTwinkleStrength: { value: 1 },
    uStarOpacity: { value: 1 },
  },
  vertexShader: `
    attribute float starSeed;
    attribute float starSize;
    varying float vStarAlpha;
    varying float vStarTone;
    uniform float uTime;
    uniform float uReducedMotion;
    uniform float uTwinkleStrength;
    uniform float uStarOpacity;
    void main() {
      float motion = mix(1.0, 0.34, uReducedMotion);
      float slow = sin(uTime * motion * (0.22 + starSeed * 0.48) + starSeed * 73.7);
      float quick = sin(uTime * motion * (0.82 + starSeed * 1.15) + starSeed * 19.3);
      float pulse = sin(uTime * motion * (0.09 + starSeed * 0.16) + starSeed * 127.4);
      float twinkle = smoothstep(-0.42, 0.86, slow * 0.62 + quick * 0.24 + pulse * 0.14);
      float wink = smoothstep(0.72, 1.0, sin(uTime * motion * (0.16 + starSeed * 0.36) + starSeed * 211.1) * 0.5 + 0.5);
      vStarAlpha = mix(0.07, 0.84, twinkle) * (0.82 + wink * 0.28) * uTwinkleStrength * uStarOpacity;
      vStarTone = starSeed;
      vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
      gl_Position = projectionMatrix * mvPosition;
      gl_PointSize = clamp(starSize * (88.0 / max(14.0, -mvPosition.z)) * (0.9 + wink * 0.16), 0.55, 2.25);
    }
  `,
  fragmentShader: `
    varying float vStarAlpha;
    varying float vStarTone;
    void main() {
      vec2 p = gl_PointCoord - 0.5;
      float d = length(p) * 2.0;
      float core = 1.0 - smoothstep(0.12, 0.92, d);
      core *= 0.78 + (1.0 - smoothstep(0.0, 0.28, d)) * 0.42;
      if (core <= 0.01) discard;
      vec3 cool = vec3(0.70, 0.84, 1.0);
      vec3 warm = vec3(1.0, 0.92, 0.76);
      vec3 color = mix(cool, warm, smoothstep(0.76, 1.0, vStarTone) * 0.45);
      gl_FragColor = vec4(color, core * vStarAlpha);
    }
  `,
  transparent: true,
  depthTest: true,
  depthWrite: false,
  blending: THREE.AdditiveBlending,
  toneMapped: false,
});
const starField = new THREE.Points(starGeo, starMat);
starField.name = 'Procedural_Twinkling_Stars';
starField.renderOrder = -6;
addLegacyVisual(starField);

function tuneTexture(texture, {
  repeatX = 1,
  repeatY = 1,
  colorSpace = THREE.SRGBColorSpace,
  anisotropy = 4,
  mapping = null,
} = {}) {
  texture.colorSpace = colorSpace;
  if (mapping) texture.mapping = mapping;
  texture.wrapS = repeatX === 1 ? THREE.ClampToEdgeWrapping : THREE.RepeatWrapping;
  texture.wrapT = repeatY === 1 ? THREE.ClampToEdgeWrapping : THREE.RepeatWrapping;
  texture.repeat.set(repeatX, repeatY);
  texture.anisotropy = Math.min(anisotropy, renderer.capabilities.getMaxAnisotropy());
  texture.needsUpdate = true;
  return texture;
}

function createRadialTexture(inner, mid, outer) {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = 512;
  const ctx = canvas.getContext('2d');
  const grad = ctx.createRadialGradient(256, 256, 8, 256, 256, 256);
  grad.addColorStop(0, inner);
  grad.addColorStop(0.46, mid);
  grad.addColorStop(1, outer);
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  return tuneTexture(new THREE.CanvasTexture(canvas));
}

function createBarkTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = 1024;
  const ctx = canvas.getContext('2d');
  const base = ctx.createLinearGradient(0, 0, canvas.width, 0);
  base.addColorStop(0, '#392719');
  base.addColorStop(0.32, '#6b4a32');
  base.addColorStop(0.58, '#3f2b1d');
  base.addColorStop(1, '#7a5437');
  ctx.fillStyle = base;
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  for (let i = 0; i < 150; i++) {
    const x = Math.random() * canvas.width;
    const width = 2 + Math.random() * 11;
    const alpha = 0.12 + Math.random() * 0.24;
    const yOffset = Math.random() * 120;
    ctx.strokeStyle = i % 3 === 0
      ? `rgba(24,16,10,${alpha + 0.12})`
      : `rgba(210,156,92,${alpha})`;
    ctx.lineWidth = width;
    ctx.beginPath();
    ctx.moveTo(x, -20);
    for (let y = -20; y <= canvas.height + 40; y += 54) {
      ctx.lineTo(
        x + Math.sin((y + yOffset) * 0.018) * (8 + Math.random() * 10),
        y,
      );
    }
    ctx.stroke();
  }

  for (let i = 0; i < 280; i++) {
    const x = Math.random() * canvas.width;
    const y = Math.random() * canvas.height;
    const w = 8 + Math.random() * 34;
    const h = 2 + Math.random() * 7;
    ctx.fillStyle = Math.random() > 0.55
      ? 'rgba(23,16,11,0.22)'
      : 'rgba(224,172,104,0.12)';
    ctx.fillRect(x, y, w, h);
  }

  return tuneTexture(new THREE.CanvasTexture(canvas), {
    repeatX: 1.7,
    repeatY: 3.2,
    anisotropy: 2,
  });
}

function createOakLeafTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 256;
  canvas.height = 128;
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.save();
  ctx.translate(128, 66);
  ctx.beginPath();
  for (let i = 0; i <= 96; i++) {
    const a = (i / 96) * TWO_PI;
    const lobe = 1 + Math.pow(Math.sin(a * 4.5), 2) * 0.24;
    const taper = 0.72 + 0.28 * Math.sin(a);
    const x = Math.cos(a) * 78 * lobe * taper;
    const y = Math.sin(a) * 41 * (1 + 0.08 * Math.cos(a * 2));
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.closePath();
  const leafGrad = ctx.createLinearGradient(-80, -36, 88, 36);
  leafGrad.addColorStop(0, 'rgba(255,210,224,1)');
  leafGrad.addColorStop(0.45, 'rgba(255,178,207,1)');
  leafGrad.addColorStop(1, 'rgba(206,126,157,1)');
  ctx.fillStyle = leafGrad;
  ctx.fill();

  ctx.strokeStyle = 'rgba(255,245,248,0.52)';
  ctx.lineWidth = 2.2;
  ctx.beginPath();
  ctx.moveTo(-74, 0);
  ctx.lineTo(76, 0);
  ctx.stroke();

  ctx.strokeStyle = 'rgba(255,255,255,0.24)';
  ctx.lineWidth = 1.2;
  for (let i = -5; i <= 5; i++) {
    const x = i * 12;
    const y = 3 + Math.abs(i) * 2.5;
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.quadraticCurveTo(x + 10, y * Math.sign(i || 1), x + 24, y * 1.35 * Math.sign(i || 1));
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.quadraticCurveTo(x + 10, -y * Math.sign(i || 1), x + 24, -y * 1.35 * Math.sign(i || 1));
    ctx.stroke();
  }
  ctx.restore();

  ctx.fillStyle = 'rgba(184,118,130,0.78)';
  ctx.fillRect(22, 62, 34, 5);
  return tuneTexture(new THREE.CanvasTexture(canvas), { anisotropy: 4 });
}

function createGrassTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 96;
  canvas.height = 256;
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const bladeSpecs = [
    { x: 28, w: 15, lean: -10, tip: 'rgba(138,206,105,0.92)', mid: 'rgba(57,133,55,0.96)', root: 'rgba(18,64,31,0.98)' },
    { x: 48, w: 18, lean: 4, tip: 'rgba(165,226,120,0.95)', mid: 'rgba(66,154,61,0.98)', root: 'rgba(20,74,34,0.98)' },
    { x: 66, w: 13, lean: 13, tip: 'rgba(120,190,91,0.90)', mid: 'rgba(45,118,51,0.96)', root: 'rgba(13,52,28,0.98)' },
  ];

  for (const blade of bladeSpecs) {
    const grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
    grad.addColorStop(0, blade.tip);
    grad.addColorStop(0.58, blade.mid);
    grad.addColorStop(1, blade.root);
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.moveTo(blade.x, 2);
    ctx.quadraticCurveTo(
      blade.x + blade.lean,
      92,
      blade.x + blade.lean * 0.42 + blade.w * 0.36,
      255,
    );
    ctx.lineTo(blade.x - blade.w * 0.45, 255);
    ctx.quadraticCurveTo(blade.x - blade.lean * 0.28, 96, blade.x, 2);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = 'rgba(223,255,180,0.16)';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.moveTo(blade.x, 18);
    ctx.quadraticCurveTo(blade.x + blade.lean * 0.25, 124, blade.x + blade.lean * 0.18, 242);
    ctx.stroke();
  }
  return tuneTexture(new THREE.CanvasTexture(canvas), { anisotropy: 2 });
}

function createGrassGroundTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 1024;
  canvas.height = 1024;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#244a26';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  for (let i = 0; i < 9000; i++) {
    const x = Math.random() * canvas.width;
    const y = Math.random() * canvas.height;
    const len = 4 + Math.random() * 22;
    const angle = Math.random() * TWO_PI;
    const hue = 88 + Math.random() * 38;
    const sat = 28 + Math.random() * 34;
    const light = 20 + Math.random() * 28;
    ctx.strokeStyle = `hsla(${hue}, ${sat}%, ${light}%, ${0.20 + Math.random() * 0.28})`;
    ctx.lineWidth = 0.5 + Math.random() * 1.2;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(x + Math.cos(angle) * len, y + Math.sin(angle) * len);
    ctx.stroke();
  }

  for (let i = 0; i < 700; i++) {
    const x = Math.random() * canvas.width;
    const y = Math.random() * canvas.height;
    const radius = 12 + Math.random() * 42;
    const grad = ctx.createRadialGradient(x, y, 0, x, y, radius);
    grad.addColorStop(0, `rgba(100, 148, 72, ${0.045 + Math.random() * 0.06})`);
    grad.addColorStop(1, 'rgba(14, 36, 21, 0)');
    ctx.fillStyle = grad;
    ctx.fillRect(x - radius, y - radius, radius * 2, radius * 2);
  }

  return tuneTexture(new THREE.CanvasTexture(canvas), {
    repeatX: 18,
    repeatY: 18,
    anisotropy: 8,
  });
}

function createGrassGroundBumpTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = 512;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#747474';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  for (let i = 0; i < 5500; i++) {
    const x = Math.random() * canvas.width;
    const y = Math.random() * canvas.height;
    const len = 3 + Math.random() * 15;
    const angle = Math.random() * TWO_PI;
    const shade = 84 + Math.floor(Math.random() * 70);
    ctx.strokeStyle = `rgba(${shade},${shade},${shade},${0.18 + Math.random() * 0.22})`;
    ctx.lineWidth = 0.5 + Math.random() * 1.1;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(x + Math.cos(angle) * len, y + Math.sin(angle) * len);
    ctx.stroke();
  }
  return tuneTexture(new THREE.CanvasTexture(canvas), {
    repeatX: 18,
    repeatY: 18,
    anisotropy: 4,
    colorSpace: THREE.NoColorSpace,
  });
}

function createGrassClumpGeometry() {
  const positions = [];
  const uvs = [];
  const indices = [];
  const bladeCount = 7;

  for (let i = 0; i < bladeCount; i++) {
    const seed = i + 1;
    const yaw = (i / bladeCount) * TWO_PI + Math.sin(seed * 12.91) * 0.28;
    const width = 0.018 + (Math.sin(seed * 6.13) * 0.5 + 0.5) * 0.018;
    const height = 0.12 + (Math.sin(seed * 4.77) * 0.5 + 0.5) * 0.13;
    const offsetRadius = (Math.sin(seed * 8.41) * 0.5 + 0.5) * 0.028;
    const offsetAngle = Math.sin(seed * 3.33) * TWO_PI;
    const baseX = Math.cos(offsetAngle) * offsetRadius;
    const baseZ = Math.sin(offsetAngle) * offsetRadius;
    const sideX = Math.cos(yaw) * width;
    const sideZ = Math.sin(yaw) * width;
    const lean = 0.026 + (Math.sin(seed * 5.17) * 0.5 + 0.5) * 0.035;
    const leanX = Math.cos(yaw + Math.PI * 0.5) * lean;
    const leanZ = Math.sin(yaw + Math.PI * 0.5) * lean;
    const midLeanX = leanX * 0.42;
    const midLeanZ = leanZ * 0.42;
    const base = positions.length / 3;

    positions.push(
      baseX - sideX, 0, baseZ - sideZ,
      baseX + sideX, 0, baseZ + sideZ,
      baseX + midLeanX - sideX * 0.58, height * 0.58, baseZ + midLeanZ - sideZ * 0.58,
      baseX + midLeanX + sideX * 0.58, height * 0.58, baseZ + midLeanZ + sideZ * 0.58,
      baseX + leanX - sideX * 0.16, height, baseZ + leanZ - sideZ * 0.16,
      baseX + leanX + sideX * 0.16, height, baseZ + leanZ + sideZ * 0.16,
    );
    uvs.push(
      0, 1,
      1, 1,
      0.08, 0.42,
      0.92, 0.42,
      0.42, 0,
      0.58, 0,
    );
    indices.push(
      base, base + 1, base + 2,
      base + 1, base + 3, base + 2,
      base + 2, base + 3, base + 4,
      base + 3, base + 5, base + 4,
    );
  }

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geometry.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
  geometry.setIndex(indices);
  geometry.computeVertexNormals();
  geometry.computeBoundingSphere();
  return geometry;
}

function createShadowTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = 512;
  const ctx = canvas.getContext('2d');
  const grad = ctx.createRadialGradient(256, 256, 10, 256, 256, 256);
  grad.addColorStop(0, 'rgba(0,0,0,0.45)');
  grad.addColorStop(0.52, 'rgba(0,0,0,0.24)');
  grad.addColorStop(1, 'rgba(0,0,0,0)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  return tuneTexture(new THREE.CanvasTexture(canvas), { anisotropy: 1 });
}

let sharedGltfLoader = null;
let sharedFbxLoader = null;
let sharedObjLoader = null;
let sharedKtx2Loader = null;
let sharedDracoLoader = null;

function getKtx2Loader() {
  if (!sharedKtx2Loader) {
    sharedKtx2Loader = new KTX2Loader()
      .setTranscoderPath(`${SCENE_LIB_BASE}basis/`)
      .detectSupport(renderer);
  }
  return sharedKtx2Loader;
}

function getGltfLoader() {
  if (!sharedGltfLoader) {
    sharedGltfLoader = new GLTFLoader();
    sharedGltfLoader.setMeshoptDecoder(MeshoptDecoder);
    sharedGltfLoader.setKTX2Loader(getKtx2Loader());

    sharedDracoLoader = new DRACOLoader();
    sharedDracoLoader.setDecoderPath(`${SCENE_LIB_BASE}draco/gltf/`);
    sharedGltfLoader.setDRACOLoader(sharedDracoLoader);
  }
  return sharedGltfLoader;
}

function getFbxLoader() {
  if (!sharedFbxLoader) {
    sharedFbxLoader = new FBXLoader();
  }
  return sharedFbxLoader;
}

function getObjLoader() {
  if (!sharedObjLoader) {
    sharedObjLoader = new OBJLoader();
  }
  return sharedObjLoader;
}

function loadTextureAsset(path, options = {}) {
  return new Promise((resolve, reject) => {
    new THREE.TextureLoader().load(
      path,
      (texture) => resolve(tuneTexture(texture, options)),
      undefined,
      reject,
    );
  });
}

function loadKtx2TextureAsset(path, options = {}) {
  return new Promise((resolve, reject) => {
    getKtx2Loader().load(
      path,
      (texture) => resolve(tuneTexture(texture, options)),
      undefined,
      reject,
    );
  });
}

function loadTextureByType(path, options = {}) {
  return path.toLowerCase().endsWith('.ktx2')
    ? loadKtx2TextureAsset(path, options)
    : loadTextureAsset(path, options);
}

function tuneMoonSurfaceTexture(texture, { forGltf = false, colorSpace = THREE.SRGBColorSpace } = {}) {
  if (!texture) return null;
  texture.colorSpace = colorSpace;
  texture.flipY = !forGltf;
  texture.wrapS = THREE.RepeatWrapping;
  texture.wrapT = THREE.ClampToEdgeWrapping;
  texture.anisotropy = Math.min(MOON_TEXTURE_ANISOTROPY, renderer.capabilities.getMaxAnisotropy());
  texture.generateMipmaps = true;
  texture.minFilter = THREE.LinearMipmapLinearFilter;
  texture.magFilter = THREE.LinearFilter;
  texture.needsUpdate = true;
  return texture;
}

function createMoonBumpTexture(surfaceTexture, { forGltf = false } = {}) {
  if (!surfaceTexture) return null;
  const bumpTexture = surfaceTexture.clone();
  bumpTexture.colorSpace = THREE.NoColorSpace;
  bumpTexture.flipY = !forGltf;
  bumpTexture.wrapS = THREE.RepeatWrapping;
  bumpTexture.wrapT = THREE.ClampToEdgeWrapping;
  bumpTexture.anisotropy = Math.min(MOON_TEXTURE_ANISOTROPY, renderer.capabilities.getMaxAnisotropy());
  bumpTexture.generateMipmaps = true;
  bumpTexture.minFilter = THREE.LinearMipmapLinearFilter;
  bumpTexture.magFilter = THREE.LinearFilter;
  bumpTexture.needsUpdate = true;
  return bumpTexture;
}

async function loadFirstTextureAsset(paths, options = {}) {
  let lastError = null;
  for (const path of paths) {
    try {
      const texture = await loadTextureByType(path, options);
      return { texture, path };
    } catch (error) {
      lastError = error;
      console.warn(`Texture candidate failed: ${path}`, error);
    }
  }
  throw lastError || new Error('No texture candidates provided');
}

function loadGltfAsset(path) {
  return new Promise((resolve, reject) => {
    getGltfLoader().load(path, resolve, undefined, reject);
  });
}

function loadFbxAsset(path) {
  return new Promise((resolve, reject) => {
    getFbxLoader().load(path, resolve, undefined, reject);
  });
}

function loadObjAsset(path) {
  return new Promise((resolve, reject) => {
    getObjLoader().load(path, resolve, undefined, reject);
  });
}

async function loadFirstGltfAsset(paths) {
  let lastError = null;
  for (const path of paths) {
    try {
      const gltf = await loadGltfAsset(path);
      return { gltf, path };
    } catch (error) {
      lastError = error;
      console.warn(`GLB candidate failed: ${path}`, error);
    }
  }
  throw lastError || new Error('No GLB candidates provided');
}

function loadExrAsset(path) {
  return new Promise((resolve, reject) => {
    new EXRLoader().load(
      path,
      (texture) => {
        texture.mapping = THREE.EquirectangularReflectionMapping;
        texture.needsUpdate = true;
        resolve(texture);
      },
      undefined,
      reject,
    );
  });
}

function getObjectBounds(object) {
  object.updateMatrixWorld(true);
  return new THREE.Box3().setFromObject(object);
}

function fitObjectToHeight(object, targetHeight) {
  object.position.set(0, 0, 0);
  object.updateMatrixWorld(true);
  const bounds = getObjectBounds(object);
  const size = bounds.getSize(new THREE.Vector3());
  const scale = targetHeight / Math.max(size.y, size.z, size.x, 0.001);
  object.scale.multiplyScalar(scale);
  object.updateMatrixWorld(true);
  return getObjectBounds(object);
}

function placeObjectOnGround(object, groundPosition) {
  const bounds = getObjectBounds(object);
  const center = bounds.getCenter(new THREE.Vector3());
  object.position.x += groundPosition.x - center.x;
  object.position.z += groundPosition.z - center.z;
  object.position.y += groundPosition.y - bounds.min.y;
  object.updateMatrixWorld(true);
}

function centerObjectAt(object, position) {
  const bounds = getObjectBounds(object);
  const center = bounds.getCenter(new THREE.Vector3());
  object.position.add(position.clone().sub(center));
  object.updateMatrixWorld(true);
}

function fitObjectToExactBox(object, targetSize) {
  object.position.set(0, 0, 0);
  object.updateMatrixWorld(true);
  const bounds = getObjectBounds(object);
  const size = bounds.getSize(new THREE.Vector3());
  object.scale.set(
    object.scale.x * (targetSize.x / Math.max(size.x, 0.001)),
    object.scale.y * (targetSize.y / Math.max(size.y, 0.001)),
    object.scale.z * (targetSize.z / Math.max(size.z, 0.001)),
  );
  object.updateMatrixWorld(true);
  return getObjectBounds(object);
}

function fitObjectToFootprint(object, targetDiameter, maxHeight) {
  object.position.set(0, 0, 0);
  object.updateMatrixWorld(true);
  let bounds = getObjectBounds(object);
  const size = bounds.getSize(new THREE.Vector3());
  const footprint = Math.max(size.x, size.z, 0.001);
  let scale = targetDiameter / footprint;
  if (maxHeight > 0 && size.y * scale > maxHeight) {
    scale = maxHeight / Math.max(size.y, 0.001);
  }
  object.scale.multiplyScalar(clamp(scale, 0.0001, 100));
  object.updateMatrixWorld(true);
  bounds = getObjectBounds(object);
  return bounds;
}

function placeObjectOnGroundCenter(object, groundPosition, yOffset = 0.006) {
  const bounds = getObjectBounds(object);
  const center = bounds.getCenter(new THREE.Vector3());
  object.position.x += groundPosition.x - center.x;
  object.position.z += groundPosition.z - center.z;
  object.position.y += yOffset - bounds.min.y;
  object.updateMatrixWorld(true);
}

function prepareGroundDetailSource(sourceScene, {
  name,
  height = 0.45,
  tint = 0xffffff,
  tintStrength = 0.18,
  emissive = 0x000000,
  emissiveIntensity = 0,
  alphaTest = 0.035,
  doubleSide = true,
  roughness = 0.86,
  yOffset = 0,
} = {}) {
  const source = sourceScene.clone(true);
  source.name = name || 'SceneV2_Ground_Detail_Source';
  fitObjectToHeight(source, height);
  placeObjectOnGroundCenter(source, new THREE.Vector3(0, 0, 0), yOffset);
  const tintColor = new THREE.Color(tint);
  const emissiveColor = new THREE.Color(emissive);
  source.traverse((object) => {
    if (!object.isMesh) return;
    const materials = Array.isArray(object.material) ? object.material : [object.material];
    const clonedMaterials = materials.map((material) => {
      const next = material?.clone?.() || new THREE.MeshStandardMaterial();
      if (next.map) {
        next.map.colorSpace = THREE.SRGBColorSpace;
        next.map.anisotropy = Math.min(6, renderer.capabilities.getMaxAnisotropy());
        next.map.needsUpdate = true;
      }
      if (next.normalMap) {
        next.normalMap.colorSpace = THREE.NoColorSpace;
        next.normalMap.needsUpdate = true;
      }
      if (next.color) next.color.lerp(tintColor, tintStrength);
      next.roughness = Math.max(next.roughness ?? roughness, roughness);
      next.metalness = 0;
      next.envMapIntensity = Math.min(next.envMapIntensity ?? 0.18, 0.22);
      if (emissiveIntensity > 0) {
        next.emissive = emissiveColor.clone();
        next.emissiveIntensity = emissiveIntensity;
      }
      if (doubleSide) next.side = THREE.DoubleSide;
      next.alphaTest = Math.max(next.alphaTest || 0, alphaTest);
      next.userData.baseEmissiveIntensity = emissiveIntensity;
      next.needsUpdate = true;
      return next;
    });
    object.material = Array.isArray(object.material) ? clonedMaterials : clonedMaterials[0];
    object.castShadow = false;
    object.receiveShadow = false;
    object.frustumCulled = true;
    object.userData.organicGroundDetail = true;
  });
  return source;
}

async function loadGroundDetailSource(asset) {
  const gltf = await loadGltfAsset(asset.path);
  return {
    ...asset,
    source: prepareGroundDetailSource(gltf.scene, {
      name: `SceneV2_${asset.kind}_${asset.name}_Source`,
      height: asset.height,
      tint: asset.tint,
      tintStrength: asset.tintStrength,
      emissive: asset.emissive,
      emissiveIntensity: asset.emissiveIntensity,
      alphaTest: asset.alphaTest,
      doubleSide: asset.doubleSide,
      roughness: asset.roughness,
      yOffset: asset.yOffset,
    }),
  };
}

function placeGroundDetailClone(group, asset, placement, index) {
  const detail = asset.source.clone(true);
  detail.name = `SceneV2_${asset.kind}_${asset.name}_${index + 1}`;
  const seed = placement.seed || (9100 + index * 83);
  const scalar = (placement.scale ?? 1) * (0.9 + grassFieldRandom(seed + 3) * 0.22);
  detail.scale.multiplyScalar(scalar);
  detail.scale.x *= placement.scaleX || 1;
  detail.scale.y *= placement.scaleY || 1;
  detail.scale.z *= placement.scaleZ || 1;
  detail.rotation.set(
    placement.rx || 0,
    (placement.ry || 0) + (grassFieldRandom(seed + 7) - 0.5) * (placement.rotationJitter ?? 0.55),
    placement.rz || 0,
  );
  placeObjectOnGroundCenter(
    detail,
    new THREE.Vector3(placement.x, 0, placement.z),
    placement.yOffset ?? asset.yOffset ?? 0.012,
  );
  detail.userData.organicDetailKind = asset.kind;
  detail.traverse((object) => {
    object.userData.organicDetailKind = asset.kind;
  });
  group.add(detail);
  return detail;
}

async function loadOrganicGroundDetails() {
  if (sceneAssets.groundDetailGroup) return;
  const group = new THREE.Group();
  group.name = 'SceneV2_Organic_Ground_Details';
  sceneAssets.groundDetailGroup = group;
  addLegacyVisual(group);

  const includeHeavyDecor = visualSettings.visualQuality === 'high'
    || ['1', 'true', 'yes'].includes((urlParams.get('heavyDecor') || '').toLowerCase());
  const detailAssetDefs = [
    { kind: 'rock', name: 'rock1', path: `${NEW_ASSET_BASE}rock1.glb`, height: 0.34, tint: 0x6c7d63, tintStrength: 0.22, roughness: 0.94 },
    { kind: 'rock', name: 'rock2', path: `${NEW_ASSET_BASE}rock2.glb`, height: 0.42, tint: 0x74836c, tintStrength: 0.2, roughness: 0.94 },
    { kind: 'rock', name: 'rock3', path: `${NEW_ASSET_BASE}rock3.glb`, height: 0.5, tint: 0x66785e, tintStrength: 0.2, roughness: 0.95 },
    { kind: 'rock', name: 'rock_pack', path: `${NEW_ASSET_BASE}rock_pack.glb`, height: 0.52, tint: 0x708164, tintStrength: 0.18, roughness: 0.95 },
    { kind: 'petal', name: 'cherry_petals2', path: `${NEW_ASSET_BASE}cherry_petals2.glb`, height: 0.075, tint: 0xffd4df, tintStrength: 0.26, alphaTest: 0.02, yOffset: 0.018 },
    { kind: 'petal', name: 'cherry_petals1', path: `${NEW_ASSET_BASE}cherry_petals1.glb`, height: 0.105, tint: 0xffdce7, tintStrength: 0.2, alphaTest: 0.02, yOffset: 0.02, highOnly: true },
    { kind: 'flower', name: 'lavender', path: `${NEW_ASSET_BASE}lavender.glb`, height: 0.38, tint: 0xd5c1ff, tintStrength: 0.18, emissive: 0x8061ff, emissiveIntensity: 0.012 },
    { kind: 'flower', name: 'chamomile', path: `${NEW_ASSET_BASE}chamomile.glb`, height: 0.34, tint: 0xfff2c7, tintStrength: 0.14, emissive: 0xffe29b, emissiveIntensity: 0.008 },
    { kind: 'glow', name: 'glowing_plants', path: `${NEW_ASSET_BASE}glowing_plants.glb`, height: 0.42, tint: 0x9dffd4, tintStrength: 0.2, emissive: 0x65ffb5, emissiveIntensity: 0.08 },
  ];

  const loaded = [];
  for (const def of detailAssetDefs) {
    if (def.highOnly && !includeHeavyDecor) continue;
    try {
      loaded.push(await loadGroundDetailSource(def));
    } catch (error) {
      console.warn(`Organic ground detail GLB unavailable: ${def.path}`, error);
    }
  }

  const byKind = (kind) => loaded.filter((asset) => asset.kind === kind);
  const rocks = byKind('rock');
  const petals = byKind('petal');
  const flowers = [...byKind('flower'), ...byKind('glow')];

  let rockCount = 0;
  const rockPlacements = [
    { x: -1.55, z: -2.45, scale: 0.64, ry: 0.4, yOffset: 0.016 },
    { x: 1.85, z: -2.9, scale: 0.52, ry: -0.8, yOffset: 0.014 },
    { x: -2.8, z: -4.7, scale: 0.78, ry: 1.5, yOffset: 0.014 },
    { x: 3.15, z: -5.2, scale: 0.7, ry: -1.2, yOffset: 0.014 },
    { x: -5.7, z: -7.8, scale: 0.82, ry: 1.9, yOffset: 0.01 },
    { x: 6.3, z: -8.4, scale: 0.78, ry: -2.1, yOffset: 0.01 },
    { x: -9.8, z: -11.2, scale: 0.92, ry: 2.4, yOffset: 0.008 },
    { x: 10.6, z: -12.1, scale: 0.9, ry: -2.2, yOffset: 0.008 },
    { x: -15.8, z: -16.0, scale: 1.05, ry: 2.8, yOffset: 0.006 },
    { x: 16.4, z: -17.2, scale: 1.0, ry: -2.6, yOffset: 0.006 },
    { x: -20.6, z: -8.9, scale: 1.02, ry: 1.2, yOffset: 0.006 },
    { x: 21.2, z: -9.7, scale: 1.04, ry: -1.4, yOffset: 0.006 },
  ];
  if (rocks.length > 0) {
    for (let i = 0; i < rockPlacements.length; i++) {
      placeGroundDetailClone(group, rocks[i % rocks.length], { ...rockPlacements[i], seed: 9300 + i * 43 }, i);
      rockCount += 1;
    }
  }

  let petalPatchCount = 0;
  if (petals.length > 0) {
    const petalCount = includeHeavyDecor ? 26 : 18;
    for (let i = 0; i < petalCount; i++) {
      const seed = 9700 + i * 59;
      const angle = (i / petalCount) * TWO_PI + (grassFieldRandom(seed) - 0.5) * 0.38;
      const radius = 0.45 + grassFieldRandom(seed + 3) * 2.55;
      const petalAsset = petals[i % petals.length];
      placeGroundDetailClone(group, petalAsset, {
        x: TREE_POS.x + Math.cos(angle) * radius,
        z: TREE_POS.z + Math.sin(angle) * radius,
        scale: 0.42 + grassFieldRandom(seed + 5) * 0.44,
        scaleX: 1.2 + grassFieldRandom(seed + 9) * 0.8,
        scaleZ: 0.78 + grassFieldRandom(seed + 11) * 0.46,
        ry: angle + Math.PI / 2,
        rotationJitter: 1.6,
        yOffset: 0.018 + grassFieldRandom(seed + 15) * 0.008,
        seed,
      }, i);
      petalPatchCount += 1;
    }
  }

  let flowerPatchCount = 0;
  const flowerPlacements = [
    { x: -6.8, z: -6.4, scale: 0.74, ry: 0.6 },
    { x: 7.1, z: -7.0, scale: 0.7, ry: -0.8 },
    { x: -11.4, z: -9.4, scale: 0.86, ry: 1.4 },
    { x: 12.1, z: -10.0, scale: 0.82, ry: -1.3 },
    { x: -4.8, z: -13.8, scale: 0.78, ry: 0.2 },
    { x: 5.2, z: -14.6, scale: 0.8, ry: -0.2 },
    { x: -15.2, z: -19.2, scale: 0.94, ry: 2.1 },
    { x: 16.0, z: -20.0, scale: 0.92, ry: -2.0 },
    { x: -23.4, z: -13.4, scale: 1.02, ry: 2.6 },
    { x: 24.0, z: -14.2, scale: 1.0, ry: -2.7 },
    { x: -8.4, z: -25.6, scale: 0.95, ry: 1.0 },
    { x: 9.2, z: -26.2, scale: 0.95, ry: -1.0 },
    { x: -26.0, z: -23.4, scale: 1.04, ry: 2.8 },
    { x: 26.8, z: -24.0, scale: 1.04, ry: -2.8 },
  ];
  if (flowers.length > 0) {
    for (let i = 0; i < flowerPlacements.length; i++) {
      const asset = flowers[i % flowers.length];
      const placement = flowerPlacements[i];
      placeGroundDetailClone(group, asset, {
        ...placement,
        scale: placement.scale * (asset.kind === 'glow' ? 0.78 : 1),
        yOffset: asset.kind === 'glow' ? 0.018 : 0.01,
        rotationJitter: 0.86,
        seed: 10100 + i * 71,
      }, i);
      flowerPatchCount += 1;
    }
  }

  sceneAssets.groundDetailSourceFiles = loaded.map((asset) => asset.path);
  sceneAssets.rockCount = rockCount;
  sceneAssets.flowerPatchCount = flowerPatchCount;
  sceneAssets.petalPatchCount = petalPatchCount;
  sceneAssets.groundDetailProfile = loaded.length > 0
    ? `organic-details-${loaded.length}-sources`
    : 'organic-details-none';
  visualSettings.groundDetailProfile = sceneAssets.groundDetailProfile;
  console.info(`Organic ground details: ${rockCount} rocks, ${petalPatchCount} petal patches, ${flowerPatchCount} flower/glow patches.`);
}

function createGeneratedEnvironment() {
  const canvas = document.createElement('canvas');
  canvas.width = 1024;
  canvas.height = 512;
  const ctx = canvas.getContext('2d');
  const grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
  grad.addColorStop(0, '#07121c');
  grad.addColorStop(0.42, '#162f34');
  grad.addColorStop(1, '#071014');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = 'rgba(120, 255, 206, 0.14)';
  ctx.fillRect(0, 118, canvas.width, 66);

  const texture = new THREE.CanvasTexture(canvas);
  texture.mapping = THREE.EquirectangularReflectionMapping;
  texture.colorSpace = THREE.SRGBColorSpace;
  const pmrem = new THREE.PMREMGenerator(renderer);
  const envMap = pmrem.fromEquirectangular(texture).texture;
  scene.environment = envMap;
  texture.dispose();
  pmrem.dispose();
}

function createAssetLeafMaterial(textures) {
  const material = new THREE.MeshStandardMaterial({
    map: textures.leaf,
    color: 0xffffff,
    roughness: 0.92,
    metalness: 0,
    side: THREE.DoubleSide,
    alphaTest: 0.32,
    transparent: false,
  });

  material.onBeforeCompile = (shader) => {
    shader.uniforms.uTime = sceneAssets.uniforms.uTime;
    shader.uniforms.uTreeVitality = sceneAssets.uniforms.uTreeVitality;
    shader.uniforms.uWitherAmount = sceneAssets.uniforms.uWitherAmount;
    shader.uniforms.uWindStrength = sceneAssets.uniforms.uWindStrength;

    shader.vertexShader = shader.vertexShader.replace(
      '#include <common>',
      `#include <common>
      uniform float uTime;
      uniform float uTreeVitality;
      uniform float uWindStrength;`,
    );
    shader.vertexShader = shader.vertexShader.replace(
      '#include <begin_vertex>',
      `#include <begin_vertex>
      float swaySeed = dot(position.xz, vec2(2.17, 1.31));
      float sway = sin(uTime * 0.72 + swaySeed) * uWindStrength * (0.35 + uTreeVitality);
      transformed.x += sway;
      transformed.z += cos(uTime * 0.56 + swaySeed * 0.7) * uWindStrength * 0.42;`,
    );

    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <common>',
      `#include <common>
      uniform float uTreeVitality;
      uniform float uWitherAmount;`,
    );
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <color_fragment>',
      `#include <color_fragment>
      vec3 lush = vec3(0.34, 0.82, 0.28);
      vec3 deep = vec3(0.12, 0.38, 0.16);
      vec3 dry = vec3(0.72, 0.48, 0.20);
      vec3 withered = mix(dry, deep, uTreeVitality * 0.18);
      vec3 healthy = mix(deep, lush, uTreeVitality);
      diffuseColor.rgb *= mix(withered, healthy, 1.0 - uWitherAmount);
      diffuseColor.rgb *= 0.86 + uTreeVitality * 0.22;`,
    );
  };
  material.customProgramCacheKey = () => 'breathstate-scene-v2-leaves';
  return material;
}

function createSakuraBlossomMaterial(sourceMaterial, fallbackMap) {
  const material = sourceMaterial?.clone?.() || new THREE.MeshStandardMaterial();
  if (!material.map && fallbackMap) material.map = fallbackMap;
  material.color = new THREE.Color(0xffffff);
  material.roughness = Math.max(material.roughness ?? 0.72, 0.76);
  material.metalness = 0;
  material.side = THREE.DoubleSide;
  material.transparent = true;
  material.opacity = Math.max(material.opacity ?? 0.86, 0.82);
  material.alphaTest = Math.max(material.alphaTest ?? 0, 0.045);
  material.depthWrite = false;
  material.emissive = new THREE.Color(0xffd6df);
  material.emissiveIntensity = 0.018;

  material.onBeforeCompile = (shader) => {
    shader.uniforms.uTime = sceneAssets.uniforms.uTime;
    shader.uniforms.uTreeVitality = sceneAssets.uniforms.uTreeVitality;
    shader.uniforms.uWitherAmount = sceneAssets.uniforms.uWitherAmount;
    shader.uniforms.uWindStrength = sceneAssets.uniforms.uWindStrength;

    shader.vertexShader = shader.vertexShader.replace(
      '#include <common>',
      `#include <common>
      uniform float uTime;
      uniform float uTreeVitality;
      uniform float uWindStrength;
      attribute float blossomSeed;
      varying float vBlossomSeed;
      varying vec3 vBlossomWorld;
      varying vec2 vBlossomUv;
      float bs_hash(float n) {
        return fract(sin(n) * 43758.5453123);
      }`,
    );
    shader.vertexShader = shader.vertexShader.replace(
      '#include <begin_vertex>',
      `#include <begin_vertex>
      vBlossomSeed = blossomSeed;
      #ifdef USE_UV
        vBlossomUv = uv;
      #else
        vBlossomUv = position.xz * 0.17;
      #endif
      vBlossomWorld = (modelMatrix * vec4(position, 1.0)).xyz;
      float swaySeed = dot(position.xz, vec2(2.41, 1.83)) + blossomSeed * 8.0;
      float crownMask = smoothstep(0.15, 1.0, position.y + position.z * 0.04);
      float microFlutter = sin(uTime * 1.24 + blossomSeed * 31.0) * 0.0035 * (1.0 - uTreeVitality);
      float sway = sin(uTime * 0.58 + swaySeed) * uWindStrength * (0.24 + uTreeVitality * 0.54);
      transformed.x += sway * crownMask;
      transformed.y += microFlutter * crownMask;
      transformed.z += cos(uTime * 0.46 + swaySeed * 0.73) * uWindStrength * 0.44 * crownMask;`,
    );

    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <common>',
      `#include <common>
      uniform float uTreeVitality;
      uniform float uWitherAmount;
      varying float vBlossomSeed;
      varying vec3 vBlossomWorld;
      varying vec2 vBlossomUv;
      float bs_hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
      }
      float bs_noise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        vec2 u = f * f * (3.0 - 2.0 * f);
        return mix(
          mix(bs_hash(i), bs_hash(i + vec2(1.0, 0.0)), u.x),
          mix(bs_hash(i + vec2(0.0, 1.0)), bs_hash(i + vec2(1.0, 1.0)), u.x),
          u.y
        );
      }`,
    );
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <map_fragment>',
      `#include <map_fragment>
      float petalNoise = bs_noise(vBlossomUv * 18.0 + vBlossomSeed * 3.7);
      float crownNoise = bs_noise(vBlossomWorld.xz * 1.35 + vec2(vBlossomSeed * 2.1, vBlossomWorld.y * 0.18));
      float blossomLift = smoothstep(0.30, 0.94, uTreeVitality);
      float petalHighlight = smoothstep(0.44, 0.98, petalNoise) * (0.45 + blossomLift * 0.55);
      float veinShade = smoothstep(0.18, 0.52, abs(vBlossomUv.x - 0.5)) * 0.12;
      vec3 porcelain = vec3(1.0, 0.91, 0.95);
      vec3 palePetal = vec3(1.0, 0.78, 0.88);
      vec3 rosePetal = vec3(1.0, 0.54, 0.72);
      vec3 mauvePetal = vec3(0.78, 0.50, 0.64);
      vec3 amberPetal = vec3(0.78, 0.48, 0.28);
      vec3 dryPetal = vec3(0.42, 0.28, 0.20);
      vec3 sourceColor = diffuseColor.rgb;
      vec3 healthy = mix(rosePetal, palePetal, blossomLift);
      healthy = mix(healthy, porcelain, petalHighlight * 0.52);
      healthy = mix(healthy, mauvePetal, (1.0 - petalNoise) * 0.16);
      vec3 withered = mix(dryPetal, amberPetal, clamp(uTreeVitality * 0.42 + crownNoise * 0.18, 0.0, 1.0));
      float colorAuthority = 0.36 + blossomLift * 0.34;
      diffuseColor.rgb = mix(sourceColor, healthy, colorAuthority);
      diffuseColor.rgb = mix(diffuseColor.rgb, withered, smoothstep(0.12, 0.92, uWitherAmount) * 0.62);
      diffuseColor.rgb *= 0.9 + blossomLift * 0.18 + petalHighlight * 0.14 - veinShade;
      diffuseColor.a *= mix(0.50, 0.98, blossomLift) * (0.82 + petalNoise * 0.18);`,
    );

    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <emissivemap_fragment>',
      `#include <emissivemap_fragment>
      float petalGlow = smoothstep(0.48, 1.0, uTreeVitality) * (0.18 + bs_noise(vBlossomUv * 10.0 + vBlossomSeed) * 0.18);
      totalEmissiveRadiance += vec3(1.0, 0.68, 0.78) * petalGlow * 0.08;`,
    );

    material.userData.shader = shader;
  };
  material.customProgramCacheKey = () => 'breathstate-scene-v2-sakura-blossoms-v2';
  material.needsUpdate = true;
  return material;
}

function ensureBlossomVariationAttribute(geometry) {
  if (geometry.attributes.blossomSeed || !geometry.attributes.position) return;
  const count = geometry.attributes.position.count;
  const seeds = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    const x = geometry.attributes.position.getX(i);
    const y = geometry.attributes.position.getY(i);
    const z = geometry.attributes.position.getZ(i);
    seeds[i] = Math.abs(Math.sin(x * 12.9898 + y * 78.233 + z * 37.719 + i * 0.013)) % 1;
  }
  geometry.setAttribute('blossomSeed', new THREE.BufferAttribute(seeds, 1));
}

function createSakuraBarkMaterial(sourceMaterial) {
  const material = sourceMaterial?.clone?.() || new THREE.MeshStandardMaterial({ color: BARK.clone() });
  material.color = material.color || new THREE.Color(0xffffff);
  material.roughness = Math.max(material.roughness ?? 0.82, 0.86);
  material.metalness = 0;
  material.emissive = BARK_GLOW.clone();
  material.emissiveIntensity = 0.035;
  material.needsUpdate = true;
  return material;
}

let grassMaterialSerial = 0;

function attachGrassWindShader(material, cacheKey) {
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uTime = sceneAssets.uniforms.uTime;
    shader.uniforms.uTreeVitality = sceneAssets.uniforms.uTreeVitality;
    shader.uniforms.uWindStrength = sceneAssets.uniforms.uWindStrength;

    shader.vertexShader = shader.vertexShader.replace(
      '#include <common>',
      `#include <common>
      uniform float uTime;
      uniform float uTreeVitality;
      uniform float uWindStrength;
      varying float vGrassBlade;
      varying float vGrassSeed;`,
    );
    shader.vertexShader = shader.vertexShader.replace(
      '#include <begin_vertex>',
      `#include <begin_vertex>
      float bladeMask = smoothstep(0.008, 0.18, position.y);
      vec3 grassInstanceOrigin = vec3(0.0);
      #ifdef USE_INSTANCING
        grassInstanceOrigin = vec3(instanceMatrix[3].x, instanceMatrix[3].y, instanceMatrix[3].z);
      #endif
      float windSeed = dot(position.xz + grassInstanceOrigin.xz, vec2(4.71, 2.93));
      vGrassBlade = bladeMask;
      vGrassSeed = fract(sin(windSeed * 12.9898 + grassInstanceOrigin.x * 4.3 + grassInstanceOrigin.z * 2.1) * 43758.5453);
                                    
      float primaryWind = sin(uTime * 0.58 + windSeed) * uWindStrength;
      float gustWind = sin(uTime * 1.24 + windSeed * 1.73 + 0.9) * uWindStrength * 0.46;
      float microFlutter = sin(uTime * 2.82 + windSeed * 3.14) * uWindStrength * 0.14;
      float totalSway = (primaryWind + gustWind + microFlutter) * bladeMask * (0.64 + uTreeVitality * 0.38);
      transformed.x += totalSway * 0.72;
      transformed.z += (cos(uTime * 0.48 + windSeed * 0.61) * uWindStrength + cos(uTime * 1.08 + windSeed * 2.2) * uWindStrength * 0.3) * bladeMask * 0.42;`,
    );
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <common>',
      `#include <common>
      uniform float uTreeVitality;
      varying float vGrassBlade;
      varying float vGrassSeed;`,
    );
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <color_fragment>',
      `#include <color_fragment>
      vec3 sourceGrassTint = diffuseColor.rgb;
      vec3 grassRoot = vec3(0.06, 0.17, 0.09);
      vec3 grassMid = vec3(0.19, 0.50, 0.14);
      vec3 grassTipDry = vec3(0.44, 0.70, 0.22);
      vec3 grassTipLush = vec3(0.64, 0.96, 0.34);
      vec3 dryMoonShadow = vec3(0.10, 0.20, 0.12);
      vec3 lush = mix(grassRoot, grassMid, smoothstep(0.04, 0.68, vGrassBlade));
      vec3 tipColor = mix(grassTipDry, grassTipLush, uTreeVitality);
      lush = mix(lush, tipColor, smoothstep(0.50, 1.0, vGrassBlade) * 0.64);
      lush *= 0.82 + vGrassSeed * 0.26;
      lush = mix(dryMoonShadow, lush, 0.66 + uTreeVitality * 0.30);
      diffuseColor.rgb = mix(lush, lush * (0.72 + sourceGrassTint * 1.15), 0.36);
      diffuseColor.rgb *= 0.86 + uTreeVitality * 0.18;`,
    );
    material.userData.shader = shader;
  };
  material.customProgramCacheKey = () => `breathstate-grass-wind-${cacheKey}`;
  material.needsUpdate = true;
  return material;
}

function createGrassAssetMaterial(sourceMaterial) {
  const alphaMap = sourceMaterial?.alphaMap || sourceMaterial?.map || null;
  const material = new THREE.MeshStandardMaterial({
    color: 0x4f8f42,
    roughness: 0.98,
    metalness: 0,
    side: THREE.DoubleSide,
    alphaMap,
    alphaTest: alphaMap ? 0.18 : 0,
    transparent: Boolean(alphaMap),
    depthWrite: true,
    vertexColors: false,
    emissive: new THREE.Color(0x041007),
    emissiveIntensity: 0.006,
  });
  if (alphaMap) {
    alphaMap.colorSpace = THREE.NoColorSpace;
    alphaMap.needsUpdate = true;
  }
  return attachGrassWindShader(material, `asset-${grassMaterialSerial++}`);
}

function applyGrassAssetMaterials(grassAsset) {
  grassAsset.traverse((object) => {
    if (!object.isMesh) {
      if (object.isLine || object.isPoints || object.isLight || object.isCamera) {
        object.visible = false;
      }
      return;
    }
    object.frustumCulled = true;
    object.castShadow = false;
    object.receiveShadow = true;
    if (object.geometry) {
      object.geometry.computeBoundingSphere();
      object.geometry.computeVertexNormals?.();
    }
    if (Array.isArray(object.material)) {
      object.material = object.material.map((material) => createGrassAssetMaterial(material));
    } else {
      object.material = createGrassAssetMaterial(object.material);
    }
  });
}

function isSakuraBlossomMesh(object) {
  const name = `${object.name || ''} ${object.material?.name || ''}`.toLowerCase();
  return name.includes('sakura') && !name.includes('bark');
}

function applySakuraAssetMaterials(sakura, textures, { reset = true } = {}) {
  if (reset) {
    sceneAssets.oakLeaves = [];
    sceneAssets.blossomMeshes = [];
    sceneAssets.barkMeshes = [];
    sceneAssets.blossomMaterials = [];
    sceneAssets.barkMaterials = [];
    sceneAssets.oakLeavesLod0 = null;
    sceneAssets.oakLeavesLod1 = null;
  }

  sakura.traverse((object) => {
    if (!object.isMesh) return;
    object.frustumCulled = true;
    object.castShadow = visualSettings.visualQuality === 'high';
    object.receiveShadow = visualSettings.visualQuality === 'high';
    object.geometry.computeBoundingSphere();

    if (isSakuraBlossomMesh(object)) {
      ensureBlossomVariationAttribute(object.geometry);
      sceneAssets.blossomMaterial = createSakuraBlossomMaterial(object.material, textures.blossom);
      object.material = sceneAssets.blossomMaterial;
      sceneAssets.blossomMaterials.push(sceneAssets.blossomMaterial);
      object.renderOrder = 2;
      object.geometry.setDrawRange(0, Infinity);
      sceneAssets.blossomMeshes.push(object);
      sceneAssets.oakLeaves.push(object);
      if (!sceneAssets.oakLeavesLod0) sceneAssets.oakLeavesLod0 = object;
    } else {
      sceneAssets.barkMaterial = createSakuraBarkMaterial(object.material);
      object.material = sceneAssets.barkMaterial;
      sceneAssets.barkMaterials.push(sceneAssets.barkMaterial);
      sceneAssets.barkMeshes.push(object);
    }
  });
}

function applyNightSkyTexture(texture, profile = 'texture') {
  skyMat.uniforms.skyMap.value = texture;
  skyMat.uniforms.useSkyMap.value = 1;
  sceneAssets.skyTexture = texture;
  sceneAssets.nightSkyTexture = texture;
  sceneAssets.skyProfile = profile;
  visualSettings.skyProfile = profile;

  const pmrem = new THREE.PMREMGenerator(renderer);
  scene.environment = pmrem.fromEquirectangular(texture).texture;
  pmrem.dispose();
}

function createNightSkyModel(gltf) {
  if (sceneAssets.skyModel) return;
  const sky = gltf.scene;
  sky.name = 'SceneV2_Night_Sky_Model';
  fitObjectToHeight(sky, 112);
  centerObjectAt(sky, new THREE.Vector3(0, 0, 0));
  sky.traverse((object) => {
    if (!object.isMesh) return;
    const source = object.material;
    const map = source?.map || source?.emissiveMap || null;
    object.material = new THREE.MeshBasicMaterial({
      map,
      color: 0xffffff,
      side: THREE.DoubleSide,
      depthWrite: false,
      depthTest: false,
      fog: false,
      toneMapped: false,
    });
    object.frustumCulled = false;
    object.renderOrder = -20;
  });
  addLegacyVisual(sky);
  skyDome.visible = false;
  sceneAssets.skyModel = sky;
  sceneAssets.skyProfile = 'model';
  visualSettings.skyProfile = 'model';
}

async function applyBakedSceneAo() {
  groundMat.aoMap = null;
  groundMat.needsUpdate = true;
  canopyShadow.visible = false;
}

function ensureGrassAssetGroup() {
  if (!sceneAssets.grassGroup) {
    sceneAssets.grassGroup = new THREE.Group();
    sceneAssets.grassGroup.name = GRASS_FBX_GROUP_NAME;
    sceneAssets.grassGroup.userData.sceneName = 'SceneV2_Glb_Grass_Field';
    addLegacyVisual(sceneAssets.grassGroup);
  }
  return sceneAssets.grassGroup;
}

function makeGrassPosition(offsetX, offsetZ) {
  return TREE_POS.clone().add(new THREE.Vector3(offsetX, 0, offsetZ));
}

function grassFieldRandom(seed) {
  return Math.abs(Math.sin(seed * 12.9898) * 43758.5453123) % 1;
}

function createAnimatedGrassFieldMatrices() {
  const fieldMatrices = [];
  const fieldTransform = new THREE.Object3D();
  const gridRadius = 3;
  const spacingX = 8.2;
  const spacingZ = 8.0;

  for (let ix = -gridRadius; ix <= gridRadius; ix++) {
    for (let iz = -gridRadius; iz <= gridRadius; iz++) {
      const seed = (ix + 11) * 31 + (iz + 13) * 17;
      const stagger = (iz % 2) * 2.8;
      const jitterX = (grassFieldRandom(seed) - 0.5) * 1.6;
      const jitterZ = (grassFieldRandom(seed + 7) - 0.5) * 1.4;
      const position = makeGrassPosition(
        ix * spacingX + stagger + jitterX,
        iz * spacingZ + jitterZ,
      );
      const scaleJitter = 0.92 + grassFieldRandom(seed + 19) * 0.18;

      fieldTransform.position.set(
        position.x,
        0.018 + grassFieldRandom(seed + 23) * 0.012,
        position.z,
      );
      fieldTransform.rotation.set(0, grassFieldRandom(seed + 29) * TWO_PI, 0);
      fieldTransform.scale.set(2.38 * scaleJitter, 0.33, 2.02 * scaleJitter);
      fieldTransform.updateMatrix();
      fieldMatrices.push(fieldTransform.matrix.clone());
    }
  }

  return fieldMatrices;

                                                                                  
  const transforms = [];
  const rings = [
                                                               
                                         
    [ 0.0, -1.2, 2.06, 0.34, 1.86,  0.34,  0.006],
    [-2.8, -2.4, 1.94, 0.33, 1.76, -0.52,  0.007],
    [ 2.8, -2.2, 1.94, 0.33, 1.76,  0.58,  0.007],
    [-2.6,  2.0, 1.88, 0.32, 1.70,  1.28,  0.008],
    [ 2.6,  2.1, 1.88, 0.32, 1.70, -1.24,  0.008],
    [ 0.0,  3.2, 1.92, 0.33, 1.74, -0.12,  0.007],
               
    [-5.2, -5.0, 1.84, 0.33, 1.68, -0.22,  0.009],
    [ 5.2, -4.8, 1.84, 0.33, 1.68,  0.28,  0.009],
    [-8.6, -9.8, 1.82, 0.33, 1.66, -0.18,  0.008],
    [ 8.6, -9.6, 1.82, 0.33, 1.66,  Math.PI + 0.18, 0.009],
    [-9.3,  8.0, 1.78, 0.33, 1.60,  Math.PI * 0.5 - 0.24, 0.011],
    [ 9.3,  8.2, 1.78, 0.33, 1.60, -Math.PI * 0.5 + 0.22, 0.012],
    [ 0.0, 16.2, 1.76, 0.32, 1.56, -0.6,   0.014],
    [-5.6,  12.4, 1.74, 0.32, 1.54, 0.88,  0.013],
    [ 5.4,  12.0, 1.74, 0.32, 1.54,-0.82,  0.013],
    [-14.0,  0.0, 1.72, 0.32, 1.52,  Math.PI * 0.5 + 0.14, 0.014],
    [ 14.0,  0.4, 1.72, 0.32, 1.52, -Math.PI * 0.5 - 0.12, 0.015],
                 
    [-15.2, -0.6, 1.48, 0.31, 1.38,  Math.PI * 0.5 + 0.08, 0.015],
    [ 15.2, -0.2, 1.48, 0.31, 1.38, -Math.PI * 0.5 - 0.06, 0.016],
    [-3.4, -18.4, 1.36, 0.30, 1.24,  0.08,  0.018],
    [ 3.6, -18.0, 1.36, 0.30, 1.24,  Math.PI - 0.1, 0.019],
    [ 0.0,  28.0, 1.36, 0.30, 1.22, -0.48,  0.020],
    [-12.0, -16.0, 1.42, 0.30, 1.30, -0.38, 0.016],
    [ 12.0, -15.6, 1.42, 0.30, 1.30,  0.42, 0.017],
    [-18.0, -12.0, 1.38, 0.30, 1.26,  1.1,  0.016],
    [ 18.0, -11.8, 1.38, 0.30, 1.26, -1.0,  0.017],
    [-20.0,  4.0, 1.34, 0.30, 1.22,  1.6,   0.018],
    [ 20.0,  4.2, 1.34, 0.30, 1.22, -1.54,  0.018],
    [-16.0,  16.0, 1.32, 0.29, 1.20,  2.2,   0.020],
    [ 16.0,  16.2, 1.32, 0.29, 1.20, -2.1,   0.020],
    [-6.0, -26.0, 1.28, 0.29, 1.16,  0.22,  0.022],
    [ 6.0, -25.6, 1.28, 0.29, 1.16, -0.18,  0.022],
    [ 0.0, -28.0, 1.28, 0.29, 1.16,  0.0,   0.023],
    [-24.0, -4.0, 1.24, 0.28, 1.12,  1.8,   0.021],
    [ 24.0, -3.8, 1.24, 0.28, 1.12, -1.7,   0.021],
    [-10.0,  24.0, 1.24, 0.28, 1.12,  0.9,   0.022],
    [ 10.0,  23.8, 1.24, 0.28, 1.12, -0.8,   0.022],
    [ 0.0,  32.0, 1.22, 0.28, 1.10, -0.3,   0.024],
    [-22.0,  14.0, 1.20, 0.27, 1.08,  2.4,   0.023],
    [ 22.0,  14.2, 1.20, 0.27, 1.08, -2.3,   0.023],
  ];
  const transform = new THREE.Object3D();
  return transforms.concat(rings).map(([x, z, sx, sy, sz, ry, y]) => {
    const position = makeGrassPosition(x, z);
    transform.position.set(position.x, y, position.z);
    transform.rotation.set(0, ry, 0);
    transform.scale.set(sx, sy, sz);
    transform.updateMatrix();
    return transform.matrix.clone();
  });
}

function isGrassTemplateMesh(object) {
  const name = `${object.name || ''} ${object.parent?.name || ''}`.toLowerCase();
  if (!object.isMesh) return false;
  if (name.includes('plane')) return false;
  return true;
}

function collectGrassTemplates(gltf) {
  const templates = [];
  gltf.scene.updateMatrixWorld(true);
  gltf.scene.traverse((object) => {
    if (!isGrassTemplateMesh(object)) return;
    const geometry = object.geometry.clone();
    if (object.geometry) {
      geometry.computeBoundingBox();
      const bounds = geometry.boundingBox;
      const center = bounds.getCenter(new THREE.Vector3());
      geometry.translate(-center.x, -bounds.min.y, -center.z);
      geometry.computeBoundingSphere();
      geometry.computeVertexNormals?.();
    }
    const sourceMaterials = Array.isArray(object.material)
      ? object.material
      : [object.material];
    const materials = sourceMaterials.map((material) => createGrassAssetMaterial(material));
    templates.push({
      name: object.name || `Grass_Template_${templates.length + 1}`,
      geometry,
      material: Array.isArray(object.material) ? materials : materials[0],
      localMatrix: new THREE.Matrix4(),
    });
  });
  return templates;
}

function createGrassInstancedField(gltf, sourcePath) {
  const templates = collectGrassTemplates(gltf);
  if (templates.length === 0) {
    throw new Error(`No grass meshes found in ${sourcePath}`);
  }

  const matrices = createAnimatedGrassFieldMatrices();
  const field = ensureGrassAssetGroup();
  field.clear();

  for (const template of templates) {
    const isPrimaryGrassMesh = field.children.length === 0;
    const instanced = new THREE.InstancedMesh(
      template.geometry,
      template.material,
      matrices.length,
    );
    instanced.name = isPrimaryGrassMesh
      ? GRASS_FBX_MAIN_NAME
      : (template.name || `SceneV2_Animated_Grass_${field.children.length + 1}`);
    instanced.userData.sourceName = template.name;
    instanced.frustumCulled = false;
    instanced.castShadow = false;
    instanced.receiveShadow = false;
    instanced.renderOrder = 1;
    for (let i = 0; i < matrices.length; i++) {
      const matrix = matrices[i].clone().multiply(template.localMatrix);
      instanced.setMatrixAt(i, matrix);
    }
    instanced.instanceMatrix.needsUpdate = true;
    field.add(instanced);
  }

  sceneAssets.grassPatchCount = matrices.length;
  sceneAssets.grassSourceFiles = [sourcePath];
  return { field, patchCount: matrices.length };
}

function collectAssetGrassMeshes(root) {
  const meshes = [];
  root.updateMatrixWorld(true);
  root.traverse((object) => {
    if (!object.isMesh || !object.geometry) return;
    const geometry = object.geometry.clone();
    geometry.computeBoundingBox();
    const bounds = geometry.boundingBox;
    const center = bounds.getCenter(new THREE.Vector3());
    geometry.translate(-center.x, -bounds.min.y, -center.z);
    geometry.computeBoundingSphere();
    geometry.computeVertexNormals?.();
    meshes.push({
      geometry,
      material: createGrassAssetMaterial(object.material),
      name: object.name || `Asset_Grass_${meshes.length + 1}`,
    });
  });
  return meshes;
}

function createAssetGrassAccentMatrices(count, radiusMin, radiusMax, yOffset, scaleBase) {
  const matrices = [];
  const transform = new THREE.Object3D();
  for (let i = 0; i < count; i++) {
    const seed = i + 41;
    const angle = grassFieldRandom(seed) * TWO_PI;
    const radius = radiusMin + grassFieldRandom(seed + 3) * (radiusMax - radiusMin);
    const position = makeGrassPosition(
      Math.cos(angle) * radius + (grassFieldRandom(seed + 7) - 0.5) * 1.2,
      Math.sin(angle) * radius * 0.72 + (grassFieldRandom(seed + 11) - 0.5) * 1.2,
    );
    const scale = scaleBase * (0.72 + grassFieldRandom(seed + 17) * 0.5);
    transform.position.set(position.x, yOffset + grassFieldRandom(seed + 21) * 0.012, position.z);
    transform.rotation.set(0, grassFieldRandom(seed + 23) * TWO_PI, 0);
    transform.scale.set(scale * 0.9, scale * 0.16, scale * 0.9);
    transform.updateMatrix();
    matrices.push(transform.matrix.clone());
  }
  return matrices;
}

function addAssetGrassAccentMeshes(root, sourcePath, {
  count = 3,
  radiusMin = 2.8,
  radiusMax = 7.2,
  yOffset = 0.016,
  scaleBase = 0.22,
  maxMeshes = 1,
} = {}) {
  const meshes = collectAssetGrassMeshes(root).slice(0, maxMeshes);
  if (meshes.length === 0) return 0;
  const group = ensureGrassAssetGroup();
  const matrices = createAssetGrassAccentMatrices(count, radiusMin, radiusMax, yOffset, scaleBase);
  for (const mesh of meshes) {
    const instanced = new THREE.InstancedMesh(mesh.geometry, mesh.material, matrices.length);
    instanced.name = group.children.length === 0
      ? GRASS_FBX_MAIN_NAME
      : `${mesh.name}_Accent_${group.children.length + 1}`;
    instanced.frustumCulled = false;
    instanced.castShadow = false;
    instanced.receiveShadow = false;
    instanced.renderOrder = 2;
    for (let i = 0; i < matrices.length; i++) instanced.setMatrixAt(i, matrices[i]);
    instanced.instanceMatrix.needsUpdate = true;
    group.add(instanced);
  }
  sceneAssets.grassSourceFiles.push(sourcePath);
  return matrices.length * meshes.length;
}

function animationTrackTargetName(trackName) {
  const dotIndex = trackName.indexOf('.');
  return dotIndex > 0 ? trackName.slice(0, dotIndex) : '';
}

function remapGrassTrackName(trackName, targetRoot) {
  const dotIndex = trackName.indexOf('.');
  if (dotIndex <= 0) return trackName;
  const targetName = trackName.slice(0, dotIndex);
  if (targetRoot.getObjectByName(targetName)) return trackName;
  const targetAlias = {
    Grass: GRASS_FBX_GROUP_NAME,
    Grass_Implementation: GRASS_FBX_GROUP_NAME,
    [GRASS_FBX_GROUP_NAME]: GRASS_FBX_GROUP_NAME,
    [GRASS_FBX_MAIN_NAME]: GRASS_FBX_MAIN_NAME,
  }[targetName];
  if (!targetAlias || !targetRoot.getObjectByName(targetAlias)) return null;
  return `${targetAlias}${trackName.slice(dotIndex)}`;
}

function makeCompatibleGrassClip(clip, targetRoot) {
  const compatibleTracks = [];
  for (const track of clip.tracks || []) {
    const targetName = animationTrackTargetName(track.name);
    const remappedName = targetName
      ? remapGrassTrackName(track.name, targetRoot)
      : track.name;
    if (!remappedName) continue;
    const compatibleTrack = track.clone();
    compatibleTrack.name = remappedName;
    compatibleTracks.push(compatibleTrack);
  }
  if (compatibleTracks.length === 0) return null;
  return new THREE.AnimationClip(
    clip.name || 'Grass_FBX_Extracted_Loop',
    clip.duration,
    compatibleTracks,
    clip.blendMode,
  );
}

async function extractGrassFbxAnimations(targetRoot) {
  const sourcePath = `${NEW_ASSET_BASE}Animated%2BGrass.fbx`;
  try {
    const fbx = await loadFbxAsset(sourcePath);
    const animations = fbx.animations || [];
    if (animations.length === 0) {
      console.info(`Grass FBX has no animation clips: ${sourcePath}`);
      return 0;
    }

    const mixer = new THREE.AnimationMixer(targetRoot);
    let playable = 0;
    for (const clip of animations) {
      const compatibleClip = makeCompatibleGrassClip(clip, targetRoot);
      if (!compatibleClip) continue;
      const action = mixer.clipAction(compatibleClip);
      action.setLoop(THREE.LoopRepeat, Infinity);
      action.enabled = true;
      action.play();
      sceneAssets.grassActions.push(action);
      playable += 1;
    }

    if (playable > 0) {
      mixer.timeScale = comfortState.reducedMotion ? 0.32 : 0.82;
      sceneAssets.grassMixers.push(mixer);
      sceneAssets.grassSourceFiles.push(sourcePath);
      console.info(`Extracted ${playable} compatible grass animation clip(s) from ${sourcePath}`);
    } else {
      console.info(`Grass FBX clips did not target GLB nodes; shader wind remains active: ${sourcePath}`);
    }
    return playable;
  } catch (error) {
    console.warn(`Grass FBX animation extraction failed: ${sourcePath}`, error);
    return 0;
  }
}

async function initializeGrassAssets() {
  setAssetStatus('loading', 'Preparing grass field');
  sceneAssets.grassMixers = [];
  sceneAssets.grassActions = [];
  visualSettings.grassProfile = 'procedural-hyperreal-lawn';
  sceneAssets.grassProfile = visualSettings.grassProfile;
  sceneAssets.grassPatchCount = grassVisibleCount;
  sceneAssets.grassSourceFiles = [
    `${GRASS_ASSET_BASE}Animated%2BGrass.blend`,
    `${GRASS_ASSET_BASE}Animated%2BGrass.glb`,
    `${GRASS_ASSET_BASE}Animated%2BGrass.obj`,
    `${GRASS_ASSET_BASE}Animated%2BGrass.fbx`,
  ];
  grassMesh.visible = true;
  grassMesh.count = grassVisibleCount;

  const grassGroup = ensureGrassAssetGroup();
  grassGroup.clear();
  let assetAccentCount = 0;

  try {
    const gltf = await loadGltfAsset(`${GRASS_ASSET_BASE}Animated%2BGrass.glb`);
    assetAccentCount += addAssetGrassAccentMeshes(gltf.scene, `${GRASS_ASSET_BASE}Animated%2BGrass.glb`, {
      count: visualSettings.visualQuality === 'high' ? 5 : 3,
      radiusMin: 2.2,
      radiusMax: 7.8,
      yOffset: 0.012,
      scaleBase: 0.18,
    });
  } catch (error) {
    console.warn('Animated+Grass GLB accent load failed; procedural lawn remains active.', error);
  }

  try {
    const obj = await loadObjAsset(`${GRASS_ASSET_BASE}Animated%2BGrass.obj`);
    assetAccentCount += addAssetGrassAccentMeshes(obj, `${GRASS_ASSET_BASE}Animated%2BGrass.obj`, {
      count: visualSettings.visualQuality === 'high' ? 3 : 2,
      radiusMin: 4.4,
      radiusMax: 10.5,
      yOffset: 0.018,
      scaleBase: 0.14,
    });
  } catch (error) {
    console.warn('Animated+Grass OBJ accent load failed; GLB/procedural grass remains active.', error);
  }

  const extractedClips = assetAccentCount > 0
    ? await extractGrassFbxAnimations(grassGroup)
    : 0;
  sceneAssets.grassPatchCount = grassVisibleCount + assetAccentCount;
  visualSettings.grassProfile = extractedClips > 0
    ? 'procedural-lawn-asset-accents-fbx'
    : 'procedural-lawn-asset-accents';
  sceneAssets.grassProfile = visualSettings.grassProfile;
}

function createStarsModel(gltf) {
  if (sceneAssets.starsModel) return;
  const stars = gltf.scene;
  stars.name = 'SceneV2_Stars_GLB';
  fitObjectToHeight(stars, 96);
  centerObjectAt(stars, new THREE.Vector3(0, 0, 0));
  stars.traverse((object) => {
    if (object.isPoints) { object.frustumCulled = false; object.renderOrder = -18; return; }
    if (!object.isMesh) return;
    const src = object.material;
    const map = src?.map || src?.emissiveMap || null;
    object.material = new THREE.MeshBasicMaterial({
      map,
      color: map ? 0xffffff : 0xd8eeff,
      side: THREE.BackSide,
      depthWrite: false,
      depthTest: false,
      fog: false,
      toneMapped: false,
      transparent: true,
      opacity: src?.opacity ?? 0.94,
    });
    object.frustumCulled = false;
    object.renderOrder = -18;
  });
  addLegacyVisual(stars);
  sceneAssets.starsModel = stars;
                                                            
  starMat.uniforms.uStarOpacity.value = 0.22;
}

function createMoonGlowTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = 512;
  const ctx = canvas.getContext('2d');
  const grad = ctx.createRadialGradient(256, 256, 68, 256, 256, 256);
  grad.addColorStop(0, 'rgba(246, 242, 220, 0.42)');
  grad.addColorStop(0.34, 'rgba(218, 232, 255, 0.20)');
  grad.addColorStop(0.64, 'rgba(142, 190, 255, 0.065)');
  grad.addColorStop(1, 'rgba(142, 190, 255, 0)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  return tuneTexture(new THREE.CanvasTexture(canvas), { anisotropy: 1 });
}

function createMoonHalo() {
  if (sceneAssets.moonHalo) return;
  const halo = new THREE.Sprite(new THREE.SpriteMaterial({
    map: createMoonGlowTexture(),
    color: 0xf4f6ff,
    transparent: true,
    opacity: 0.5,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    depthTest: false,
    toneMapped: false,
  }));
  halo.name = 'SceneV2_Moon_Subtle_Glow';
  halo.position.copy(MOON_POS);
  halo.scale.setScalar(MOON_DIAMETER * 2.9);
  halo.renderOrder = -7;
  addLegacyVisual(halo);
  sceneAssets.moonHalo = halo;
}

function createMoon(texture, normalMap) {
  if (sceneAssets.moon) return;
  const moonMap = tuneMoonSurfaceTexture(texture);
  const moonBump = createMoonBumpTexture(moonMap);
  if (normalMap) tuneMoonSurfaceTexture(normalMap, { colorSpace: THREE.NoColorSpace });
  const moon = new THREE.Mesh(
    new THREE.SphereGeometry(MOON_DIAMETER * 0.5, 96, 64),
    new THREE.MeshStandardMaterial({
      map: moonMap,
      normalMap,
      bumpMap: moonBump,
      bumpScale: 0.026,
      color: 0xfaf4df,
      roughness: 0.97,
      metalness: 0,
      emissive: new THREE.Color(0xe8dfc6),
      emissiveMap: moonMap,
      emissiveIntensity: 0.075,
    }),
  );
  moon.position.copy(MOON_POS);
  moon.rotation.y = -0.42;
  addLegacyVisual(moon);

  sceneAssets.moon = moon;
  createMoonHalo();
}

function createMoonObject(sourceObject, detailTexture = null, { forGltf = false, sourceLabel = 'model' } = {}) {
  if (sceneAssets.moonModel) return;
  if (sceneAssets.moon) {
    sceneAssets.moon.removeFromParent();
    sceneAssets.moon = null;
  }
  const moon = sourceObject;
  moon.name = `SceneV2_Hyperreal_Moon_${sourceLabel}`;
  fitObjectToExactBox(moon, new THREE.Vector3(MOON_DIAMETER, MOON_DIAMETER, MOON_DIAMETER));
  centerObjectAt(moon, MOON_POS);
  moon.rotation.y -= 0.42;
  const moonMap = detailTexture
    ? tuneMoonSurfaceTexture(detailTexture, { forGltf })
    : null;
  const moonBump = createMoonBumpTexture(moonMap, { forGltf });
  moon.traverse((object) => {
    if (!object.isMesh) return;
    const sourceMaterial = object.material;
    const sourceMap = moonMap
      || tuneMoonSurfaceTexture(sourceMaterial?.map || sourceMaterial?.emissiveMap, { forGltf });
    const materialBump = moonBump || createMoonBumpTexture(sourceMap, { forGltf });
    const material = new THREE.MeshStandardMaterial({
      map: sourceMap,
      bumpMap: materialBump,
      bumpScale: materialBump ? 0.023 : 0,
      color: 0xfff8df,
      roughness: 0.92,
      metalness: 0,
      emissive: new THREE.Color(0xf5ecd0),
      emissiveMap: sourceMap,
      emissiveIntensity: 0.16,
      side: THREE.FrontSide,
    });
    if (sourceMaterial?.normalMap) {
      material.normalMap = tuneMoonSurfaceTexture(sourceMaterial.normalMap, {
        forGltf,
        colorSpace: THREE.NoColorSpace,
      });
      material.normalScale = sourceMaterial.normalScale?.clone?.() || new THREE.Vector2(0.55, 0.55);
    }
    material.envMapIntensity = 0.14;
    object.material = material;
    object.castShadow = false;
    object.receiveShadow = false;
    object.frustumCulled = false;
  });
  addLegacyVisual(moon);
  sceneAssets.moon = moon;
  sceneAssets.moonModel = moon;
  createMoonHalo();
}

function createMoonbeamCone() {
  if (sceneAssets.moonbeamCone) return;
  const coneGeo = new THREE.CylinderGeometry(1.5, 0.22, 14, 24, 1, true);
  const coneMat = new THREE.ShaderMaterial({
    uniforms: {
      uTime: sceneAssets.uniforms.uTime,
      uGroundSoftness: { value: 0.44 },
    },
    vertexShader: `
      varying vec2 vUv;
      void main() {
        vUv = uv;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }
    `,
    fragmentShader: `
      uniform float uTime;
      uniform float uGroundSoftness;
      varying vec2 vUv;
      void main() {
        float fadeY = (1.0 - vUv.y) * vUv.y * 3.8;
        float fadeEdge = 1.0 - abs(vUv.x - 0.5) * 1.9;
        float shimmer = 0.86 + 0.14 * sin(uTime * 0.36 + vUv.y * 15.0);
        float alpha = clamp(fadeY * fadeEdge * shimmer * uGroundSoftness * 0.14, 0.0, 1.0);
        gl_FragColor = vec4(0.86, 0.93, 1.0, alpha);
      }
    `,
    transparent: true,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    side: THREE.BackSide,
  });
  const cone = new THREE.Mesh(coneGeo, coneMat);
  cone.position.set(MOON_POS.x, 1.2, MOON_POS.z);
  cone.renderOrder = -2;
  addLegacyVisual(cone);
  sceneAssets.moonbeamCone = cone;
}

function createAurora() {
  if (sceneAssets.aurora) return;
  const aurora = new THREE.Mesh(
    new THREE.PlaneGeometry(24, 7.2, 80, 10),
    new THREE.ShaderMaterial({
      uniforms: {
        uTime: sceneAssets.uniforms.uTime,
        uIntensity: sceneAssets.uniforms.uAuroraIntensity,
      },
      vertexShader: `
        varying vec2 vUv;
        uniform float uTime;
        void main() {
          vUv = uv;
          vec3 p = position;
          p.y += sin(position.x * 0.32 + uTime * 0.18) * 0.24;
          p.y += sin(position.x * 0.68 - uTime * 0.12) * 0.12;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
        }
      `,
      fragmentShader: `
        varying vec2 vUv;
        uniform float uTime;
        uniform float uIntensity;
        float hash(vec2 p) {
          return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
        }
        float noise(vec2 p) {
          vec2 i = floor(p);
          vec2 f = fract(p);
          vec2 u = f * f * (3.0 - 2.0 * f);
          return mix(
            mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
            mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
            u.y
          );
        }
        void main() {
          float ribbon = smoothstep(0.06, 0.62, vUv.y) * (1.0 - smoothstep(0.62, 1.0, vUv.y));
          float wave = noise(vec2(vUv.x * 5.5 + uTime * 0.025, vUv.y * 3.0));
          float band = smoothstep(0.36, 0.9, sin(vUv.x * 12.0 + wave * 3.4 + uTime * 0.18) * 0.5 + 0.5);
          vec3 emerald = vec3(0.18, 1.0, 0.62);
          vec3 cyan = vec3(0.12, 0.76, 1.0);
          vec3 violet = vec3(0.42, 0.22, 0.86);
          vec3 color = mix(cyan, emerald, vUv.y);
          color = mix(color, violet, smoothstep(0.72, 1.0, vUv.y) * 0.42);
          float alpha = ribbon * band * (0.15 + wave * 0.42) * uIntensity;
          gl_FragColor = vec4(color, alpha);
        }
      `,
      transparent: true,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      side: THREE.DoubleSide,
    }),
  );
  aurora.position.set(0, 8.4, -23);
  aurora.rotation.x = -0.18;
  addLegacyVisual(aurora);
  sceneAssets.aurora = aurora;
}

function createAuroraModel(gltf) {
  if (sceneAssets.auroraModel) return;
  if (sceneAssets.aurora) {
    sceneAssets.aurora.removeFromParent();
    sceneAssets.aurora = null;
  }
  const aurora = gltf.scene;
  aurora.name = 'SceneV2_Aurora_Model';
  fitObjectToHeight(aurora, 7.2);
  aurora.scale.x *= 3.2;
  aurora.scale.z *= 1.45;
  centerObjectAt(aurora, new THREE.Vector3(0, 8.4, -23.5));
  aurora.rotation.x = -0.16;
  aurora.traverse((object) => {
    if (!object.isMesh) return;
    const source = object.material;
    const map = source?.map || source?.emissiveMap || null;
    object.material = new THREE.MeshBasicMaterial({
      map,
      color: 0xd8fff1,
      transparent: true,
      opacity: comfortState.reducedMotion ? 0.28 : 0.44,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      side: THREE.DoubleSide,
      toneMapped: false,
    });
    object.frustumCulled = false;
    object.renderOrder = -1;
  });
  addLegacyVisual(aurora);
  sceneAssets.aurora = aurora;
  sceneAssets.auroraModel = aurora;
}

function createSanctuaryPineMaterial(sourceMaterial, variant = 0, depthTone = 'mid') {
  const map = sourceMaterial?.map || sourceMaterial?.emissiveMap || null;
  const alphaMap = sourceMaterial?.alphaMap || null;
  if (map) {
    map.colorSpace = THREE.SRGBColorSpace;
    map.anisotropy = Math.min(4, renderer.capabilities.getMaxAnisotropy());
    map.needsUpdate = true;
  }
  if (alphaMap) {
    alphaMap.anisotropy = Math.min(4, renderer.capabilities.getMaxAnisotropy());
    alphaMap.needsUpdate = true;
  }
  const color = new THREE.Color(variant % 2 === 0 ? 0x11261f : 0x0c1e24);
  if (depthTone === 'front' || depthTone === 'back') {
    color.lerp(new THREE.Color(0x244a32), 0.46);
    color.offsetHSL(0.01, 0.06, 0.018);
  } else {
    color.offsetHSL(0, 0, -0.03 - variant * 0.012);
  }
  const material = new THREE.MeshStandardMaterial({
    map,
    alphaMap,
    color,
    roughness: 0.98,
    metalness: 0,
    transparent: Boolean(sourceMaterial?.transparent || alphaMap),
    opacity: Math.min(sourceMaterial?.opacity ?? 0.96, 0.96),
    alphaTest: Math.max(sourceMaterial?.alphaTest || 0, map || alphaMap ? 0.035 : 0),
    side: THREE.DoubleSide,
    depthWrite: true,
  });
  material.emissive = new THREE.Color(depthTone === 'front' || depthTone === 'back' ? 0x03100a : 0x010506);
  material.emissiveIntensity = depthTone === 'front' || depthTone === 'back' ? 0.046 : 0.026;
  material.envMapIntensity = depthTone === 'front' || depthTone === 'back' ? 0.055 : 0.022;
  material.fog = true;
  return material;
}

function prepareSanctuaryPineSource(source, variant = 0, depthTone = 'mid') {
  source.name = `SceneV2_Sanctuary_Pine_Source_${variant + 1}_${depthTone}`;
  fitObjectToHeight(source, 1);
  placeObjectOnGroundCenter(source, new THREE.Vector3(0, 0, 0), 0);
  source.traverse((object) => {
    if (!object.isMesh) return;
    const materials = Array.isArray(object.material) ? object.material : [object.material];
    object.material = materials.map((material, materialIndex) => createSanctuaryPineMaterial(
      material,
      variant + materialIndex,
      depthTone,
    ));
    if (Array.isArray(object.material) && object.material.length === 1) {
      object.material = object.material[0];
    }
    object.castShadow = false;
    object.receiveShadow = false;
    object.frustumCulled = true;
  });
  return source;
}

function createProceduralPineSource(variant = 0, depthTone = 'mid') {
  const source = new THREE.Group();
  source.name = `SceneV2_Sanctuary_Procedural_Pine_${variant + 1}_${depthTone}`;
  const trunk = new THREE.Mesh(
    new THREE.CylinderGeometry(0.09, 0.14, 0.52, 5),
    new THREE.MeshStandardMaterial({
      color: depthTone === 'front' || depthTone === 'back' ? 0x26311f : 0x121815,
      roughness: 1,
      metalness: 0,
    }),
  );
  trunk.material.fog = true;
  trunk.position.y = 0.26;
  source.add(trunk);
  const needleMat = createSanctuaryPineMaterial(null, variant, depthTone);
  for (let layer = 0; layer < 3; layer++) {
    const cone = new THREE.Mesh(
      new THREE.ConeGeometry(0.54 - layer * 0.1, 0.82, 6),
      needleMat,
    );
    cone.position.y = 0.68 + layer * 0.29;
    source.add(cone);
  }
  fitObjectToHeight(source, 1);
  placeObjectOnGroundCenter(source, new THREE.Vector3(0, 0, 0), 0);
  return source;
}

function createProceduralSanctuaryHills(group) {
  const hillCount = visualSettings.visualQuality === 'high' ? 24 : 18;
  const hillGeo = new THREE.SphereGeometry(1, 14, 5, 0, TWO_PI, 0, Math.PI / 2);
  const hillMaterials = [
    new THREE.MeshStandardMaterial({
      color: 0x081616,
      roughness: 1,
      metalness: 0,
      emissive: 0x010505,
      emissiveIntensity: 0.04,
    }),
    new THREE.MeshStandardMaterial({
      color: 0x0b1b22,
      roughness: 1,
      metalness: 0,
      emissive: 0x020708,
      emissiveIntensity: 0.04,
    }),
  ];
  for (const material of hillMaterials) material.fog = true;

  for (let i = 0; i < hillCount; i++) {
    const seed = 1200 + i * 37;
    const angle = (i / hillCount) * TWO_PI + (grassFieldRandom(seed) - 0.5) * 0.18;
    const radius = 43.5 + grassFieldRandom(seed + 3) * 9.5;
    const hill = new THREE.Mesh(hillGeo, hillMaterials[i % hillMaterials.length]);
    hill.name = `SceneV2_Sanctuary_Hill_${i + 1}`;
    hill.position.set(
      SANCTUARY_CENTER.x + Math.cos(angle) * radius,
      -0.42 - grassFieldRandom(seed + 5) * 0.22,
      SANCTUARY_CENTER.z + Math.sin(angle) * radius,
    );
    hill.rotation.y = angle + Math.PI / 2 + (grassFieldRandom(seed + 7) - 0.5) * 0.45;
    hill.scale.set(
      7.8 + grassFieldRandom(seed + 11) * 8.2,
      1.0 + grassFieldRandom(seed + 13) * 1.45,
      3.8 + grassFieldRandom(seed + 17) * 4.6,
    );
    hill.castShadow = false;
    hill.receiveShadow = false;
    hill.frustumCulled = true;
    group.add(hill);
  }
  return hillCount;
}

function prepareSanctuaryHillSource(source) {
  source.name = 'SceneV2_Sanctuary_Hill_Source_GLB';
  fitObjectToHeight(source, 1);
  placeObjectOnGroundCenter(source, new THREE.Vector3(0, 0, 0), 0);
  source.traverse((object) => {
    if (!object.isMesh) return;
    const materials = Array.isArray(object.material) ? object.material : [object.material];
    object.material = materials.map((material, index) => {
      const sourceMap = material?.map || material?.emissiveMap || null;
      if (sourceMap) {
        sourceMap.colorSpace = THREE.SRGBColorSpace;
        sourceMap.anisotropy = Math.min(4, renderer.capabilities.getMaxAnisotropy());
        sourceMap.needsUpdate = true;
      }
      const hillMaterial = new THREE.MeshStandardMaterial({
        map: sourceMap,
        color: index % 2 === 0 ? 0x314d3a : 0x263f39,
        roughness: 0.96,
        metalness: 0,
        side: THREE.DoubleSide,
        depthWrite: true,
      });
      hillMaterial.emissive = new THREE.Color(index % 2 === 0 ? 0x0a1d10 : 0x07191a);
      hillMaterial.emissiveIntensity = 0.12;
      hillMaterial.envMapIntensity = 0.1;
      hillMaterial.fog = true;
      return hillMaterial;
    });
    if (Array.isArray(object.material) && object.material.length === 1) {
      object.material = object.material[0];
    }
    object.castShadow = false;
    object.receiveShadow = false;
    object.frustumCulled = true;
  });
  return source;
}

function placeSanctuaryHillModels(group, hillSource) {
  const hillCount = visualSettings.visualQuality === 'high' ? 36 : 28;
  for (let i = 0; i < hillCount; i++) {
    const seed = 5200 + i * 67;
    const angle = (i / hillCount) * TWO_PI + (grassFieldRandom(seed) - 0.5) * 0.045;
    const radius = 27.2 + grassFieldRandom(seed + 3) * 3.8;
    const hill = hillSource.clone(true);
    hill.name = `SceneV2_Sanctuary_Hill_GLB_${i + 1}`;
    const wideScale = 18.0 + grassFieldRandom(seed + 5) * 12.0;
    hill.scale.x *= wideScale;
    hill.scale.y *= 4.0 + grassFieldRandom(seed + 7) * 1.9;
    hill.scale.z *= 8.2 + grassFieldRandom(seed + 11) * 5.8;
    hill.rotation.y = angle + Math.PI / 2 + (grassFieldRandom(seed + 17) - 0.5) * 0.18;
    placeObjectOnGroundCenter(
      hill,
      new THREE.Vector3(
        SANCTUARY_CENTER.x + Math.cos(angle) * radius,
        0,
        SANCTUARY_CENTER.z + Math.sin(angle) * radius,
      ),
      -0.06 - grassFieldRandom(seed + 13) * 0.04,
    );
    hill.traverse((object) => {
      if (!object.isMesh) return;
      object.frustumCulled = false;
      object.renderOrder = -0.6;
    });
    group.add(hill);
  }
  return hillCount;
}

async function createSanctuaryHills(group) {
  try {
    const gltf = await loadGltfAsset(`${NEW_ASSET_BASE}hill.glb`);
    const hillSource = prepareSanctuaryHillSource(gltf.scene);
    return {
      count: placeSanctuaryHillModels(group, hillSource),
      profile: 'hill-glb',
      sourceFiles: [`${NEW_ASSET_BASE}hill.glb`],
    };
  } catch (error) {
    console.warn('Sanctuary hill GLB unavailable; using procedural hill fallback.', error);
    return {
      count: createProceduralSanctuaryHills(group),
      profile: 'procedural-hills',
      sourceFiles: [],
    };
  }
}

function placeSanctuaryPines(group, pineSources) {
  const pineCount = visualSettings.visualQuality === 'high' ? 520 : 360;
  for (let i = 0; i < pineCount; i++) {
    const seed = 3000 + i * 53;
    const angle = (i / pineCount) * TWO_PI + (grassFieldRandom(seed) - 0.5) * 0.06;
    const frontFactor = smoothstep(-0.2, 0.82, Math.sin(angle));
    const depthTone = frontFactor > 0.48 ? 'front' : 'back';
    const behindUserBias = frontFactor > 0.88 ? 3.4 : 0;
    const ringLayer = i % 3;
    const radius = 32.2
      + ringLayer * 3.25
      + grassFieldRandom(seed + 3) * 5.4
      + behindUserBias;
    const sourceSet = pineSources[i % pineSources.length];
    const source = sourceSet[depthTone] || sourceSet.mid || sourceSet.front || sourceSet.back;
    const pine = source.clone(true);
    pine.name = `SceneV2_Sanctuary_Pine_${i + 1}`;
    const height = (3.25 + grassFieldRandom(seed + 7) * 4.35) * (0.94 + ringLayer * 0.035);
    const widthScale = 1.04 + grassFieldRandom(seed + 11) * 0.74;
    pine.scale.multiplyScalar(height);
    pine.scale.x *= widthScale;
    pine.scale.z *= 0.98 + grassFieldRandom(seed + 13) * 0.56;
    pine.rotation.y = angle + Math.PI + (grassFieldRandom(seed + 17) - 0.5) * 1.08;
    placeObjectOnGroundCenter(
      pine,
      new THREE.Vector3(
        SANCTUARY_CENTER.x + Math.cos(angle) * radius,
        0,
        SANCTUARY_CENTER.z + Math.sin(angle) * radius,
      ),
      -0.04 - ringLayer * 0.012 - grassFieldRandom(seed + 19) * 0.08,
    );
    pine.traverse((object) => {
      if (!object.isMesh) return;
      object.frustumCulled = true;
      object.renderOrder = -0.2;
    });
    group.add(pine);
  }
  return pineCount;
}

async function createSanctuaryBorder() {
  if (sceneAssets.sanctuaryGroup) return;
  const group = new THREE.Group();
  group.name = 'SceneV2_Sanctuary_Forest_Border';
  addLegacyVisual(group);
  sceneAssets.sanctuaryGroup = group;

  const pineAssets = [
    `${NEW_ASSET_BASE}pine_tree1.glb`,
    `${NEW_ASSET_BASE}pine_tree2.glb`,
  ];
  const pineSources = [];
  const loadedSourceFiles = [];
  for (let i = 0; i < pineAssets.length; i++) {
    const path = pineAssets[i];
    try {
      const gltf = await loadGltfAsset(path);
      pineSources.push({
        front: prepareSanctuaryPineSource(gltf.scene.clone(true), i, 'front'),
        back: prepareSanctuaryPineSource(gltf.scene.clone(true), i, 'back'),
      });
      loadedSourceFiles.push(path);
    } catch (error) {
      console.warn(`Sanctuary pine GLB unavailable: ${path}`, error);
    }
  }

  if (pineSources.length === 0) {
    pineSources.push(
      {
        front: createProceduralPineSource(0, 'front'),
        back: createProceduralPineSource(0, 'back'),
      },
      {
        front: createProceduralPineSource(1, 'front'),
        back: createProceduralPineSource(1, 'back'),
      },
    );
  }

  const hillResult = await createSanctuaryHills(group);
  const pineCount = placeSanctuaryPines(group, pineSources);
  sceneAssets.sanctuarySourceFiles = [...loadedSourceFiles, ...hillResult.sourceFiles];
  sceneAssets.sanctuaryPineCount = pineCount;
  sceneAssets.sanctuaryHillCount = hillResult.count;
  const pineProfile = loadedSourceFiles.length === pineAssets.length
    ? 'dense-pine-glb'
    : loadedSourceFiles.length > 0
      ? 'dense-pine-partial'
      : 'dense-procedural-pine';
  visualSettings.forestProfile = `${pineProfile}-${hillResult.profile}`;
  sceneAssets.forestProfile = visualSettings.forestProfile;
  console.info(`Created sanctuary border: ${pineCount} pines, ${hillResult.count} hills, profile=${visualSettings.forestProfile}`);
}

async function loadBushFlowers() {
  if (sceneAssets.bushGroup) return;
  const group = new THREE.Group();
  group.name = 'SceneV2_Ground_Botanical_Accents';
  sceneAssets.bushGroup = group;
  addLegacyVisual(group);

  const clusters = [
    { pos: [-7.4, 0.0, -2.4], ry: 0.48,  scale: 0.62, height: 0.72, v: 0 },
    { pos: [ 7.2, 0.0, -2.8], ry: -0.56, scale: 0.66, height: 0.78, v: 1 },
    { pos: [-4.9, 0.0, -5.0], ry: 1.12,  scale: 0.52, height: 0.68, v: 3 },
    { pos: [ 5.3, 0.0, -5.7], ry: -1.28, scale: 0.58, height: 0.72, v: 4 },
    { pos: [-8.9, 0.0, -8.3], ry: 1.68,  scale: 0.74, height: 0.86, v: 1 },
    { pos: [ 9.4, 0.0, -8.8], ry: -1.74, scale: 0.78, height: 0.9,  v: 0 },
    { pos: [-3.5, 0.0,-11.2], ry: 0.26,  scale: 0.6,  height: 0.76, v: 4 },
    { pos: [ 4.2, 0.0,-11.8], ry: -0.34, scale: 0.62, height: 0.78, v: 3 },
    { pos: [ 0.0, 0.0,-14.6], ry: 0.12,  scale: 0.68, height: 0.82, v: 2 },
    { pos: [-13.2,0.0, -4.2], ry: 2.12,  scale: 0.76, height: 0.86, v: 4 },
    { pos: [ 13.5,0.0, -5.0], ry: -2.06, scale: 0.8,  height: 0.9,  v: 3 },
    { pos: [-15.7,0.0,-10.6], ry: 2.74,  scale: 0.92, height: 1.0,  v: 0 },
    { pos: [ 16.2,0.0,-11.2], ry: -2.82, scale: 0.88, height: 0.98, v: 1 },
    { pos: [-9.8, 0.0,-17.2], ry: 1.36,  scale: 0.84, height: 0.94, v: 3 },
    { pos: [ 10.6,0.0,-17.6], ry: -1.24, scale: 0.9,  height: 0.98, v: 4 },
    { pos: [-20.4,0.0, -7.8], ry: 2.34,  scale: 0.88, height: 1.0,  v: 1 },
    { pos: [ 21.0,0.0, -8.8], ry: -2.4,  scale: 0.9,  height: 1.0,  v: 0 },
    { pos: [-22.0,0.0,-16.8], ry: 2.96,  scale: 1.02, height: 1.12, v: 4 },
    { pos: [ 22.6,0.0,-17.4], ry: -2.9,  scale: 1.0,  height: 1.1,  v: 3 },
    { pos: [-6.0, 0.0,-22.0], ry: 0.86,  scale: 0.92, height: 1.02, v: 2 },
    { pos: [ 6.8, 0.0,-22.4], ry: -0.94, scale: 0.92, height: 1.02, v: 2 },
    { pos: [-16.8,0.0,-24.6], ry: 1.86,  scale: 1.0,  height: 1.08, v: 0 },
    { pos: [ 17.4,0.0,-25.0], ry: -1.78, scale: 1.0,  height: 1.08, v: 1 },
    { pos: [-28.2,0.0,-12.8], ry: 2.62,  scale: 1.08, height: 1.16, v: 3 },
    { pos: [ 28.6,0.0,-13.6], ry: -2.58, scale: 1.08, height: 1.16, v: 4 },
  ];

  const includeHeavyBushes = visualSettings.visualQuality === 'high'
    || ['1', 'true', 'yes'].includes((urlParams.get('heavyBushes') || '').toLowerCase());
  const bushAssets = [
    { index: 0, path: `${NEW_ASSET_BASE}bush1.glb`, height: 0.82 },
    { index: 1, path: `${NEW_ASSET_BASE}bush2.glb`, height: 0.88 },
    { index: 2, path: `${NEW_ASSET_BASE}bush3.glb`, height: 1.08, highOnly: true },
    { index: 3, path: `${NEW_ASSET_BASE}bush4.glb`, height: 0.74 },
    { index: 4, path: `${NEW_ASSET_BASE}bush5.glb`, height: 0.8 },
  ];
  const loadedBushes = [];
  for (const asset of bushAssets) {
    if (asset.highOnly && !includeHeavyBushes) continue;
    try {
      const gltf = await loadGltfAsset(asset.path);
      loadedBushes.push({ ...asset, scene: gltf.scene });
    } catch (error) {
      console.warn(`Bush GLB unavailable: ${asset.path}`, error);
    }
  }

  if (loadedBushes.length === 0) {
    const fallbackPaths = [
      `${NEW_ASSET_BASE}lowpoly_flower_bushes.glb`,
      `${NEW_ASSET_BASE}low_poly_bush_forsythia.glb`,
    ];
    for (let i = 0; i < fallbackPaths.length; i++) {
      try {
        const gltf = await loadGltfAsset(fallbackPaths[i]);
        loadedBushes.push({ index: i, path: fallbackPaths[i], height: 0.82, scene: gltf.scene });
      } catch (error) {
        console.warn(`Fallback bush GLB unavailable: ${fallbackPaths[i]}`, error);
      }
    }
  }

  if (loadedBushes.length === 0) {
    console.warn('Bush GLBs unavailable; using procedural fallback.');
    _createProceduralBushes(group, clusters);
    return;
  }

  const chooseBush = (variety) => loadedBushes.find((asset) => asset.index === variety)
    || loadedBushes[variety % loadedBushes.length];

  for (let i = 0; i < clusters.length; i++) {
    const cluster = clusters[i];
    const sourceAsset = chooseBush(cluster.v);
    const bush = sourceAsset.scene.clone(true);
    fitObjectToHeight(bush, cluster.height || sourceAsset.height || 0.84);
    const seed = 7400 + i * 97 + cluster.v * 11;
    bush.rotation.y = cluster.ry + (grassFieldRandom(seed) - 0.5) * 0.42;
    bush.scale.multiplyScalar(cluster.scale * (0.9 + grassFieldRandom(seed + 3) * 0.2));
    placeObjectOnGroundCenter(
      bush,
      new THREE.Vector3(cluster.pos[0], cluster.pos[1], cluster.pos[2]),
      0.006 + grassFieldRandom(seed + 7) * 0.012,
    );
    bush.traverse((object) => {
      if (!object.isMesh) return;
      const mats = Array.isArray(object.material) ? object.material : [object.material];
      object.material = mats.map((m) => {
        const c = m?.clone?.() || new THREE.MeshStandardMaterial();
        if (c.map) {
          c.map.colorSpace = THREE.SRGBColorSpace;
          c.map.anisotropy = Math.min(8, renderer.capabilities.getMaxAnisotropy());
          c.map.needsUpdate = true;
        }
        if (!c.map && c.color) {
          const lushTint = new THREE.Color(0x4f9b43).lerp(new THREE.Color(0xf1b7ca), cluster.v === 1 ? 0.18 : 0.04);
          c.color.lerp(lushTint, 0.34);
        }
        c.roughness = Math.max(c.roughness ?? 0.8, 0.72);
        c.metalness = 0;
        c.emissive = new THREE.Color(cluster.v === 1 ? 0xffd2a4 : 0xf3aac8);
        c.emissiveIntensity = 0.006;
        c.envMapIntensity = 0.16;
        c.side = THREE.DoubleSide;
        c.alphaTest = Math.max(c.alphaTest || 0, 0.04);
        c.userData.baseEmissiveIntensity = 0.006;
        c.needsUpdate = true;
        return c;
      });
      if (Array.isArray(object.material) && object.material.length === 1) {
        object.material = object.material[0];
      }
      object.castShadow = false;
      object.receiveShadow = false;
      object.frustumCulled = true;
      object.userData.botanicalAccent = true;
    });
    group.add(bush);
  }
  sceneAssets.bushSourceFiles = loadedBushes.map((asset) => asset.path);
  sceneAssets.bushClusterCount = clusters.length;
  console.info(`Loaded ${loadedBushes.length} bush variety GLB(s) - placed ${clusters.length} botanical clusters.`);
}

function _createProceduralBushes(group, clusters) {
  const flowerTex = (() => {
    const cv = document.createElement('canvas');
    cv.width = 64; cv.height = 64;
    const c = cv.getContext('2d');
    const g = c.createRadialGradient(32, 32, 2, 32, 32, 28);
    g.addColorStop(0, 'rgba(255,175,205,1)');
    g.addColorStop(0.5, 'rgba(255,130,172,0.9)');
    g.addColorStop(1, 'rgba(255,80,140,0)');
    c.fillStyle = g;
    c.beginPath(); c.arc(32, 32, 28, 0, Math.PI * 2); c.fill();
    const t = new THREE.CanvasTexture(cv);
    t.colorSpace = THREE.SRGBColorSpace;
    return t;
  })();
  for (const cl of clusters) {
    const bush = new THREE.Group();
    bush.add(new THREE.Mesh(
      new THREE.SphereGeometry(0.42, 8, 6),
      new THREE.MeshStandardMaterial({ color: 0x3d8b3d, roughness: 0.92 }),
    ));
    const fm = new THREE.MeshBasicMaterial({ map: flowerTex, transparent: true, side: THREE.DoubleSide, depthWrite: false, opacity: 0.9 });
    for (let f = 0; f < 10; f++) {
      const tAngle = f * (Math.PI * 2 / 10) + Math.random() * 0.4;
      const phi = Math.random() * Math.PI * 0.7;
      const r = 0.34 + Math.random() * 0.12;
      const fl = new THREE.Mesh(new THREE.PlaneGeometry(0.18, 0.18), fm);
      fl.position.set(Math.sin(phi)*Math.cos(tAngle)*r, Math.abs(Math.cos(phi))*0.38+0.06, Math.sin(phi)*Math.sin(tAngle)*r);
      fl.rotation.y = tAngle;
      bush.add(fl);
    }
    bush.position.set(...cl.pos); bush.rotation.y = cl.ry; bush.scale.setScalar(cl.scale);
    group.add(bush);
  }
}

function applyOakAssetMaterials(oak, textures) {
  sceneAssets.leafMaterial = createAssetLeafMaterial(textures);
  sceneAssets.barkMaterial = new THREE.MeshStandardMaterial({
    map: textures.bark,
    normalMap: textures.barkNormal,
    roughnessMap: textures.barkRoughness,
    color: 0xffffff,
    roughness: 0.86,
    metalness: 0,
    emissive: BARK_GLOW.clone(),
    emissiveIntensity: 0.035,
  });

  oak.traverse((object) => {
    if (!object.isMesh) return;
    object.frustumCulled = true;
    object.castShadow = visualSettings.visualQuality === 'high';
    object.receiveShadow = visualSettings.visualQuality === 'high';
    if (object.name.includes('Oak_Leaves')) {
      object.material = sceneAssets.leafMaterial;
      object.geometry.computeBoundingSphere();
      object.geometry.setDrawRange(0, Infinity);
      sceneAssets.oakLeaves.push(object);
      if (object.name.includes('LOD0')) sceneAssets.oakLeavesLod0 = object;
      if (object.name.includes('LOD1')) {
        sceneAssets.oakLeavesLod1 = object;
        object.visible = false;
      }
    } else {
      object.material = sceneAssets.barkMaterial;
    }
  });
}

async function initializeSceneV2Assets() {
  const loadStartedAt = performance.now();
  setAssetStatus('loading', 'Preparing scene');
  let usingFallbackTree = true;
  try {
    createGeneratedEnvironment();

    let blossomFallback = null;
    try {
      const blossomResult = await loadFirstTextureAsset(
        visualSettings.visualQuality === 'quest'
          ? [
            `${SCENE_V2_BASE}sakura_blossom_atlas.ktx2`,
            `${SCENE_V2_BASE}sakura_blossom_atlas.webp`,
          ]
          : [`${SCENE_V2_BASE}sakura_blossom_atlas.webp`],
        { anisotropy: 4 },
      );
      const petalResult = await loadFirstTextureAsset(
        visualSettings.visualQuality === 'quest'
          ? [
            `${SCENE_V2_BASE}sakura_petal_particle.ktx2`,
            `${SCENE_V2_BASE}sakura_petal_particle.webp`,
          ]
          : [`${SCENE_V2_BASE}sakura_petal_particle.webp`],
        { anisotropy: 2 },
      );
      blossomFallback = blossomResult.texture;
      visualSettings.textureProfile = blossomResult.path.endsWith('.ktx2') ? 'ktx2' : 'webp';
      sceneAssets.textureProfile = visualSettings.textureProfile;
      const petalTexture = petalResult.texture;
      fallingLeafMat.map = petalTexture;
      fallingLeafMat.color.set(0xffffff);
      fallingLeafMat.needsUpdate = true;
    } catch (textureError) {
      console.warn('Sakura derived textures unavailable; using embedded and procedural colors.', textureError);
    }

    setAssetStatus('loading', 'Loading sakura');
    try {
      const treeCandidates = visualSettings.visualQuality === 'quest'
        ? [
          `${SCENE_V2_BASE}sakura_quest_lod0.glb`,
          `${SCENE_V2_BASE}sakura_quest_lod1.glb`,
          `${SCENE_V2_BASE}sakura.glb`,
        ]
        : [
          `${SCENE_V2_BASE}sakura.glb`,
          `${SCENE_V2_BASE}sakura_quest_lod0.glb`,
        ];
      const { gltf, path } = await loadFirstGltfAsset(treeCandidates);
      setAssetStatus('loading', 'Optimizing sakura');
      const sakura = gltf.scene;
      sakura.name = 'SceneV2_Coherence_Sakura';
      fitObjectToHeight(sakura, 5.65);
      placeObjectOnGround(sakura, TREE_POS);
      sakura.userData.baseScale = sakura.scale.clone();
      sakura.userData.basePosition = sakura.position.clone();
      applySakuraAssetMaterials(sakura, { blossom: blossomFallback });
      addLegacyVisual(sakura);
      sceneAssets.treeModel = sakura;
      sceneAssets.oakGroup = sakura;
      sceneAssets.treeBaseScale.copy(sakura.scale);
      sceneAssets.treeBasePosition.copy(sakura.position);
      sceneAssets.assetProfile = path.includes('_quest') ? 'quest' : 'source';
      sceneAssets.activeTreeLod = path.includes('lod1')
        ? 'lod1'
        : path.includes('lod0')
          ? 'lod0'
          : 'source';
      sceneAssets.treeLods[sceneAssets.activeTreeLod] = sakura;
      visualSettings.assetProfile = sceneAssets.assetProfile;
      visualSettings.activeTreeLod = sceneAssets.activeTreeLod;
      treeGroup.visible = false;
      usingFallbackTree = false;

      if (visualSettings.visualQuality === 'quest' && sceneAssets.activeTreeLod === 'lod0') {
        try {
          const lod1Gltf = await loadGltfAsset(`${SCENE_V2_BASE}sakura_quest_lod1.glb`);
          const sakuraLod1 = lod1Gltf.scene;
          sakuraLod1.name = 'SceneV2_Coherence_Sakura_LOD1';
          fitObjectToHeight(sakuraLod1, 5.65);
          placeObjectOnGround(sakuraLod1, TREE_POS);
          sakuraLod1.userData.baseScale = sakuraLod1.scale.clone();
          sakuraLod1.userData.basePosition = sakuraLod1.position.clone();
          applySakuraAssetMaterials(sakuraLod1, { blossom: blossomFallback }, { reset: false });
          sakuraLod1.visible = false;
          addLegacyVisual(sakuraLod1);
          sceneAssets.treeLods.lod1 = sakuraLod1;
        } catch (lodError) {
          console.warn('Sakura LOD1 unavailable; staying on active tree LOD.', lodError);
        }
      }
    } catch (treeError) {
      console.warn('Sakura GLB failed; using procedural sakura fallback.', treeError);
      treeGroup.visible = true;
    }

                                                                              
    {
      const cloudOrigin = TREE_POS.clone().add(new THREE.Vector3(0, 3.5, 0));
      const leafCloudN = visualSettings.visualQuality === 'quest' ? 900 : 1400;
      sakuraLeafCloud = new SakuraLeafCloud(cloudOrigin, leafCloudN);
      if (blossomFallback) sakuraLeafCloud.setTexture(blossomFallback);
      addLegacyVisual(sakuraLeafCloud.mesh);
    }

    setAssetStatus('loading', 'Preparing star field');
    skyDome.visible = true;
    skyMat.uniforms.skyMap.value = null;
    skyMat.uniforms.useSkyMap.value = 0;
    sceneAssets.skyTexture = null;
    sceneAssets.nightSkyTexture = null;
    sceneAssets.skyProfile = 'procedural-twinkling-stars';
    visualSettings.skyProfile = 'procedural-twinkling-stars';
    if (sceneAssets.skyModel) {
      sceneAssets.skyModel.removeFromParent();
      sceneAssets.skyModel = null;
    }
    if (sceneAssets.starsModel) {
      sceneAssets.starsModel.removeFromParent();
      sceneAssets.starsModel = null;
    }

    setAssetStatus('loading', 'Applying baked ambience');
    await applyBakedSceneAo();
    await initializeGrassAssets();

    setAssetStatus('loading', 'Growing forest border');
    await createSanctuaryBorder();

    setAssetStatus('loading', 'Loading moon');
    try {
      const moonDetailPromise = loadTextureAsset(`${NEW_ASSET_BASE}8k_moon.jpg`, {
        anisotropy: MOON_TEXTURE_ANISOTROPY,
      }).then((texture) => texture).catch((textureError) => {
        console.warn('8K moon texture optional load failed; using model embedded texture.', textureError);
        return null;
      });
      try {
        const [moonFbx, moonDetail] = await Promise.all([
          loadFbxAsset(`${NEW_ASSET_BASE}Moon.fbx`),
          moonDetailPromise,
        ]);
        createMoonObject(moonFbx, moonDetail, { forGltf: false, sourceLabel: 'FBX' });
      } catch (fbxMoonError) {
        console.warn('Moon FBX failed; using GLB moon backup.', fbxMoonError);
        const moonCandidates = [
          `${NEW_ASSET_BASE}moon.glb`,
          `${NEW_ASSET_BASE}moon%20(1).glb`,
          ...(visualSettings.visualQuality === 'quest'
            ? [`${SCENE_V2_BASE}moon_quest.glb`, `${SCENE_V2_BASE}moon.glb`]
            : [`${SCENE_V2_BASE}moon.glb`, `${SCENE_V2_BASE}moon_quest.glb`]),
        ];
        const [{ gltf: moonGltf }, moonDetail] = await Promise.all([
          loadFirstGltfAsset(moonCandidates),
          moonDetailPromise,
        ]);
        createMoonObject(moonGltf.scene, moonDetail, { forGltf: true, sourceLabel: 'GLB' });
      }
    } catch (moonError) {
      console.warn('Moon model loading failed; using lightweight moon fallback.', moonError);
      try {
        const [{ texture: moonAlbedo }, moonNormal] = await Promise.all([
          loadFirstTextureAsset([
            `${NEW_ASSET_BASE}8k_moon.jpg`,
            `${SCENE_V2_BASE}moon_albedo.webp`,
          ], { anisotropy: MOON_TEXTURE_ANISOTROPY }),
          loadTextureAsset(`${SCENE_V2_BASE}moon_normal.webp`, { anisotropy: 2, colorSpace: THREE.NoColorSpace }),
        ]);
        createMoon(moonAlbedo, moonNormal);
      } catch (fallbackMoonError) {
        console.warn('Moon fallback textures failed; continuing without model moon.', fallbackMoonError);
      }
    }

                                                    
    await loadBushFlowers();
    await loadOrganicGroundDetails();

    visualSettings.assetLoadMs = Math.round(performance.now() - loadStartedAt);
    sceneAssets.assetLoadMs = visualSettings.assetLoadMs;
    setAssetStatus(usingFallbackTree ? 'fallback' : 'ready', usingFallbackTree ? 'Using fallback tree' : 'Scene ready');
  } catch (error) {
    console.warn('Scene v2 initialization failed; using procedural fallback.', error);
    visualSettings.assetLoadMs = Math.round(performance.now() - loadStartedAt);
    sceneAssets.assetLoadMs = visualSettings.assetLoadMs;
    sceneAssets.skyProfile = 'procedural';
    visualSettings.skyProfile = 'procedural';
    setAssetStatus('fallback', 'Using fallback scene');
  } finally {
    setTimeout(hideLoadingOverlay, 500);
  }
}

const groundTexture = createGrassGroundTexture();
const groundBumpTexture = createGrassGroundBumpTexture();
const groundGeo = new THREE.CircleGeometry(42, 192);
const groundMat = new THREE.MeshStandardMaterial({
  map: groundTexture,
  bumpMap: groundBumpTexture,
  bumpScale: 0.035,
  color: 0xa9c982,
  roughness: 0.98,
  metalness: 0.0,
});
const ground = new THREE.Mesh(groundGeo, groundMat);
ground.rotation.x = -Math.PI / 2;
ground.position.set(TREE_POS.x, -0.045, TREE_POS.z + 1.5);
ground.visible = true;
ground.receiveShadow = false;
addLegacyVisual(ground);

const canopyShadowMat = new THREE.MeshBasicMaterial({
  map: createShadowTexture(),
  transparent: true,
  opacity: 0.42,
  depthWrite: false,
});
const canopyShadow = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), canopyShadowMat);
canopyShadow.position.set(TREE_POS.x, 0.012, TREE_POS.z + 0.12);
canopyShadow.rotation.x = -Math.PI / 2;
canopyShadow.scale.set(5.4, 3.8, 1);
canopyShadow.visible = false;
addLegacyVisual(canopyShadow);

const clearingRingGeo = new THREE.RingGeometry(1.95, 2.08, 128);
const clearingRingMat = new THREE.MeshBasicMaterial({
  color: 0x9ee6c0,
  transparent: true,
  opacity: 0.15,
  side: THREE.DoubleSide,
  depthWrite: false,
});
const clearingRing = new THREE.Mesh(clearingRingGeo, clearingRingMat);
clearingRing.position.set(TREE_POS.x, 0.025, TREE_POS.z);
clearingRing.rotation.x = -Math.PI / 2;
addLegacyVisual(clearingRing);

const guideRingGeo = new THREE.TorusGeometry(2.02, 0.012, 12, 160);
const guideRingMat = new THREE.MeshBasicMaterial({
  color: 0x8ee9c3,
  transparent: true,
  opacity: 0.35,
  blending: THREE.AdditiveBlending,
  depthWrite: false,
});
const guideRing = new THREE.Mesh(guideRingGeo, guideRingMat);
guideRing.position.set(TREE_POS.x, 0.05, TREE_POS.z);
guideRing.rotation.x = Math.PI / 2;
addLegacyVisual(guideRing);

const guideMarkerMat = new THREE.MeshBasicMaterial({
  color: 0xd8fff0,
  transparent: true,
  opacity: 0.78,
  blending: THREE.AdditiveBlending,
  depthWrite: false,
});
const guideMarker = new THREE.Mesh(new THREE.SphereGeometry(0.055, 16, 12), guideMarkerMat);
addLegacyVisual(guideMarker);

const treeGroup = new THREE.Group();
treeGroup.position.copy(TREE_POS);
addLegacyVisual(treeGroup);

const barkTexture = createBarkTexture();
const oakLeafTexture = createOakLeafTexture();
const grassTexture = createGrassTexture();
const dummy = new THREE.Object3D();

const trunkMat = new THREE.MeshStandardMaterial({
  map: barkTexture,
  bumpMap: barkTexture,
  bumpScale: 0.08,
  color: BARK.clone(),
  roughness: 0.86,
  metalness: 0.0,
  emissive: BARK_GLOW.clone(),
  emissiveIntensity: 0.045,
});
const branchMat = trunkMat.clone();
branchMat.color = new THREE.Color(0x5c3f2e);

function createOakTrunkGeometry() {
  const geometry = new THREE.CylinderGeometry(0.29, 0.58, 3.55, 34, 16);
  const position = geometry.attributes.position;
  for (let i = 0; i < position.count; i++) {
    const x = position.getX(i);
    const y = position.getY(i);
    const z = position.getZ(i);
    const t = (y + 1.775) / 3.55;
    const angle = Math.atan2(z, x);
    const rootSwell = 1 + Math.pow(1 - t, 2.3) * 0.23;
    const furrow = 1
      + Math.sin(angle * 5.0 + t * 7.2) * 0.045
      + Math.sin(angle * 11.0 - t * 5.5) * 0.025;
    const bendX = Math.sin(t * Math.PI * 0.92) * 0.045;
    const bendZ = Math.sin(t * Math.PI * 1.35 + 0.7) * 0.028;
    position.setXYZ(
      i,
      x * rootSwell * furrow + bendX,
      y,
      z * rootSwell * furrow + bendZ,
    );
  }
  geometry.computeVertexNormals();
  return geometry;
}

const trunk = new THREE.Mesh(
  createOakTrunkGeometry(),
  trunkMat,
);
trunk.position.set(0, 1.78, 0);
trunk.rotation.z = -0.035;
treeGroup.add(trunk);

function createBranchSegment(start, end, radiusStart, radiusEnd, radialSegments = 16) {
  const direction = end.clone().sub(start);
  const length = direction.length();
  const mesh = new THREE.Mesh(
    new THREE.CylinderGeometry(radiusEnd, radiusStart, length, radialSegments, 2),
    branchMat,
  );
  mesh.position.copy(start).add(end).multiplyScalar(0.5);
  mesh.quaternion.setFromUnitVectors(
    new THREE.Vector3(0, 1, 0),
    direction.clone().normalize(),
  );
  return mesh;
}

function createOakBranch(points, baseRadius, tipRadius) {
  const group = new THREE.Group();
  const vectors = points.map((point) => new THREE.Vector3(...point));
  for (let i = 0; i < vectors.length - 1; i++) {
    const t0 = i / (vectors.length - 1);
    const t1 = (i + 1) / (vectors.length - 1);
    const r0 = lerp(baseRadius, tipRadius, t0);
    const r1 = lerp(baseRadius, tipRadius, t1);
    group.add(createBranchSegment(vectors[i], vectors[i + 1], r0, r1));
  }
  return group;
}

for (const branch of [
  [[[0.02, 2.22, 0.02], [-0.42, 2.58, -0.16], [-1.18, 2.95, -0.48], [-2.06, 3.16, -0.3]], 0.19, 0.045],
  [[[0.0, 2.35, 0.01], [0.44, 2.68, -0.18], [1.22, 3.06, -0.52], [2.05, 3.28, -0.34]], 0.18, 0.043],
  [[[-0.02, 2.52, 0.02], [-0.56, 2.84, 0.25], [-1.34, 3.18, 0.62], [-2.0, 3.5, 0.82]], 0.16, 0.038],
  [[[0.02, 2.6, 0.0], [0.52, 2.96, 0.22], [1.34, 3.38, 0.62], [1.92, 3.72, 0.72]], 0.15, 0.036],
  [[[0.0, 2.82, -0.02], [-0.24, 3.22, -0.15], [-0.6, 3.82, -0.28], [-0.92, 4.24, -0.08]], 0.12, 0.03],
  [[[0.04, 2.92, -0.02], [0.28, 3.3, -0.22], [0.66, 3.86, -0.32], [1.06, 4.22, -0.06]], 0.12, 0.03],
  [[[0.0, 3.0, 0.0], [0.06, 3.42, 0.05], [0.08, 3.9, -0.02], [0.0, 4.3, -0.06]], 0.115, 0.035],
]) {
  treeGroup.add(createOakBranch(branch[0], branch[1], branch[2]));
}

for (const root of [
  [[[-0.07, 0.18, 0.04], [-0.46, 0.06, 0.3], [-1.05, 0.025, 0.52]], 0.16, 0.055],
  [[[0.08, 0.16, 0.02], [0.5, 0.06, 0.28], [1.1, 0.025, 0.48]], 0.15, 0.05],
  [[[0.0, 0.14, -0.08], [-0.36, 0.055, -0.44], [-0.92, 0.02, -0.84]], 0.145, 0.045],
  [[[0.04, 0.13, -0.08], [0.38, 0.055, -0.46], [0.96, 0.02, -0.88]], 0.14, 0.043],
  [[[0.02, 0.15, 0.08], [0.06, 0.052, 0.55], [0.14, 0.02, 1.06]], 0.13, 0.038],
]) {
  treeGroup.add(createOakBranch(root[0], root[1], root[2]));
}

const canopyGroup = new THREE.Group();
canopyGroup.position.set(0, 3.42, 0);
treeGroup.add(canopyGroup);

const clusterMat = new THREE.MeshStandardMaterial({
  color: LEAF_HIGH.clone(),
  roughness: 0.9,
  metalness: 0.0,
  flatShading: false,
});
const clusterGeo = new THREE.IcosahedronGeometry(1, 3);
const canopyLobes = [
  [0, 0.04, -0.08, 1.42, 0.74, 1.02],
  [-0.94, -0.08, -0.2, 0.94, 0.56, 0.76],
  [0.92, -0.05, -0.24, 0.96, 0.58, 0.78],
  [-1.24, 0.16, 0.38, 0.78, 0.5, 0.62],
  [1.2, 0.2, 0.34, 0.8, 0.52, 0.64],
  [-0.55, 0.44, -0.28, 0.88, 0.56, 0.66],
  [0.52, 0.46, -0.32, 0.86, 0.54, 0.64],
  [-0.24, 0.58, 0.38, 0.82, 0.5, 0.62],
  [0.28, 0.56, 0.38, 0.82, 0.5, 0.62],
  [-0.44, -0.22, 0.7, 0.86, 0.5, 0.64],
  [0.46, -0.18, 0.68, 0.86, 0.5, 0.64],
  [0.02, -0.26, -0.86, 0.96, 0.54, 0.72],
  [-1.46, 0.32, -0.18, 0.58, 0.42, 0.48],
  [1.46, 0.34, -0.18, 0.58, 0.42, 0.48],
];
const lobeWeights = canopyLobes.map((lobe) => lobe[3] * lobe[4] * lobe[5]);
const totalLobeWeight = lobeWeights.reduce((sum, value) => sum + value, 0);

for (const cluster of canopyLobes) {
  const mesh = new THREE.Mesh(clusterGeo, clusterMat);
  mesh.position.set(cluster[0], cluster[1], cluster[2]);
  mesh.scale.set(cluster[3], cluster[4], cluster[5]);
  mesh.rotation.set(Math.random() * 0.24, Math.random() * TWO_PI, Math.random() * 0.18);
  canopyGroup.add(mesh);
}

function pickCanopyLobe() {
  let roll = Math.random() * totalLobeWeight;
  for (let i = 0; i < canopyLobes.length; i++) {
    roll -= lobeWeights[i];
    if (roll <= 0) return canopyLobes[i];
  }
  return canopyLobes[0];
}

const leafCount = useLegacyScene ? 2600 : 1;
const leafGeo = new THREE.PlaneGeometry(0.19, 0.095);
const leafMat = new THREE.MeshStandardMaterial({
  map: oakLeafTexture,
  color: LEAF_HIGH.clone(),
  roughness: 0.92,
  side: THREE.DoubleSide,
  alphaTest: 0.28,
  vertexColors: true,
});
const leafMesh = new THREE.InstancedMesh(leafGeo, leafMat, leafCount);
leafMesh.instanceMatrix.setUsage(THREE.StaticDrawUsage);
for (let i = 0; i < leafCount; i++) {
  const lobe = pickCanopyLobe();
  const theta = Math.random() * TWO_PI;
  const phi = Math.acos(2 * Math.random() - 1);
  const shell = 0.58 + Math.pow(Math.random(), 0.42) * 0.52;
  const x = lobe[0] + Math.sin(phi) * Math.cos(theta) * lobe[3] * shell;
  const y = lobe[1] + Math.cos(phi) * lobe[4] * shell + Math.random() * 0.08;
  const z = lobe[2] + Math.sin(phi) * Math.sin(theta) * lobe[5] * shell;
  dummy.position.set(x, y, z);
  dummy.rotation.set(
    Math.random() * Math.PI,
    Math.atan2(x, z) + Math.PI * 0.5 + (Math.random() - 0.5) * 1.6,
    (Math.random() - 0.5) * 0.95,
  );
  const s = 0.78 + Math.random() * 0.82;
  dummy.scale.set(s * (0.86 + Math.random() * 0.35), s, s);
  dummy.updateMatrix();
  leafMesh.setMatrixAt(i, dummy.matrix);
  const color = new THREE.Color().setHSL(
    0.94 + Math.random() * 0.045,
    0.28 + Math.random() * 0.22,
    0.66 + Math.random() * 0.16,
  );
  leafMesh.setColorAt(i, color);
}
leafMesh.instanceColor.needsUpdate = true;
leafMesh.count = Math.floor(leafCount * treeVitality.leafDensity);
canopyGroup.add(leafMesh);

const grassGridColumns = useLegacyScene
  ? (visualSettings.visualQuality === 'high' ? 860 : 660)
  : 1;
const grassGridRows = useLegacyScene
  ? (visualSettings.visualQuality === 'high' ? 620 : 475)
  : 1;
const grassCapacity = grassGridColumns * grassGridRows;
const grassGeo = createGrassClumpGeometry();
const grassMat = new THREE.MeshStandardMaterial({
  map: grassTexture,
  color: 0x7cb866,
  roughness: 0.98,
  side: THREE.DoubleSide,
  alphaTest: 0.14,
  transparent: true,
  vertexColors: true,
});
attachGrassWindShader(grassMat, 'procedural');
const grassMesh = new THREE.InstancedMesh(grassGeo, grassMat, grassCapacity);
grassMesh.instanceMatrix.setUsage(THREE.StaticDrawUsage);
grassMesh.frustumCulled = false;
grassMesh.visible = false;
grassMesh.count = 0;
let grassVisibleCount = 0;
const grassFieldRadiusX = 40.5;
const grassFieldRadiusZ = 34.5;
const fieldCenterZ = TREE_POS.z + 1.5;
for (let row = 0; row < grassGridRows; row++) {
  for (let col = 0; col < grassGridColumns; col++) {
    const seed = (row + 19) * 911 + (col + 37) * 3571;
    const jitterX = (grassFieldRandom(seed) - 0.5) * 1.12;
    const jitterZ = (grassFieldRandom(seed + 5) - 0.5) * 1.12;
    const u = -1 + ((col + 0.5) / grassGridColumns) * 2 + jitterX / grassGridColumns;
    const v = -1 + ((row + 0.5) / grassGridRows) * 2 + jitterZ / grassGridRows;
    const ellipse = u * u + v * v;
    if (ellipse > 1.0 || grassVisibleCount >= grassCapacity) continue;
    const edgeFade = 1 - smoothstep(0.78, 1.0, ellipse);
    const densityVariation = 0.94 + grassFieldRandom(seed + 11) * 0.24;

  dummy.position.set(
      TREE_POS.x + u * grassFieldRadiusX,
      0.002 + grassFieldRandom(seed + 17) * 0.012,
      fieldCenterZ + v * grassFieldRadiusZ,
  );
    dummy.rotation.set(
      0,
      grassFieldRandom(seed + 23) * TWO_PI,
      (grassFieldRandom(seed + 29) - 0.5) * 0.035,
    );
    const height = (0.78 + grassFieldRandom(seed + 31) * 0.96) * densityVariation * (0.9 + edgeFade * 0.12);
    const width = (1.22 + grassFieldRandom(seed + 41) * 0.96) * densityVariation;
  dummy.scale.set(
    width,
    height,
    width,
  );
  dummy.updateMatrix();
    grassMesh.setMatrixAt(grassVisibleCount, dummy.matrix);
  const color = new THREE.Color().setHSL(
      0.27 + grassFieldRandom(seed + 47) * 0.06,
      0.4 + grassFieldRandom(seed + 53) * 0.26,
      0.21 + grassFieldRandom(seed + 59) * 0.17 + edgeFade * 0.025,
  );
    grassMesh.setColorAt(grassVisibleCount, color);
    grassVisibleCount += 1;
  }
}
grassMesh.instanceColor.needsUpdate = true;
grassMesh.instanceMatrix.needsUpdate = true;
addLegacyVisual(grassMesh);

function createGlowTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 64;
  canvas.height = 64;
  const ctx = canvas.getContext('2d');
  const grad = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
  grad.addColorStop(0, 'rgba(255,255,255,1)');
  grad.addColorStop(0.22, 'rgba(255,255,255,0.55)');
  grad.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, 64, 64);
  return new THREE.CanvasTexture(canvas);
}

const fireflyCount = useLegacyScene
  ? (visualSettings.visualQuality === 'high' ? 960 : 720)
  : 0;
const fireflyGeo = new THREE.BufferGeometry();
const fireflyPositions = new Float32Array(fireflyCount * 3);
const fireflyPhases = new Float32Array(fireflyCount);
const fireflySizes = new Float32Array(fireflyCount);
const fireflySeeds = [];
for (let i = 0; i < fireflyCount; i++) {
  const seed = {
    angle: Math.random() * TWO_PI,
    radius: 1.2 + Math.random() * 4.4,
    height: 0.7 + Math.random() * 3.7,
    speed: 0.022 + Math.random() * 0.07,
    wobble: Math.random() * TWO_PI,
    phase: Math.random() * TWO_PI,
    radialSpan: 0.16 + Math.random() * 0.38,
    verticalSpan: 0.08 + Math.random() * 0.28,
    driftX: -0.32 + Math.random() * 0.64,
    driftZ: -0.32 + Math.random() * 0.64,
  };
  fireflySeeds.push(seed);
  fireflyPhases[i] = Math.random();
  fireflySizes[i] = 0.78 + Math.random() * 0.7;
  fireflyPositions[i * 3] = TREE_POS.x + Math.cos(seed.angle) * seed.radius;
  fireflyPositions[i * 3 + 1] = seed.height;
  fireflyPositions[i * 3 + 2] = TREE_POS.z + Math.sin(seed.angle) * seed.radius;
}
fireflyGeo.setAttribute('position', new THREE.BufferAttribute(fireflyPositions, 3));
fireflyGeo.setAttribute('fireflyPhase', new THREE.BufferAttribute(fireflyPhases, 1));
fireflyGeo.setAttribute('fireflySize', new THREE.BufferAttribute(fireflySizes, 1));
const fireflyMat = new THREE.ShaderMaterial({
  uniforms: {
    uTime: sceneAssets.uniforms.uTime,
    uOpacity: { value: 0.2 },
    uBaseSize: { value: 0.08 },
    uBreathGlow: { value: 0.5 },
    uReducedMotion: { value: 0 },
  },
  vertexShader: `
    attribute float fireflyPhase;
    attribute float fireflySize;
    varying float vGlow;
    varying float vTone;
    uniform float uTime;
    uniform float uBaseSize;
    uniform float uBreathGlow;
    uniform float uReducedMotion;
    void main() {
      float motion = mix(1.0, 0.38, uReducedMotion);
      float flicker = sin(uTime * motion * (0.72 + fireflyPhase * 0.9) + fireflyPhase * 24.1);
      float ember = sin(uTime * motion * (0.18 + fireflyPhase * 0.36) + fireflyPhase * 51.7);
      vGlow = clamp(0.64 + flicker * 0.16 + ember * 0.1 + uBreathGlow * 0.32, 0.34, 1.25);
      vTone = fireflyPhase;
      vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
      gl_Position = projectionMatrix * mvPosition;
      gl_PointSize = clamp(uBaseSize * fireflySize * vGlow * (145.0 / max(8.0, -mvPosition.z)), 3.0, 13.5);
    }
  `,
  fragmentShader: `
    varying float vGlow;
    varying float vTone;
    uniform float uOpacity;
    void main() {
      vec2 p = gl_PointCoord - 0.5;
      float d = length(p) * 2.0;
      float core = 1.0 - smoothstep(0.0, 0.34, d);
      float halo = 1.0 - smoothstep(0.18, 1.0, d);
      float alpha = (core * 0.72 + halo * 0.52) * uOpacity * vGlow;
      if (alpha <= 0.006) discard;
      vec3 amber = vec3(1.0, 0.72, 0.30);
      vec3 gold = vec3(1.0, 0.92, 0.58);
      vec3 softGreen = vec3(0.56, 1.0, 0.68);
      vec3 color = mix(amber, gold, core);
      color = mix(color, softGreen, smoothstep(0.82, 1.0, vTone) * 0.18);
      gl_FragColor = vec4(color, alpha);
    }
  `,
  transparent: true,
  blending: THREE.AdditiveBlending,
  depthWrite: false,
  depthTest: true,
  toneMapped: false,
});
const fireflies = new THREE.Points(fireflyGeo, fireflyMat);
addLegacyVisual(fireflies);

const fallingLeafCount = useLegacyScene ? 86 : 1;
const fallingLeafGeo = new THREE.PlaneGeometry(0.105, 0.055);
const fallingLeafMat = new THREE.MeshBasicMaterial({
  color: 0xffc6d5,
  transparent: true,
  opacity: 0.1,
  side: THREE.DoubleSide,
  depthWrite: false,
});
const fallingLeaves = new THREE.InstancedMesh(fallingLeafGeo, fallingLeafMat, fallingLeafCount);
fallingLeaves.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
const fallingLeafData = [];

function resetFallingLeaf(i, fromTop = true) {
  const angle = Math.random() * TWO_PI;
  const radius = Math.random() * 1.4;
  fallingLeafData[i] = {
    x: Math.cos(angle) * radius,
    y: fromTop ? 3.1 + Math.random() * 1.1 : 0.3 + Math.random() * 3.6,
    z: Math.sin(angle) * radius,
    drift: -0.18 + Math.random() * 0.36,
    speed: 0.14 + Math.random() * 0.28,
    spin: Math.random() * TWO_PI,
    scale: 0.72 + Math.random() * 0.62,
  };
}

for (let i = 0; i < fallingLeafCount; i++) resetFallingLeaf(i, false);
addLegacyVisual(fallingLeaves);

const blossomCount = useLegacyScene ? 150 : 1;
const blossomGeo = new THREE.SphereGeometry(0.028, 8, 6);
const blossomMat = new THREE.MeshBasicMaterial({
  color: 0xffd7c2,
  transparent: true,
  opacity: 0,
  depthWrite: false,
});
const blossomMesh = new THREE.InstancedMesh(blossomGeo, blossomMat, blossomCount);
blossomMesh.instanceMatrix.setUsage(THREE.StaticDrawUsage);
for (let i = 0; i < blossomCount; i++) {
  const theta = Math.random() * TWO_PI;
  const phi = Math.acos(2 * Math.random() - 1);
  const shell = 0.78 + Math.random() * 0.28;
  dummy.position.set(
    Math.sin(phi) * Math.cos(theta) * 1.35 * shell,
    Math.cos(phi) * 0.82 * shell + Math.random() * 0.1,
    Math.sin(phi) * Math.sin(theta) * 1.08 * shell,
  );
  dummy.scale.setScalar(0.65 + Math.random() * 0.7);
  dummy.updateMatrix();
  blossomMesh.setMatrixAt(i, dummy.matrix);
}
blossomMesh.count = 0;
canopyGroup.add(blossomMesh);

const metricsCanvas = document.createElement('canvas');
metricsCanvas.width = 512;
metricsCanvas.height = 256;
const metricsTexture = new THREE.CanvasTexture(metricsCanvas);
metricsTexture.minFilter = THREE.LinearFilter;
const metricsPanel = new THREE.Mesh(
  new THREE.PlaneGeometry(0.68, 0.34),
  new THREE.MeshBasicMaterial({
    map: metricsTexture,
    transparent: true,
    side: THREE.DoubleSide,
  }),
);
metricsPanel.position.set(-1.18, 1.42, -2.25);
metricsPanel.rotation.y = 0.26;
metricsPanel.layers.set(SANCTUARY_LAYERS.clinical);
scene.add(metricsPanel);

const statusCanvas = document.createElement('canvas');
statusCanvas.width = 768;
statusCanvas.height = 256;
const statusTexture = new THREE.CanvasTexture(statusCanvas);
statusTexture.minFilter = THREE.LinearFilter;
const statusPanel = new THREE.Mesh(
  new THREE.PlaneGeometry(1.02, 0.34),
  new THREE.MeshBasicMaterial({
    map: statusTexture,
    transparent: true,
    side: THREE.DoubleSide,
  }),
);
statusPanel.position.set(0, 0.78, -2.08);
statusPanel.layers.set(SANCTUARY_LAYERS.clinical);
scene.add(statusPanel);

const resultCanvas = document.createElement('canvas');
resultCanvas.width = 640;
resultCanvas.height = 360;
const resultTexture = new THREE.CanvasTexture(resultCanvas);
resultTexture.minFilter = THREE.LinearFilter;
const resultPanel = new THREE.Mesh(
  new THREE.PlaneGeometry(0.92, 0.52),
  new THREE.MeshBasicMaterial({
    map: resultTexture,
    transparent: true,
    side: THREE.DoubleSide,
  }),
);
resultPanel.position.set(0, 1.54, -2.18);
resultPanel.visible = false;
resultPanel.layers.set(SANCTUARY_LAYERS.clinical);
scene.add(resultPanel);

const profileCanvas = document.createElement('canvas');
profileCanvas.width = 512;
profileCanvas.height = 560;
const profileTexture = new THREE.CanvasTexture(profileCanvas);
profileTexture.minFilter = THREE.LinearFilter;
const profilePanel = new THREE.Mesh(
  new THREE.PlaneGeometry(0.88, 0.96),
  new THREE.MeshBasicMaterial({
    map: profileTexture,
    transparent: true,
    side: THREE.DoubleSide,
  }),
);
profilePanel.position.set(0, 1.94, -2.24);
profilePanel.visible = profileState.enabled;
profilePanel.renderOrder = 12;
profilePanel.layers.set(SANCTUARY_LAYERS.clinical);
scene.add(profilePanel);

const commandPanel = new THREE.Group();
commandPanel.position.set(1.06, 1.2, -2.22);
commandPanel.rotation.y = -0.34;
commandPanel.name = 'Essential session actions';
commandPanel.layers.set(SANCTUARY_LAYERS.interactive);
scene.add(commandPanel);

const commandButtons = [];
const commandHitTargets = [];
const xrControllers = [];

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

function createButtonTexture(label, color) {
  const canvas = document.createElement('canvas');
  canvas.width = 320;
  canvas.height = 96;
  const texture = new THREE.CanvasTexture(canvas);
  texture.minFilter = THREE.LinearFilter;
  texture.userData.label = label;
  texture.userData.color = color;
  return texture;
}

function redrawButtonTexture(texture, { label, enabled, active, pending }) {
  const key = `${label}:${enabled}:${active}:${pending}`;
  if (texture.userData.renderKey === key) return;
  texture.userData.renderKey = key;
  const canvas = texture.image;
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = enabled ? texture.userData.color : '#52615f';
  roundRect(ctx, 0, 0, canvas.width, canvas.height, 22);
  ctx.fill();
  ctx.strokeStyle = pending
    ? '#ffffff'
    : active
      ? '#d8fff0'
      : 'rgba(255,255,255,0.34)';
  ctx.lineWidth = active || pending ? 7 : 3;
  roundRect(ctx, 4, 4, canvas.width - 8, canvas.height - 8, 19);
  ctx.stroke();
  ctx.fillStyle = enabled ? '#07111f' : '#d4dfdc';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.font = `bold ${label.length > 12 ? 25 : label.length > 9 ? 28 : 32}px system-ui, sans-serif`;
  ctx.fillText(label, canvas.width / 2, canvas.height / 2);
  texture.needsUpdate = true;
}

function addCommandButton(
  label,
  command,
  x,
  y,
  color,
  onPress = null,
  controlKey = null,
) {
  const texture = createButtonTexture(label, color);
  const mesh = new THREE.Mesh(
    new THREE.PlaneGeometry(0.42, 0.135),
    new THREE.MeshBasicMaterial({
      map: texture,
      transparent: true,
      side: THREE.DoubleSide,
    }),
  );
  mesh.position.set(x, y, 0);
  mesh.userData.command = command;
  mesh.userData.onPress = onPress;
  mesh.userData.label = label;
  mesh.userData.controlKey = controlKey;
  mesh.userData.enabled = true;
  mesh.userData.active = false;
  mesh.userData.baseScale = 1;
  mesh.layers.set(SANCTUARY_LAYERS.interactive);
  commandPanel.add(mesh);

  const hitTarget = new THREE.Mesh(
    new THREE.PlaneGeometry(0.44, 0.155),
    new THREE.MeshBasicMaterial({
      color: 0xd8fff0,
      transparent: true,
      opacity: 0,
      side: THREE.DoubleSide,
      depthWrite: false,
    }),
  );
  hitTarget.position.set(x, y, 0.014);
  hitTarget.userData.command = command;
  hitTarget.userData.onPress = onPress;
  hitTarget.userData.visual = mesh;
  hitTarget.layers.set(SANCTUARY_LAYERS.interactive);
  commandPanel.add(hitTarget);
  mesh.userData.hitTarget = hitTarget;

  commandButtons.push(mesh);
  commandHitTargets.push(hitTarget);
  redrawButtonTexture(texture, {
    label,
    enabled: true,
    active: false,
    pending: false,
  });
}

addCommandButton('Start', 'start', -0.23, 0.09, '#4ade80');
addCommandButton('Pause', 'pause', 0.23, 0.09, '#f6cf5b');
addCommandButton('Resume', 'resume', -0.23, -0.09, '#67c9e8');
addCommandButton('Stop', 'stop', 0.23, -0.09, '#e68b9b');

refreshVrCommandControls = () => {
  const now = performance.now();
  if (commandUiState.pending && now >= commandUiState.until) {
    commandUiState.pending = null;
    commandUiState.message = 'No confirmation received - check the host connection';
    commandUiState.tone = 'error';
    commandUiState.until = now + 6000;
  }
  if (!commandUiState.pending && now >= commandUiState.until) {
    commandUiState.tone = 'neutral';
  }
  for (const mesh of commandButtons) {
    const command = mesh.userData.command;
    let enabled = true;
    let active = false;
    let label = mesh.userData.label;
    if (command === 'start') enabled = !sessionState.active && !sessionState.starting;
    if (command === 'pause') enabled = sessionState.active && !sessionState.paused;
    if (command === 'resume') enabled = sessionState.active && sessionState.paused;
    if (command === 'stop') enabled = sessionState.active || sessionState.starting;
    mesh.userData.enabled = enabled;
    mesh.userData.active = active;
    mesh.material.opacity = enabled ? 1 : 0.62;
    redrawButtonTexture(mesh.material.map, {
      label,
      enabled,
      active,
      pending: commandUiState.pending === command,
    });
    const target = mesh.userData.hitTarget;
    if (target) target.userData.disabled = !enabled;
  }
};
refreshVrCommandControls();

const controllerRaycaster = new THREE.Raycaster();
controllerRaycaster.far = 8;
controllerRaycaster.layers.set(SANCTUARY_LAYERS.interactive);
const controllerMatrix = new THREE.Matrix4();

function controllerHits(controller) {
  controller.updateMatrixWorld(true);
  commandPanel.updateMatrixWorld(true);
  for (const target of commandHitTargets) target.updateMatrixWorld(true);

  controllerMatrix.identity().extractRotation(controller.matrixWorld);
  controllerRaycaster.ray.origin.setFromMatrixPosition(controller.matrixWorld);
  controllerRaycaster.ray.direction.set(0, 0, -1).applyMatrix4(controllerMatrix);
  return controllerRaycaster.intersectObjects(commandHitTargets, false);
}

function pressCommandTarget(target) {
  if (target.userData.disabled) {
    setCommandFeedback('That control is unavailable in the current session state', 'warning');
    return false;
  }
  const action = target.userData.onPress;
  if (typeof action === 'function') {
    action();
    return true;
  }
  const command = target.userData.command;
  if (command) sendCommand(command);
  return Boolean(command);
}

function pulseController(controller, intensity = 0.45, durationMs = 36) {
  const gamepad = controller.userData.inputSource?.gamepad;
  const actuator = gamepad?.hapticActuators?.[0] || gamepad?.vibrationActuator;
  try {
    actuator?.pulse?.(intensity, durationMs);
  } catch (_) {
                                                                             
  }
}

function handleControllerSelect(controller) {
  const now = performance.now();
  if (now - (controller.userData.lastCommandPressAt || 0) < 260) return;

  const hits = controllerHits(controller);
  if (hits.length > 0) {
    controller.userData.lastCommandPressAt = now;
    const accepted = pressCommandTarget(hits[0].object);
    pulseController(controller, accepted ? 0.48 : 0.16, accepted ? 42 : 24);
  }
}

function updateControllerButtonHover() {
  for (const target of commandHitTargets) {
    target.material.opacity = 0;
    const visual = target.userData.visual;
    if (visual) visual.scale.setScalar(1);
  }

  for (const controller of xrControllers) {
    const hits = controllerHits(controller);
    const line = controller.userData.rayLine;
    if (hits.length > 0) {
      const target = hits[0].object;
      target.material.opacity = 0.13;
      const visual = target.userData.visual;
      if (visual) visual.scale.setScalar(1.08);
      if (line) line.material.opacity = 0.82;
    } else if (line) {
      line.material.opacity = 0.36;
    }
  }
}

for (let i = 0; i < 2; i++) {
  const controller = renderer.xr.getController(i);
  controller.addEventListener('connected', (event) => {
    controller.userData.inputSource = event.data;
  });
  controller.addEventListener('disconnected', () => {
    controller.userData.inputSource = null;
  });
  controller.addEventListener('selectstart', () => handleControllerSelect(controller));
  controller.addEventListener('select', () => handleControllerSelect(controller));
  controller.addEventListener('squeeze', () => handleControllerSelect(controller));
  const lineGeo = new THREE.BufferGeometry().setFromPoints([
    new THREE.Vector3(0, 0, 0),
    new THREE.Vector3(0, 0, -3.2),
  ]);
  const line = new THREE.Line(
    lineGeo,
    new THREE.LineBasicMaterial({
      color: 0x8ee9c3,
      transparent: true,
      opacity: 0.36,
    }),
  );
  controller.userData.rayLine = line;
  controller.add(line);
  scene.add(controller);
  xrControllers.push(controller);
}

function coherenceLabel(value) {
  if (value >= 0.85) return 'Peak';
  if (value >= 0.7) return 'High';
  if (value >= 0.4) return 'Building';
  return 'Gentle';
}

function formatTime(seconds) {
  const total = Math.max(0, Math.floor(seconds || 0));
  const minutes = String(Math.floor(total / 60)).padStart(2, '0');
  const secs = String(total % 60).padStart(2, '0');
  return `${minutes}:${secs}`;
}

function formatDurationText(seconds) {
  const total = Math.max(0, Math.floor(seconds || 0));
  const minutes = Math.floor(total / 60);
  const secs = total % 60;
  if (minutes > 0) return `${minutes}m ${secs}s`;
  return `${secs}s`;
}

function formatCompactNumber(value) {
  if (!Number.isFinite(value)) return '--';
  const abs = Math.abs(value);
  if (abs >= 1000000) return `${(value / 1000000).toFixed(1)}m`;
  if (abs >= 1000) return `${(value / 1000).toFixed(1)}k`;
  return `${Math.round(value)}`;
}

let lastProfileStateSample = -Infinity;

function updateProfileState(dt, time) {
  if (!profileState.enabled) return;

  const frameMs = dt > 0 ? dt * 1000 : 0;
  if (frameMs > 0) {
    profileState.sampleCount += 1;
    profileState.frameMs = frameMs;
    profileState.avgFrameMs = profileState.avgFrameMs
      ? lerp(profileState.avgFrameMs, frameMs, 0.08)
      : frameMs;
    profileState.fps = profileState.avgFrameMs > 0 ? 1000 / profileState.avgFrameMs : 0;
    profileState.minFps = profileState.minFps > 0
      ? Math.min(profileState.minFps, profileState.fps)
      : profileState.fps;
    profileState.maxFrameMs = Math.max(profileState.maxFrameMs, frameMs);
    if (profileState.sampleCount > 10 && frameMs > 20) {
      profileState.droppedFrameHints += 1;
    }
  }

                                                                         
                                                          
  if (time - lastProfileStateSample < 0.25) return;
  lastProfileStateSample = time;

  const sanctuaryProfile = useLegacyScene ? null : sanctuarySceneV3?.snapshot();

  const renderInfo = renderer.info.render || {};
  const memoryInfo = renderer.info.memory || {};
  profileState.drawCalls = renderInfo.calls || 0;
  profileState.triangles = renderInfo.triangles || 0;
  profileState.geometries = memoryInfo.geometries || 0;
  profileState.textures = memoryInfo.textures || 0;
  profileState.programs = Array.isArray(renderer.info.programs)
    ? renderer.info.programs.length
    : 0;
  profileState.assetLoadMs = visualSettings.assetLoadMs || 0;
  profileState.sceneVersion = visualSettings.sceneVersion;
  profileState.assetStatus = visualSettings.assetStatus;
  profileState.assetProfile = visualSettings.assetProfile;
  profileState.textureProfile = visualSettings.textureProfile;
  profileState.activeTreeLod = visualSettings.activeTreeLod;
  profileState.skyProfile = visualSettings.skyProfile;
  profileState.grassProfile = visualSettings.grassProfile;
  profileState.landscapeProfile = visualSettings.landscapeProfile;
  profileState.forestProfile = visualSettings.forestProfile;
  profileState.groundDetailProfile = visualSettings.groundDetailProfile;
  profileState.atmosphereProfile = visualSettings.atmosphereProfile;
  profileState.fogDensity = useLegacyScene
    ? (visualSettings.fogDensity || 0)
    : (sanctuaryProfile?.fogDensity || 0);
  profileState.grassPatchCount = useLegacyScene
    ? (sceneAssets.grassPatchCount || 0)
    : (sanctuaryProfile?.activeGrassInstances || 0);
  profileState.grassTriangleCount = useLegacyScene
    ? 0
    : (sanctuaryProfile?.activeGrassTriangles || 0);
  profileState.rockCount = useLegacyScene
    ? (sceneAssets.rockCount || 0)
    : (sanctuaryProfile?.rockCount || 0);
  profileState.flowerPatchCount = useLegacyScene
    ? (sceneAssets.flowerPatchCount || 0)
    : (sanctuaryProfile?.flowerCount || 0);
  profileState.bushCount = useLegacyScene
    ? (sceneAssets.bushCount || 0)
    : (sanctuaryProfile?.bushCount || 0);
  profileState.detailDrawCallCount = useLegacyScene
    ? 0
    : (sanctuaryProfile?.activeDetailDrawCalls || 0);
  profileState.grassShadingProfile = useLegacyScene
    ? 'legacy'
    : (sanctuaryProfile?.grassShadingProfile || 'unknown');
  profileState.detailShadingProfile = useLegacyScene
    ? 'legacy'
    : (sanctuaryProfile?.detailShadingProfile || 'unknown');
  profileState.grassRangeUpdateCount = sanctuaryProfile?.grassRangeUpdateCount || 0;
  profileState.detailRangeUpdateCount = sanctuaryProfile?.detailRangeUpdateCount || 0;
  profileState.atmosphereRangeUpdateCount =
    sanctuaryProfile?.atmosphereRangeUpdateCount || 0;
  profileState.petalBufferUpdateCount = sanctuaryProfile?.petalBufferUpdateCount || 0;
  profileState.fallingRenderer = useLegacyScene
    ? 'legacy'
    : (sanctuaryProfile?.fallingRenderer || 'none');
  profileState.petalPatchCount = useLegacyScene
    ? (sceneAssets.petalPatchCount || 0)
    : (sanctuaryProfile?.groundPetalCount || 0);
  profileState.starCount = useLegacyScene
    ? (visualSettings.visualQuality === 'high' ? 14000 : 9000)
    : (sanctuaryProfile?.activeStarCount || 0);
  profileState.fireflyCount = useLegacyScene
    ? fireflyCount
    : (sanctuaryProfile?.activeFireflies || 0);
  profileState.adaptiveQualityLevel = useLegacyScene
    ? 'legacy'
    : (sanctuaryProfile?.adaptiveQualityLevel || 'full');
  profileState.performanceScale = useLegacyScene
    ? 1
    : (sanctuaryProfile?.appliedPerformanceScale || 1);
  profileState.rendererPixelRatio = renderer.getPixelRatio();
  profileState.framebufferScale = rendererPolicy.framebufferScale;
  profileState.foveation = appliedXrFoveation;
  profileState.contextLosses = vrDiagnostics.contextLosses;
  profileState.contextRestores = vrDiagnostics.contextRestores;
  profileState.sanctuaryPineCount = sceneAssets.sanctuaryPineCount || 0;
  profileState.sanctuaryHillCount = sceneAssets.sanctuaryHillCount || 0;
  profileState.visualQuality = visualSettings.visualQuality;
  profileState.xrPresenting = renderer.xr.isPresenting;
  const canopyProfile = sanctuaryProfile;
  profileState.canopyMode = canopyProfile?.canopyMode || 'legacy';
  profileState.canopyStatus = canopyProfile?.canopyStatus || 'legacy';
  profileState.canopyValidationStage = canopyValidationState.stage;
  profileState.canopyValidationElapsedSeconds = canopyValidationState.elapsedSeconds;
  profileState.activeLeafCount = canopyProfile?.activeLeafCount || 0;
  profileState.activeBlossomCount = canopyProfile?.activeBlossomCount || 0;
  profileState.canopyTransitionFrames = canopyProfile?.canopyTransitionFrames || 0;
  profileState.canopyAverageTransitionFrameMs =
    canopyProfile?.canopyAverageTransitionFrameMs || 0;
  profileState.canopyMaxTransitionFrameMs = canopyProfile?.canopyMaxTransitionFrameMs || 0;
  profileState.canopySlowTransitionFrames = canopyProfile?.canopySlowTransitionFrames || 0;
  profileState.canopyIntegrityFailures = canopyProfile?.canopyIntegrityFailures || 0;
}

function profileLines() {
  const hzTarget = profileState.visualQuality === 'quest' ? '80-90Hz target' : 'desktop/high';
  const fps = profileState.fps > 0 ? profileState.fps.toFixed(1) : '--';
  const avgMs = profileState.avgFrameMs > 0 ? profileState.avgFrameMs.toFixed(1) : '--';
  const maxMs = profileState.maxFrameMs > 0 ? profileState.maxFrameMs.toFixed(1) : '--';
  return [
    `Quest Profile (${hzTarget}) | Scene ${profileState.sceneVersion}`,
    `FPS ${fps} | avg ${avgMs}ms | max ${maxMs}ms`,
    `Draw ${profileState.drawCalls} | Tri ${formatCompactNumber(profileState.triangles)}`,
    `Geo ${profileState.geometries} | Tex ${profileState.textures} | Prog ${profileState.programs}`,
    `Asset ${profileState.assetProfile}/${profileState.textureProfile} | LOD ${profileState.activeTreeLod}`,
    `Sky ${profileState.skyProfile} | Land ${profileState.landscapeProfile} | Grass ${profileState.grassProfile}`,
    `Atmos ${profileState.atmosphereProfile} | Fog ${profileState.fogDensity.toFixed(3)}`,
    `Sky stars ${profileState.starCount} | Fireflies ${profileState.fireflyCount}`,
    `Adaptive ${profileState.adaptiveQualityLevel} | Scale ${profileState.performanceScale.toFixed(2)}`,
    `Canopy ${profileState.canopyMode}/${profileState.canopyStatus} | ${profileState.canopyValidationStage} ${profileState.canopyValidationElapsedSeconds.toFixed(1)}s | Leaf ${profileState.activeLeafCount} Blossom ${profileState.activeBlossomCount}`,
    `Canopy frames ${profileState.canopyTransitionFrames} | avg ${profileState.canopyAverageTransitionFrameMs.toFixed(1)}ms | max ${profileState.canopyMaxTransitionFrameMs.toFixed(1)}ms | slow ${profileState.canopySlowTransitionFrames} | integrity ${profileState.canopyIntegrityFailures}`,
    `Render DPR ${profileState.rendererPixelRatio.toFixed(2)} | XR scale ${profileState.framebufferScale.toFixed(2)} | Fov ${profileState.foveation.toFixed(2)}`,
    `Grass ${profileState.grassPatchCount} | ${formatCompactNumber(profileState.grassTriangleCount)} tris`,
    `Shade G:${profileState.grassShadingProfile} D:${profileState.detailShadingProfile} | Range G${profileState.grassRangeUpdateCount} D${profileState.detailRangeUpdateCount} A${profileState.atmosphereRangeUpdateCount} | Petal uploads ${profileState.petalBufferUpdateCount}`,
    `Details draws ${profileState.detailDrawCallCount} | R${profileState.rockCount} F${profileState.flowerPatchCount} B${profileState.bushCount} | Petals ${profileState.petalPatchCount} ${profileState.fallingRenderer}`,
    `Forest ${profileState.forestProfile} | Pines ${profileState.sanctuaryPineCount} | Hills ${profileState.sanctuaryHillCount}`,
    `Load ${profileState.assetLoadMs || '--'}ms | Status ${profileState.assetStatus}`,
    `XR ${profileState.xrPresenting ? 'yes' : 'no'} | Slow hints ${profileState.droppedFrameHints}`,
    `Context loss/restore ${profileState.contextLosses}/${profileState.contextRestores}`,
  ];
}

let lastMetricsRender = 0;
let lastStatusRender = 0;
let lastProfileRender = 0;
const tempLeafColor = new THREE.Color();
const tempGrassColor = new THREE.Color();
const tempCanopyLightColor = new THREE.Color();
const tempFallingPetalColor = new THREE.Color();
const tempDryPetalColor = new THREE.Color(0xb77a48);
const tempSkyTop = new THREE.Color();
const tempSkyHorizon = new THREE.Color();
const tempSkyLow = new THREE.Color();
const tempFogColor = new THREE.Color();
const tempCameraPosition = new THREE.Vector3();
const tempForward = new THREE.Vector3();
const tempRight = new THREE.Vector3();
const tempPanelCenter = new THREE.Vector3();
const worldUp = new THREE.Vector3(0, 1, 0);

function renderMetricsText(time) {
  if (time - lastMetricsRender < 1) return;
  lastMetricsRender = time;
  const isSweep = sessionState.protocol === 'resonance_sweep';

  const ctx = metricsCanvas.getContext('2d');
  const w = metricsCanvas.width;
  const h = metricsCanvas.height;
  ctx.clearRect(0, 0, w, h);

  ctx.fillStyle = 'rgba(8, 19, 25, 0.72)';
  roundRect(ctx, 0, 0, w, h, 24);
  ctx.fill();
  ctx.strokeStyle = 'rgba(142, 233, 195, 0.24)';
  ctx.lineWidth = 2;
  roundRect(ctx, 1, 1, w - 2, h - 2, 24);
  ctx.stroke();

  ctx.fillStyle = '#a7f3d0';
  ctx.font = 'bold 24px system-ui, sans-serif';
  ctx.fillText(
    isSweep
      ? 'Precise RF Assessment'
      : comfortState.displayMode === 'clinician'
        ? 'Clinical Metrics'
        : 'Tree Vitality',
    26,
    42,
  );

  ctx.fillStyle = demoMode ? '#fbbf24' : '#4ade80';
  ctx.font = '600 14px system-ui, sans-serif';
  ctx.fillText(demoMode ? 'Demo' : 'Live', 404, 39);

  if (comfortState.displayMode === 'clinician' && !isSweep) {
    const items = [
      ['HR', smooth.heartRate > 0 ? Math.round(smooth.heartRate).toString() : '--', 'bpm'],
      ['Coherence', `${Math.round(smooth.coherence * 100)}`, '%'],
      ['RMSSD', smooth.rmssd > 0 ? smooth.rmssd.toFixed(1) : '--', 'ms'],
      ['SDNN', smooth.sdnn > 0 ? smooth.sdnn.toFixed(1) : '--', 'ms'],
      ['Stress', Math.round(smooth.stressIndex).toString(), 'SI'],
      ['Signal', state.signalQuality || '--', `${smooth.breathingRate.toFixed(1)} BPM`],
    ];
    for (let i = 0; i < items.length; i++) {
      const col = i % 2;
      const row = Math.floor(i / 2);
      const x = col === 0 ? 28 : 270;
      const y = 88 + row * 54;
      const [label, value, unit] = items[i];
      ctx.fillStyle = '#8aa7a4';
      ctx.font = '500 14px system-ui, sans-serif';
      ctx.fillText(label, x, y);
      ctx.fillStyle = '#e5fff5';
      ctx.font = `${comfortState.largerText ? 'bold 24px' : 'bold 22px'} system-ui, sans-serif`;
      ctx.fillText(value, x, y + 25);
      ctx.fillStyle = '#7dd3bc';
      ctx.font = '500 13px system-ui, sans-serif';
      ctx.fillText(unit, x + 112, y + 25);
    }
    metricsTexture.needsUpdate = true;
    return;
  }

  const vitality = Math.round(progressState.treeVitalityScore || treeVitality.vitality * 100);
  const coherence = Math.round(smooth.coherence * 100);
  const beltState = sweepState.deviceStates?.respirationBelt || 'disconnected';
  const polarState = sweepState.deviceStates?.polar || 'disconnected';
  const metrics = isSweep
    ? [
        ['Cycle', `${Number(sweepState.cycleIndex || 0) + 1} / ${sweepState.cycleCount || 78}`, sweepState.status || 'idle'],
        ['Scheduled rate', `${Number(sweepState.scheduledBpm || 0).toFixed(2)} BPM`, `${sweepState.phase || 'inhale'} ${Math.round((sweepState.phaseProgress || 0) * 100)}%`],
        ['Acquisition', sweepState.resultMode || 'checking', `Polar ${polarState} | Belt ${beltState}`],
      ]
    : [
        ['Coherence', `${coherence}%`, coherenceLabel(smooth.coherence)],
        ['Vitality', `${vitality}%`, `Tier ${progressState.unlockedAmbientTier}`],
        ['Streaks', `${Math.round(progressState.bestStreaks.high70 || 0)}s`, `Sync ${Math.round(progressState.bestStreaks.breathSync || 0)}s`],
      ];

  let y = 86;
  for (const [label, value, detail] of metrics) {
    ctx.fillStyle = '#8aa7a4';
    ctx.font = '500 16px system-ui, sans-serif';
    ctx.fillText(label, 26, y);
    ctx.fillStyle = '#e5fff5';
    ctx.font = 'bold 22px system-ui, sans-serif';
    ctx.fillText(value, 180, y);
    ctx.fillStyle = '#7dd3bc';
    ctx.font = '500 14px system-ui, sans-serif';
    ctx.fillText(String(detail || ''), 330, y);
    y += 48;
  }

  if (lastResult && !isSweep) {
    ctx.fillStyle = '#d8fff0';
    ctx.font = '600 14px system-ui, sans-serif';
    ctx.fillText(`Last: ${Math.round(lastResult.averageCoherence || 0)}% avg | ${Math.round(lastResult.treeVitalityScore || 0)}% vitality`, 26, 226);
  }

  metricsTexture.needsUpdate = true;
}

function renderStatusText(time) {
  if (time - lastStatusRender < 0.12) return;
  lastStatusRender = time;

  const ctx = statusCanvas.getContext('2d');
  const w = statusCanvas.width;
  const h = statusCanvas.height;
  ctx.clearRect(0, 0, w, h);

  ctx.fillStyle = 'rgba(5, 18, 21, 0.88)';
  roundRect(ctx, 0, 0, w, h, 28);
  ctx.fill();
  ctx.strokeStyle = comfortState.highContrastGuide
    ? 'rgba(216, 255, 240, 0.88)'
    : 'rgba(142, 233, 195, 0.38)';
  ctx.lineWidth = comfortState.highContrastGuide ? 5 : 3;
  roundRect(ctx, 3, 3, w - 6, h - 6, 25);
  ctx.stroke();

  const rawPhase = String(breathState.phase || '').toLowerCase();
  const seconds = Math.max(0, Math.ceil(Number(breathState.secondsRemaining || 0)));
  let title = 'READY';
  let instruction = 'Select Start, then follow the breathing guide';
  let accent = '#8ee9c3';
  let progress = 0;
  if (sessionState.lastError && !sessionState.active) {
    title = 'SETUP NEEDED';
    instruction = sessionState.lastError;
    accent = '#ff9fb1';
  } else if (commandUiState.pending) {
    title = `${commandUiState.pending.toUpperCase()}...`;
    instruction = 'Waiting for BreathState to confirm';
    accent = '#f6cf5b';
  } else if (sessionState.starting) {
    title = 'PREPARING';
    instruction = 'Connecting sensors and preparing your session';
    accent = '#f6cf5b';
  } else if (sessionState.paused) {
    title = 'PAUSED';
    instruction = 'Select Resume when you are ready';
    accent = '#f6cf5b';
  } else if (sessionState.active) {
    progress = clamp01(breathState.phaseProgress || 0);
    if (rawPhase.includes('inhale')) {
      title = `INHALE  ${seconds}`;
      instruction = 'Breathe in slowly through your nose';
      accent = '#7de3d0';
    } else if (rawPhase.includes('exhale')) {
      title = `EXHALE  ${seconds}`;
      instruction = 'Let the breath leave gently and completely';
      accent = '#f3cb78';
    } else if (rawPhase.includes('hold')) {
      title = `HOLD  ${seconds}`;
      instruction = 'Rest softly without straining';
      accent = '#d6b6f2';
    } else {
      title = String(breathState.phaseLabel || 'Breathe').toUpperCase();
      instruction = 'Follow the expanding light around the tree';
      accent = '#8ee9c3';
    }
  } else if (performance.now() < commandUiState.until && commandUiState.tone === 'success') {
    instruction = commandUiState.message;
  }

  ctx.fillStyle = accent;
  ctx.font = `${comfortState.largerText ? 'bold 55px' : 'bold 49px'} system-ui, sans-serif`;
  ctx.textAlign = 'center';
  ctx.fillText(title, w / 2, 68);

  ctx.fillStyle = '#d8fff0';
  let instructionSize = comfortState.largerText ? 27 : 24;
  do {
    ctx.font = `600 ${instructionSize}px system-ui, sans-serif`;
    instructionSize -= 1;
  } while (ctx.measureText(instruction).width > w - 72 && instructionSize > 16);
  ctx.fillText(instruction, w / 2, 112);

  const barX = 62;
  const barY = 139;
  const barWidth = w - barX * 2;
  const barHeight = 20;
  ctx.fillStyle = 'rgba(152, 184, 178, 0.22)';
  roundRect(ctx, barX, barY, barWidth, barHeight, 10);
  ctx.fill();
  if (progress > 0) {
    ctx.fillStyle = accent;
    roundRect(ctx, barX, barY, Math.max(barHeight, barWidth * progress), barHeight, 10);
    ctx.fill();
  }

  const coherence = Math.round(smooth.coherence * 100);
  const protocolLabel = sessionState.protocol === 'resonance_sweep' ? 'Precise RF' : 'Resonance';
  const sessionTime = sessionState.active
    ? `${formatTime(sessionState.remainingSeconds)} remaining`
    : `${Math.round((sessionState.durationSeconds || 300) / 60)} min selected`;
  ctx.fillStyle = '#9dbbb5';
  ctx.font = `${comfortState.largerText ? '600 24px' : '600 21px'} system-ui, sans-serif`;
  ctx.fillText(
    `${protocolLabel}   |   Coherence ${coherence}%   |   ${smooth.breathingRate.toFixed(1)} BPM   |   ${sessionTime}`,
    w / 2,
    205,
  );

  ctx.fillStyle = demoMode ? '#f6cf5b' : '#7de3b2';
  ctx.font = 'bold 17px system-ui, sans-serif';
  ctx.fillText(demoMode ? 'DEMO' : 'LIVE', w / 2, 235);
  ctx.textAlign = 'start';

  statusTexture.needsUpdate = true;
}

function renderProfileText(time) {
  if (!profileState.enabled || time - lastProfileRender < 0.25) return;
  lastProfileRender = time;

  const lines = profileLines();
  if (profileDom) profileDom.textContent = lines.join('\n');

  const ctx = profileCanvas.getContext('2d');
  const w = profileCanvas.width;
  const h = profileCanvas.height;
  ctx.clearRect(0, 0, w, h);

  ctx.fillStyle = 'rgba(4, 12, 18, 0.78)';
  roundRect(ctx, 0, 0, w, h, 24);
  ctx.fill();
  ctx.strokeStyle = 'rgba(167, 243, 208, 0.32)';
  ctx.lineWidth = 2;
  roundRect(ctx, 2, 2, w - 4, h - 4, 22);
  ctx.stroke();

  ctx.fillStyle = '#d8fff0';
  ctx.font = 'bold 22px ui-monospace, SFMono-Regular, Consolas, monospace';
  ctx.fillText(lines[0], 24, 42);

  let y = 76;
  ctx.font = '15px ui-monospace, SFMono-Regular, Consolas, monospace';
  for (let i = 1; i < lines.length; i++) {
    ctx.fillStyle = i <= 2 ? '#e5fff5' : '#a7f3d0';
    ctx.fillText(lines[i], 24, y);
    y += 27;
  }

  profileTexture.needsUpdate = true;
}

function renderResultText() {
  if (!lastResult) return;

  const ctx = resultCanvas.getContext('2d');
  const w = resultCanvas.width;
  const h = resultCanvas.height;
  ctx.clearRect(0, 0, w, h);

  ctx.fillStyle = 'rgba(8, 19, 25, 0.82)';
  roundRect(ctx, 0, 0, w, h, 28);
  ctx.fill();
  ctx.strokeStyle = 'rgba(255, 215, 194, 0.32)';
  ctx.lineWidth = 2;
  roundRect(ctx, 2, 2, w - 4, h - 4, 28);
  ctx.stroke();

  ctx.fillStyle = '#ffd7c2';
  ctx.font = 'bold 30px system-ui, sans-serif';
  ctx.fillText('Session Complete', 34, 52);

  const delta = Number(lastResult.vitalityDelta || 0);
  const metrics = [
    ['Duration', formatDurationText(lastResult.durationSeconds), 'Goal complete'],
    ['Avg coherence', `${Math.round(lastResult.averageCoherence || 0)}%`, `Score ${Math.round(lastResult.sessionScore || 0)}`],
    ['Best 70+ streak', `${Math.round(lastResult.bestHighCoherenceStreakSeconds || 0)}s`, `Sync ${Math.round(lastResult.bestBreathSyncStreakSeconds || 0)}s`],
    ['Tree vitality', `${Math.round(lastResult.treeVitalityScore || 0)}%`, `${delta >= 0 ? '+' : ''}${delta.toFixed(1)}`],
  ];
  const sweepResult = lastResult.resonanceSweep;
  if (sweepResult) {
    const rate = Number(sweepResult.appliedPatientFrequencyBpm || sweepResult.rfBpm || 0);
    const mode = sweepResult.resultMode || 'estimated';
    const qualityPassed = sweepResult.quality?.flags?.length === 0;
    const confirmation = sweepResult.estimateConfirmationRequired
      ? 'confirmation required'
      : qualityPassed
        ? 'quality passed'
        : 'quality warnings';
    metrics.push([
      'Precise RF',
      rate > 0 ? `${rate.toFixed(2)} BPM` : '--',
      `${mode} | ${confirmation}`,
    ]);
  }

  let y = 102;
  for (const [label, value, detail] of metrics) {
    ctx.fillStyle = '#8aa7a4';
    ctx.font = '500 18px system-ui, sans-serif';
    ctx.fillText(label, 36, y);
    ctx.fillStyle = '#e5fff5';
    ctx.font = 'bold 25px system-ui, sans-serif';
    ctx.fillText(value, 258, y);
    ctx.fillStyle = '#a7f3d0';
    ctx.font = '500 16px system-ui, sans-serif';
    ctx.fillText(detail, 448, y);
    y += 46;
  }

  ctx.fillStyle = '#d8fff0';
  ctx.font = '600 17px system-ui, sans-serif';
  wrapText(ctx, String(lastResult.recommendation || ''), 36, sweepResult ? 332 : 306, 560, 24);
  resultTexture.needsUpdate = true;
}

function wrapText(ctx, text, x, y, maxWidth, lineHeight) {
  const words = text.split(/\s+/);
  let line = '';
  for (const word of words) {
    const testLine = line ? `${line} ${word}` : word;
    if (ctx.measureText(testLine).width > maxWidth && line) {
      ctx.fillText(line, x, y);
      line = word;
      y += lineHeight;
    } else {
      line = testLine;
    }
  }
  if (line) ctx.fillText(line, x, y);
}

function updateDemoData(dt) {
  if (canopyValidationMode) {
    const nowMs = performance.now();
    if (!Number.isFinite(canopyValidationState.startedAtMs)) {
      canopyValidationState.startedAtMs = nowMs;
    }
    canopyValidationState.elapsedSeconds = Math.max(
      0,
      (nowMs - canopyValidationState.startedAtMs) / 1000,
    );
    const sample = canopyValidationSample(canopyValidationState.elapsedSeconds);
    canopyValidationState.stage = sample.stage;
    canopyValidationState.cycleProgress = sample.cycleProgress;
    canopyValidationState.cycleIndex = sample.cycleIndex;
    canopyValidationState.coherence = sample.coherence;
    state.coherence = sample.coherence;
    state.rmssd = 24 + sample.coherence * 54;
    state.stressIndex = 260 - sample.coherence * 170;
    state.heartRate = 76 - sample.coherence * 9;
    state.sdnn = 25 + sample.coherence * 28;
    state.breathingRate = 6;
    state.signalQuality = 'demo';
    return;
  }
  demoPhase += dt * 0.12;
  state.rmssd = 38 + Math.sin(demoPhase) * 16 + Math.sin(demoPhase * 0.32) * 7;
  state.stressIndex = 190 + Math.sin(demoPhase * 0.7) * 130;
  state.coherence = clamp01(0.54 + Math.sin(demoPhase * 0.52) * 0.3);
  state.heartRate = 70 + Math.sin(demoPhase * 1.15) * 7;
  state.sdnn = 32 + Math.sin(demoPhase * 0.8) * 10;
  state.breathingRate = 5.8 + Math.sin(demoPhase * 0.15) * 0.7;
  state.signalQuality = 'demo';
}

function updateDemoSession(dt) {
  if (!demoMode || !sessionState.active || sessionState.paused) return;
  sessionState.elapsedSeconds = Math.min(
    sessionState.durationSeconds,
    sessionState.elapsedSeconds + dt,
  );
  sessionState.remainingSeconds = Math.max(
    0,
    sessionState.durationSeconds - sessionState.elapsedSeconds,
  );

  const inhaleSeconds = Math.max(0.5, Number(breathState.inhaleMs || 5000) / 1000);
  const exhaleSeconds = Math.max(0.5, Number(breathState.exhaleMs || 5000) / 1000);
  const cycleSeconds = inhaleSeconds + exhaleSeconds;
  const cyclePosition = sessionState.elapsedSeconds % cycleSeconds;
  const inhale = cyclePosition < inhaleSeconds;
  const phasePosition = inhale ? cyclePosition : cyclePosition - inhaleSeconds;
  const phaseDuration = inhale ? inhaleSeconds : exhaleSeconds;
  breathState.phase = inhale ? 'inhale' : 'exhale';
  breathState.phaseLabel = inhale ? 'Inhale' : 'Exhale';
  breathState.phaseProgress = clamp01(phasePosition / phaseDuration);
  breathState.cycleProgress = clamp01(cyclePosition / cycleSeconds);
  breathState.secondsRemaining = Math.max(0, Math.ceil(phaseDuration - phasePosition));

  if (sessionState.remainingSeconds <= 0) {
    applyDemoSessionCommand('stop');
  }
}

function getBreathGuide(time) {
  const cycleSec = 60.0 / Math.max(smooth.breathingRate, 3);
  const freeCycle = (time % cycleSec) / cycleSec;
  let cycleProgress = freeCycle;
  let breathT = freeCycle < 0.5 ? freeCycle * 2 : 1 - (freeCycle - 0.5) * 2;
  let inhale = freeCycle < 0.5;

  if (sessionState.active) {
    const p = clamp01(breathState.phaseProgress || 0);
    cycleProgress = clamp01(breathState.cycleProgress || 0);
    if (breathState.phase === 'inhale') {
      breathT = p;
      inhale = true;
    } else if (breathState.phase === 'exhale') {
      breathT = 1 - p;
      inhale = false;
    }
  }

  return {
    expansion: easeInOut(breathT),
    cycleProgress,
    inhale,
  };
}

function updateTreeMaterials(vitality, smoothFactor) {
  const tier = progressState.unlockedAmbientTier;
  const progressVitality = clamp01(progressState.treeVitalityScore / 100);
  const leafBlend = Math.max(vitality.vitality, progressVitality * 0.92);
  const warmSky = smoothstep(2, 4, tier);
  const particleBonus = comfortState.reducedParticles ? 0 : tier >= 4 ? 0.18 : 0;

  tempLeafColor.copy(LEAF_LOW).lerp(LEAF_HIGH, leafBlend);
  tempLeafColor.offsetHSL(0, (vitality.greenSaturation - 0.55) * 0.16, 0.035 * vitality.groundSoftness);
  leafMat.color.lerp(tempLeafColor, smoothFactor * 0.8);
  clusterMat.color.lerp(tempLeafColor, smoothFactor * 0.55);
  tempGrassColor.copy(GRASS_LOW).lerp(GRASS_HIGH, vitality.groundSoftness);
  if (grassMesh.visible) {
    grassMat.color.lerp(tempGrassColor, smoothFactor * 0.5);
  }

  trunkMat.emissive.lerp(BARK_GLOW, smoothFactor * 0.35);
  trunkMat.emissiveIntensity = vitality.trunkGlow * 0.6;
  branchMat.emissiveIntensity = vitality.trunkGlow * 0.32;

  tempCanopyLightColor.copy(CANOPY_LIGHT_LOW).lerp(CANOPY_LIGHT_HIGH, vitality.trunkGlow);
  canopyLight.color.lerp(tempCanopyLightColor, smoothFactor * 0.4);
  canopyLight.intensity = 0.55 + vitality.trunkGlow * 1.65;
  groundLight.intensity = 0.22 + vitality.groundSoftness * 0.72 + warmSky * 0.22;
  clearingRingMat.opacity = 0.08 + vitality.groundSoftness * 0.2;
  fireflyMat.uniforms.uOpacity.value = comfortState.reducedParticles
    ? 0.05 + vitality.groundSoftness * 0.08
    : 0.06 + vitality.groundSoftness * 0.28 + particleBonus;
  fireflyMat.uniforms.uBaseSize.value = 0.076 + (tier >= 4 ? 0.015 : 0);
  fallingLeafMat.opacity = comfortState.reducedParticles
    ? 0.02 + vitality.fallingLeaves * 0.08
    : 0.04 + vitality.fallingLeaves * 0.32;
  tempFallingPetalColor
    .copy(LEAF_HIGH)
    .lerp(tempDryPetalColor, clamp01(vitality.fallingLeaves * 1.25));
  fallingLeafMat.color.lerp(tempFallingPetalColor, smoothFactor * 0.7);
  blossomMat.opacity = tier >= 2 ? 0.08 + vitality.vitality * 0.34 : 0;

  const atmosphereCoherence = smoothstep(0.24, 0.88, Math.max(vitality.vitality, smooth.coherence * 0.92));
  const horizonWarmth = clamp01(atmosphereCoherence * 0.82 + warmSky * 0.36);
  tempSkyTop.copy(SKY_TOP)
    .lerp(SKY_COHERENT_TOP, atmosphereCoherence * 0.72)
    .lerp(SKY_WARM_TOP, warmSky * 0.32);
  tempSkyHorizon.copy(SKY_HORIZON)
    .lerp(SKY_COHERENT_HORIZON, horizonWarmth)
    .lerp(SKY_WARM_HORIZON, warmSky * 0.28);
  tempSkyLow.copy(SKY_LOW).lerp(SKY_COHERENT_LOW, atmosphereCoherence * 0.62);
  tempFogColor.copy(FOG_LOW).lerp(FOG_COHERENT, horizonWarmth);
  const targetFogDensity = lerp(0.041, 0.027, atmosphereCoherence);

  skyMat.uniforms.topColor.value.lerp(tempSkyTop, smoothFactor * 0.25);
  skyMat.uniforms.horizonColor.value.lerp(tempSkyHorizon, smoothFactor * 0.28);
  skyMat.uniforms.lowColor.value.lerp(tempSkyLow, smoothFactor * 0.3);
  scene.background.lerp(tempSkyLow, smoothFactor * 0.2);
  if (scene.fog) {
    scene.fog.color.lerp(tempFogColor, smoothFactor * 0.32);
    scene.fog.density = lerp(scene.fog.density, targetFogDensity, smoothFactor * 0.22);
    visualSettings.fogDensity = scene.fog.density;
  }
}

function updateTreeGeometry(time, dt, breathGuide) {
  const vitality = treeVitality.snapshot();
  const tier = progressState.unlockedAmbientTier;
  const richness = tier >= 1 ? 0.08 : 0;
  const motionScale = comfortState.reducedMotion ? 0.28 : 1;
  const breathScale = 1 + breathGuide.expansion * 0.055 * motionScale;
  const fullness = Math.min(1.08, vitality.canopyFullness + richness) * breathScale;
  canopyGroup.scale.set(1.08 * fullness, 0.96 * fullness, 1.04 * fullness);
  canopyGroup.position.y = 3.52 + breathGuide.expansion * 0.075 * motionScale;
  trunk.scale.set(1 + vitality.trunkGlow * 0.012, 1, 1 + vitality.trunkGlow * 0.012);

  leafMesh.count = clamp(Math.floor(leafCount * Math.min(1, vitality.leafDensity + richness)), 1, leafCount);
  blossomMesh.count = tier >= 2 ? clamp(Math.floor(blossomCount * vitality.vitality * 0.82), 8, blossomCount) : 0;

  guideRing.scale.setScalar(0.96 + breathGuide.expansion * 0.12);
  guideRingMat.opacity = comfortState.highContrastGuide
    ? 0.72
    : 0.17 + breathGuide.expansion * 0.3 + vitality.groundSoftness * 0.08;
  guideRingMat.color.lerp(
    comfortState.highContrastGuide
      ? (breathGuide.inhale ? GUIDE_CONTRAST_IN : GUIDE_CONTRAST_OUT)
      : (breathGuide.inhale ? EMERALD : BLUE),
    1 - Math.exp(-dt * 3.5),
  );
  guideRing.rotation.z += dt * 0.035 * motionScale;

  const markerAngle = breathGuide.cycleProgress * TWO_PI - Math.PI / 2;
  const markerRadius = 2.02 * (0.96 + breathGuide.expansion * 0.12);
  guideMarker.position.set(
    TREE_POS.x + Math.cos(markerAngle) * markerRadius,
    0.085,
    TREE_POS.z + Math.sin(markerAngle) * markerRadius,
  );
  guideMarker.scale.setScalar((comfortState.highContrastGuide ? 1.12 : 0.82) + breathGuide.expansion * 0.45);
  guideMarkerMat.opacity = comfortState.highContrastGuide ? 0.95 : 0.45 + breathGuide.expansion * 0.42;

  const activeFireflies = comfortState.reducedParticles
    ? Math.floor(fireflyCount * 0.25)
    : fireflyCount;
  fireflyGeo.setDrawRange(0, activeFireflies);
  fireflyMat.uniforms.uBreathGlow.value = breathGuide.inhale
    ? 0.52 + breathGuide.expansion * 0.48
    : 0.2 + breathGuide.expansion * 0.28;
  fireflyMat.uniforms.uReducedMotion.value = comfortState.reducedMotion ? 1 : 0;
  starMat.uniforms.uReducedMotion.value = comfortState.reducedMotion ? 1 : 0;
  starMat.uniforms.uTwinkleStrength.value = comfortState.reducedMotion ? 0.72 : 1.0;
  const fireflyPos = fireflyGeo.attributes.position.array;
  for (let i = 0; i < activeFireflies; i++) {
    const seed = fireflySeeds[i];
    const slowTime = time * motionScale;
    const angle = seed.angle + slowTime * seed.speed;
    const radius = seed.radius
      + Math.sin(slowTime * 0.16 + seed.wobble) * seed.radialSpan
      + Math.sin(slowTime * 0.09 + seed.phase * 1.7) * seed.radialSpan * 0.52;
    const brownianX = Math.sin(slowTime * 0.21 + seed.phase) * seed.driftX
      + Math.sin(slowTime * 0.11 + seed.wobble * 1.3) * 0.11;
    const brownianZ = Math.cos(slowTime * 0.18 + seed.phase * 1.4) * seed.driftZ
      + Math.cos(slowTime * 0.1 + seed.wobble * 0.7) * 0.13;
    fireflyPos[i * 3] = TREE_POS.x + Math.cos(angle) * radius + brownianX;
    fireflyPos[i * 3 + 1] = seed.height
      + Math.sin(slowTime * 0.24 + seed.wobble) * seed.verticalSpan
      + Math.sin(slowTime * 0.13 + seed.phase) * seed.verticalSpan * 0.45;
    fireflyPos[i * 3 + 2] = TREE_POS.z + Math.sin(angle) * radius + brownianZ;
  }
  fireflyGeo.attributes.position.needsUpdate = true;

  const leafParticleScale = comfortState.reducedParticles ? 0.25 : 1;
  const activeLeaves = clamp(
    Math.floor(fallingLeafCount * vitality.fallingLeaves * leafParticleScale),
    1,
    fallingLeafCount,
  );
  fallingLeaves.count = activeLeaves;
  for (let i = 0; i < activeLeaves; i++) {
    const leaf = fallingLeafData[i];
    leaf.y -= leaf.speed * dt * (0.75 + vitality.fallingLeaves) * motionScale;
    leaf.x += Math.sin(time * 0.8 * motionScale + leaf.spin) * leaf.drift * dt * motionScale;
    leaf.z += Math.cos(time * 0.66 * motionScale + leaf.spin) * leaf.drift * dt * 0.6 * motionScale;
    leaf.spin += dt * (0.8 + vitality.fallingLeaves) * motionScale;
    if (leaf.y < 0.06) resetFallingLeaf(i, true);
    dummy.position.set(TREE_POS.x + leaf.x, leaf.y, TREE_POS.z + leaf.z);
    dummy.rotation.set(leaf.spin * 0.6, leaf.spin, leaf.spin * 0.35);
    dummy.scale.setScalar(leaf.scale);
    dummy.updateMatrix();
    fallingLeaves.setMatrixAt(i, dummy.matrix);
  }
  fallingLeaves.instanceMatrix.needsUpdate = true;
}

function updateSceneV2DynamicAssets(vitality, time, breathGuide) {
  const tier = progressState.unlockedAmbientTier;
  const richness = tier >= 1 ? 0.08 : 0;
  const motionScale = comfortState.reducedMotion ? 0.28 : 1;
  const progressVitality = clamp01(progressState.treeVitalityScore / 100);
  const effectiveVitality = Math.max(vitality.vitality, progressVitality * 0.88);
  const witherAmount = clamp01(1 - effectiveVitality);
  const blossomDensity = clamp(
    0.22 + smoothstep(0.12, 0.96, vitality.leafDensity) * 0.74 + richness,
    0.16,
    1,
  );
  const breathScale = 1 + breathGuide.expansion * 0.014 * motionScale;

  sceneAssets.uniforms.uTime.value = time;
  sceneAssets.uniforms.uTreeVitality.value = effectiveVitality;
  sceneAssets.uniforms.uWitherAmount.value = witherAmount;
  sceneAssets.uniforms.uWindStrength.value = comfortState.reducedMotion
    ? 0.008
    : 0.018 + vitality.groundSoftness * 0.018;
                                                       
  sceneAssets.uniforms.uAuroraIntensity.value = comfortState.reducedMotion ? 0.32 : 0.65;

  if (sceneAssets.moonHalo) {
    const haloPulse = comfortState.reducedMotion ? 0 : Math.sin(time * 0.28) * 0.035;
    sceneAssets.moonHalo.material.opacity = 0.42 + vitality.groundSoftness * 0.08 + haloPulse;
    sceneAssets.moonHalo.scale.setScalar(MOON_DIAMETER * (2.72 + vitality.groundSoftness * 0.16));
  }

  if (sceneAssets.auroraModel) {
    sceneAssets.auroraModel.visible = true;
    const auroraOpacity = comfortState.reducedMotion
      ? 0.28
      : 0.42 + Math.sin(time * 0.18) * 0.07;
    sceneAssets.auroraModel.rotation.y = Math.sin(time * (comfortState.reducedMotion ? 0.007 : 0.022)) * 0.062;
    sceneAssets.auroraModel.traverse((object) => {
      if (object.isMesh && object.material) object.material.opacity = auroraOpacity;
    });
  } else if (sceneAssets.aurora) {
    sceneAssets.aurora.visible = true;
  }

                                                 
  if (sceneAssets.moonbeamCone) {
    sceneAssets.moonbeamCone.material.uniforms.uGroundSoftness.value = vitality.groundSoftness;
  }

                                                                     
  if (sceneAssets.bushGroup && !comfortState.reducedParticles) {
    const bushBloom = 0.28 + vitality.vitality * 0.72;
    sceneAssets.bushGroup.traverse((object) => {
      if (!object.isMesh || !object.material) return;
      const materials = Array.isArray(object.material) ? object.material : [object.material];
      for (const material of materials) {
        if (material.transparent) {
          material.opacity = clamp01(bushBloom * 0.94 + 0.06);
        }
        if (material.emissive) {
          material.emissiveIntensity = (material.userData.baseEmissiveIntensity ?? 0.006)
            + vitality.vitality * 0.018;
        }
      }
    });
  }

  if (sceneAssets.groundDetailGroup) {
    const detailBloom = comfortState.reducedParticles
      ? 0.35
      : 0.55 + vitality.vitality * 0.45 + breathGuide.expansion * 0.12;
    sceneAssets.groundDetailGroup.traverse((object) => {
      if (!object.isMesh || !object.material) return;
      const kind = object.userData.organicDetailKind || object.parent?.userData?.organicDetailKind;
      if (kind !== 'glow' && kind !== 'flower') return;
      const materials = Array.isArray(object.material) ? object.material : [object.material];
      for (const material of materials) {
        if (!material.emissive) continue;
        const base = material.userData.baseEmissiveIntensity ?? 0.006;
        material.emissiveIntensity = kind === 'glow'
          ? base + detailBloom * 0.09
          : base + detailBloom * 0.012;
      }
    });
  }

  const treeModels = Object.entries(sceneAssets.treeLods)
    .filter(([, model]) => Boolean(model));
  if (treeModels.length === 0) {
    const tree = sceneAssets.treeModel || sceneAssets.oakGroup;
    if (!tree) return;
    treeModels.push([sceneAssets.activeTreeLod || 'source', tree]);
  }

  let desiredLod = sceneAssets.treeLods.lod0 ? 'lod0' : sceneAssets.activeTreeLod;
  if (visualSettings.visualQuality === 'quest' && sceneAssets.treeLods.lod1) {
    const activeCam = renderer.xr.isPresenting ? renderer.xr.getCamera(camera) : camera;
    activeCam.getWorldPosition(tempCameraPosition);
    const viewerDistance = tempCameraPosition.distanceTo(TREE_POS);
    if (viewerDistance > 5.7 || (comfortState.reducedMotion && viewerDistance > 4.9)) {
      desiredLod = 'lod1';
    }
  }
  if (!sceneAssets.treeLods[desiredLod]) desiredLod = treeModels[0][0];

  for (const [lod, model] of treeModels) {
    model.visible = lod === desiredLod;
    const baseScale = model.userData.baseScale || sceneAssets.treeBaseScale;
    const basePosition = model.userData.basePosition || sceneAssets.treeBasePosition;
    model.scale.set(
      baseScale.x * breathScale,
      baseScale.y * (1 + breathGuide.expansion * 0.006 * motionScale),
      baseScale.z * breathScale,
    );
    model.position.copy(basePosition);
    model.position.y += breathGuide.expansion * 0.026 * motionScale;
  }
  sceneAssets.treeModel = sceneAssets.treeLods[desiredLod] || sceneAssets.treeModel;
  sceneAssets.activeTreeLod = desiredLod;
  visualSettings.activeTreeLod = desiredLod;

  if (sceneAssets.barkMaterial) {
    sceneAssets.barkMaterial.emissiveIntensity = 0.018 + vitality.trunkGlow * 0.16;
  }

  for (const material of sceneAssets.barkMaterials) {
    material.emissiveIntensity = 0.018 + vitality.trunkGlow * 0.16;
  }

  for (const barkObject of sceneAssets.barkMeshes) {
    if (barkObject.material) {
      barkObject.material.emissiveIntensity = 0.018 + vitality.trunkGlow * 0.16;
    }
  }

  for (const material of sceneAssets.blossomMaterials) {
    material.opacity = clamp(0.50 + effectiveVitality * 0.45, 0.42, 0.96);
    material.alphaTest = 0.045 + witherAmount * 0.045;
    material.emissiveIntensity = comfortState.reducedMotion
      ? 0.01 + effectiveVitality * 0.02
      : 0.014 + effectiveVitality * 0.034;
  }

  for (const leafObject of sceneAssets.oakLeaves) {
    const indexCount = leafObject.geometry.index?.count
      ?? leafObject.geometry.attributes.position?.count
      ?? 0;
    if (indexCount > 0) {
      const currentCount = !Number.isFinite(leafObject.geometry.drawRange.count)
        ? indexCount
        : leafObject.geometry.drawRange.count;
      const rawTarget = Math.max(3, Math.floor((indexCount * blossomDensity) / 3) * 3);
      const blendRate = rawTarget >= currentCount ? 0.08 : 0.035;
      const targetCount = Math.max(3, Math.floor(lerp(currentCount, rawTarget, blendRate) / 3) * 3);
      leafObject.geometry.setDrawRange(0, targetCount);
    }
  }

  if (sceneAssets.oakLeavesLod0) sceneAssets.oakLeavesLod0.visible = true;
  if (sceneAssets.oakLeavesLod1) sceneAssets.oakLeavesLod1.visible = visualSettings.visualQuality === 'high';

  if (canopyShadow.visible) {
    canopyShadowMat.opacity = 0.18 + vitality.canopyFullness * 0.24;
    canopyShadow.scale.set(5.2 + vitality.canopyFullness * 0.96, 3.75 + vitality.canopyFullness * 0.64, 1);
  }
}

function lookAtCamera(object, cam) {
  cam.getWorldPosition(tempCameraPosition);
  object.lookAt(tempCameraPosition);
}

function recenterExperience(notifyHost = false) {
  const activeCam = renderer.xr.isPresenting ? renderer.xr.getCamera(camera) : camera;
  activeCam.getWorldPosition(tempCameraPosition);
  activeCam.getWorldDirection(tempForward);
  tempForward.y = 0;
  if (tempForward.lengthSq() < 0.001) tempForward.set(0, 0, -1);
  tempForward.normalize();
  tempRight.crossVectors(tempForward, worldUp).normalize();

  tempPanelCenter.copy(tempCameraPosition).addScaledVector(tempForward, 2.15);
  const seatedY = comfortState.seatedMode ? 1.12 : Math.max(1.0, tempCameraPosition.y - 0.55);

  statusPanel.position.copy(tempPanelCenter);
  statusPanel.position.y = seatedY - 0.30;

  metricsPanel.position.copy(tempPanelCenter).addScaledVector(tempRight, -1.0);
  metricsPanel.position.y = seatedY + 0.36;

  commandPanel.position.copy(tempPanelCenter).addScaledVector(tempRight, 1.02);
  commandPanel.position.y = seatedY + 0.18;

  resultPanel.position.copy(tempPanelCenter);
  resultPanel.position.y = seatedY + 0.46;

  profilePanel.position.copy(tempPanelCenter);
  profilePanel.position.y = seatedY + 0.92;

  lookAtCamera(statusPanel, activeCam);
  lookAtCamera(metricsPanel, activeCam);
  lookAtCamera(commandPanel, activeCam);
  lookAtCamera(resultPanel, activeCam);
  lookAtCamera(profilePanel, activeCam);

  if (notifyHost) sendCommand('recenter');
}

const clock = new THREE.Clock();
let prevTime = 0;
let appliedXrFoveation = rendererPolicy.foveation;

async function requestPreferredXrFrameRate() {
  const session = renderer.xr.getSession();
  if (!questRendererPolicy || !session?.updateTargetFrameRate) return;
  const supported = Array.from(session.supportedFrameRates || [])
    .filter((rate) => Number.isFinite(rate) && rate <= 90)
    .sort((left, right) => right - left);
  const target = supported.find((rate) => rate >= 90)
    || supported.find((rate) => rate >= 80)
    || supported[0];
  if (!target) return;
  try {
    await session.updateTargetFrameRate(target);
    vrDiagnostics.renderer.requestedFrameRate = target;
    recordVrDiagnostic('xr-frame-rate', `${target}Hz`);
  } catch (error) {
    recordVrDiagnostic('xr-frame-rate-unsupported', error?.message || error);
  }
}

function applyAdaptiveFoveation(level = 'full') {
  if (!renderer.xr.isPresenting) return;
  const target = !questRendererPolicy
    ? rendererPolicy.foveation
    : level === 'protected'
      ? 1
      : level === 'balanced'
        ? 0.9
        : rendererPolicy.foveation;
  if (Math.abs(target - appliedXrFoveation) < 0.01) return;
  try {
    renderer.xr.setFoveation(target);
    appliedXrFoveation = target;
    vrDiagnostics.renderer.foveation = target;
    recordVrDiagnostic('xr-foveation', target.toFixed(2));
  } catch (error) {
    recordVrDiagnostic('xr-foveation-unsupported', error?.message || error);
  }
}

function animate() {
  const time = clock.getElapsedTime();
  const dt = Math.min(time - prevTime, 0.1);
  prevTime = time;

  if (performance.now() - lastDataTime > 10000 && !demoMode) {
    demoMode = true;
    updateStatusIndicator(true);
  }

  if (demoMode) {
    updateDemoData(dt);
    updateDemoSession(dt);
  }

  const smoothFactor = 1 - Math.exp(-dt * 3.0);
  smooth.rmssd = lerp(smooth.rmssd, state.rmssd, smoothFactor);
  smooth.stressIndex = lerp(smooth.stressIndex, state.stressIndex, smoothFactor);
  smooth.coherence = lerp(smooth.coherence, state.coherence, smoothFactor);
  smooth.heartRate = lerp(smooth.heartRate, state.heartRate, smoothFactor);
  smooth.sdnn = lerp(smooth.sdnn, state.sdnn, smoothFactor);
  smooth.breathingRate = lerp(smooth.breathingRate, state.breathingRate, smoothFactor);

  treeVitality.update(smooth.coherence, dt);
  const breathGuide = getBreathGuide(time);
  const vitalitySnapshot = treeVitality.snapshot();
  if (useLegacyScene) {
    sceneAssets.uniforms.uTime.value = time;
    skyMat.uniforms.uTime.value = time;
    if (sakuraLeafCloud) {
      sakuraLeafCloud.update(
        vitalitySnapshot.leafDensity,
        dt,
        time,
        vitalitySnapshot.vitality,
      );
      const burst = sakuraLeafCloud.takeBurst();
      if (burst >= 20 && !comfortState.reducedParticles) {
        fallingLeafMat.opacity = Math.min(
          0.76,
          (fallingLeafMat.opacity || 0.04) + burst * 0.0022,
        );
      }
    }
    updateTreeMaterials(vitalitySnapshot, smoothFactor);
    updateTreeGeometry(time, dt, breathGuide);
    updateSceneV2DynamicAssets(vitalitySnapshot, time, breathGuide);
    for (const mixer of sceneAssets.grassMixers) {
      mixer.timeScale = comfortState.reducedMotion ? 0.32 : 0.82;
      mixer.update(dt);
    }
  } else {
                                                                         
                                                                            
                                                                          
    const validationTreeVitality = canopyValidationMode && demoMode
      ? undefined
      : vitalitySnapshot;
    const sanctuaryFrameState = sanctuarySceneV3?.update({
      coherence: smooth.coherence,
      fallingCoherence: state.coherence,
      treeVitality: validationTreeVitality,
      signalQuality: state.signalQuality,
      breathPhase: breathState.phase,
      breathProgress: breathGuide.cycleProgress,
      comfortOptions: comfortState,
      ambientTier: progressState.unlockedAmbientTier,
      deltaTime: dt,
      elapsedTime: time,
      sessionActive: sessionState.active,
      sessionPaused: sessionState.paused,
      xrPresenting: renderer.xr.isPresenting,
    });
    applyAdaptiveFoveation(
      sanctuaryFrameState?.adaptiveQualityLevel || 'full',
    );
  }
  updateProfileState(dt, time);

  metricsPanel.visible = comfortState.displayMode === 'clinician';
  profilePanel.visible = profileState.enabled;
  const textScale = comfortState.largerText ? 1.16 : 1;
  statusPanel.scale.setScalar(textScale);
  metricsPanel.scale.setScalar(textScale);
  resultPanel.scale.setScalar(comfortState.largerText ? 1.12 : 1);
  profilePanel.scale.setScalar(comfortState.largerText ? 1.08 : 1);

  renderMetricsText(time);
  renderStatusText(time);
  renderProfileText(time);
  refreshVrCommandControls();

  if (resultPanel.visible && performance.now() > resultSummaryUntil) {
    resultPanel.visible = false;
  }

  if (renderer.xr.isPresenting) {
    const xrCamera = renderer.xr.getCamera(camera);
    lookAtCamera(metricsPanel, xrCamera);
    lookAtCamera(statusPanel, xrCamera);
    lookAtCamera(commandPanel, xrCamera);
    if (resultPanel.visible) lookAtCamera(resultPanel, xrCamera);
    if (profilePanel.visible) lookAtCamera(profilePanel, xrCamera);
    updateControllerButtonHover();
  } else {
    if (profilePanel.visible) lookAtCamera(profilePanel, camera);
  }

  renderer.render(scene, camera);
}

renderer.setAnimationLoop(animate);
renderer.xr.addEventListener('sessionstart', () => {
  vrDiagnostics.xrSessionStarts += 1;
  recordVrDiagnostic('xr-session-start');
  void requestPreferredXrFrameRate();
  try {
    renderer.xr.setFoveation(rendererPolicy.foveation);
    appliedXrFoveation = rendererPolicy.foveation;
    vrDiagnostics.renderer.foveation = appliedXrFoveation;
  } catch (error) {
    recordVrDiagnostic('xr-foveation-unsupported', error?.message || error);
  }
  const xrCamera = renderer.xr.getCamera(camera);
  xrCamera.layers.enableAll();
  for (const eyeCamera of xrCamera.cameras || []) {
    eyeCamera.layers.enableAll();
  }
  setTimeout(() => recenterExperience(false), 250);
});

renderer.xr.addEventListener('sessionend', () => {
  vrDiagnostics.xrSessionEnds += 1;
  recordVrDiagnostic('xr-session-end');
  for (const target of commandHitTargets) {
    target.material.opacity = 0;
    target.userData.visual?.scale.setScalar(1);
  }
  for (const controller of xrControllers) {
    if (controller.userData.rayLine) controller.userData.rayLine.material.opacity = 0.36;
  }
  prevTime = clock.getElapsedTime();
});

document.addEventListener('visibilitychange', () => {
  recordVrDiagnostic(document.hidden ? 'document-hidden' : 'document-visible');
  if (!document.hidden) prevTime = clock.getElapsedTime();
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  requestAnimationFrame(layoutDomOverlays);
});

if (useLegacyScene) {
  initializeSceneV2Assets();
} else {
  setAssetStatus('loading', 'Loading sanctuary landscape, sakura, meadow, moon, and aurora');
  sanctuarySceneV3.ready.then((snapshot) => {
    vrDiagnostics.assetReadyMs = Math.round(performance.now());
    recordVrDiagnostic('sanctuary-assets-ready', snapshot.assetStatus);
    applySanctuarySnapshot(snapshot);
    setAssetStatus(
      snapshot.assetStatus,
      snapshot.assetStatus === 'ready'
        ? 'Sanctuary V3 nocturnal sanctuary ready'
        : snapshot.assetStatus === 'partial-fallback'
          ? 'Sanctuary V3 ready with fallback'
          : 'Using Sanctuary V3 fallback',
    );
    setTimeout(hideLoadingOverlay, 180);
  }).catch((error) => {
    recordVrDiagnostic('sanctuary-startup-fallback', error?.message || error);
    console.error('Sanctuary V3 startup failed; opening the initialized fallback.', error);
    setAssetStatus('fallback', 'Opening fallback scene');
    if (sanctuarySceneV3.snapshot().initialized) {
      hideLoadingOverlay();
    } else {
      window.__breathStateVrBoot?.fail(error);
    }
  });
}
