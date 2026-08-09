import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import {
  detailAssetAbundance,
  quantizePerformanceScale,
} from './sanctuary_performance.js?v=25';

const DETAIL_ASSET_BASE = 'assets/sanctuary_v3/details/';
const WORLD_UP = new THREE.Vector3(0, 1, 0);

const DETAIL_DEFINITIONS = Object.freeze([
  { name: 'rock1', kind: 'rock', count: 4, height: 0.48, radius: [2.4, 10.8], seed: 11 },
  { name: 'rock2', kind: 'rock', count: 4, height: 0.58, radius: [3.2, 12.5], seed: 23 },
  { name: 'rock3', kind: 'rock', count: 3, height: 0.7, radius: [4.5, 13.8], seed: 37 },
  { name: 'rock_pack', kind: 'rock', count: 3, height: 0.46, radius: [2.8, 11.6], seed: 43 },
  { name: 'lavender', kind: 'flower', count: 32, height: 0.42, radius: [3.8, 17.5], seed: 59 },
  { name: 'chamomile', kind: 'flower', count: 12, height: 0.38, radius: [4.2, 16.2], seed: 71 },
  { name: 'glowing_plants', kind: 'glow', count: 12, height: 0.48, radius: [4.8, 15.8], seed: 83, assetFile: 'glowing_plants_parts_quest.glb' },
  { name: 'bush1', kind: 'bush', count: 6, height: 0.82, radius: [8.8, 19.5], seed: 97 },
  { name: 'bush2', kind: 'bush', count: 8, height: 0.74, radius: [8.2, 19.8], seed: 109 },
  { name: 'bush3', kind: 'bush', count: 2, questCount: 1, height: 0.96, radius: [13.5, 20.5], seed: 127 },
  { name: 'bush4', kind: 'bush', count: 9, height: 0.7, radius: [8.5, 19.2], seed: 139 },
  { name: 'bush5', kind: 'bush', count: 8, height: 0.78, radius: [9.2, 20.2], seed: 151 },
]);

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

function tintFor(kind) {
  if (kind === 'rock') return new THREE.Color(0x9aa28d);
  if (kind === 'flower') return new THREE.Color(0xf6f1e4);
  if (kind === 'glowLeaf') return new THREE.Color(0x3f914c);
  if (kind === 'glowOrb') return new THREE.Color(0xb76cff);
  if (kind === 'glow') return new THREE.Color(0x4b9957);
  return new THREE.Color(0x9acb86);
}

function createDetailMaterial(source, kind, dynamicMaterials, quality) {
  const sourceColor = source?.color?.clone() || new THREE.Color(0xffffff);
  const tintStrength = kind === 'glowLeaf' || kind === 'glowOrb' ? 0.88 : kind === 'rock' ? 0.08 : 0.14;
  sourceColor.lerp(tintFor(kind), tintStrength);
  const isSplitGlowPart = kind === 'glowLeaf' || kind === 'glowOrb';
  const parameters = {
    map: isSplitGlowPart ? null : source?.map || null,
    normalMap: source?.normalMap || null,
    aoMap: source?.aoMap || null,
    alphaMap: source?.alphaMap || null,
    color: sourceColor,
    side: kind === 'rock' ? THREE.FrontSide : THREE.DoubleSide,
    alphaTest: kind === 'rock' ? 0 : 0.12,
    transparent: false,
    depthWrite: true,
  };
  const material = quality === 'quest'
    ? new THREE.MeshLambertMaterial(parameters)
    : new THREE.MeshStandardMaterial({
        ...parameters,
        roughnessMap: source?.roughnessMap || null,
        roughness: kind === 'rock' ? 0.94 : kind === 'glowOrb' ? 0.58 : 0.84,
        metalness: 0,
      });
  material.name = `SanctuaryV3_${kind}_${quality === 'quest' ? 'Lambert' : 'PBR'}`;
  for (const texture of [
    material.map,
    material.normalMap,
    quality === 'quest' ? null : material.roughnessMap,
    material.aoMap,
    material.alphaMap,
  ]) {
    if (texture) texture.anisotropy = 4;
  }
  if (kind !== 'rock') {
    if (kind === 'glowOrb') material.emissive.set(0x9b42e6);
    else if (kind === 'glowLeaf' || kind === 'glow') material.emissive.set(0x153d1c);
    else material.emissive.copy(sourceColor);
    material.emissiveIntensity = kind === 'glowOrb' ? 0.48 : kind === 'glowLeaf' ? 0.035 : 0.012;
    dynamicMaterials.push({ material, kind });
  }
  return material;
}

function prepareAssetParts(scene, targetHeight, kind, dynamicMaterials, quality) {
  scene.updateMatrixWorld(true);
  const rawParts = [];
  const bounds = new THREE.Box3();
  const instanceMatrix = new THREE.Matrix4();
  const worldMatrix = new THREE.Matrix4();
  const appendGeometry = (object, matrix) => {
    const objectName = `${object.name || ''} ${object.parent?.name || ''}`.toLowerCase();
    const partKind = kind === 'glow'
      ? objectName.includes('leaf')
        ? 'glowLeaf'
        : objectName.includes('flow')
          ? 'glowOrb'
          : 'glow'
      : kind;
    const geometry = object.geometry.clone();
    geometry.applyMatrix4(matrix);
    geometry.computeBoundingBox();
    bounds.union(geometry.boundingBox);
    rawParts.push({
      geometry,
      materials: (Array.isArray(object.material) ? object.material : [object.material]),
      partKind,
    });
  };
  scene.traverse((object) => {
    if (!object.isMesh || !object.geometry?.attributes?.position) return;
    if (object.isInstancedMesh) {
      for (let index = 0; index < object.count; index++) {
        object.getMatrixAt(index, instanceMatrix);
        worldMatrix.copy(object.matrixWorld).multiply(instanceMatrix);
        appendGeometry(object, worldMatrix);
      }
    } else {
      appendGeometry(object, object.matrixWorld);
    }
  });
  if (!rawParts.length || bounds.isEmpty()) throw new Error('Detail asset has no renderable mesh');

  const center = bounds.getCenter(new THREE.Vector3());
  const size = bounds.getSize(new THREE.Vector3());
  const scale = targetHeight / Math.max(size.y, 0.001);
  const groups = new Map();
  rawParts.forEach(({ geometry, materials, partKind }, index) => {
    geometry.translate(-center.x, -bounds.min.y, -center.z);
    geometry.scale(scale, scale, scale);
    geometry.computeBoundingSphere();
    const materialKey = materials.length === 1 ? materials[0]?.uuid || `material-${index}` : `group-${index}`;
    const key = `${partKind}:${materialKey}`;
    if (!groups.has(key)) groups.set(key, { geometries: [], materials, partKind });
    groups.get(key).geometries.push(geometry);
  });

  const parts = [];
  for (const group of groups.values()) {
    const merged = group.geometries.length > 1
      ? mergeGeometries(group.geometries, false)
      : group.geometries[0];
    if (merged) {
      parts.push({
        geometry: merged,
        material: group.materials.map(
          (source) => createDetailMaterial(
            source,
            group.partKind,
            dynamicMaterials,
            quality,
          ),
        ),
      });
    } else {
      for (const geometry of group.geometries) {
        parts.push({
          geometry,
          material: group.materials.map(
            (source) => createDetailMaterial(
              source,
              group.partKind,
              dynamicMaterials,
              quality,
            ),
          ),
        });
      }
    }
  }
  return parts;
}

function makePlacements(definition, count, treePosition, terrainSampler) {
  const placements = [];
  for (let index = 0; index < count; index++) {
    let candidate = null;
    for (let attempt = 0; attempt < 28; attempt++) {
      const key = definition.seed + index * 31 + attempt * 113;
      const angle = seededRandom(key) * Math.PI * 2;
      const radius = THREE.MathUtils.lerp(
        definition.radius[0],
        definition.radius[1],
        Math.sqrt(seededRandom(key + 7)),
      );
      const x = treePosition.x + Math.cos(angle) * radius;
      const z = treePosition.z + Math.sin(angle) * radius * 0.84;
      const blocksCentralView = Math.abs(x) < 3.15 && z > treePosition.z - 0.8 && z < 1.8;
      if (!blocksCentralView || attempt === 27) {
        candidate = { x, z, key };
        break;
      }
    }
    const height = terrainSampler?.sample(candidate.x, candidate.z);
    const normal = terrainSampler?.normal(candidate.x, candidate.z) || WORLD_UP;
    placements.push({
      position: new THREE.Vector3(
        candidate.x,
        (Number.isFinite(height) ? height : 0) + (definition.kind === 'rock' ? -0.035 : 0.012),
        candidate.z,
      ),
      normal,
      yaw: seededRandom(candidate.key + 13) * Math.PI * 2,
      scale: 0.78 + seededRandom(candidate.key + 19) * 0.48,
    });
  }
  return placements;
}

export class SanctuaryGroundDetails {
  constructor({ quality = 'quest', treePosition, layer = 0 } = {}) {
    this.quality = quality;
    this.treePosition = treePosition.clone();
    this.layer = layer;
    this.root = new THREE.Group();
    this.root.name = 'SanctuaryV3_Organic_Ground_Details';
    this.root.layers.set(layer);
    this.status = 'idle';
    this.dynamicMaterials = [];
    this.instanceCount = 0;
    this.drawCalls = 0;
    this.activeMeshInstances = 0;
    this.activeDrawCalls = 0;
    this.rockCount = 0;
    this.flowerCount = 0;
    this.bushCount = 0;
    this.failedAssets = [];
    this.lastAbundanceBucket = null;
    this.detailRangeUpdateCount = 0;
    this.detailShadingProfile = quality === 'quest' ? 'lambert-quest' : 'pbr-high';
  }

  async load({ parent, terrainSampler }) {
    this.status = 'loading';
    parent.add(this.root);
    const loader = new GLTFLoader();
    loader.setMeshoptDecoder(MeshoptDecoder);
    const definitions = DETAIL_DEFINITIONS
      .map((definition) => ({
        ...definition,
        activeCount: this.quality === 'quest'
          ? definition.questCount ?? definition.count
          : definition.count,
      }))
      .filter((definition) => definition.activeCount > 0);

    const results = await Promise.allSettled(definitions.map(async (definition) => {
      const assetFile = definition.assetFile || `${definition.name}_quest.glb`;
      const gltf = await loadGltf(loader, `${DETAIL_ASSET_BASE}${assetFile}`);
      this.addAsset(gltf.scene, definition, terrainSampler);
    }));
    results.forEach((result, index) => {
      if (result.status === 'rejected') {
        this.failedAssets.push(definitions[index].name);
        console.warn(`Sanctuary detail ${definitions[index].name} failed to load.`, result.reason);
      }
    });
    this.status = this.failedAssets.length === 0
      ? 'ready'
      : this.failedAssets.length < definitions.length
        ? 'partial-fallback'
        : 'fallback';
    return this.snapshot();
  }

  addAsset(scene, definition, terrainSampler) {
    const parts = prepareAssetParts(
      scene,
      definition.height,
      definition.kind,
      this.dynamicMaterials,
      this.quality,
    );
    const placements = makePlacements(
      definition,
      definition.activeCount,
      this.treePosition,
      terrainSampler,
    );
    const align = new THREE.Quaternion();
    const yaw = new THREE.Quaternion();
    const dummy = new THREE.Object3D();

    for (let partIndex = 0; partIndex < parts.length; partIndex++) {
      const part = parts[partIndex];
      const material = part.material.length === 1 ? part.material[0] : part.material;
      const mesh = new THREE.InstancedMesh(part.geometry, material, placements.length);
      mesh.name = `SanctuaryV3_${definition.name}_Part_${partIndex + 1}`;
      mesh.layers.set(this.layer);
      mesh.castShadow = false;
      mesh.receiveShadow = false;
      placements.forEach((placement, index) => {
        align.setFromUnitVectors(WORLD_UP, placement.normal);
        yaw.setFromAxisAngle(WORLD_UP, placement.yaw);
        dummy.position.copy(placement.position);
        dummy.quaternion.copy(align).multiply(yaw);
        dummy.scale.setScalar(placement.scale);
        dummy.updateMatrix();
        mesh.setMatrixAt(index, dummy.matrix);
      });
      mesh.instanceMatrix.needsUpdate = true;
      mesh.userData.detailAsset = definition.name;
      mesh.userData.detailKind = definition.kind;
      mesh.userData.maxInstanceCount = placements.length;
      mesh.userData.drawCallCost = Array.isArray(material) ? material.length : 1;
      this.root.add(mesh);
      this.drawCalls += mesh.userData.drawCallCost;
      this.activeDrawCalls += mesh.userData.drawCallCost;
      this.activeMeshInstances += placements.length;
    }

    this.instanceCount += placements.length;
    if (definition.kind === 'rock') this.rockCount += placements.length;
    else if (definition.kind === 'bush') this.bushCount += placements.length;
    else this.flowerCount += placements.length;
  }

  update({ visualState, breathProgress, comfortOptions, performanceScale = 1 } = {}) {
    const vitality = visualState?.vitality ?? 0.5;
    const breath = 0.5 - Math.cos((breathProgress || 0) * Math.PI * 2) * 0.5;
    const reducedMotion = comfortOptions?.reducedMotion === true;
    for (const entry of this.dynamicMaterials) {
      if (entry.kind === 'glowOrb') {
        entry.material.emissiveIntensity = 0.26 + vitality * 0.42
          + breath * (reducedMotion ? 0.012 : 0.035);
      } else if (entry.kind === 'glowLeaf' || entry.kind === 'glow') {
        entry.material.emissiveIntensity = 0.025 + vitality * 0.035;
      } else {
        entry.material.emissiveIntensity = 0.006 + vitality * 0.022;
      }
    }
    const performanceBucket = quantizePerformanceScale(performanceScale);
    if (performanceBucket === this.lastAbundanceBucket) return;
    this.lastAbundanceBucket = performanceBucket;
    this.detailRangeUpdateCount += 1;
    this.activeMeshInstances = 0;
    this.activeDrawCalls = 0;
    for (const mesh of this.root.children) {
      if (!mesh.isInstancedMesh) continue;
      const abundance = detailAssetAbundance(
        mesh.userData.detailKind,
        mesh.userData.detailAsset,
        performanceBucket,
      );
      const maximum = mesh.userData.maxInstanceCount || mesh.count;
      mesh.count = abundance <= 0
        ? 0
        : Math.max(1, Math.round(maximum * abundance));
      mesh.visible = mesh.count > 0;
      if (!mesh.visible) continue;
      this.activeMeshInstances += mesh.count;
      this.activeDrawCalls += mesh.userData.drawCallCost || 1;
    }
  }

  snapshot() {
    return {
      detailStatus: this.status,
      detailInstances: this.instanceCount,
      detailDrawCalls: this.drawCalls,
      activeDetailMeshInstances: this.activeMeshInstances,
      activeDetailDrawCalls: this.activeDrawCalls,
      rockCount: this.rockCount,
      flowerCount: this.flowerCount,
      bushCount: this.bushCount,
      failedDetailAssets: [...this.failedAssets],
      bush3QuestCount: this.quality === 'quest' ? 1 : 2,
      detailShadingProfile: this.detailShadingProfile,
      detailRangeUpdateCount: this.detailRangeUpdateCount,
    };
  }
}
