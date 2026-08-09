import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const PETAL_ASSET_BASE = 'assets/sanctuary_v3/tree/';
const ANIMATED_FALLING_PETAL_ASSET = `${PETAL_ASSET_BASE}falling_leaves_animated_quest.glb`;
const ANIMATED_PETAL_TARGET_HEIGHT = 5.7;
const ANIMATED_PETAL_GEOMETRY_SCALE = 0.18;
const ANIMATED_PETAL_DEPTH_OFFSET = -2.0;
const USE_AUTHORED_NON_SAKURA_LEAF_ANIMATION = false;

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

function deterministicRandom(index, salt = 0) {
  return Math.abs(Math.sin(index * 91.731 + salt * 17.137) * 43758.5453) % 1;
}

export function coherenceToFallingIntensity(coherence, visualState) {
  const fallbackCoherence = visualState?.vitality ?? 1;
  const normalisedCoherence = Number.isFinite(coherence)
    ? coherence > 1 ? coherence / 100 : coherence
    : fallbackCoherence;
  const clampedCoherence = THREE.MathUtils.clamp(normalisedCoherence, 0, 1);
  if (clampedCoherence >= 0.995) return 0;
  return Math.pow(1 - clampedCoherence, 1.18);
}

function makeFallingPetalGeometry() {
  const geometry = new THREE.BufferGeometry();
  geometry.name = 'SanctuaryV3_Sakura_Petal_Geometry';
  geometry.setAttribute('position', new THREE.Float32BufferAttribute([
    0, -0.052, 0,
    -0.025, -0.028, 0.006,
    -0.047, 0.008, 0.01,
    -0.03, 0.047, 0.006,
    0, 0.033, 0.014,
    0.03, 0.047, 0.006,
    0.047, 0.008, 0.01,
    0.025, -0.028, 0.006,
    0, 0, 0.018,
  ], 3));
  geometry.setIndex([
    0, 1, 8,
    1, 2, 8,
    2, 3, 8,
    3, 4, 8,
    4, 5, 8,
    5, 6, 8,
    6, 7, 8,
    7, 0, 8,
  ]);
  geometry.computeVertexNormals();
  geometry.computeBoundingSphere();
  return geometry;
}

function prepareGroundPetalGeometry(scene) {
  scene.updateMatrixWorld(true);
  const geometries = [];
  let sourceMaterial = null;
  scene.traverse((object) => {
    if (!object.isMesh || !object.geometry?.attributes?.position) return;
    const geometry = object.geometry.clone();
    geometry.applyMatrix4(object.matrixWorld);
    for (const attribute of Object.keys(geometry.attributes)) {
      if (!['position', 'normal', 'uv'].includes(attribute)) {
        geometry.deleteAttribute(attribute);
      }
    }
    if (!geometry.attributes.normal) geometry.computeVertexNormals();
    geometries.push(geometry);
    sourceMaterial ||= Array.isArray(object.material) ? object.material[0] : object.material;
  });
  if (!geometries.length) throw new Error('Ground petal GLB contains no mesh geometry');

  const merged = geometries.length === 1 ? geometries[0] : mergeGeometries(geometries, false);
  if (!merged) throw new Error('Ground petal geometry could not be merged');
  merged.computeBoundingBox();
  const box = merged.boundingBox;
  const center = box.getCenter(new THREE.Vector3());
  const size = box.getSize(new THREE.Vector3());
  const scale = 0.58 / Math.max(size.x, size.y, size.z, 0.001);
  merged.translate(-center.x, -box.min.y, -center.z);
  merged.scale(scale, scale, scale);
  merged.computeBoundingSphere();
  return { geometry: merged, sourceMaterial };
}

function prepareAnimatedPetalMaterial(source, materialCache) {
  if (materialCache.has(source)) return materialCache.get(source);
  const material = source.clone();
  material.map = null;
  if (material.color) material.color.set(0xff83ad);
  if (material.emissive) {
    material.emissive.set(0x5b1433);
    material.emissiveIntensity = 0.34;
  }
  material.vertexColors = false;
  material.side = THREE.DoubleSide;
  material.transparent = true;
  material.opacity = 0.48;
  material.alphaTest = Math.max(material.alphaTest || 0, 0.06);
  material.depthWrite = false;
  material.roughness = Math.max(material.roughness ?? 0.75, 0.72);
  material.metalness = 0;
  material.needsUpdate = true;
  materialCache.set(source, material);
  return material;
}

function shrinkAnimatedPetalGeometry(source, geometryCache) {
  if (geometryCache.has(source)) return geometryCache.get(source);
  const geometry = source.clone();
  geometry.computeBoundingBox();
  const center = geometry.boundingBox.getCenter(new THREE.Vector3());
  const position = geometry.attributes.position;
  for (let index = 0; index < position.count; index++) {
    position.setXYZ(
      index,
      center.x + (position.getX(index) - center.x) * ANIMATED_PETAL_GEOMETRY_SCALE,
      center.y + (position.getY(index) - center.y) * ANIMATED_PETAL_GEOMETRY_SCALE,
      center.z + (position.getZ(index) - center.z) * ANIMATED_PETAL_GEOMETRY_SCALE,
    );
  }
  position.needsUpdate = true;
  geometry.computeBoundingBox();
  geometry.computeBoundingSphere();
  geometryCache.set(source, geometry);
  return geometry;
}

function prepareAnimatedPetalScene(scene, treePosition, layer) {
  scene.updateMatrixWorld(true);
  const initialBounds = new THREE.Box3().setFromObject(scene);
  const initialSize = initialBounds.getSize(new THREE.Vector3());
  if (initialBounds.isEmpty() || initialSize.y < 0.0001) {
    throw new Error('Animated falling-leaf GLB has invalid bounds');
  }

  const uniformScale = ANIMATED_PETAL_TARGET_HEIGHT / initialSize.y;
  scene.scale.multiplyScalar(uniformScale);
  scene.updateMatrixWorld(true);
  const bounds = new THREE.Box3().setFromObject(scene);
  const center = bounds.getCenter(new THREE.Vector3());
  scene.position.x += treePosition.x - center.x;
  scene.position.y += 0.12 - bounds.min.y;
  scene.position.z += treePosition.z - center.z + ANIMATED_PETAL_DEPTH_OFFSET;
  scene.updateMatrixWorld(true);

  const materialCache = new Map();
  const geometryCache = new Map();
  const materials = [];
  const meshes = [];
  scene.traverse((object) => {
    object.layers.set(layer);
    if (!object.isMesh) return;
    object.geometry = shrinkAnimatedPetalGeometry(object.geometry, geometryCache);
    object.material = Array.isArray(object.material)
      ? object.material.map((material) => prepareAnimatedPetalMaterial(material, materialCache))
      : prepareAnimatedPetalMaterial(object.material, materialCache);
    object.castShadow = false;
    object.receiveShadow = false;
    object.frustumCulled = false;
    meshes.push(object);
  });
  materials.push(...materialCache.values());
  if (!meshes.length) throw new Error('Animated falling-leaf GLB contains no meshes');
  return { materials, meshes };
}

                                                                              
export class SanctuaryPetalSystem {
  constructor({ quality = 'quest', treePosition, layer = 0 } = {}) {
    this.quality = quality;
    this.treePosition = treePosition.clone();
    this.layer = layer;
    this.status = 'idle';
    this.root = new THREE.Group();
    this.root.name = 'SanctuaryV3_Petals';
    this.root.layers.set(layer);
    this.fallingMesh = null;
    this.animatedFallingRoot = null;
    this.animatedFallingMixer = null;
    this.animatedFallingAction = null;
    this.animatedFallingMaterials = [];
    this.animatedFallingMeshes = [];
    this.animatedFallingOpacity = 0.48;
    this.animatedFallingClip = null;
    this.fallingRenderer = 'none';
    this.exactOriginMesh = null;
    this.exactOriginData = [];
    this.exactOriginQueue = [];
    this.maxExactOriginPetals = quality === 'high' ? 160 : 96;
    this.activeExactOriginPetals = 0;
    this.totalExactOriginPetals = 0;
    this.recentShedLoad = 0;
    this.eventDriven = false;
    this.groundMesh = null;
    this.fallingData = [];
    this.maxFallingPetals = quality === 'high' ? 320 : 210;
    this.groundPetalCount = quality === 'high' ? 82 : 58;
    this.activeFallingPetals = 0;
    this.sheddingRate = 0;
    this.fallingIntensity = 0;
    this.groundCoverage = 0.38;
    this.terrainSampler = null;
    this.updateDummy = new THREE.Object3D();
    this.petalBufferUpdateCount = 0;
  }

  async load({ parent, terrainSampler }) {
    this.status = 'loading';
    this.terrainSampler = terrainSampler || null;
    parent.add(this.root);
    try {
      const loader = new GLTFLoader();
      loader.setMeshoptDecoder(MeshoptDecoder);
      const animatedPetalRequest = USE_AUTHORED_NON_SAKURA_LEAF_ANIMATION
        && this.quality === 'high'
        ? loadGltf(loader, ANIMATED_FALLING_PETAL_ASSET)
        : Promise.resolve(null);
      const [animatedResult, groundResult] = await Promise.allSettled([
        animatedPetalRequest,
        loadGltf(loader, `${PETAL_ASSET_BASE}sakura_ground_petals.glb`),
      ]);
      if (groundResult.status === 'rejected') throw groundResult.reason;

      this.createExactOriginPetals();

      if (animatedResult.status === 'fulfilled' && animatedResult.value) {
        try {
          this.createAnimatedFallingPetals(animatedResult.value);
        } catch (error) {
          console.warn('Animated falling leaves could not be prepared; using fallback petals.', error);
        }
      } else if (animatedResult.status === 'rejected') {
        console.warn('Animated falling leaves could not be loaded; using fallback petals.', animatedResult.reason);
      }
      if (!this.animatedFallingRoot) {
        this.createFallingPetals();
      }
      this.createGroundPetals(groundResult.value.scene, terrainSampler);
      this.status = 'ready';
      return this.snapshot();
    } catch (error) {
      this.status = 'fallback';
      throw error;
    }
  }

  createAnimatedFallingPetals(gltf) {
    const clip = gltf.animations?.find((candidate) => candidate.name === 'idle')
      || gltf.animations?.[0];
    if (!clip) throw new Error('Animated falling-leaf GLB contains no animation clip');

    const scene = gltf.scene;
    scene.name = 'SanctuaryV3_Authored_Animated_Falling_Leaves';
    const prepared = prepareAnimatedPetalScene(scene, this.treePosition, this.layer);
    this.root.add(scene);
    this.animatedFallingRoot = scene;
    this.animatedFallingMaterials = prepared.materials;
    this.animatedFallingMeshes = prepared.meshes;
    this.animatedFallingMixer = new THREE.AnimationMixer(scene);
    this.animatedFallingAction = this.animatedFallingMixer.clipAction(clip);
    this.animatedFallingAction.setLoop(THREE.LoopRepeat, Infinity);
    this.animatedFallingAction.play();
    this.animatedFallingAction.paused = true;
    scene.visible = false;
    for (const mesh of prepared.meshes) mesh.visible = false;
    this.animatedFallingClip = clip.name || 'unnamed';
    this.activeFallingPetals = 0;
    this.fallingRenderer = 'animated-glb';
  }

  createFallingPetals() {
    const MaterialClass = this.quality === 'quest'
      ? THREE.MeshLambertMaterial
      : THREE.MeshStandardMaterial;
    const material = new MaterialClass({
      name: 'SanctuaryV3_Sakura_Petal_Material',
      color: 0xff9fbd,
      emissive: 0x4a1028,
      emissiveIntensity: 0.2,
      ...(this.quality === 'high' ? { roughness: 0.86, metalness: 0 } : {}),
      side: THREE.DoubleSide,
      transparent: false,
    });
    const mesh = new THREE.InstancedMesh(
      makeFallingPetalGeometry(),
      material,
      this.maxFallingPetals,
    );
    mesh.name = 'SanctuaryV3_Instanced_Falling_Petals';
    mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    mesh.count = 0;
    mesh.frustumCulled = false;
    mesh.layers.set(this.layer);
    this.root.add(mesh);
    this.fallingMesh = mesh;
    this.fallingRenderer = this.quality === 'quest'
      ? 'instanced-quest'
      : 'instanced-fallback';

    for (let index = 0; index < this.maxFallingPetals; index++) {
      const radius = 0.55 + deterministicRandom(index, 1) * 3.05;
      const angle = deterministicRandom(index, 2) * Math.PI * 2;
      this.fallingData.push({
        x: this.treePosition.x + Math.cos(angle) * radius,
        y: 1.3 + deterministicRandom(index, 3) * 4.8,
        z: this.treePosition.z + Math.sin(angle) * radius,
        speed: 0.075 + deterministicRandom(index, 4) * 0.115,
        drift: 0.18 + deterministicRandom(index, 5) * 0.3,
        phase: deterministicRandom(index, 6) * Math.PI * 2,
        spin: 0.25 + deterministicRandom(index, 7) * 0.75,
        scale: 0.72 + deterministicRandom(index, 8) * 0.75,
      });
    }
  }

  createExactOriginPetals() {
    const MaterialClass = this.quality === 'quest'
      ? THREE.MeshLambertMaterial
      : THREE.MeshStandardMaterial;
    const material = new MaterialClass({
      name: 'SanctuaryV3_Exact_Origin_Sakura_Petal_Material',
      color: 0xffb1c9,
      emissive: 0x5a1430,
      emissiveIntensity: 0.24,
      ...(this.quality === 'high' ? { roughness: 0.88, metalness: 0 } : {}),
      side: THREE.DoubleSide,
      transparent: false,
      vertexColors: true,
    });
    const mesh = new THREE.InstancedMesh(
      makeFallingPetalGeometry(),
      material,
      this.maxExactOriginPetals,
    );
    mesh.name = 'SanctuaryV3_Exact_Origin_Petals';
    mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    mesh.count = 0;
    mesh.frustumCulled = false;
    mesh.layers.set(this.layer);
    this.root.add(mesh);
    this.exactOriginMesh = mesh;
    this.exactOriginData = Array.from(
      { length: this.maxExactOriginPetals },
      () => ({ active: false }),
    );
  }

  enqueueShedEvents(events) {
    if (!Array.isArray(events) || !events.length) return;
    for (const event of events) {
      if (!Array.isArray(event?.position) || event.position.length !== 3) continue;
      this.exactOriginQueue.push(event);
      if (this.exactOriginQueue.length > this.maxExactOriginPetals) {
        this.exactOriginQueue.shift();
      }
    }
    this.recentShedLoad = Math.min(20, this.recentShedLoad + events.length);
  }

  createGroundPetals(scene, terrainSampler) {
    const { geometry, sourceMaterial } = prepareGroundPetalGeometry(scene);
    const material = new THREE.MeshStandardMaterial({
      map: sourceMaterial?.map || null,
      color: 0xffdce8,
      roughness: 0.94,
      metalness: 0,
      side: THREE.DoubleSide,
      alphaTest: 0.1,
      transparent: false,
    });
    if (material.map) material.map.colorSpace = THREE.SRGBColorSpace;
    const mesh = new THREE.InstancedMesh(geometry, material, this.groundPetalCount);
    mesh.name = 'SanctuaryV3_Instanced_Ground_Petal_Patches';
    mesh.layers.set(this.layer);

    const dummy = new THREE.Object3D();
    for (let index = 0; index < this.groundPetalCount; index++) {
      const radius = 0.78 + Math.sqrt(deterministicRandom(index, 11)) * 3.85;
      const angle = deterministicRandom(index, 12) * Math.PI * 2;
      const x = this.treePosition.x + Math.cos(angle) * radius;
      const z = this.treePosition.z + Math.sin(angle) * radius * 0.82;
      const surface = terrainSampler?.sample(x, z);
      dummy.position.set(x, (Number.isFinite(surface) ? surface : 0) + 0.018, z);
      dummy.rotation.set(0, deterministicRandom(index, 13) * Math.PI * 2, 0);
      const scale = 0.62 + deterministicRandom(index, 14) * 0.85;
      dummy.scale.set(scale, scale, scale);
      dummy.updateMatrix();
      mesh.setMatrixAt(index, dummy.matrix);
    }
    mesh.instanceMatrix.needsUpdate = true;
    mesh.count = Math.round(this.groundPetalCount * this.groundCoverage);
    this.root.add(mesh);
    this.groundMesh = mesh;
  }

  update({
    visualState,
    coherence,
    comfortOptions,
    elapsedTime = 0,
    deltaTime = 1 / 72,
    performanceScale = 1,
    eventDriven = false,
  } = {}) {
    const reducedMotion = comfortOptions?.reducedMotion === true;
    const reducedParticles = comfortOptions?.reducedParticles === true;
    this.eventDriven = eventDriven;
    this.sheddingRate = visualState?.sheddingRate ?? 0.02;
    const normalisedCoherence = Number.isFinite(coherence)
      ? coherence > 1 ? coherence / 100 : coherence
      : visualState?.vitality ?? 1;
    const maximumCoherence = normalisedCoherence >= 0.995
      || visualState?.fullBloom === true;
    this.recentShedLoad = Math.max(0, this.recentShedLoad - deltaTime * 3.5);
    if (maximumCoherence) {
      this.recentShedLoad = 0;
      if (this.exactOriginQueue.length || this.activeExactOriginPetals > 0) {
        this.clearExactOriginPetals();
      }
    }
    const eventBurst = THREE.MathUtils.smoothstep(this.recentShedLoad, 3, 12);
    const clinicalDecline = THREE.MathUtils.clamp(
      ((visualState?.shedImpulse ?? 0) - 0.18) / 0.65,
      0,
      1,
    );
    this.fallingIntensity = eventDriven
      ? maximumCoherence ? 0 : Math.max(eventBurst, clinicalDecline)
      : coherenceToFallingIntensity(coherence, visualState);

    this.updateExactOriginFalling({
      reducedMotion,
      reducedParticles,
      elapsedTime,
      deltaTime,
      performanceScale,
      maximumCoherence,
    });
    if (this.animatedFallingRoot) {
      this.updateAnimatedFalling({
        reducedMotion,
        reducedParticles,
        deltaTime,
        performanceScale,
        fallingIntensity: this.fallingIntensity,
      });
    } else if (this.fallingMesh) {
      this.updateFallbackFalling({
        reducedMotion,
        reducedParticles,
        elapsedTime,
        deltaTime,
        performanceScale,
        fallingIntensity: this.fallingIntensity,
      });
    }

    if (this.groundMesh) {
      const coverageTarget = THREE.MathUtils.clamp(
        0.32 + (1 - (visualState?.blossomHealth ?? 0.7)) * 0.46 + this.sheddingRate * 0.32,
        0.3,
        1,
      );
      this.groundCoverage = THREE.MathUtils.lerp(
        this.groundCoverage,
        coverageTarget,
        1 - Math.exp(-0.055 * deltaTime),
      );
      const groundCount = Math.max(
        12,
        Math.round(this.groundPetalCount * this.groundCoverage),
      );
      if (groundCount !== this.groundMesh.count) this.groundMesh.count = groundCount;
    }
  }

  spawnExactOriginPetal(event, sequence) {
    let slot = this.exactOriginData.find((candidate) => !candidate.active);
    if (!slot) {
      slot = this.exactOriginData.reduce((oldest, candidate) => (
        candidate.age > oldest.age ? candidate : oldest
      ));
    }
    const seed = Number.isFinite(event.seed) ? event.seed : sequence;
    slot.active = true;
    slot.age = 0;
    slot.lifetime = 5.2 + deterministicRandom(sequence, seed + 91) * 2.8;
    slot.position = new THREE.Vector3(...event.position);
    slot.velocity = new THREE.Vector3(
      (deterministicRandom(sequence, seed + 92) - 0.5) * 0.17,
      -(0.16 + deterministicRandom(sequence, seed + 93) * 0.13),
      (deterministicRandom(sequence, seed + 94) - 0.5) * 0.12,
    );
    slot.phase = deterministicRandom(sequence, seed + 95) * Math.PI * 2;
    slot.spin = 0.65 + deterministicRandom(sequence, seed + 96) * 1.15;
    slot.scale = 0.45 + deterministicRandom(sequence, seed + 97) * 0.38;
    slot.colour = new THREE.Color([
      0xff8fb1,
      0xffa7c3,
      0xffbfd3,
      0xffd4e1,
    ][Math.floor(deterministicRandom(sequence, seed + 98) * 4)]);
    this.totalExactOriginPetals++;
  }

  clearExactOriginPetals() {
    this.exactOriginQueue.length = 0;
    for (const petal of this.exactOriginData) petal.active = false;
    this.activeExactOriginPetals = 0;
    if (this.exactOriginMesh?.count) this.exactOriginMesh.count = 0;
  }

  updateExactOriginFalling({
    reducedMotion,
    reducedParticles,
    elapsedTime,
    deltaTime,
    performanceScale,
    maximumCoherence,
  }) {
    if (!this.exactOriginMesh || maximumCoherence) return;
    if (this.exactOriginQueue.length === 0 && this.activeExactOriginPetals === 0) return;
    const performanceLimit = Math.max(
      12,
      Math.floor(this.maxExactOriginPetals * THREE.MathUtils.clamp(performanceScale, 0.2, 1)),
    );
    const activeLimit = reducedParticles ? Math.min(24, performanceLimit) : performanceLimit;
    let activeBeforeSpawn = 0;
    for (const petal of this.exactOriginData) {
      if (petal.active) activeBeforeSpawn++;
    }
    while (this.exactOriginQueue.length && activeBeforeSpawn < activeLimit) {
      this.spawnExactOriginPetal(this.exactOriginQueue.shift(), this.totalExactOriginPetals + 1);
      activeBeforeSpawn++;
    }
    if (reducedParticles && this.exactOriginQueue.length > 12) {
      this.exactOriginQueue.splice(0, this.exactOriginQueue.length - 12);
    }
    if (activeBeforeSpawn === 0) {
      this.activeExactOriginPetals = 0;
      if (this.exactOriginMesh.count) this.exactOriginMesh.count = 0;
      return;
    }

    const dummy = this.updateDummy;
    const motionScale = reducedMotion ? 0.38 : 1;
    let drawIndex = 0;
    for (const petal of this.exactOriginData) {
      if (!petal.active) continue;
      petal.age += deltaTime;
      petal.velocity.y -= 0.012 * deltaTime * motionScale;
      petal.position.addScaledVector(petal.velocity, deltaTime * motionScale);
      petal.position.x += Math.sin(elapsedTime * 0.72 + petal.phase)
        * 0.045 * deltaTime * motionScale;
      petal.position.z += Math.cos(elapsedTime * 0.51 + petal.phase)
        * 0.03 * deltaTime * motionScale;
      const sampledSurface = this.terrainSampler?.sample(petal.position.x, petal.position.z);
      const surface = (Number.isFinite(sampledSurface) ? sampledSurface : 0) + 0.015;
      if (petal.position.y <= surface || petal.age >= petal.lifetime) {
        petal.active = false;
        continue;
      }
      if (drawIndex >= activeLimit) continue;
      dummy.position.copy(petal.position);
      dummy.rotation.set(
        petal.phase + petal.age * petal.spin,
        petal.age * petal.spin * 0.63,
        Math.sin(petal.phase + petal.age * 1.2) * 0.9,
      );
      dummy.scale.setScalar(petal.scale);
      dummy.updateMatrix();
      this.exactOriginMesh.setMatrixAt(drawIndex, dummy.matrix);
      this.exactOriginMesh.setColorAt(drawIndex, petal.colour);
      drawIndex++;
    }
    this.activeExactOriginPetals = drawIndex;
    this.exactOriginMesh.count = drawIndex;
    this.exactOriginMesh.instanceMatrix.needsUpdate = true;
    this.petalBufferUpdateCount += 1;
    if (this.exactOriginMesh.instanceColor) {
      this.exactOriginMesh.instanceColor.needsUpdate = true;
    }
  }

  updateAnimatedFalling({
    reducedMotion,
    reducedParticles,
    deltaTime,
    performanceScale,
    fallingIntensity,
  }) {
    if (fallingIntensity <= 0) {
      this.animatedFallingRoot.visible = false;
      this.animatedFallingAction.paused = true;
      this.activeFallingPetals = 0;
      for (const mesh of this.animatedFallingMeshes) mesh.visible = false;
      return;
    }

    this.animatedFallingRoot.visible = true;
    this.animatedFallingAction.paused = false;
    const performanceFactor = THREE.MathUtils.clamp(performanceScale, 0.45, 1);
    const targetOpacity = THREE.MathUtils.clamp(
      (reducedParticles ? 0.38 : 0.5) + fallingIntensity * 0.45,
      0.34,
      reducedParticles ? 0.62 : 0.95,
    );
    this.animatedFallingOpacity = THREE.MathUtils.lerp(
      this.animatedFallingOpacity,
      targetOpacity,
      1 - Math.exp(-1.15 * deltaTime),
    );
    const particleFactor = reducedParticles ? 0.46 : 1;
    const visibleCount = Math.max(
      1,
      Math.ceil(
        this.animatedFallingMeshes.length
          * fallingIntensity
          * performanceFactor
          * particleFactor,
      ),
    );
    for (let index = 0; index < this.animatedFallingMeshes.length; index++) {
      this.animatedFallingMeshes[index].visible = index < visibleCount;
    }
    for (const material of this.animatedFallingMaterials) {
      material.opacity = this.animatedFallingOpacity;
      if (material.emissive) {
        material.emissiveIntensity = 0.26 + fallingIntensity * 0.2;
      }
    }
    this.activeFallingPetals = visibleCount;
    const motionScale = reducedMotion ? 0.22 : 1;
    this.animatedFallingAction?.setEffectiveTimeScale(
      motionScale * (0.38 + fallingIntensity * 1.42),
    );
    this.animatedFallingMixer?.update(deltaTime);
  }

  updateFallbackFalling({
    reducedMotion,
    reducedParticles,
    elapsedTime,
    deltaTime,
    performanceScale,
    fallingIntensity,
  }) {
    const performanceLimit = Math.max(28, Math.floor(this.maxFallingPetals * performanceScale));
    const maxVisible = reducedParticles
      ? Math.min(54, performanceLimit)
      : performanceLimit;
    const previousActiveCount = this.activeFallingPetals;
    this.activeFallingPetals = Math.round(maxVisible * fallingIntensity);
    this.fallingMesh.count = this.activeFallingPetals;
    if (this.activeFallingPetals === 0) {
      if (previousActiveCount > 0) this.fallingMesh.instanceMatrix.needsUpdate = true;
      return;
    }

    const dummy = this.updateDummy;
    const motionScale = reducedMotion ? 0.28 : 1;
    for (let index = 0; index < this.activeFallingPetals; index++) {
      const petal = this.fallingData[index];
      petal.y -= petal.speed * motionScale * deltaTime;
      petal.x += Math.sin(elapsedTime * 0.31 + petal.phase) * petal.drift * deltaTime * motionScale;
      petal.z += Math.cos(elapsedTime * 0.24 + petal.phase) * petal.drift * 0.55 * deltaTime * motionScale;
      const sampledSurface = this.terrainSampler?.sample(petal.x, petal.z);
      const surface = (Number.isFinite(sampledSurface) ? sampledSurface : 0) + 0.012;
      if (petal.y < surface) {
        petal.y = 4.15 + deterministicRandom(index, Math.floor(elapsedTime) + 21) * 1.9;
        const radius = 0.55 + deterministicRandom(index, Math.floor(elapsedTime) + 22) * 2.85;
        const angle = deterministicRandom(index, Math.floor(elapsedTime) + 23) * Math.PI * 2;
        petal.x = this.treePosition.x + Math.cos(angle) * radius;
        petal.z = this.treePosition.z + Math.sin(angle) * radius;
      }
      dummy.position.set(petal.x, petal.y, petal.z);
      dummy.rotation.set(
        elapsedTime * petal.spin + petal.phase,
        elapsedTime * petal.spin * 0.63,
        Math.sin(elapsedTime * 0.47 + petal.phase) * 0.8,
      );
      dummy.scale.setScalar(petal.scale);
      dummy.updateMatrix();
      this.fallingMesh.setMatrixAt(index, dummy.matrix);
    }
    this.fallingMesh.instanceMatrix.needsUpdate = true;
    this.petalBufferUpdateCount += 1;
  }

  snapshot() {
    return {
      petalStatus: this.status,
      fallingRenderer: this.fallingRenderer,
      exactOriginRenderer: this.exactOriginMesh ? 'instanced' : 'none',
      fallingAnimationClip: this.animatedFallingClip,
      authoredFallingAnimationEnabled: Boolean(this.animatedFallingRoot),
      fallingPetalGeometry: 'curved-notched-sakura-petal',
      fallingIntensity: this.fallingIntensity,
      fallingPetalCount: this.activeFallingPetals + this.activeExactOriginPetals,
      authoredFallingPetalCount: this.activeFallingPetals,
      exactOriginPetalCount: this.activeExactOriginPetals,
      queuedShedEventCount: this.exactOriginQueue.length,
      totalExactOriginPetals: this.totalExactOriginPetals,
      maxExactOriginPetals: this.maxExactOriginPetals,
      eventDrivenShedding: this.eventDriven,
      groundPetalCount: this.groundMesh?.count || 0,
      maxFallingPetals: this.maxFallingPetals,
      maxGroundPetals: this.groundPetalCount,
      sheddingRate: this.sheddingRate,
      petalBufferUpdateCount: this.petalBufferUpdateCount,
    };
  }
}
