import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';

const ENVIRONMENT_ASSET_BASE = 'assets/sanctuary_v3/environment/';
const LANDSCAPE_CENTER_Z = -5.3;
const LANDSCAPE_DIAMETER = 92;
const LANDSCAPE_RELIEF_SCALE = 0.68;
const WORLD_UP = new THREE.Vector3(0, 1, 0);
const GOLDEN_ANGLE = Math.PI * (3 - Math.sqrt(5));
const RADIAL_LOW_DISCREPANCY = 0.7548776662466927;

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

function seededRandom(seed) {
  const value = Math.sin(seed * 12.9898 + 78.233) * 43758.5453;
  return value - Math.floor(value);
}

function fitLandscapeToScene(landscape) {
  landscape.rotation.y += Math.PI;
  landscape.updateMatrixWorld(true);
  const initialBox = new THREE.Box3().setFromObject(landscape);
  const initialSize = initialBox.getSize(new THREE.Vector3());
  const horizontalSpan = Math.max(initialSize.x, initialSize.z, 0.001);
  landscape.scale.multiplyScalar(LANDSCAPE_DIAMETER / horizontalSpan);
  landscape.scale.y *= LANDSCAPE_RELIEF_SCALE;
  landscape.updateMatrixWorld(true);

  const fittedBox = new THREE.Box3().setFromObject(landscape);
  const center = fittedBox.getCenter(new THREE.Vector3());
  landscape.position.x -= center.x;
  landscape.position.z += LANDSCAPE_CENTER_Z - center.z;
  landscape.position.y += -0.42 - fittedBox.min.y;
  landscape.updateMatrixWorld(true);
}

class TerrainHeightSampler {
  constructor(landscape, resolution = 176) {
    this.resolution = resolution;
    this.bounds = new THREE.Box3().setFromObject(landscape);
    this.heights = new Float32Array(resolution * resolution);
    this.heights.fill(Number.NaN);
    this.normals = new Float32Array(resolution * resolution * 3);
    this.normals.fill(Number.NaN);
    this.minX = this.bounds.min.x;
    this.maxX = this.bounds.max.x;
    this.minZ = this.bounds.min.z;
    this.maxZ = this.bounds.max.z;
    this.width = Math.max(this.maxX - this.minX, 0.001);
    this.depth = Math.max(this.maxZ - this.minZ, 0.001);
    this.populate(landscape);
  }

  index(x, z) {
    return z * this.resolution + x;
  }

  populate(landscape) {
    const point = new THREE.Vector3();
    landscape.updateMatrixWorld(true);
    landscape.traverse((object) => {
      if (!object.isMesh || !object.geometry?.attributes?.position) return;
      const position = object.geometry.attributes.position;
      for (let index = 0; index < position.count; index++) {
        point.fromBufferAttribute(position, index).applyMatrix4(object.matrixWorld);
        const gx = THREE.MathUtils.clamp(
          Math.round(((point.x - this.minX) / this.width) * (this.resolution - 1)),
          0,
          this.resolution - 1,
        );
        const gz = THREE.MathUtils.clamp(
          Math.round(((point.z - this.minZ) / this.depth) * (this.resolution - 1)),
          0,
          this.resolution - 1,
        );
        const cell = this.index(gx, gz);
        if (!Number.isFinite(this.heights[cell]) || point.y > this.heights[cell]) {
          this.heights[cell] = point.y;
        }
      }
    });
  }

  nearestHeight(gx, gz) {
    for (let radius = 0; radius <= 8; radius++) {
      let sum = 0;
      let count = 0;
      const minX = Math.max(0, gx - radius);
      const maxX = Math.min(this.resolution - 1, gx + radius);
      const minZ = Math.max(0, gz - radius);
      const maxZ = Math.min(this.resolution - 1, gz + radius);
      for (let z = minZ; z <= maxZ; z++) {
        for (let x = minX; x <= maxX; x++) {
          if (radius > 0 && x > minX && x < maxX && z > minZ && z < maxZ) continue;
          const value = this.heights[this.index(x, z)];
          if (Number.isFinite(value)) {
            sum += value;
            count += 1;
          }
        }
      }
      if (count > 0) return sum / count;
    }
    return null;
  }

  sample(x, z) {
    if (x < this.minX || x > this.maxX || z < this.minZ || z > this.maxZ) return null;
    const gx = THREE.MathUtils.clamp(
      Math.round(((x - this.minX) / this.width) * (this.resolution - 1)),
      0,
      this.resolution - 1,
    );
    const gz = THREE.MathUtils.clamp(
      Math.round(((z - this.minZ) / this.depth) * (this.resolution - 1)),
      0,
      this.resolution - 1,
    );
    const value = this.heights[this.index(gx, gz)];
    return Number.isFinite(value) ? value : this.nearestHeight(gx, gz);
  }

  normal(x, z, target = new THREE.Vector3()) {
    const gx = THREE.MathUtils.clamp(
      Math.round(((x - this.minX) / this.width) * (this.resolution - 1)),
      0,
      this.resolution - 1,
    );
    const gz = THREE.MathUtils.clamp(
      Math.round(((z - this.minZ) / this.depth) * (this.resolution - 1)),
      0,
      this.resolution - 1,
    );
    const normalIndex = this.index(gx, gz) * 3;
    if (Number.isFinite(this.normals[normalIndex])) {
      return target.set(
        this.normals[normalIndex],
        this.normals[normalIndex + 1],
        this.normals[normalIndex + 2],
      );
    }
    const center = this.sample(x, z);
    if (!Number.isFinite(center)) return target.copy(WORLD_UP);
    const spacing = Math.max(this.width, this.depth) / (this.resolution - 1);
    const left = this.sample(x - spacing, z) ?? center;
    const right = this.sample(x + spacing, z) ?? center;
    const back = this.sample(x, z - spacing) ?? center;
    const front = this.sample(x, z + spacing) ?? center;
    target.set(left - right, spacing * 2, back - front).normalize();
    this.normals[normalIndex] = target.x;
    this.normals[normalIndex + 1] = target.y;
    this.normals[normalIndex + 2] = target.z;
    return target;
  }
}

function createGrassClumpGeometry({ blades: bladeCount, segments, seed }) {
  const positions = [];
  const uvs = [];
  const flex = [];
  const indices = [];

  for (let blade = 0; blade < bladeCount; blade++) {
    const bladeSeed = seed * 97 + blade * 31;
    const angle = seededRandom(bladeSeed) * Math.PI * 2;
    const radius = seededRandom(bladeSeed + 3) * 0.13;
    const originX = Math.cos(angle) * radius;
    const originZ = Math.sin(angle) * radius;
    const height = 0.24 + seededRandom(bladeSeed + 7) * 0.22;
    const width = 0.009 + seededRandom(bladeSeed + 11) * 0.012;
    const leanAngle = angle + (seededRandom(bladeSeed + 13) - 0.5) * 1.8;
    const lean = 0.05 + seededRandom(bladeSeed + 17) * 0.1;
    const rightX = Math.cos(angle + Math.PI / 2);
    const rightZ = Math.sin(angle + Math.PI / 2);
    const baseVertex = positions.length / 3;

    for (let segment = 0; segment <= segments; segment++) {
      const t = segment / segments;
      const bend = lean * t * t;
      const centerX = originX + Math.cos(leanAngle) * bend;
      const centerZ = originZ + Math.sin(leanAngle) * bend;
      const halfWidth = width * (1 - t * 0.86);
      positions.push(
        centerX - rightX * halfWidth,
        height * t,
        centerZ - rightZ * halfWidth,
        centerX + rightX * halfWidth,
        height * t,
        centerZ + rightZ * halfWidth,
      );
      uvs.push(0, t, 1, t);
      flex.push(t, t);
    }

    for (let segment = 0; segment < segments; segment++) {
      const row = baseVertex + segment * 2;
      indices.push(row, row + 1, row + 2, row + 1, row + 3, row + 2);
    }
  }

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geometry.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
  geometry.setAttribute('grassFlex', new THREE.Float32BufferAttribute(flex, 1));
  geometry.setIndex(indices);
  geometry.computeVertexNormals();
  geometry.computeBoundingBox();
  geometry.computeBoundingSphere();
  return geometry;
}

function prepareAuthoredGrassGeometry(sourceGeometry) {
  const geometry = sourceGeometry.clone();
  geometry.computeBoundingBox();
  const bounds = geometry.boundingBox;
  const center = bounds.getCenter(new THREE.Vector3());
  geometry.translate(-center.x, -bounds.min.y, -center.z);
  geometry.computeBoundingBox();
  const height = Math.max(geometry.boundingBox.max.y, 0.001);
  const position = geometry.attributes.position;
  const flex = new Float32Array(position.count);
  for (let index = 0; index < position.count; index++) {
    flex[index] = THREE.MathUtils.clamp(position.getY(index) / height, 0, 1);
  }
  geometry.setAttribute('grassFlex', new THREE.BufferAttribute(flex, 1));
  geometry.computeBoundingSphere();
  return geometry;
}

function createGrassMaterial(uniforms, quality) {
  const parameters = {
    color: 0x7fa965,
    side: THREE.DoubleSide,
    vertexColors: true,
  };
  const material = quality === 'quest'
    ? new THREE.MeshLambertMaterial(parameters)
    : new THREE.MeshStandardMaterial({
        ...parameters,
        roughness: 0.96,
        metalness: 0,
      });
  material.name = quality === 'quest'
    ? 'SanctuaryV3_Grass_Lambert_Quest'
    : 'SanctuaryV3_Grass_PBR_High';
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uGrassTime = uniforms.time;
    shader.uniforms.uGrassWind = uniforms.wind;
    shader.vertexShader = shader.vertexShader
      .replace(
        '#include <common>',
        `#include <common>
        attribute float grassFlex;
        uniform float uGrassTime;
        uniform float uGrassWind;
        varying float vGrassFlex;
        varying float vGrassSeed;`,
      )
      .replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
        vec3 sanctuaryGrassOrigin = vec3(0.0);
        #ifdef USE_INSTANCING
          sanctuaryGrassOrigin = vec3(
            instanceMatrix[3].x,
            instanceMatrix[3].y,
            instanceMatrix[3].z
          );
        #endif
        float sanctuarySeed = fract(sin(dot(
          sanctuaryGrassOrigin.xz,
          vec2(12.9898, 78.233)
        )) * 43758.5453);
        float sanctuaryWideWind = sin(
          uGrassTime * 0.72 + sanctuaryGrassOrigin.x * 0.16
          + sanctuaryGrassOrigin.z * 0.11 + sanctuarySeed * 4.2
        );
        float sanctuaryFineWind = sin(
          uGrassTime * (1.08 + sanctuarySeed * 0.38) + sanctuarySeed * 18.7
        );
        float sanctuaryBend = (sanctuaryWideWind * 0.052 + sanctuaryFineWind * 0.014)
          * grassFlex * grassFlex * uGrassWind;
        transformed.x += sanctuaryBend;
        transformed.z += sanctuaryBend * (0.36 + sanctuarySeed * 0.42);
        vGrassFlex = grassFlex;
        vGrassSeed = sanctuarySeed;`,
      );
    shader.fragmentShader = shader.fragmentShader
      .replace(
        '#include <common>',
        `#include <common>
        varying float vGrassFlex;
        varying float vGrassSeed;`,
      )
      .replace(
        '#include <color_fragment>',
        `#include <color_fragment>
        vec3 sanctuaryRoot = vec3(0.055, 0.16, 0.07);
        vec3 sanctuaryMid = vec3(0.18, 0.45, 0.14);
        vec3 sanctuaryTip = vec3(0.46, 0.67, 0.22);
        vec3 sanctuaryGradient = mix(
          sanctuaryRoot,
          sanctuaryMid,
          smoothstep(0.02, 0.64, vGrassFlex)
        );
        sanctuaryGradient = mix(
          sanctuaryGradient,
          sanctuaryTip,
          smoothstep(0.54, 1.0, vGrassFlex)
        );
        sanctuaryGradient *= 0.91 + vGrassSeed * 0.16;
        diffuseColor.rgb = mix(diffuseColor.rgb, sanctuaryGradient, 0.72);`,
      );
  };
  material.customProgramCacheKey = () => `sanctuary-v3-grass-breeze-v3-${quality}`;
  material.needsUpdate = true;
  return material;
}

function configureLandscapeMaterial(sourceMaterial, anisotropy) {
  const material = sourceMaterial.clone();
  material.name = 'SanctuaryV3_Landscape_PBR';
  material.color = new THREE.Color(0x8cab79);
  material.emissive = new THREE.Color(0x10261a);
  material.emissiveMap = null;
  material.emissiveIntensity = 0.08;
  material.metalness = 0;
  material.roughness = 0.96;
  material.side = THREE.FrontSide;
  material.transparent = false;
  material.depthWrite = true;
  for (const key of ['map', 'normalMap', 'roughnessMap', 'aoMap']) {
    if (material[key]) {
      material[key].anisotropy = anisotropy;
      material[key].needsUpdate = true;
    }
  }
  material.onBeforeCompile = (shader) => {
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <map_fragment>',
      `#include <map_fragment>
      float sanctuaryTerrainLight = dot(
        diffuseColor.rgb,
        vec3(0.2126, 0.7152, 0.0722)
      );
      vec3 sanctuaryTerrainDark = vec3(0.025, 0.105, 0.045);
      vec3 sanctuaryTerrainMid = vec3(0.105, 0.285, 0.095);
      vec3 sanctuaryTerrainLightColor = vec3(0.31, 0.47, 0.18);
      vec3 sanctuaryTerrainGreen = mix(
        sanctuaryTerrainDark,
        sanctuaryTerrainMid,
        smoothstep(0.04, 0.48, sanctuaryTerrainLight)
      );
      sanctuaryTerrainGreen = mix(
        sanctuaryTerrainGreen,
        sanctuaryTerrainLightColor,
        smoothstep(0.46, 0.92, sanctuaryTerrainLight)
      );
      diffuseColor.rgb = mix(diffuseColor.rgb, sanctuaryTerrainGreen, 0.94);`,
    );
  };
  material.customProgramCacheKey = () => 'sanctuary-v3-moss-terrain-v1';
  material.needsUpdate = true;
  return material;
}

export class SanctuaryLandscape {
  constructor({ quality = 'quest', treePosition = new THREE.Vector3(0, 0, -6.8), layer = 0 } = {}) {
    this.quality = quality;
    this.treePosition = treePosition.clone();
    this.layer = layer;
    this.landscape = null;
    this.heightSampler = null;
    this.grassGroup = new THREE.Group();
    this.grassGroup.name = 'SanctuaryV3_Grass_Field';
    this.grassGroup.layers.set(layer);
    this.source = null;
    this.activeLod = 'none';
    this.status = 'idle';
    this.grassStatus = 'idle';
    this.grassSource = null;
    this.grassInstances = 0;
    this.activeGrassInstances = 0;
    this.grassTriangles = 0;
    this.activeGrassTriangles = 0;
    this.grassRangeUpdateCount = 0;
    this.grassAbundancePolicy = 'constant-full-density';
    this.grassShadingProfile = quality === 'quest' ? 'lambert-quest' : 'pbr-high';
    this.uniforms = {
      time: { value: 0 },
      wind: { value: 0.72 },
    };
  }

  async load({ parent, renderer }) {
    this.status = 'loading';
    const loader = new GLTFLoader();
    loader.setMeshoptDecoder(MeshoptDecoder);
    const candidates = this.quality === 'high'
      ? [
          ['high', `${ENVIRONMENT_ASSET_BASE}landscape_high.glb`],
          ['lod0', `${ENVIRONMENT_ASSET_BASE}landscape_quest_lod0.glb`],
          ['lod1', `${ENVIRONMENT_ASSET_BASE}landscape_quest_lod1.glb`],
        ]
      : [
          ['lod0', `${ENVIRONMENT_ASSET_BASE}landscape_quest_lod0.glb`],
          ['lod1', `${ENVIRONMENT_ASSET_BASE}landscape_quest_lod1.glb`],
          ['high', `${ENVIRONMENT_ASSET_BASE}landscape_high.glb`],
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
    if (!loaded) throw lastError || new Error('No Sanctuary V3 landscape source loaded');

    const landscape = loaded.gltf.scene;
    landscape.name = 'SanctuaryV3_Landscape';
    const anisotropy = Math.min(8, renderer.capabilities.getMaxAnisotropy());
    landscape.traverse((object) => {
      if (!object.isMesh) return;
      object.material = configureLandscapeMaterial(object.material, anisotropy);
      object.castShadow = false;
      object.receiveShadow = false;
      object.layers.set(this.layer);
    });

    parent.add(landscape);
    fitLandscapeToScene(landscape);
    let sampler = new TerrainHeightSampler(
      landscape,
      this.quality === 'high' ? 224 : 176,
    );
    const treeGround = sampler.sample(this.treePosition.x, this.treePosition.z);
    if (Number.isFinite(treeGround)) {
      landscape.position.y -= treeGround;
      landscape.updateMatrixWorld(true);
      sampler = new TerrainHeightSampler(
        landscape,
        this.quality === 'high' ? 224 : 176,
      );
    }

    this.landscape = landscape;
    this.heightSampler = sampler;
    this.source = loaded.path;
    this.activeLod = loaded.lod;
    this.status = 'ready';

    try {
      await this.buildGrass(parent);
      this.grassStatus = 'ready';
    } catch (error) {
      this.grassStatus = 'fallback';
      console.warn('Sanctuary V3 grass generation failed; landscape remains active.', error);
    }
    return this.snapshot();
  }

  async buildGrass(parent) {
    this.grassStatus = 'loading';
    const material = createGrassMaterial(this.uniforms, this.quality);
    const loader = new GLTFLoader();
    loader.setMeshoptDecoder(MeshoptDecoder);
    try {
      const authored = await loadGltf(
        loader,
        `${ENVIRONMENT_ASSET_BASE}animated_grass_variants.glb`,
      );
      const geometries = [];
      authored.scene.traverse((object) => {
        if (object.isMesh && object.geometry?.attributes?.position) {
          geometries.push(prepareAuthoredGrassGeometry(object.geometry));
        }
      });
      if (geometries.length < 3) throw new Error('Authored grass requires three variants');
      geometries.sort((left, right) => (
        left.boundingBox.max.y - right.boundingBox.max.y
      ));
      this.buildAuthoredGrass(parent, material, geometries);
      this.grassSource = `${ENVIRONMENT_ASSET_BASE}animated_grass_variants.glb`;
    } catch (error) {
      console.warn('Authored grass variants failed; using thin procedural fallback.', error);
      this.buildProceduralGrass(parent, material);
      this.grassSource = 'procedural-thin-fallback';
    }
  }

  buildAuthoredGrass(parent, material, geometries) {
    const zones = this.quality === 'high'
      ? [
          { name: 'near', count: 52000, inner: 0, outer: 16, seed: 11, variant: 2, width: 1.68 },
          { name: 'mid', count: 68000, inner: 12, outer: 31, seed: 37, variant: 1, width: 2.16 },
          { name: 'far', count: 90000, inner: 27, outer: 46, seed: 71, variant: 0, width: 2.78 },
        ]
      : [
          { name: 'near', count: 28000, inner: 0, outer: 16, seed: 11, variant: 2, width: 2.06 },
          { name: 'mid', count: 32000, inner: 12, outer: 31, seed: 37, variant: 1, width: 2.72 },
          { name: 'far', count: 36000, inner: 27, outer: 46, seed: 71, variant: 0, width: 3.48 },
        ];

    for (const zone of zones) {
      this.addGrassZone(zone, geometries[zone.variant], material, true);
    }
    parent.add(this.grassGroup);
  }

  buildProceduralGrass(parent, material) {
    const zones = this.quality === 'high'
      ? [
          { name: 'near', count: 9000, inner: 0, outer: 16, blades: 4, segments: 2, seed: 11 },
          { name: 'mid', count: 16000, inner: 12, outer: 31, blades: 3, segments: 1, seed: 37 },
          { name: 'far', count: 23000, inner: 27, outer: 46, blades: 2, segments: 1, seed: 71 },
        ]
      : [
          { name: 'near', count: 7000, inner: 0, outer: 16, blades: 4, segments: 2, seed: 11 },
          { name: 'mid', count: 12000, inner: 12, outer: 31, blades: 3, segments: 1, seed: 37 },
          { name: 'far', count: 17000, inner: 27, outer: 46, blades: 2, segments: 1, seed: 71 },
        ];
    for (const zone of zones) {
      this.addGrassZone(zone, createGrassClumpGeometry(zone), material, false);
    }
    parent.add(this.grassGroup);
  }

  addGrassZone(zone, geometry, material, authored) {
    const dummy = new THREE.Object3D();
    const slopeQuaternion = new THREE.Quaternion();
    const yawQuaternion = new THREE.Quaternion();
    const color = new THREE.Color();
    const normal = new THREE.Vector3();
    const mesh = new THREE.InstancedMesh(geometry, material, zone.count);
    mesh.name = `SanctuaryV3_Grass_${zone.name}`;
    mesh.instanceMatrix.setUsage(THREE.StaticDrawUsage);
    mesh.layers.set(this.layer);
    mesh.castShadow = false;
    mesh.receiveShadow = false;
    let placed = 0;
    let attempt = 0;
    while (placed < zone.count && attempt < zone.count * 5) {
      const seed = zone.seed * 100000 + attempt * 17;
      const latticeIndex = attempt % zone.count;
      const angle = attempt * GOLDEN_ANGLE + (seededRandom(seed) - 0.5) * 0.22;
      const areaProgress = (
        (latticeIndex + 0.5) * RADIAL_LOW_DISCREPANCY
      ) % 1;
      attempt += 1;
      const radiusSquared = THREE.MathUtils.lerp(
        zone.inner * zone.inner,
        zone.outer * zone.outer,
        areaProgress,
      );
      const radius = Math.sqrt(radiusSquared);
      const x = Math.cos(angle) * radius;
      const z = LANDSCAPE_CENTER_Z + Math.sin(angle) * radius;
      const y = this.heightSampler.sample(x, z);
      if (!Number.isFinite(y)) continue;
      this.heightSampler.normal(x, z, normal);
      if (normal.y < 0.62) continue;

      const treeDistance = Math.hypot(x - this.treePosition.x, z - this.treePosition.z);
      const userDistance = Math.hypot(x, z - 1.8);
      if (treeDistance < 0.62) continue;

      const heightScale = (authored ? 0.54 : 0.76)
        + seededRandom(seed + 7) * (authored ? 0.42 : 0.58);
      const proximityScale = (userDistance < 1.15 ? 0.52 : 1)
        * (treeDistance < 1.25 ? 0.66 : 1);
      const widthScale = authored
        ? (0.7 + seededRandom(seed + 11) * 0.5) * (zone.width || 1)
        : 0.76 + seededRandom(seed + 11) * 0.42;
      dummy.position.set(x, y + 0.008, z);
      slopeQuaternion.setFromUnitVectors(WORLD_UP, normal);
      yawQuaternion.setFromAxisAngle(normal, seededRandom(seed + 13) * Math.PI * 2);
      dummy.quaternion.copy(slopeQuaternion).multiply(yawQuaternion);
      dummy.scale.set(widthScale, heightScale * proximityScale, widthScale);
      dummy.updateMatrix();
      mesh.setMatrixAt(placed, dummy.matrix);
      color.setHSL(
        0.285 + seededRandom(seed + 19) * 0.045,
        0.46 + seededRandom(seed + 23) * 0.18,
        0.25 + seededRandom(seed + 29) * 0.11,
      );
      mesh.setColorAt(placed, color);
      placed += 1;
    }
    mesh.count = placed;
    mesh.userData.maxInstanceCount = placed;
    mesh.userData.grassZone = zone.name;
    mesh.userData.authoredSource = authored;
    mesh.userData.trianglesPerInstance = geometry.index
      ? geometry.index.count / 3
      : geometry.attributes.position.count / 3;
    mesh.instanceMatrix.needsUpdate = true;
    if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;
    mesh.computeBoundingBox();
    mesh.computeBoundingSphere();
    this.grassGroup.add(mesh);
    this.grassInstances += placed;
    this.activeGrassInstances += placed;
    this.grassTriangles += placed * mesh.userData.trianglesPerInstance;
    this.activeGrassTriangles += placed * mesh.userData.trianglesPerInstance;
  }

  update({
    elapsedTime,
    comfortOptions,
  } = {}) {
    this.uniforms.time.value = elapsedTime || 0;
    this.uniforms.wind.value = comfortOptions?.reducedMotion ? 0.16 : 0.72;
  }

  snapshot() {
    return {
      landscapeStatus: this.status,
      landscapeSource: this.source,
      activeLandscapeLod: this.activeLod,
      grassStatus: this.grassStatus,
      grassSource: this.grassSource,
      grassInstances: this.grassInstances,
      activeGrassInstances: this.activeGrassInstances,
      grassTriangles: Math.round(this.grassTriangles),
      activeGrassTriangles: Math.round(this.activeGrassTriangles),
      grassShadingProfile: this.grassShadingProfile,
      grassAbundancePolicy: this.grassAbundancePolicy,
      grassResonanceReactive: false,
      grassRangeUpdateCount: this.grassRangeUpdateCount,
    };
  }
}
