import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { SanctuaryLandscape } from './sanctuary_landscape.js?v=25';
import { SanctuaryAtmosphere } from './sanctuary_atmosphere.js?v=25';
import { SanctuaryGroundDetails } from './sanctuary_details.js?v=25';
import { SanctuaryBreathingGuide } from './sanctuary_guidance.js?v=25';
import { SanctuaryPetalSystem } from './sanctuary_petals.js?v=25';
import { SanctuaryPerformanceGovernor } from './sanctuary_performance.js?v=25';
import { SanctuaryTreeVisualState } from './sanctuary_tree_state.js?v=25';
import { SakuraCanopyController } from './sanctuary_canopy.js?v=25';
import { CanopyTransitionProfiler } from './sanctuary_canopy_profiler.js?v=25';

export const SANCTUARY_LAYERS = Object.freeze({
  scenery: 0,
  interactive: 1,
  clinical: 2,
  effects: 3,
});

const DEFAULT_BACKGROUND = 0x03070b;
const DEFAULT_FOG = 0x071018;
const TREE_POSITION = new THREE.Vector3(0, 0, -6.8);
const TREE_FILL_COLOR = new THREE.Color(0xffdbe6);
const TREE_FULL_BLOOM_COLOR = new THREE.Color(0xffcf8a);
const TREE_TARGET_HEIGHT = 9;
const TREE_ASSET_BASE = 'assets/sanctuary_v3/tree/';

function resolveCanopyMode(requestedMode) {
  if (requestedMode === 'dynamic' || requestedMode === 'source') return requestedMode;
  try {
    const canopyModeOverride = new URLSearchParams(
      globalThis.location?.search || '',
    ).get('canopy');
    return canopyModeOverride === 'source' ? 'source' : 'dynamic';
  } catch (_) {
    return 'dynamic';
  }
}

function disposeMaterial(material) {
  if (!material) return;
  const materials = Array.isArray(material) ? material : [material];
  for (const item of materials) {
    for (const value of Object.values(item)) {
      if (value?.isTexture) value.dispose();
    }
    item.dispose();
  }
}

function loadGltf(loader, path) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`Timed out loading ${path}`)), 12000);
    loader.load(
      path,
      (value) => {
        clearTimeout(timeout);
        resolve(value);
      },
      undefined,
      (error) => {
        clearTimeout(timeout);
        reject(error);
      },
    );
  });
}

function loadTexture(path) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`Timed out loading ${path}`)), 12000);
    new THREE.TextureLoader().load(
      path,
      (value) => {
        clearTimeout(timeout);
        resolve(value);
      },
      undefined,
      (error) => {
        clearTimeout(timeout);
        reject(error);
      },
    );
  });
}

function fitTreeToScene(tree) {
  tree.updateMatrixWorld(true);
  const initialBox = new THREE.Box3().setFromObject(tree);
  const initialHeight = Math.max(initialBox.max.y - initialBox.min.y, 0.001);
  tree.scale.multiplyScalar(TREE_TARGET_HEIGHT / initialHeight);
  tree.scale.x *= 1.12;
  tree.scale.z *= 1.08;
  tree.updateMatrixWorld(true);

  const finalBox = new THREE.Box3().setFromObject(tree);
  const center = finalBox.getCenter(new THREE.Vector3());
  tree.position.x += TREE_POSITION.x - center.x;
  tree.position.y += TREE_POSITION.y - finalBox.min.y;
  tree.position.z += TREE_POSITION.z - center.z;
  tree.updateMatrixWorld(true);
}

function configureBarkMaterial(sourceMaterial, uniforms) {
  const material = sourceMaterial.clone();
  material.name = 'SanctuaryV3_Sakura_Bark_PBR';
  material.color = new THREE.Color(0x8b684b);
  material.roughness = 0.88;
  material.metalness = 0;
  material.emissive = new THREE.Color(0x5a321f);
  material.emissiveIntensity = 0.035;
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uSanctuaryTime = uniforms.time;
    shader.uniforms.uSanctuaryWind = uniforms.wind;
    shader.uniforms.uSanctuaryBreath = uniforms.breath;
    shader.uniforms.uSanctuaryVitality = uniforms.vitality;
    shader.vertexShader = shader.vertexShader
      .replace(
        '#include <common>',
        `#include <common>
        uniform float uSanctuaryTime;
        uniform float uSanctuaryWind;
        uniform float uSanctuaryBreath;
        varying float vSanctuaryBarkHeight;`,
      )
      .replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
        vec3 sanctuaryWorld = (modelMatrix * vec4(position, 1.0)).xyz;
        float sanctuaryHeight = smoothstep(0.9, 8.4, sanctuaryWorld.y);
        float sanctuarySway = sin(uSanctuaryTime * 0.34 + sanctuaryWorld.y * 0.41)
          * 0.018 * sanctuaryHeight * uSanctuaryWind;
        transformed.x += sanctuarySway;
        transformed.z += cos(uSanctuaryTime * 0.27 + sanctuaryWorld.y * 0.33)
          * 0.011 * sanctuaryHeight * uSanctuaryWind;
        transformed.xz *= 1.0 + uSanctuaryBreath * sanctuaryHeight * 0.0018;
        vSanctuaryBarkHeight = sanctuaryHeight;`,
      );
    shader.fragmentShader = shader.fragmentShader
      .replace(
        '#include <common>',
        `#include <common>
        uniform float uSanctuaryVitality;
        uniform float uSanctuaryBreath;
        varying float vSanctuaryBarkHeight;`,
      )
      .replace(
        '#include <color_fragment>',
        `#include <color_fragment>
        vec3 sanctuaryDryBark = vec3(0.34, 0.21, 0.13);
        vec3 sanctuaryLivingBark = vec3(0.48, 0.33, 0.22);
        vec3 sanctuaryBarkTarget = mix(
          sanctuaryDryBark,
          sanctuaryLivingBark,
          smoothstep(0.08, 0.92, uSanctuaryVitality)
        );
        diffuseColor.rgb = mix(diffuseColor.rgb, sanctuaryBarkTarget, 0.18);`,
      )
      .replace(
        '#include <emissivemap_fragment>',
        `#include <emissivemap_fragment>
        float sanctuaryBarkPulse = (0.015 + uSanctuaryBreath * 0.035)
          * vSanctuaryBarkHeight * smoothstep(0.24, 1.0, uSanctuaryVitality);
        totalEmissiveRadiance += vec3(0.88, 0.47, 0.24) * sanctuaryBarkPulse;`,
      );
  };
  material.customProgramCacheKey = () => 'sanctuary-v3-sakura-bark-v1';
  material.needsUpdate = true;
  return material;
}

function configureBlossomMaterial(sourceMaterial, uniforms, layerSeed) {
  const material = sourceMaterial.clone();
  material.name = `SanctuaryV3_Yoshino_Blossoms_${layerSeed.toFixed(2)}`;
  material.color = new THREE.Color(0xff6f9a);
  material.emissive = new THREE.Color(0xff315d);
  material.emissiveIntensity = 0.28;
  material.roughness = 0.82;
  material.metalness = 0;
  material.side = THREE.DoubleSide;
  material.transparent = false;
  material.alphaTest = 0.12;
  material.depthWrite = true;
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uSanctuaryTime = uniforms.time;
    shader.uniforms.uSanctuaryWind = uniforms.wind;
    shader.uniforms.uSanctuaryBreath = uniforms.breath;
    shader.uniforms.uSanctuaryVitality = uniforms.vitality;
    shader.uniforms.uSanctuaryWither = uniforms.wither;
    shader.uniforms.uSanctuaryLayerSeed = { value: layerSeed };
    shader.vertexShader = shader.vertexShader
      .replace(
        '#include <common>',
        `#include <common>
        uniform float uSanctuaryTime;
        uniform float uSanctuaryWind;
        uniform float uSanctuaryBreath;
        uniform float uSanctuaryLayerSeed;
        varying float vSanctuaryBlossomSeed;
        varying float vSanctuaryCanopyHeight;`,
      )
      .replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
        vec3 sanctuaryWorld = (modelMatrix * vec4(position, 1.0)).xyz;
        float sanctuaryHeight = smoothstep(1.4, 8.6, sanctuaryWorld.y);
        float sanctuarySeed = fract(sin(dot(
          position.xyz + vec3(uSanctuaryLayerSeed * 7.1),
          vec3(12.9898, 78.233, 37.719)
        )) * 43758.5453);
        float sanctuaryWideWave = sin(
          uSanctuaryTime * 0.46 + sanctuaryWorld.x * 0.42 + sanctuaryWorld.z * 0.31
          + uSanctuaryLayerSeed * 5.7
        );
        float sanctuaryFlutter = sin(
          uSanctuaryTime * (0.82 + sanctuarySeed * 0.48) + sanctuarySeed * 19.4
        );
        transformed.x += (sanctuaryWideWave * 0.042 + sanctuaryFlutter * 0.009)
          * sanctuaryHeight * uSanctuaryWind;
        transformed.z += cos(
          uSanctuaryTime * 0.39 + sanctuaryWorld.z * 0.37 + sanctuarySeed * 8.6
        ) * 0.027 * sanctuaryHeight * uSanctuaryWind;
        transformed.xz *= 1.0 + uSanctuaryBreath * sanctuaryHeight * 0.0032;
        vSanctuaryBlossomSeed = sanctuarySeed;
        vSanctuaryCanopyHeight = sanctuaryHeight;`,
      );
    shader.fragmentShader = shader.fragmentShader
      .replace(
        '#include <common>',
        `#include <common>
        uniform float uSanctuaryVitality;
        uniform float uSanctuaryWither;
        uniform float uSanctuaryBreath;
        varying float vSanctuaryBlossomSeed;
        varying float vSanctuaryCanopyHeight;`,
      )
      .replace(
        '#include <color_fragment>',
        `#include <color_fragment>
        float sanctuaryHealth = smoothstep(0.08, 0.94, uSanctuaryVitality);
        float sanctuaryCoverage = mix(0.24, 1.0, smoothstep(0.12, 0.88, sanctuaryHealth));
        float sanctuaryReveal = smoothstep(
          vSanctuaryBlossomSeed - 0.11,
          vSanctuaryBlossomSeed + 0.09,
          sanctuaryCoverage
        );
        vec3 sanctuaryDryPetal = vec3(0.92, 0.22, 0.4);
        vec3 sanctuaryRosePetal = vec3(1.0, 0.38, 0.58);
        vec3 sanctuaryYoshinoPink = vec3(1.0, 0.6, 0.76);
        vec3 sanctuaryPearlPetal = vec3(1.0, 0.84, 0.91);
        vec3 sanctuaryHealthyPetal = mix(
          sanctuaryYoshinoPink,
          sanctuaryPearlPetal,
          0.56 + vSanctuaryBlossomSeed * 0.28
        );
        vec3 sanctuaryWitheredPetal = mix(
          sanctuaryDryPetal,
          sanctuaryRosePetal,
          vSanctuaryBlossomSeed
        );
        vec3 sanctuaryPetalTarget = mix(
          sanctuaryHealthyPetal,
          sanctuaryWitheredPetal,
          smoothstep(0.04, 0.98, uSanctuaryWither)
        );
        diffuseColor.rgb = mix(diffuseColor.rgb, sanctuaryPetalTarget, 0.94);
        diffuseColor.rgb = max(diffuseColor.rgb, vec3(0.72, 0.15, 0.3));
        diffuseColor.rgb *= 0.96 + sanctuaryHealth * 0.12;
        diffuseColor.a *= sanctuaryReveal * mix(0.58, 1.0, sanctuaryHealth);`,
      )
      .replace(
        '#include <emissivemap_fragment>',
        `#include <emissivemap_fragment>
        float sanctuaryPetalGlow = smoothstep(0.62, 1.0, uSanctuaryVitality)
          * (0.016 + uSanctuaryBreath * 0.012) * vSanctuaryCanopyHeight;
        totalEmissiveRadiance += sanctuaryPetalTarget * (0.32 + sanctuaryPetalGlow);`,
      )
      .replace(
        '#include <opaque_fragment>',
        `outgoingLight = max(
          outgoingLight,
          sanctuaryPetalTarget * 0.78 + vec3(0.08, 0.012, 0.028)
        );
        #include <opaque_fragment>`,
      );
  };
  material.customProgramCacheKey = () => 'sanctuary-v3-yoshino-blossoms-v3-bright-rose';
  material.needsUpdate = true;
  return material;
}

   
                                                                             
   
export class SanctuarySceneV3 {
  constructor({ quality = 'quest', canopyMode, performanceTier = 'auto' } = {}) {
    this.quality = quality;
    this.canopyMode = resolveCanopyMode(canopyMode);
    this.root = new THREE.Group();
    this.root.name = 'SanctuaryV3_Root';
    this.root.layers.set(SANCTUARY_LAYERS.scenery);
    this.scene = null;
    this.camera = null;
    this.initialized = false;
    this.assetStatus = 'idle';
    this.treeStatus = 'idle';
    this.treeSource = null;
    this.activeTreeLod = 'none';
    this.tree = null;
    this.treeBaseScale = new THREE.Vector3(1, 1, 1);
    this.canopyLayers = 0;
    this.assetLoadMs = 0;
    this.treeLight = null;
    this.floor = null;
    this.environment = new SanctuaryLandscape({
      quality,
      treePosition: TREE_POSITION,
      layer: SANCTUARY_LAYERS.scenery,
    });
    this.treeVisualState = new SanctuaryTreeVisualState();
    this.visualStateSnapshot = this.treeVisualState.snapshot();
    this.canopyController = new SakuraCanopyController({
      quality,
      layer: SANCTUARY_LAYERS.scenery,
      mode: this.canopyMode,
    });
    this.canopyTransitionProfiler = new CanopyTransitionProfiler();
    this.canopyPerformanceSnapshot = this.canopyTransitionProfiler.snapshot();
    this.previousCanopyCounts = { leaves: 0, blossoms: 0 };
    this.petals = new SanctuaryPetalSystem({
      quality,
      treePosition: TREE_POSITION,
      layer: SANCTUARY_LAYERS.effects,
    });
    this.details = new SanctuaryGroundDetails({
      quality,
      treePosition: TREE_POSITION,
      layer: SANCTUARY_LAYERS.scenery,
    });
    this.atmosphere = new SanctuaryAtmosphere({
      quality,
      treePosition: TREE_POSITION,
      sceneryLayer: SANCTUARY_LAYERS.scenery,
      effectsLayer: SANCTUARY_LAYERS.effects,
    });
    this.guidance = new SanctuaryBreathingGuide({
      treePosition: TREE_POSITION,
      layer: SANCTUARY_LAYERS.effects,
    });
    this.performanceGovernor = new SanctuaryPerformanceGovernor({
      quality,
      forcedLevel: performanceTier,
    });
    this.performanceSnapshot = this.performanceGovernor.snapshot();
    this.appliedPerformanceScale = 1;
    this.uniforms = {
      time: { value: 0 },
      wind: { value: 0.72 },
      breath: { value: 0 },
      vitality: { value: 0.5 },
      wither: { value: 0.5 },
    };
    this.ready = Promise.resolve(this.snapshot());
  }

  initialize({ scene, camera, renderer }) {
    if (this.initialized) return this.snapshot();

    this.scene = scene;
    this.camera = camera;
    this.assetStatus = 'loading';
    this.treeStatus = 'loading';

    scene.background = new THREE.Color(DEFAULT_BACKGROUND);
    scene.fog = new THREE.FogExp2(DEFAULT_FOG, 0.018);
    camera.layers.enableAll();

    const floor = new THREE.Mesh(
      new THREE.CircleGeometry(44, 96),
      new THREE.MeshStandardMaterial({
        color: 0x07110d,
        roughness: 1,
        metalness: 0,
      }),
    );
    floor.name = 'SanctuaryV3_OrientationFloor';
    floor.rotation.x = -Math.PI / 2;
    floor.position.set(0, -0.055, -5.3);
    floor.receiveShadow = false;
    floor.layers.set(SANCTUARY_LAYERS.scenery);
    this.root.add(floor);
    this.floor = floor;

    const ambient = new THREE.HemisphereLight(0x7599a2, 0x07110d, 0.68);
    ambient.name = 'SanctuaryV3_AmbientPreview';
    ambient.layers.set(SANCTUARY_LAYERS.scenery);
    this.root.add(ambient);

    const orientationLight = new THREE.DirectionalLight(0xd5e7ea, 0.72);
    orientationLight.name = 'SanctuaryV3_OrientationLight';
    orientationLight.position.set(7, 11, 5);
    orientationLight.layers.set(SANCTUARY_LAYERS.scenery);
    this.root.add(orientationLight);

    scene.add(this.root);
    this.guidance.initialize({ parent: this.root });
    this.initialized = true;

    const startedAt = performance.now();
    this.ready = Promise.allSettled([
      this.loadHeroTree(),
      this.environment.load({ parent: this.root, renderer }),
    ]).then(async ([treeResult, environmentResult]) => {
      if (treeResult.status === 'fulfilled') {
        this.treeStatus = 'ready';
      } else {
        this.treeStatus = 'fallback';
        console.warn(
          'Sanctuary V3 sakura failed to load; keeping the environment fallback.',
          treeResult.reason,
        );
      }

      if (environmentResult.status === 'fulfilled') {
        if (this.floor) this.floor.visible = false;
      } else {
        console.warn(
          'Sanctuary V3 landscape failed to load; keeping the neutral floor.',
          environmentResult.reason,
        );
      }

      const environmentSnapshot = this.environment.snapshot();
      const landscapeReady = environmentSnapshot.landscapeStatus === 'ready';
      const grassReady = environmentSnapshot.grassStatus === 'ready';
      const secondaryResults = await Promise.allSettled([
        this.petals.load({
          parent: this.root,
          terrainSampler: this.environment.heightSampler,
        }),
        this.details.load({
          parent: this.root,
          terrainSampler: this.environment.heightSampler,
        }),
        this.atmosphere.load({
          parent: this.root,
          scene: this.scene,
          terrainSampler: this.environment.heightSampler,
        }),
      ]);
      if (secondaryResults[0].status === 'rejected') {
        console.warn('Sanctuary V3 petal system failed to load.', secondaryResults[0].reason);
      }
      if (secondaryResults[1].status === 'rejected') {
        console.warn('Sanctuary V3 ground details failed to load.', secondaryResults[1].reason);
      }
      if (secondaryResults[2].status === 'rejected') {
        console.warn('Sanctuary V3 atmosphere failed to load.', secondaryResults[2].reason);
      }
      const petalsReady = this.petals.status === 'ready';
      const detailsReady = this.details.status === 'ready';
      const atmosphereReady = this.atmosphere.status === 'ready';
      this.assetStatus = this.treeStatus === 'ready'
        && landscapeReady
        && grassReady
        && petalsReady
        && detailsReady
        && atmosphereReady
        ? 'ready'
        : this.treeStatus === 'fallback' && !landscapeReady
          ? 'fallback'
          : 'partial-fallback';
      this.assetLoadMs = Math.round(performance.now() - startedAt);
      return this.snapshot();
    });

    return this.snapshot();
  }

  async loadHeroTree() {
    const loader = new GLTFLoader();
    loader.setMeshoptDecoder(MeshoptDecoder);
    const candidates = this.quality === 'high'
      ? [
          ['source', `${TREE_ASSET_BASE}sakura_hero_source.glb`],
          ['lod0', `${TREE_ASSET_BASE}sakura_hero_lod0.glb`],
          ['lod1', `${TREE_ASSET_BASE}sakura_hero_lod1.glb`],
        ]
      : [
          ['lod0', `${TREE_ASSET_BASE}sakura_hero_lod0.glb`],
          ['lod1', `${TREE_ASSET_BASE}sakura_hero_lod1.glb`],
          ['source', `${TREE_ASSET_BASE}sakura_hero_source.glb`],
        ];

    let loaded = null;
    let lastError = null;
    for (const [lod, path] of candidates) {
      try {
        loaded = { lod, path, gltf: await loadGltf(loader, path) };
        break;
      } catch (error) {
        lastError = error;
      }
    }
    if (!loaded) throw lastError || new Error('No Sanctuary V3 sakura source loaded');

    const tree = loaded.gltf.scene;
    tree.name = 'SanctuaryV3_Hero_Yoshino_Sakura';
    tree.traverse((object) => {
      if (!object.isMesh) return;
      object.castShadow = false;
      object.receiveShadow = false;
      object.layers.set(SANCTUARY_LAYERS.scenery);
    });
    this.canopyLayers = 1;

    fitTreeToScene(tree);
    this.tree = tree;
    this.treeBaseScale.copy(tree.scale);
    this.treeSource = loaded.path;
    this.activeTreeLod = loaded.lod;
    this.root.add(tree);

    const canopySnapshot = this.canopyController.initialize({ tree });
    if (canopySnapshot.canopyStatus === 'fallback') {
      console.warn(
        'Sanctuary V3 dynamic canopy failed; retaining the authored sakura canopy.',
        canopySnapshot.canopyFallbackReason,
      );
    }
    this.canopyLayers = canopySnapshot.canopyStatus === 'ready' ? 2 : 1;

    await this.addTreeGrounding();

    this.treeLight = new THREE.PointLight(0xffdbe6, 0.52, 11, 1.8);
    this.treeLight.name = 'SanctuaryV3_Sakura_CanopyFill';
    this.treeLight.position.set(TREE_POSITION.x, 5.5, TREE_POSITION.z + 0.8);
    this.treeLight.layers.set(SANCTUARY_LAYERS.scenery);
    this.root.add(this.treeLight);
  }

  async addTreeGrounding() {
    const shadowTexture = await loadTexture(`${TREE_ASSET_BASE}sakura_canopy_shadow.webp`);
    shadowTexture.colorSpace = THREE.SRGBColorSpace;
    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(8.4, 6.3),
      new THREE.MeshBasicMaterial({
        map: shadowTexture,
        transparent: true,
        opacity: 0.42,
        depthWrite: false,
        toneMapped: false,
      }),
    );
    shadow.name = 'SanctuaryV3_Sakura_BakedShadow';
    shadow.position.set(TREE_POSITION.x, 0.006, TREE_POSITION.z + 0.22);
    shadow.rotation.x = -Math.PI / 2;
    shadow.layers.set(SANCTUARY_LAYERS.scenery);
    this.root.add(shadow);

    try {
      const aoTexture = await loadTexture(`${TREE_ASSET_BASE}sakura_ground_ao.webp`);
      aoTexture.colorSpace = THREE.SRGBColorSpace;
      const rootAo = new THREE.Mesh(
        new THREE.PlaneGeometry(3.4, 3.4),
        new THREE.MeshBasicMaterial({
          map: aoTexture,
          transparent: true,
          opacity: 0.48,
          depthWrite: false,
          toneMapped: false,
        }),
      );
      rootAo.name = 'SanctuaryV3_Sakura_Root_AO';
      rootAo.position.set(TREE_POSITION.x, 0.011, TREE_POSITION.z);
      rootAo.rotation.x = -Math.PI / 2;
      rootAo.layers.set(SANCTUARY_LAYERS.scenery);
      this.root.add(rootAo);
    } catch (error) {
      console.warn('Optional sakura root AO failed to load.', error);
    }
  }

  update({
    treeVitality,
    coherence,
    fallingCoherence,
    signalQuality,
    breathPhase,
    breathProgress,
    comfortOptions,
    deltaTime,
    elapsedTime,
    sessionActive,
    sessionPaused,
    xrPresenting,
  } = {}) {
    this.performanceSnapshot = this.performanceGovernor.update({
      deltaTime,
      xrPresenting,
    });
    const targetPerformanceScale = this.performanceSnapshot.performanceScale;
    this.appliedPerformanceScale = THREE.MathUtils.lerp(
      this.appliedPerformanceScale,
      targetPerformanceScale,
      1 - Math.exp(-0.72 * Math.min(deltaTime || 1 / 72, 0.1)),
    );
    const performanceScale = this.appliedPerformanceScale;
    this.visualStateSnapshot = this.treeVisualState.update({
      treeVitality,
      coherence,
      signalQuality,
      deltaTime,
    });
    const vitality = this.visualStateSnapshot.vitality;
    const cycleProgress = Number.isFinite(breathProgress) ? breathProgress : 0;
    const breathPulse = 0.5 - Math.cos(cycleProgress * Math.PI * 2) * 0.5;
    const reducedMotion = comfortOptions?.reducedMotion === true;

    const canopySnapshot = this.canopyController.update({
      visualState: this.visualStateSnapshot,
      comfortOptions,
      elapsedTime,
      deltaTime,
      performanceScale,
    });
    if (canopySnapshot.canopyStatus === 'fallback') this.canopyLayers = 1;
    const leafDelta = canopySnapshot.activeLeafCount - this.previousCanopyCounts.leaves;
    const blossomDelta = canopySnapshot.activeBlossomCount
      - this.previousCanopyCounts.blossoms;
    const canopyTransitioning = canopySnapshot.canopyStatus === 'ready' && (
      leafDelta !== 0
      || blossomDelta !== 0
      || (canopySnapshot.fullBloomBlend > 0 && canopySnapshot.fullBloomBlend < 1)
      || canopySnapshot.lastCanopyShedEventCount > 0
    );
    const canopyTransitionReason = canopySnapshot.fullBloomBlend > 0
      ? 'full-bloom'
      : canopySnapshot.lastCanopyShedEventCount > 0
        ? 'wither'
        : canopySnapshot.lastAdaptiveRetractionCount > 0
          ? 'adaptive-lod'
          : leafDelta > 0 || blossomDelta > 0
            ? 'growth'
            : leafDelta < 0 || blossomDelta < 0
              ? 'decline'
              : 'steady';
    this.canopyPerformanceSnapshot = this.canopyTransitionProfiler.update({
      deltaTime,
      transitioning: canopyTransitioning,
      xrPresenting,
      reason: canopyTransitionReason,
    });
    this.previousCanopyCounts.leaves = canopySnapshot.activeLeafCount;
    this.previousCanopyCounts.blossoms = canopySnapshot.activeBlossomCount;
    this.petals.enqueueShedEvents(this.canopyController.drainShedEvents());

    this.uniforms.time.value = elapsedTime || 0;
    this.uniforms.wind.value = reducedMotion ? 0.18 : 0.72;
    this.uniforms.breath.value = breathPulse;
    this.uniforms.vitality.value = this.visualStateSnapshot.blossomCoverage;
    this.uniforms.wither.value = 1 - this.visualStateSnapshot.blossomHealth;

    if (this.tree) {
      const expansion = 1 + breathPulse * (reducedMotion ? 0.0008 : 0.0026);
      this.tree.scale.set(
        this.treeBaseScale.x * expansion,
        this.treeBaseScale.y * (1 + breathPulse * 0.0014),
        this.treeBaseScale.z * expansion,
      );
    }
    if (this.treeLight) {
      const fullBloomPulse = canopySnapshot.fullBloomLightPulse || 0;
      const fullBloomBlend = canopySnapshot.fullBloomBlend || 0;
      this.treeLight.intensity = 0.22
        + this.visualStateSnapshot.branchWarmth * 0.52
        + breathPulse * 0.045
        + fullBloomBlend * 0.08
        + fullBloomPulse * 0.75;
      this.treeLight.color.copy(TREE_FILL_COLOR).lerp(
        TREE_FULL_BLOOM_COLOR,
        fullBloomPulse * 0.82,
      );
    }
    this.petals.update({
      visualState: this.visualStateSnapshot,
      coherence: fallingCoherence ?? coherence,
      comfortOptions,
      elapsedTime,
      deltaTime,
      performanceScale,
      eventDriven: canopySnapshot.canopyStatus === 'ready'
        && canopySnapshot.canopyMode === 'dynamic',
    });
    this.details.update({
      visualState: this.visualStateSnapshot,
      breathProgress,
      comfortOptions,
      performanceScale,
    });
    this.atmosphere.update({
      visualState: this.visualStateSnapshot,
      breathProgress,
      comfortOptions,
      elapsedTime,
      performanceScale,
    });
    this.environment.update({
      treeVitality,
      coherence,
      comfortOptions,
      elapsedTime,
      performanceScale,
    });
    this.guidance.update({
      breathPhase,
      breathProgress,
      comfortOptions,
      elapsedTime,
      sessionActive,
      sessionPaused,
      deltaTime,
    });

                                                                            
                                                                                
    return this.performanceSnapshot;
  }

  snapshot() {
    return {
      sceneVersion: 'v3',
      quality: this.quality,
      assetStatus: this.assetStatus,
      initialized: this.initialized,
      treeStatus: this.treeStatus,
      treeSource: this.treeSource,
      activeTreeLod: this.activeTreeLod,
      treeHeight: this.tree ? TREE_TARGET_HEIGHT : 0,
      canopyLayers: this.canopyLayers,
      assetLoadMs: this.assetLoadMs,
      treeVisualState: { ...this.visualStateSnapshot },
      ...this.canopyController.snapshot(),
      ...this.canopyPerformanceSnapshot,
      ...this.petals.snapshot(),
      ...this.details.snapshot(),
      ...this.atmosphere.snapshot(),
      ...this.guidance.snapshot(),
      ...this.performanceSnapshot,
      appliedPerformanceScale: this.appliedPerformanceScale,
      ...this.environment.snapshot(),
    };
  }

  dispose() {
    if (!this.initialized) return;
    this.canopyController.dispose();
    this.root.traverse((object) => {
      object.geometry?.dispose();
      disposeMaterial(object.material);
    });
    this.root.removeFromParent();
    this.initialized = false;
    this.assetStatus = 'disposed';
  }
}
