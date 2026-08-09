import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { quantizePerformanceScale } from './sanctuary_performance.js?v=25';

const ATMOSPHERE_ASSET_BASE = 'assets/sanctuary_v3/atmosphere/';
const SKY_CENTER = new THREE.Vector3(0, 3.5, -5.3);
const MOON_POSITION = new THREE.Vector3(18.5, 19.2, -31);
const AURORA_POSITION = new THREE.Vector3(-1.5, 10.8, -34);
const QUIET_FOG_COLOR = new THREE.Color(0x07131b);
const VITAL_FOG_COLOR = new THREE.Color(0x171327);

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

function seededRandom(seed) {
  const value = Math.sin(seed * 12.9898 + 78.233) * 43758.5453;
  return value - Math.floor(value);
}

function fitObjectToBox(object, targetSize, targetPosition) {
  object.updateMatrixWorld(true);
  const bounds = new THREE.Box3().setFromObject(object);
  const size = bounds.getSize(new THREE.Vector3());
  object.scale.multiply(new THREE.Vector3(
    targetSize.x / Math.max(size.x, 0.001),
    targetSize.y / Math.max(size.y, 0.001),
    targetSize.z / Math.max(size.z, 0.001),
  ));
  object.updateMatrixWorld(true);
  const fitted = new THREE.Box3().setFromObject(object);
  const center = fitted.getCenter(new THREE.Vector3());
  object.position.add(targetPosition.clone().sub(center));
  object.updateMatrixWorld(true);
}

function fitAuroraToScene(object) {
  object.updateMatrixWorld(true);
  const bounds = new THREE.Box3().setFromObject(object);
  const size = bounds.getSize(new THREE.Vector3());
  const scaleX = 34 / Math.max(size.x, 0.001);
  const scaleY = 7.2 / Math.max(size.y, 0.001);
  const scaleZ = size.z < size.x * 0.04
    ? scaleX
    : Math.min(7 / Math.max(size.z, 0.001), scaleX * 1.8);
  object.scale.multiply(new THREE.Vector3(scaleX, scaleY, scaleZ));
  object.updateMatrixWorld(true);
  const center = new THREE.Box3().setFromObject(object).getCenter(new THREE.Vector3());
  object.position.add(AURORA_POSITION.clone().sub(center));
  object.updateMatrixWorld(true);
}

function createGlowTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 256;
  canvas.height = 256;
  const context = canvas.getContext('2d');
  const gradient = context.createRadialGradient(128, 128, 18, 128, 128, 128);
  gradient.addColorStop(0, 'rgba(235, 246, 255, 0.78)');
  gradient.addColorStop(0.2, 'rgba(180, 215, 255, 0.28)');
  gradient.addColorStop(0.55, 'rgba(120, 172, 224, 0.08)');
  gradient.addColorStop(1, 'rgba(80, 130, 180, 0)');
  context.fillStyle = gradient;
  context.fillRect(0, 0, 256, 256);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

function createLunarSurfaceTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 1024;
  canvas.height = 512;
  const context = canvas.getContext('2d');
  const base = context.createLinearGradient(0, 0, 1024, 512);
  base.addColorStop(0, '#777d79');
  base.addColorStop(0.48, '#a7aaa1');
  base.addColorStop(1, '#686e6b');
  context.fillStyle = base;
  context.fillRect(0, 0, 1024, 512);

  for (let index = 0; index < 18; index++) {
    const x = seededRandom(index + 910) * 1024;
    const y = seededRandom(index + 1210) * 512;
    const radius = 34 + seededRandom(index + 1510) * 92;
    const mare = context.createRadialGradient(x, y, radius * 0.08, x, y, radius);
    mare.addColorStop(0, 'rgba(48, 55, 55, 0.32)');
    mare.addColorStop(0.72, 'rgba(64, 70, 69, 0.19)');
    mare.addColorStop(1, 'rgba(86, 91, 87, 0)');
    context.fillStyle = mare;
    context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
  }

  for (let index = 0; index < 150; index++) {
    const x = seededRandom(index + 2110) * 1024;
    const y = seededRandom(index + 2710) * 512;
    const radius = 2.5 + seededRandom(index + 3310) ** 2 * 24;
    const crater = context.createRadialGradient(
      x - radius * 0.18,
      y - radius * 0.16,
      radius * 0.08,
      x,
      y,
      radius,
    );
    crater.addColorStop(0, 'rgba(39, 44, 43, 0.6)');
    crater.addColorStop(0.58, 'rgba(78, 83, 80, 0.38)');
    crater.addColorStop(0.78, 'rgba(211, 211, 193, 0.34)');
    crater.addColorStop(1, 'rgba(150, 153, 143, 0)');
    context.fillStyle = crater;
    context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
  }

  const image = context.getImageData(0, 0, 1024, 512);
  for (let pixel = 0; pixel < image.data.length; pixel += 4) {
    const noise = (seededRandom(pixel * 0.013 + 4110) - 0.5) * 15;
    image.data[pixel] = THREE.MathUtils.clamp(image.data[pixel] + noise, 0, 255);
    image.data[pixel + 1] = THREE.MathUtils.clamp(image.data[pixel + 1] + noise, 0, 255);
    image.data[pixel + 2] = THREE.MathUtils.clamp(image.data[pixel + 2] + noise, 0, 255);
  }
  context.putImageData(image, 0, 0);

  const texture = new THREE.CanvasTexture(canvas);
  texture.name = 'SanctuaryV3_Procedural_Lunar_Surface';
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.wrapS = THREE.RepeatWrapping;
  texture.anisotropy = 4;
  texture.needsUpdate = true;
  return texture;
}

function createAuroraMaterial(uniforms) {
  return new THREE.ShaderMaterial({
    uniforms,
    transparent: true,
    depthWrite: false,
    side: THREE.DoubleSide,
    blending: THREE.AdditiveBlending,
    toneMapped: false,
    vertexShader: `
      uniform float uTime;
      uniform float uMotion;
      varying vec2 vAuroraUv;
      varying float vAuroraWave;
      void main() {
        vAuroraUv = uv;
        vec3 transformed = position;
        float wave = sin(position.x * 0.18 + uTime * 0.13 * uMotion)
          + sin(position.x * 0.07 - uTime * 0.09 * uMotion) * 0.55;
        transformed.y += wave * 0.045;
        transformed.z += sin(position.y * 0.21 + uTime * 0.08 * uMotion) * 0.035;
        vAuroraWave = wave;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(transformed, 1.0);
      }
    `,
    fragmentShader: `
      uniform float uTime;
      uniform float uVitality;
      uniform float uOpacity;
      uniform float uMotion;
      varying vec2 vAuroraUv;
      varying float vAuroraWave;
      void main() {
        float vertical = sin(vAuroraUv.y * 3.14159265);
        float curtainA = sin(vAuroraUv.x * 18.0 + uTime * 0.11 * uMotion + vAuroraWave);
        float curtainB = sin(vAuroraUv.x * 31.0 - uTime * 0.07 * uMotion);
        float curtain = smoothstep(-0.3, 0.82, curtainA * 0.62 + curtainB * 0.38);
        float edgeFade = smoothstep(0.0, 0.12, vAuroraUv.x)
          * smoothstep(1.0, 0.88, vAuroraUv.x);
        vec3 quiet = vec3(0.08, 0.22, 0.24);
        vec3 teal = vec3(0.18, 0.92, 0.69);
        vec3 violet = vec3(0.48, 0.31, 0.82);
        vec3 color = mix(quiet, mix(teal, violet, vAuroraUv.y * 0.38), uVitality);
        float alpha = vertical * edgeFade * (0.32 + curtain * 0.68) * uOpacity;
        if (alpha < 0.008) discard;
        gl_FragColor = vec4(color, alpha);
      }
    `,
  });
}

export class SanctuaryAtmosphere {
  constructor({ quality = 'quest', treePosition, sceneryLayer = 0, effectsLayer = 3 } = {}) {
    this.quality = quality;
    this.treePosition = treePosition.clone();
    this.sceneryLayer = sceneryLayer;
    this.effectsLayer = effectsLayer;
    this.root = new THREE.Group();
    this.root.name = 'SanctuaryV3_Nocturnal_Atmosphere';
    this.root.layers.set(sceneryLayer);
    this.status = 'idle';
    this.moonStatus = 'idle';
    this.auroraStatus = 'idle';
    this.scene = null;
    this.sky = null;
    this.stars = null;
    this.fireflies = null;
    this.moon = null;
    this.moonHalo = null;
    this.aurora = null;
    this.moonLight = null;
    this.starCount = quality === 'high' ? 75000 : 50000;
    this.activeStarCount = this.starCount;
    this.fireflyCount = quality === 'high' ? 1300 : 900;
    this.activeFireflies = this.fireflyCount;
    this.lastParticlePerformanceBucket = null;
    this.lastReducedParticles = null;
    this.atmosphereRangeUpdateCount = 0;
    this.uniforms = {
      time: { value: 0 },
      vitality: { value: 0.55 },
      breath: { value: 0 },
      reducedMotion: { value: 0 },
    };
    this.auroraUniforms = {
      uTime: this.uniforms.time,
      uVitality: this.uniforms.vitality,
      uMotion: { value: 1 },
      uOpacity: { value: 0.16 },
    };
  }

  async load({ parent, scene, terrainSampler }) {
    this.status = 'loading';
    this.scene = scene;
    parent.add(this.root);
    this.createSky();
    this.createStars();
    this.createFireflies(terrainSampler);
    const results = await Promise.allSettled([this.loadMoon(), this.loadAurora()]);
    if (results[0].status === 'rejected') {
      console.warn('Sanctuary moon model failed; using textured sphere fallback.', results[0].reason);
      await this.createMoonFallback();
    }
    if (results[1].status === 'rejected') {
      console.warn('Sanctuary aurora model failed; using curved curtain fallback.', results[1].reason);
      this.createAuroraFallback();
    }
    this.status = this.moonStatus === 'ready' && this.auroraStatus === 'ready'
      ? 'ready'
      : 'partial-fallback';
    return this.snapshot();
  }

  createSky() {
    const uniforms = {
      uTop: { value: new THREE.Color(0x01050c) },
      uHorizon: { value: new THREE.Color(0x071923) },
      uVitality: this.uniforms.vitality,
    };
    const material = new THREE.ShaderMaterial({
      uniforms,
      side: THREE.BackSide,
      depthWrite: false,
      fog: false,
      vertexShader: `
        varying vec3 vSkyDirection;
        void main() {
          vSkyDirection = normalize(position);
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform vec3 uTop;
        uniform vec3 uHorizon;
        uniform float uVitality;
        varying vec3 vSkyDirection;
        void main() {
          float height = smoothstep(-0.12, 0.82, vSkyDirection.y);
          vec3 warmHorizon = vec3(0.13, 0.08, 0.18);
          vec3 horizon = mix(uHorizon, warmHorizon, uVitality * 0.22);
          vec3 color = mix(horizon, uTop, height);
          gl_FragColor = vec4(color, 1.0);
        }
      `,
    });
    this.sky = new THREE.Mesh(new THREE.SphereGeometry(56, 32, 18), material);
    this.sky.name = 'SanctuaryV3_Midnight_Gradient_Sky';
    this.sky.position.copy(SKY_CENTER);
    this.sky.renderOrder = -20;
    this.sky.layers.set(this.sceneryLayer);
    this.root.add(this.sky);
  }

  createStars() {
    const positions = new Float32Array(this.starCount * 3);
    const phases = new Float32Array(this.starCount);
    const sizes = new Float32Array(this.starCount);
    const brightness = new Float32Array(this.starCount);
    for (let index = 0; index < this.starCount; index++) {
      const y = 0.04 + seededRandom(index * 5 + 1) * 0.96;
      const angle = seededRandom(index * 5 + 2) * Math.PI * 2;
      const horizontal = Math.sqrt(Math.max(0, 1 - y * y));
      const radius = 51.5 + seededRandom(index * 5 + 3) * 2.5;
      positions[index * 3] = SKY_CENTER.x + Math.cos(angle) * horizontal * radius;
      positions[index * 3 + 1] = SKY_CENTER.y + y * radius;
      positions[index * 3 + 2] = SKY_CENTER.z + Math.sin(angle) * horizontal * radius;
      phases[index] = seededRandom(index * 5 + 4);
      sizes[index] = 0.58 + seededRandom(index * 5 + 5) * 1.35;
      brightness[index] = 0.38 + seededRandom(index * 5 + 6) * 0.62;
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute('starPhase', new THREE.BufferAttribute(phases, 1));
    geometry.setAttribute('starSize', new THREE.BufferAttribute(sizes, 1));
    geometry.setAttribute('starBrightness', new THREE.BufferAttribute(brightness, 1));
    const material = new THREE.ShaderMaterial({
      uniforms: {
        uTime: this.uniforms.time,
        uReducedMotion: this.uniforms.reducedMotion,
      },
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      toneMapped: false,
      vertexShader: `
        uniform float uTime;
        uniform float uReducedMotion;
        attribute float starPhase;
        attribute float starSize;
        attribute float starBrightness;
        varying float vStarGlow;
        void main() {
          float speed = mix(1.0, 0.24, uReducedMotion);
          float primaryTwinkle = 0.5 + 0.5 * sin(
            uTime * (0.34 + starPhase * 0.92) * speed + starPhase * 37.0
          );
          float secondaryTwinkle = 0.5 + 0.5 * sin(
            uTime * (0.13 + starPhase * 0.21) * speed + starPhase * 71.0
          );
          float twinkle = pow(primaryTwinkle, 2.8) * (0.28 + secondaryTwinkle * 0.72);
          vStarGlow = starBrightness * (0.015 + twinkle * 0.985);
          vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
          gl_PointSize = clamp(starSize * vStarGlow * (115.0 / max(8.0, -mvPosition.z)), 1.0, 3.6);
          gl_Position = projectionMatrix * mvPosition;
        }
      `,
      fragmentShader: `
        varying float vStarGlow;
        void main() {
          float distanceToCenter = length(gl_PointCoord - vec2(0.5));
          float glow = 1.0 - smoothstep(0.05, 0.5, distanceToCenter);
          if (glow < 0.01) discard;
          vec3 color = mix(vec3(0.58, 0.76, 1.0), vec3(1.0, 0.94, 0.82), vStarGlow);
          gl_FragColor = vec4(color, glow * vStarGlow * 0.86);
        }
      `,
    });
    this.stars = new THREE.Points(geometry, material);
    this.stars.name = 'SanctuaryV3_Twinkling_Stars';
    this.stars.frustumCulled = false;
    this.stars.renderOrder = -10;
    this.stars.layers.set(this.effectsLayer);
    this.root.add(this.stars);
  }

  createFireflies(terrainSampler) {
    const positions = new Float32Array(this.fireflyCount * 3);
    const phases = new Float32Array(this.fireflyCount);
    const sizes = new Float32Array(this.fireflyCount);
    const drift = new Float32Array(this.fireflyCount);
    for (let index = 0; index < this.fireflyCount; index++) {
      const nearTree = seededRandom(index * 7 + 1) < 0.74;
      const radius = nearTree
        ? 0.7 + Math.sqrt(seededRandom(index * 7 + 2)) * 5.2
        : 5.5 + Math.sqrt(seededRandom(index * 7 + 2)) * 11.5;
      const angle = seededRandom(index * 7 + 3) * Math.PI * 2;
      const x = this.treePosition.x + Math.cos(angle) * radius;
      const z = this.treePosition.z + Math.sin(angle) * radius * 0.86;
      const ground = terrainSampler?.sample(x, z);
      positions[index * 3] = x;
      positions[index * 3 + 1] = (Number.isFinite(ground) ? ground : 0)
        + 0.28 + seededRandom(index * 7 + 4) * (nearTree ? 3.8 : 2.2);
      positions[index * 3 + 2] = z;
      phases[index] = seededRandom(index * 7 + 5);
      sizes[index] = 0.65 + seededRandom(index * 7 + 6) * 1.2;
      drift[index] = 0.22 + seededRandom(index * 7 + 7) * 0.5;
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute('fireflyPhase', new THREE.BufferAttribute(phases, 1));
    geometry.setAttribute('fireflySize', new THREE.BufferAttribute(sizes, 1));
    geometry.setAttribute('fireflyDrift', new THREE.BufferAttribute(drift, 1));
    const material = new THREE.ShaderMaterial({
      uniforms: {
        uTime: this.uniforms.time,
        uVitality: this.uniforms.vitality,
        uBreath: this.uniforms.breath,
        uReducedMotion: this.uniforms.reducedMotion,
      },
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      toneMapped: false,
      vertexShader: `
        uniform float uTime;
        uniform float uVitality;
        uniform float uBreath;
        uniform float uReducedMotion;
        attribute float fireflyPhase;
        attribute float fireflySize;
        attribute float fireflyDrift;
        varying float vFireflyGlow;
        void main() {
          float motion = mix(1.0, 0.26, uReducedMotion);
          vec3 transformed = position;
          transformed.x += (
            sin(uTime * 0.34 * motion + fireflyPhase * 31.0)
            + sin(uTime * 0.12 * motion + fireflyPhase * 73.0) * 0.42
          ) * fireflyDrift;
          transformed.y += (
            sin(uTime * 0.23 * motion + fireflyPhase * 47.0)
            + cos(uTime * 0.1 * motion + fireflyPhase * 61.0) * 0.36
          ) * fireflyDrift * 0.7;
          transformed.z += (
            cos(uTime * 0.29 * motion + fireflyPhase * 23.0)
            + sin(uTime * 0.14 * motion + fireflyPhase * 43.0) * 0.38
          ) * fireflyDrift;
          float blinkWave = 0.5 + 0.5 * sin(
            uTime * (0.74 + fireflyPhase * 1.18) * motion + fireflyPhase * 53.0
          );
          float blinkGate = pow(blinkWave, 3.4);
          float slowPulse = 0.5 + 0.5 * sin(
            uTime * (0.17 + fireflyPhase * 0.16) * motion + fireflyPhase * 89.0
          );
          float biofeedbackLift = 0.82 + uBreath * 0.1 + uVitality * 0.08;
          vFireflyGlow = blinkGate * (0.28 + slowPulse * 0.72) * biofeedbackLift;
          vec4 mvPosition = modelViewMatrix * vec4(transformed, 1.0);
          gl_PointSize = clamp(fireflySize * max(vFireflyGlow, 0.05)
            * (76.0 / max(2.0, -mvPosition.z)), 1.0, 11.0);
          gl_Position = projectionMatrix * mvPosition;
        }
      `,
      fragmentShader: `
        varying float vFireflyGlow;
        void main() {
          float distanceToCenter = length(gl_PointCoord - vec2(0.5));
          float core = 1.0 - smoothstep(0.0, 0.16, distanceToCenter);
          float halo = 1.0 - smoothstep(0.08, 0.5, distanceToCenter);
          float alpha = core * 0.84 + halo * 0.34;
          if (alpha * vFireflyGlow < 0.008) discard;
          vec3 color = mix(vec3(1.0, 0.66, 0.2), vec3(1.0, 0.94, 0.58), core);
          gl_FragColor = vec4(color, alpha * vFireflyGlow);
        }
      `,
    });
    this.fireflies = new THREE.Points(geometry, material);
    this.fireflies.name = 'SanctuaryV3_Warm_Fireflies';
    this.fireflies.frustumCulled = false;
    this.fireflies.layers.set(this.effectsLayer);
    this.root.add(this.fireflies);
  }

  async loadMoon() {
    const loader = new GLTFLoader();
    loader.setMeshoptDecoder(MeshoptDecoder);
    const gltf = await loadGltf(loader, `${ATMOSPHERE_ASSET_BASE}moon_quest.glb`);
    const moon = gltf.scene;
    moon.name = 'SanctuaryV3_Hyperreal_Moon';
    const generatedSurface = createLunarSurfaceTexture();
    moon.traverse((object) => {
      if (!object.isMesh) return;
      const source = Array.isArray(object.material) ? object.material[0] : object.material;
      const albedo = source?.map || generatedSurface;
      const normal = source?.normalMap || null;
      const roughness = source?.roughnessMap || null;
      if (albedo) {
        albedo.colorSpace = THREE.SRGBColorSpace;
        albedo.anisotropy = 4;
        albedo.needsUpdate = true;
      }
      if (normal) {
        normal.colorSpace = THREE.NoColorSpace;
        normal.anisotropy = 4;
        normal.needsUpdate = true;
      }
      const bump = normal ? null : albedo.clone();
      if (bump) {
        bump.colorSpace = THREE.NoColorSpace;
        bump.needsUpdate = true;
      }
      object.material = new THREE.MeshStandardMaterial({
        map: albedo,
        normalMap: normal,
        normalScale: new THREE.Vector2(0.72, 0.72),
        bumpMap: bump,
        bumpScale: 0.035,
        roughnessMap: roughness,
        aoMap: source?.aoMap || null,
        color: 0xd5d3c8,
        roughness: source?.roughness ?? 0.91,
        metalness: 0,
        emissive: 0x889295,
        emissiveMap: albedo,
        emissiveIntensity: 0.12,
      });
      object.material.name = 'SanctuaryV3_Lunar_Surface_PBR';
      object.layers.set(this.sceneryLayer);
    });
    fitObjectToBox(moon, new THREE.Vector3(3.15, 3.15, 3.15), MOON_POSITION);
    moon.rotation.y -= 0.38;
    this.root.add(moon);
    this.moon = moon;
    this.createMoonLighting();
    this.moonStatus = 'ready';
  }

  async createMoonFallback() {
    let albedo = null;
    let normal = null;
    try {
      [albedo, normal] = await Promise.all([
        loadTexture(`${ATMOSPHERE_ASSET_BASE}moon_albedo.webp`),
        loadTexture(`${ATMOSPHERE_ASSET_BASE}moon_normal.webp`),
      ]);
      albedo.colorSpace = THREE.SRGBColorSpace;
      normal.colorSpace = THREE.NoColorSpace;
    } catch (error) {
      console.warn('Sanctuary moon textures failed; using neutral lunar material.', error);
    }
    const surface = albedo || createLunarSurfaceTexture();
    const bump = surface.clone();
    bump.colorSpace = THREE.NoColorSpace;
    bump.needsUpdate = true;
    const moon = new THREE.Mesh(
      new THREE.SphereGeometry(1.575, 64, 32),
      new THREE.MeshStandardMaterial({
        map: surface,
        normalMap: normal,
        normalScale: new THREE.Vector2(0.58, 0.58),
        bumpMap: normal ? null : bump,
        bumpScale: 0.032,
        color: 0xd3d2c8,
        roughness: 0.96,
        metalness: 0,
        emissive: 0x7d888b,
        emissiveMap: surface,
        emissiveIntensity: 0.12,
      }),
    );
    moon.name = 'SanctuaryV3_Moon_Fallback';
    moon.position.copy(MOON_POSITION);
    moon.layers.set(this.sceneryLayer);
    this.root.add(moon);
    this.moon = moon;
    this.createMoonLighting();
    this.moonStatus = 'fallback';
  }

  createMoonLighting() {
    const halo = new THREE.Sprite(new THREE.SpriteMaterial({
      map: createGlowTexture(),
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      opacity: 0.48,
      toneMapped: false,
    }));
    halo.name = 'SanctuaryV3_Moon_Halo';
    halo.position.copy(MOON_POSITION).add(new THREE.Vector3(0, 0, 0.35));
    halo.scale.set(7.2, 7.2, 1);
    halo.layers.set(this.effectsLayer);
    this.root.add(halo);
    this.moonHalo = halo;

    const light = new THREE.DirectionalLight(0xc7dded, 0.46);
    light.name = 'SanctuaryV3_Moonlight';
    light.position.copy(MOON_POSITION);
    light.target.position.copy(this.treePosition).add(new THREE.Vector3(0, 3.2, 0));
    light.layers.set(this.sceneryLayer);
    light.target.layers.set(this.sceneryLayer);
    this.root.add(light, light.target);
    this.moonLight = light;
  }

  async loadAurora() {
    const loader = new GLTFLoader();
    loader.setMeshoptDecoder(MeshoptDecoder);
    const gltf = await loadGltf(loader, `${ATMOSPHERE_ASSET_BASE}aurora_quest.glb`);
    const aurora = gltf.scene;
    aurora.name = 'SanctuaryV3_Aurora_Curtain';
    const material = createAuroraMaterial(this.auroraUniforms);
    aurora.traverse((object) => {
      if (!object.isMesh) return;
      object.material = material;
      object.frustumCulled = false;
      object.renderOrder = -4;
      object.layers.set(this.effectsLayer);
    });
    fitAuroraToScene(aurora);
    this.root.add(aurora);
    this.aurora = aurora;
    this.auroraStatus = 'ready';
  }

  createAuroraFallback() {
    const geometry = new THREE.PlaneGeometry(34, 7.2, 32, 6);
    const position = geometry.attributes.position;
    for (let index = 0; index < position.count; index++) {
      const x = position.getX(index);
      position.setZ(index, -Math.abs(x) * 0.08);
    }
    position.needsUpdate = true;
    const aurora = new THREE.Mesh(geometry, createAuroraMaterial(this.auroraUniforms));
    aurora.name = 'SanctuaryV3_Aurora_Fallback';
    aurora.position.copy(AURORA_POSITION);
    aurora.layers.set(this.effectsLayer);
    aurora.renderOrder = -4;
    this.root.add(aurora);
    this.aurora = aurora;
    this.auroraStatus = 'fallback';
  }

  update({
    visualState,
    breathProgress,
    comfortOptions,
    elapsedTime = 0,
    performanceScale = 1,
  } = {}) {
    const vitality = visualState?.vitality ?? 0.5;
    const breath = 0.5 - Math.cos((breathProgress || 0) * Math.PI * 2) * 0.5;
    const reducedMotion = comfortOptions?.reducedMotion === true;
    const reducedParticles = comfortOptions?.reducedParticles === true;
    this.uniforms.time.value = elapsedTime;
    this.uniforms.vitality.value = vitality;
    this.uniforms.breath.value = breath;
    this.uniforms.reducedMotion.value = reducedMotion ? 1 : 0;
    this.auroraUniforms.uMotion.value = reducedMotion ? 0.22 : 1;
    this.auroraUniforms.uOpacity.value = (reducedMotion
      ? 0.045 + vitality * 0.075
      : 0.07 + vitality * 0.18) * (0.72 + performanceScale * 0.28);

    const performanceBucket = quantizePerformanceScale(performanceScale);
    if (
      performanceBucket !== this.lastParticlePerformanceBucket
      || reducedParticles !== this.lastReducedParticles
    ) {
      this.lastParticlePerformanceBucket = performanceBucket;
      this.lastReducedParticles = reducedParticles;
      this.atmosphereRangeUpdateCount += 1;
      const comfortFireflies = reducedParticles
        ? Math.round(this.fireflyCount * 0.28)
        : this.fireflyCount;
      this.activeFireflies = Math.min(
        comfortFireflies,
        Math.max(160, Math.round(this.fireflyCount * (0.35 + performanceBucket * 0.65))),
      );
      this.fireflies?.geometry.setDrawRange(0, this.activeFireflies);
      this.activeStarCount = Math.max(
        4200,
        Math.round(this.starCount * (0.55 + performanceBucket * 0.45)),
      );
      this.stars?.geometry.setDrawRange(0, this.activeStarCount);
    }
    if (this.moonHalo) this.moonHalo.material.opacity = 0.55 + vitality * 0.13 + breath * 0.025;
    if (this.moonLight) this.moonLight.intensity = 0.39 + vitality * 0.13;
    if (this.scene?.fog?.isFogExp2) {
      this.scene.fog.density = THREE.MathUtils.lerp(0.021, 0.0145, vitality);
      this.scene.fog.color.lerpColors(
        QUIET_FOG_COLOR,
        VITAL_FOG_COLOR,
        vitality * 0.32,
      );
    }
  }

  snapshot() {
    return {
      atmosphereStatus: this.status,
      moonStatus: this.moonStatus,
      auroraStatus: this.auroraStatus,
      starCount: this.starCount,
      activeStarCount: this.activeStarCount,
      fireflyCount: this.fireflyCount,
      activeFireflies: this.activeFireflies,
      fogDensity: this.scene?.fog?.density || 0,
      atmosphereDrawCalls: 11,
      atmosphereRangeUpdateCount: this.atmosphereRangeUpdateCount,
    };
  }
}
