import * as THREE from 'three';
import {
  CANOPY_QUALITY_PROFILES,
  advanceCanopyCount,
  advanceClinicalDetachmentAllowance,
  advanceFullBloomBlend,
  canopyIntegrityIssue,
  clinicalShedEventRate,
  clamp,
  deterministicUnit,
  didEnterFullBloom,
  extractConnectedTriangleComponents,
  fullBloomPulseValue,
  isClinicalDetachment,
  shouldUseAnchorFallback,
  smoothstep,
  stratifyCanopyAnchors,
} from './sanctuary_canopy_math.js?v=25';

const MIN_AUTHORED_ANCHORS = 400;
const RENDER_GREEN_LEAF_LAYER = false;
const FALLBACK_ANCHOR_COUNT = 1080;
const LEAF_BIRTH_SECONDS = 0.75;
const BLOSSOM_BIRTH_SECONDS = 1.1;
const RETRACT_SECONDS = 0.4;
const FULL_BLOOM_REVEAL_SECONDS = 4;
const FULL_BLOOM_RETIRE_SECONDS = 3;
const FULL_BLOOM_GROWTH_RATE = 0.25;
const RESPONSIVE_GROWTH_RATE = 0.2;
const RESPONSIVE_DECLINE_RATE = 0.16;
const FULL_BLOOM_PULSE_SECONDS = 4;
const Z_AXIS = new THREE.Vector3(0, 0, 1);

function sourceMaterials(mesh) {
  return Array.isArray(mesh?.material) ? mesh.material : [mesh?.material].filter(Boolean);
}

export function findAuthoredBlossomMesh(tree) {
  let match = null;
  tree?.traverse((object) => {
    if (match || !object.isMesh) return;
    const meshName = object.name?.toLowerCase() || '';
    const materialMatch = sourceMaterials(object).some((material) => (
      material?.name?.toLowerCase().includes('sakura_mat')
    ));
    if (meshName.includes('sakura_sakura_mat') || materialMatch) match = object;
  });
  return match;
}

function componentAnchor({ component, geometry, meshToTree, meshNormalToTree, index }) {
  const positionAttribute = geometry.getAttribute('position');
  const normalAttribute = geometry.getAttribute('normal');
  const uvAttribute = geometry.getAttribute('uv');
  const centre = new THREE.Vector3();
  const normal = new THREE.Vector3();
  const localVertex = new THREE.Vector3();
  const transformedVertices = [];
  let minU = 1;
  let minV = 1;
  let maxU = 0;
  let maxV = 0;

  for (const vertexIndex of component.vertexIndices) {
    localVertex.fromBufferAttribute(positionAttribute, vertexIndex).applyMatrix4(meshToTree);
    transformedVertices.push(localVertex.clone());
    centre.add(localVertex);
    if (normalAttribute) {
      normal.add(new THREE.Vector3()
        .fromBufferAttribute(normalAttribute, vertexIndex)
        .applyMatrix3(meshNormalToTree));
    }
    if (uvAttribute) {
      minU = Math.min(minU, uvAttribute.getX(vertexIndex));
      minV = Math.min(minV, uvAttribute.getY(vertexIndex));
      maxU = Math.max(maxU, uvAttribute.getX(vertexIndex));
      maxV = Math.max(maxV, uvAttribute.getY(vertexIndex));
    }
  }
  centre.multiplyScalar(1 / Math.max(transformedVertices.length, 1));

  if (normal.lengthSq() < 0.000001 && transformedVertices.length >= 3) {
    normal.crossVectors(
      transformedVertices[1].clone().sub(transformedVertices[0]),
      transformedVertices[2].clone().sub(transformedVertices[0]),
    );
  }
  if (normal.lengthSq() < 0.000001) normal.set(0, 0, 1);
  normal.normalize();

  const tangent = transformedVertices
    .map((vertex) => vertex.clone().sub(centre))
    .sort((left, right) => right.lengthSq() - left.lengthSq())[0]
    || new THREE.Vector3(1, 0, 0);
  tangent.addScaledVector(normal, -tangent.dot(normal));
  if (tangent.lengthSq() < 0.000001) {
    tangent.crossVectors(Math.abs(normal.y) < 0.9
      ? new THREE.Vector3(0, 1, 0)
      : new THREE.Vector3(1, 0, 0), normal);
  }
  tangent.normalize();
  const bitangent = new THREE.Vector3().crossVectors(normal, tangent).normalize();
  let radius = 0;
  for (const vertex of transformedVertices) radius = Math.max(radius, vertex.distanceTo(centre));

  return {
    position: centre,
    normal,
    tangent,
    bitangent,
    radius: clamp(radius, 0.012, 0.22),
    uvRect: uvAttribute
      ? [minU, minV, Math.max(maxU - minU, 0.001), Math.max(maxV - minV, 0.001)]
      : [0, 0, 1, 1],
    seed: deterministicUnit(index, 17),
  };
}

function triangleVertexIndices(geometry, triangleIndex) {
  const offset = triangleIndex * 3;
  const index = geometry.index;
  return index
    ? [index.getX(offset), index.getX(offset + 1), index.getX(offset + 2)]
    : [offset, offset + 1, offset + 2];
}

function fallbackSurfaceAnchors(geometry, meshToTree, targetCount = FALLBACK_ANCHOR_COUNT) {
  const positionAttribute = geometry.getAttribute('position');
  const uvAttribute = geometry.getAttribute('uv');
  const triangleCount = Math.floor((geometry.index?.count || positionAttribute.count) / 3);
  const triangles = [];
  let totalArea = 0;
  const a = new THREE.Vector3();
  const b = new THREE.Vector3();
  const c = new THREE.Vector3();

  for (let triangle = 0; triangle < triangleCount; triangle++) {
    const vertices = triangleVertexIndices(geometry, triangle);
    a.fromBufferAttribute(positionAttribute, vertices[0]).applyMatrix4(meshToTree);
    b.fromBufferAttribute(positionAttribute, vertices[1]).applyMatrix4(meshToTree);
    c.fromBufferAttribute(positionAttribute, vertices[2]).applyMatrix4(meshToTree);
    const area = new THREE.Triangle(a, b, c).getArea();
    if (area <= 0.0000001) continue;
    totalArea += area;
    triangles.push({ triangle, vertices, cumulativeArea: totalArea, area });
  }
  if (!triangles.length) return [];

  const anchors = [];
  const occupied = new Set();
  for (let sample = 0; sample < targetCount * 4 && anchors.length < targetCount; sample++) {
    const distance = ((sample + 0.5) / (targetCount * 4)) * totalArea;
    let low = 0;
    let high = triangles.length - 1;
    while (low < high) {
      const middle = Math.floor((low + high) / 2);
      if (triangles[middle].cumulativeArea < distance) low = middle + 1;
      else high = middle;
    }
    const record = triangles[low];
    const [ia, ib, ic] = record.vertices;
    a.fromBufferAttribute(positionAttribute, ia).applyMatrix4(meshToTree);
    b.fromBufferAttribute(positionAttribute, ib).applyMatrix4(meshToTree);
    c.fromBufferAttribute(positionAttribute, ic).applyMatrix4(meshToTree);
    let u = deterministicUnit(sample, 41);
    let v = deterministicUnit(sample, 43);
    if (u + v > 1) {
      u = 1 - u;
      v = 1 - v;
    }
    const position = a.clone()
      .addScaledVector(b.clone().sub(a), u)
      .addScaledVector(c.clone().sub(a), v);
    const voxel = [position.x, position.y, position.z]
      .map((value) => Math.round(value / 0.025))
      .join(':');
    if (occupied.has(voxel)) continue;
    occupied.add(voxel);
    const normal = new THREE.Vector3().crossVectors(
      b.clone().sub(a),
      c.clone().sub(a),
    ).normalize();
    const tangent = b.clone().sub(a).normalize();
    const bitangent = new THREE.Vector3().crossVectors(normal, tangent).normalize();
    const uvValues = [ia, ib, ic].map((vertex) => (
      uvAttribute ? [uvAttribute.getX(vertex), uvAttribute.getY(vertex)] : [0, 0]
    ));
    const minU = Math.min(...uvValues.map(([value]) => value));
    const minV = Math.min(...uvValues.map(([, value]) => value));
    const maxU = Math.max(...uvValues.map(([value]) => value));
    const maxV = Math.max(...uvValues.map(([, value]) => value));
    anchors.push({
      position,
      normal,
      tangent,
      bitangent,
      radius: clamp(Math.sqrt(record.area) * 0.36, 0.018, 0.12),
      uvRect: uvAttribute
        ? [minU, minV, Math.max(maxU - minU, 0.001), Math.max(maxV - minV, 0.001)]
        : [0, 0, 1, 1],
      seed: deterministicUnit(sample, 47),
    });
  }
  return anchors;
}

export function extractAuthoredCanopyAnchors(tree, blossomMesh) {
  if (!tree || !blossomMesh?.geometry?.getAttribute('position')) {
    throw new Error('The authored sakura blossom geometry is unavailable');
  }
  tree.updateMatrixWorld(true);
  blossomMesh.updateMatrixWorld(true);
  const meshToTree = tree.matrixWorld.clone().invert().multiply(blossomMesh.matrixWorld);
  const meshNormalToTree = new THREE.Matrix3().getNormalMatrix(meshToTree);
  const geometry = blossomMesh.geometry;
  const positions = geometry.getAttribute('position').array;
  const indices = geometry.index?.array || null;
  const components = extractConnectedTriangleComponents({ positions, indices });
  let anchors = components.map((component, index) => componentAnchor({
    component,
    geometry,
    meshToTree,
    meshNormalToTree,
    index,
  }));
  let fallbackReason = null;
  if (shouldUseAnchorFallback(anchors.length)) {
    fallbackReason = `Only ${anchors.length} authored blossom cards were found; using surface samples.`;
    anchors = fallbackSurfaceAnchors(geometry, meshToTree);
  }
  if (anchors.length < MIN_AUTHORED_ANCHORS) {
    throw new Error(`Canopy anchor extraction produced only ${anchors.length} anchors`);
  }
  return { anchors, fallbackReason };
}

function makeLeafGeometry() {
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute([
    0, -0.52, 0,
    -0.36, -0.02, 0.035,
    0, 0.58, 0.08,
    0.36, -0.02, 0.035,
    0, 0.02, 0.16,
  ], 3));
  geometry.setAttribute('uv', new THREE.Float32BufferAttribute([
    0.5, 0,
    0, 0.48,
    0.5, 1,
    1, 0.48,
    0.5, 0.5,
  ], 2));
  geometry.setIndex([0, 1, 4, 1, 2, 4, 2, 3, 4, 3, 0, 4]);
  geometry.computeVertexNormals();
  return geometry;
}

function makeCrossedBlossomGeometry() {
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute([
    -0.5, -0.5, 0, 0.5, -0.5, 0, 0.5, 0.5, 0, -0.5, 0.5, 0,
    0, -0.5, -0.5, 0, -0.5, 0.5, 0, 0.5, 0.5, 0, 0.5, -0.5,
  ], 3));
  geometry.setAttribute('uv', new THREE.Float32BufferAttribute([
    0, 0, 1, 0, 1, 1, 0, 1,
    0, 0, 1, 0, 1, 1, 0, 1,
  ], 2));
  geometry.setIndex([0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7]);
  geometry.computeVertexNormals();
  return geometry;
}

function createLeafMaterial(uniforms) {
  const material = new THREE.MeshStandardMaterial({
    name: 'SanctuaryV3_Dynamic_Sakura_Leaves',
    color: 0xffffff,
    emissive: 0x102f16,
    emissiveIntensity: 0.12,
    roughness: 0.84,
    metalness: 0,
    side: THREE.DoubleSide,
    vertexColors: true,
  });
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uCanopyHealth = uniforms.health;
    shader.uniforms.uFullBloom = uniforms.fullBloom;
    shader.fragmentShader = shader.fragmentShader
      .replace(
        '#include <common>',
        `#include <common>
        uniform float uCanopyHealth;
        uniform float uFullBloom;`,
      )
      .replace(
        '#include <color_fragment>',
        `#include <color_fragment>
        vec3 sanctuaryWitheredLeaf = vec3(0.5, 0.24, 0.08);
        diffuseColor.rgb = mix(
          sanctuaryWitheredLeaf,
          max(diffuseColor.rgb, vec3(0.22, 0.42, 0.18)),
          smoothstep(0.08, 0.9, uCanopyHealth)
        );
        diffuseColor.rgb = mix(
          diffuseColor.rgb,
          max(diffuseColor.rgb, vec3(0.38, 0.64, 0.3)),
          uFullBloom * 0.72
        );`,
      )
      .replace(
        '#include <emissivemap_fragment>',
        `#include <emissivemap_fragment>
        totalEmissiveRadiance += mix(
          vec3(0.12, 0.045, 0.012),
          vec3(0.035, 0.13, 0.04),
          uCanopyHealth
        ) * 0.16;
        totalEmissiveRadiance += vec3(0.04, 0.095, 0.025) * uFullBloom;`,
      );
  };
  material.customProgramCacheKey = () => 'sanctuary-v3-dynamic-sakura-leaves-v3-full-bloom';
  material.needsUpdate = true;
  return material;
}

function createBlossomMaterial(sourceMaterial, uniforms) {
  const material = sourceMaterial?.clone() || new THREE.MeshStandardMaterial();
  material.name = 'SanctuaryV3_Dynamic_Sakura_Blossoms';
  material.color = new THREE.Color(0xffffff);
  material.emissive = new THREE.Color(0xff7799);
  material.emissiveIntensity = 0.14;
  material.roughness = 0.86;
  material.metalness = 0;
  material.side = THREE.DoubleSide;
  material.transparent = false;
  material.alphaTest = Math.max(sourceMaterial?.alphaTest || 0, 0.12);
  material.depthWrite = true;
  material.vertexColors = true;
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uCanopyHealth = uniforms.health;
    shader.uniforms.uFullBloom = uniforms.fullBloom;
    shader.vertexShader = shader.vertexShader
      .replace(
        '#include <common>',
        `#include <common>
        attribute vec4 instanceUvRect;`,
      )
      .replace(
        '#include <uv_vertex>',
        `#include <uv_vertex>
        #ifdef USE_MAP
          vMapUv = instanceUvRect.xy + vMapUv * instanceUvRect.zw;
        #endif`,
      );
    shader.fragmentShader = shader.fragmentShader
      .replace(
        '#include <common>',
        `#include <common>
        uniform float uCanopyHealth;
        uniform float uFullBloom;`,
      )
      .replace(
        '#include <map_fragment>',
        `#include <map_fragment>
        vec3 sanctuaryHealthyBlossom = max(
          diffuseColor.rgb,
          vec3(0.76, 0.4, 0.54)
        );
        vec3 sanctuaryWitheredBlossom = vec3(0.56, 0.2, 0.13);
        diffuseColor.rgb = mix(
          sanctuaryWitheredBlossom,
          sanctuaryHealthyBlossom,
          smoothstep(0.06, 0.92, uCanopyHealth)
        );
        vec3 sanctuaryPearlBlossom = max(
          diffuseColor.rgb,
          vec3(0.96, 0.62, 0.74)
        );
        diffuseColor.rgb = mix(diffuseColor.rgb, sanctuaryPearlBlossom, uFullBloom * 0.78);`,
      )
      .replace(
        '#include <emissivemap_fragment>',
        `#include <emissivemap_fragment>
        totalEmissiveRadiance += vec3(0.18, 0.055, 0.085) * uFullBloom;`,
      );
  };
  material.customProgramCacheKey = () => 'sanctuary-v3-dynamic-sakura-blossoms-v3-full-bloom';
  material.needsUpdate = true;
  return material;
}

function createPeakBlossomMaterial(sourceMaterial, uniforms) {
  const material = sourceMaterial?.isMeshStandardMaterial || sourceMaterial?.isMeshPhysicalMaterial
    ? sourceMaterial.clone()
    : new THREE.MeshStandardMaterial({ map: sourceMaterial?.map || null });
  material.name = 'SanctuaryV3_Full_Bloom_Pearl_Blossoms';
  material.color = new THREE.Color(0xffffff);
  material.emissive = new THREE.Color(0xff8dab);
  material.emissiveIntensity = 0.2;
  material.roughness = 0.82;
  material.metalness = 0;
  material.side = THREE.DoubleSide;
  material.transparent = false;
  material.alphaTest = Math.max(sourceMaterial?.alphaTest || 0, 0.12);
  material.depthWrite = true;
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uPeakReveal = uniforms.peakReveal;
    shader.vertexShader = shader.vertexShader
      .replace(
        '#include <common>',
        `#include <common>
        attribute vec3 canopyCardCenter;
        attribute float canopyCardSeed;
        uniform float uPeakReveal;`,
      )
      .replace(
        '#include <begin_vertex>',
        `float sanctuaryCardReveal = smoothstep(
          canopyCardSeed * 0.14,
          1.0,
          uPeakReveal
        );
        vec3 transformed = canopyCardCenter
          + (position - canopyCardCenter) * sanctuaryCardReveal;`,
      );
    shader.fragmentShader = shader.fragmentShader
      .replace(
        '#include <common>',
        `#include <common>
        uniform float uPeakReveal;`,
      )
      .replace(
        '#include <map_fragment>',
        `#include <map_fragment>
        vec3 sanctuaryRoseFloor = max(diffuseColor.rgb, vec3(0.82, 0.38, 0.52));
        vec3 sanctuaryPearlPink = vec3(1.0, 0.73, 0.82);
        diffuseColor.rgb = mix(
          sanctuaryRoseFloor,
          max(sanctuaryRoseFloor, sanctuaryPearlPink),
          uPeakReveal * 0.46
        );`,
      )
      .replace(
        '#include <emissivemap_fragment>',
        `#include <emissivemap_fragment>
        totalEmissiveRadiance += vec3(0.2, 0.065, 0.095) * (0.1 + uPeakReveal * 0.55);`,
      );
  };
  material.customProgramCacheKey = () => 'sanctuary-v3-authored-peak-blossoms-v1';
  material.needsUpdate = true;
  return material;
}

function createPeakCanopy(sourceMesh, sourceMaterial, uniforms, layer) {
  const geometry = sourceMesh.geometry.clone();
  const positionAttribute = geometry.getAttribute('position');
  const components = extractConnectedTriangleComponents({
    positions: positionAttribute.array,
    indices: geometry.index?.array || null,
  });
  if (!components.length) throw new Error('The authored peak canopy has no blossom cards');

  const cardCentres = new Float32Array(positionAttribute.count * 3);
  const cardSeeds = new Float32Array(positionAttribute.count);
  const centre = new THREE.Vector3();
  const vertex = new THREE.Vector3();
  components.forEach((component, componentIndex) => {
    centre.set(0, 0, 0);
    for (const vertexIndex of component.vertexIndices) {
      centre.add(vertex.fromBufferAttribute(positionAttribute, vertexIndex));
    }
    centre.multiplyScalar(1 / Math.max(component.vertexIndices.length, 1));
    const seed = deterministicUnit(componentIndex, 101);
    for (const vertexIndex of component.vertexIndices) {
      cardCentres.set([centre.x, centre.y, centre.z], vertexIndex * 3);
      cardSeeds[vertexIndex] = seed;
    }
  });
  geometry.setAttribute('canopyCardCenter', new THREE.BufferAttribute(cardCentres, 3));
  geometry.setAttribute('canopyCardSeed', new THREE.BufferAttribute(cardSeeds, 1));

  const mesh = sourceMesh.clone(false);
  mesh.name = 'SanctuaryV3_Authored_Full_Bloom_Canopy';
  mesh.geometry = geometry;
  mesh.material = createPeakBlossomMaterial(sourceMaterial, uniforms);
  mesh.layers.set(layer);
  mesh.visible = true;
  sourceMesh.parent?.add(mesh);
  return {
    mesh,
    cardCount: components.length,
    triangleCount: Math.floor((geometry.index?.count || positionAttribute.count) / 3),
  };
}

function makeAnchorPool(anchors, capacity, { preferTips }) {
  const order = stratifyCanopyAnchors(anchors, { preferTips });
  const centre = anchors.reduce(
    (value, anchor) => value.add(anchor.position),
    new THREE.Vector3(),
  ).multiplyScalar(1 / anchors.length);
  const pool = [];
  for (let index = 0; index < capacity; index++) {
    const sourceIndex = order[index % order.length];
    const source = anchors[sourceIndex];
    const duplicate = Math.floor(index / order.length);
    const jitterScale = duplicate > 0 ? source.radius * 0.42 : 0;
    const position = source.position.clone()
      .addScaledVector(source.tangent, (deterministicUnit(index, 53) - 0.5) * jitterScale)
      .addScaledVector(source.bitangent, (deterministicUnit(index, 59) - 0.5) * jitterScale);
    if (!preferTips) position.lerp(centre, 0.035);
    const quaternion = new THREE.Quaternion().setFromUnitVectors(Z_AXIS, source.normal);
    pool.push({
      position,
      tangent: source.tangent.clone(),
      bitangent: source.bitangent.clone(),
      quaternion,
      rotation: deterministicUnit(index, preferTips ? 61 : 67) * Math.PI * 2,
      baseScale: clamp(
        source.radius * (preferTips ? 0.68 : 0.42)
          * (0.82 + deterministicUnit(index, 71) * 0.36),
        preferTips ? 0.014 : 0.009,
        preferTips ? 0.06 : 0.038,
      ),
      swayPhase: deterministicUnit(index, 73) * Math.PI * 2,
      uvRect: source.uvRect,
    });
  }
  return pool;
}

function makeLayer({ name, geometry, material, anchors, layer, blossom = false }) {
  const mesh = new THREE.InstancedMesh(geometry, material, anchors.length);
  mesh.name = name;
  mesh.count = 0;
  mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
  mesh.frustumCulled = false;
  mesh.layers.set(layer);
  const birthTimes = new Float32Array(anchors.length);
  const deathTimes = new Float32Array(anchors.length);
  birthTimes.fill(Number.NEGATIVE_INFINITY);
  deathTimes.fill(Number.NaN);

  if (blossom) {
    const uvRects = new Float32Array(anchors.length * 4);
    anchors.forEach((anchor, index) => uvRects.set(anchor.uvRect, index * 4));
    geometry.setAttribute('instanceUvRect', new THREE.InstancedBufferAttribute(uvRects, 4));
  }
  const colours = blossom
    ? [0xffc0d1, 0xffcddd, 0xffd9e6, 0xffe5ed]
    : [0x579b50, 0x66aa5b, 0x73b665, 0x80bf70];
  anchors.forEach((anchor, index) => {
    mesh.setColorAt(index, new THREE.Color(colours[Math.floor(
      deterministicUnit(index, blossom ? 79 : 83) * colours.length,
    )]));
  });
  if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;

  return {
    mesh,
    anchors,
    birthTimes,
    deathTimes,
    scheduledCount: 0,
    renderedCount: 0,
    targetCount: 0,
    birthSeconds: blossom ? BLOSSOM_BIRTH_SECONDS : LEAF_BIRTH_SECONDS,
    blossom,
  };
}

export class SakuraCanopyController {
  constructor({ quality = 'quest', layer = 0, mode = 'source' } = {}) {
    this.quality = quality === 'high' ? 'high' : 'quest';
    this.profile = CANOPY_QUALITY_PROFILES[this.quality];
    this.layer = layer;
    this.mode = mode === 'dynamic' ? 'dynamic' : 'source';
    this.status = this.mode === 'dynamic' ? 'idle' : 'source';
    this.root = new THREE.Group();
    this.root.name = 'SanctuaryV3_Branch_Aware_Canopy';
    this.root.layers.set(layer);
    this.sourceBlossomMesh = null;
    this.peakCanopy = null;
    this.peakStatus = this.mode === 'dynamic' ? 'idle' : 'source';
    this.leafLayer = null;
    this.blossomLayer = null;
    this.anchorCount = 0;
    this.fallbackReason = null;
    this.dummy = new THREE.Object3D();
    this.materialUniforms = {
      health: { value: 0.7 },
      fullBloom: { value: 0 },
      peakReveal: { value: 0 },
    };
    this.fullBloomBlend = 0;
    this.fullBloomPulse = 0;
    this.fullBloomPulseElapsed = Number.POSITIVE_INFINITY;
    this.fullBloomWasActive = false;
    this.bloomCelebrationCount = 0;
    this.lastBlossomCoverage = null;
    this.shedEventBudget = 0;
    this.pendingShedEvents = [];
    this.lastShedEventCount = 0;
    this.totalDetachedPetals = 0;
    this.clinicalLeafTargetCount = 0;
    this.clinicalBlossomTargetCount = 0;
    this.clinicalBlossomRenderBoundary = 0;
    this.previousClinicalBlossomTargetCount = null;
    this.clinicalDetachmentAllowance = 0;
    this.adaptiveCanopyScale = 1;
    this.lastAdaptiveRetractionCount = 0;
    this.totalAdaptiveRetractions = 0;
    this.integrityFailures = 0;
    this.lastIntegrityIssue = null;
    this.renderGreenLeafLayer = RENDER_GREEN_LEAF_LAYER;
  }

  initialize({ tree, blossomMesh } = {}) {
    if (this.mode !== 'dynamic') return this.snapshot();
    this.status = 'loading';
    this.sourceBlossomMesh = blossomMesh || findAuthoredBlossomMesh(tree);
    if (!this.sourceBlossomMesh) {
      return this.fallbackToSource(new Error('The Sakura_Mat blossom mesh was not found'));
    }

    try {
      const { anchors, fallbackReason } = extractAuthoredCanopyAnchors(
        tree,
        this.sourceBlossomMesh,
      );
      this.anchorCount = anchors.length;
      this.fallbackReason = fallbackReason;
      const blossomSourceMaterial = sourceMaterials(this.sourceBlossomMesh)
        .find((material) => material.name?.toLowerCase().includes('sakura_mat'))
        || sourceMaterials(this.sourceBlossomMesh)[0];
      const leafAnchors = makeAnchorPool(anchors, this.profile.maxLeaves, { preferTips: false });
      const blossomAnchors = makeAnchorPool(
        anchors,
        this.profile.maxBlossoms,
        { preferTips: true },
      );
      this.leafLayer = makeLayer({
        name: 'SanctuaryV3_Branch_Aware_Leaves',
        geometry: makeLeafGeometry(),
        material: createLeafMaterial(this.materialUniforms),
        anchors: leafAnchors,
        layer: this.layer,
      });
      this.leafLayer.mesh.visible = this.renderGreenLeafLayer;
      this.blossomLayer = makeLayer({
        name: 'SanctuaryV3_Branch_Aware_Blossoms',
        geometry: makeCrossedBlossomGeometry(),
        material: createBlossomMaterial(blossomSourceMaterial, this.materialUniforms),
        anchors: blossomAnchors,
        layer: this.layer,
        blossom: true,
      });
      this.peakCanopy = createPeakCanopy(
        this.sourceBlossomMesh,
        blossomSourceMaterial,
        this.materialUniforms,
        this.layer,
      );
      this.peakStatus = 'ready';
      this.root.add(this.blossomLayer.mesh);
      tree.add(this.root);
      this.sourceBlossomMesh.visible = false;
      this.status = 'ready';
      return this.snapshot();
    } catch (error) {
      return this.fallbackToSource(error);
    }
  }

  update({
    visualState,
    comfortOptions,
    elapsedTime = 0,
    deltaTime = 1 / 72,
    performanceScale = 1,
  } = {}) {
    if (this.status !== 'ready') return this.snapshot();
    const dt = clamp(deltaTime, 1 / 240, 0.1);
    const reducedMotion = comfortOptions?.reducedMotion === true;
    const adaptiveScale = clamp(performanceScale, 0.1, 1);
    const previousAdaptiveScale = this.adaptiveCanopyScale;
    this.adaptiveCanopyScale = adaptiveScale;
    const fullBloom = visualState?.fullBloom === true;
    this.fullBloomBlend = advanceFullBloomBlend(
      this.fullBloomBlend,
      fullBloom,
      dt,
      {
        enterSeconds: FULL_BLOOM_REVEAL_SECONDS,
        exitSeconds: FULL_BLOOM_RETIRE_SECONDS,
      },
    );
    if (didEnterFullBloom(fullBloom, this.fullBloomWasActive)) {
      this.fullBloomPulseElapsed = 0;
      this.bloomCelebrationCount++;
    }
    this.fullBloomPulse = fullBloomPulseValue(
      this.fullBloomPulseElapsed,
      FULL_BLOOM_PULSE_SECONDS,
    );
    if (Number.isFinite(this.fullBloomPulseElapsed)) {
      this.fullBloomPulseElapsed += dt;
      if (this.fullBloomPulseElapsed >= FULL_BLOOM_PULSE_SECONDS) {
        this.fullBloomPulseElapsed = Number.POSITIVE_INFINITY;
      }
    }
    this.fullBloomWasActive = fullBloom;
    const blossomCoverage = clamp(visualState?.blossomCoverage ?? 0);
    const coverageDelta = this.lastBlossomCoverage === null
      ? 0
      : blossomCoverage - this.lastBlossomCoverage;
    this.lastBlossomCoverage = blossomCoverage;
    this.materialUniforms.health.value = clamp(visualState?.canopyHealth ?? 0.7);
    this.materialUniforms.fullBloom.value = this.fullBloomBlend;
    this.materialUniforms.peakReveal.value = this.fullBloomBlend;
    const shedEventsPerSecond = fullBloom ? 0 : clinicalShedEventRate({
      shedImpulse: visualState?.shedImpulse ?? 0,
      signalAccepted: visualState?.signalAccepted === true,
      coverageDelta,
    });
    this.shedEventBudget = shedEventsPerSecond > 0
      ? Math.min(8, this.shedEventBudget + shedEventsPerSecond * dt)
      : 0;
    this.pendingShedEvents.length = 0;
    this.lastShedEventCount = 0;
    this.lastAdaptiveRetractionCount = 0;
    const targetBlossomCoverage = fullBloom ? 1 : blossomCoverage;
    this.clinicalLeafTargetCount = 0;
    this.clinicalBlossomTargetCount = Math.round(
      this.profile.maxBlossoms * targetBlossomCoverage,
    );
    const previousClinicalBlossomTarget = this.previousClinicalBlossomTargetCount
      ?? this.clinicalBlossomTargetCount;
    this.clinicalDetachmentAllowance = advanceClinicalDetachmentAllowance({
      currentAllowance: this.clinicalDetachmentAllowance,
      previousClinicalTarget: previousClinicalBlossomTarget,
      currentClinicalTarget: this.clinicalBlossomTargetCount,
      previousPerformanceScale: previousAdaptiveScale,
      clinicalDeclineActive: shedEventsPerSecond > 0,
      deltaTime: dt,
    });
    this.previousClinicalBlossomTargetCount = this.clinicalBlossomTargetCount;
    const blossomTarget = Math.round(this.clinicalBlossomTargetCount * adaptiveScale);
    this.clinicalBlossomRenderBoundary = blossomTarget;
    const growthRate = fullBloom ? FULL_BLOOM_GROWTH_RATE : RESPONSIVE_GROWTH_RATE;
    this.leafLayer.targetCount = 0;
    this.leafLayer.scheduledCount = 0;
    this.leafLayer.renderedCount = 0;
    this.leafLayer.mesh.count = 0;
    const blossomRetractions = this.updateLayer(
      this.blossomLayer,
      blossomTarget,
      elapsedTime,
      dt,
      reducedMotion,
      shedEventsPerSecond > 0,
      growthRate,
      this.clinicalBlossomRenderBoundary,
      shedEventsPerSecond,
      RESPONSIVE_DECLINE_RATE,
    );
    this.lastAdaptiveRetractionCount = blossomRetractions.adaptive;
    this.totalAdaptiveRetractions += blossomRetractions.adaptive;
    this.lastShedEventCount = this.pendingShedEvents.length;
    const integrityIssue = canopyIntegrityIssue({
      activeLeafCount: this.leafLayer.renderedCount,
      activeBlossomCount: this.blossomLayer.renderedCount,
      targetLeafCount: this.leafLayer.targetCount,
      targetBlossomCount: this.blossomLayer.targetCount,
      maxLeaves: this.profile.maxLeaves,
      maxBlossoms: this.profile.maxBlossoms,
      fullBloomBlend: this.fullBloomBlend,
      materialHealth: this.materialUniforms.health.value,
    });
    if (integrityIssue) {
      this.integrityFailures++;
      this.lastIntegrityIssue = integrityIssue;
      return this.fallbackToSource(new Error(`Canopy integrity: ${integrityIssue}`));
    }
    return this.snapshot();
  }

  updateLayer(
    layer,
    targetCount,
    elapsedTime,
    deltaTime,
    reducedMotion,
    emitShedEvents,
    growthRate = 0.1,
    clinicalRenderBoundary = targetCount,
    shedEventsPerSecond = 0,
    declineRate = RESPONSIVE_DECLINE_RATE,
  ) {
    const retractions = { clinical: 0, adaptive: 0 };
    const capacity = layer.anchors.length;
    layer.targetCount = clamp(targetCount, 0, capacity);
    layer.scheduledCount = advanceCanopyCount(
      layer.scheduledCount,
      layer.targetCount,
      capacity,
      deltaTime,
      { growthRate, declineRate },
    );
    const desiredCount = Math.round(layer.scheduledCount);

    if (desiredCount > layer.renderedCount) {
      for (let index = layer.renderedCount; index < desiredCount; index++) {
        layer.birthTimes[index] = elapsedTime;
        layer.deathTimes[index] = Number.NaN;
      }
      layer.renderedCount = desiredCount;
    }
    for (let index = 0; index < desiredCount; index++) {
      if (Number.isFinite(layer.deathTimes[index])) {
        layer.deathTimes[index] = Number.NaN;
        layer.birthTimes[index] = elapsedTime - layer.birthSeconds * 0.72;
      }
    }
    for (let index = desiredCount; index < layer.renderedCount; index++) {
      if (!Number.isFinite(layer.deathTimes[index])) {
        layer.deathTimes[index] = elapsedTime;
        const clinicalRetraction = emitShedEvents
          && this.clinicalDetachmentAllowance > 0
          && index >= Math.ceil(clinicalRenderBoundary);
        if (clinicalRetraction) retractions.clinical++;
        else retractions.adaptive++;
        if (emitShedEvents && isClinicalDetachment({
          instanceIndex: index,
          clinicalRenderBoundary,
          shedEventsPerSecond,
          shedEventBudget: this.shedEventBudget,
          clinicalDetachmentAllowance: this.clinicalDetachmentAllowance,
        })) {
          const anchor = layer.anchors[index];
          const position = this.root.localToWorld(anchor.position.clone());
          this.pendingShedEvents.push({
            position: [position.x, position.y, position.z],
            seed: anchor.swayPhase + index,
            kind: 'blossom',
          });
          this.shedEventBudget -= 1;
          this.clinicalDetachmentAllowance -= 1;
          this.totalDetachedPetals++;
        }
      }
    }
    while (layer.renderedCount > desiredCount) {
      const tail = layer.renderedCount - 1;
      if (elapsedTime - layer.deathTimes[tail] < RETRACT_SECONDS) break;
      layer.renderedCount--;
    }

    const wind = reducedMotion ? 0.16 : 0.72;
    for (let index = 0; index < layer.renderedCount; index++) {
      const anchor = layer.anchors[index];
      const birth = smoothstep(
        (elapsedTime - layer.birthTimes[index]) / layer.birthSeconds,
        0,
        1,
      );
      const death = Number.isFinite(layer.deathTimes[index])
        ? 1 - smoothstep((elapsedTime - layer.deathTimes[index]) / RETRACT_SECONDS, 0, 1)
        : 1;
      const scale = anchor.baseScale * birth * death;
      const sway = Math.sin(elapsedTime * 0.62 + anchor.swayPhase) * 0.014 * wind;
      this.dummy.position.copy(anchor.position)
        .addScaledVector(anchor.tangent, sway)
        .addScaledVector(anchor.bitangent, sway * 0.42);
      this.dummy.quaternion.copy(anchor.quaternion);
      this.dummy.rotateZ(anchor.rotation + (1 - birth) * (reducedMotion ? 0.08 : 0.48));
      this.dummy.scale.set(
        scale,
        scale * (layer.blossom ? 1 : 1.16),
        scale,
      );
      this.dummy.updateMatrix();
      layer.mesh.setMatrixAt(index, this.dummy.matrix);
    }
    layer.mesh.count = layer.renderedCount;
    layer.mesh.instanceMatrix.needsUpdate = true;
    return retractions;
  }

  fallbackToSource(error) {
    this.disposeDynamicResources();
    if (this.sourceBlossomMesh) this.sourceBlossomMesh.visible = true;
    this.status = 'fallback';
    this.peakStatus = 'fallback';
    this.fallbackReason = error?.message || String(error);
    this.pendingShedEvents.length = 0;
    return this.snapshot();
  }

  drainShedEvents() {
    const events = this.pendingShedEvents.slice();
    this.pendingShedEvents.length = 0;
    return events;
  }

  disposeDynamicResources() {
    this.root.removeFromParent();
    if (this.peakCanopy) {
      this.peakCanopy.mesh.removeFromParent();
      this.peakCanopy.mesh.geometry.dispose();
      this.peakCanopy.mesh.material.dispose();
      this.peakCanopy = null;
    }
    for (const layer of [this.leafLayer, this.blossomLayer]) {
      if (!layer) continue;
      layer.mesh.removeFromParent();
      layer.mesh.geometry.dispose();
      layer.mesh.material.dispose();
    }
    this.leafLayer = null;
    this.blossomLayer = null;
    this.peakStatus = this.mode === 'dynamic' ? 'disposed' : 'source';
  }

  snapshot() {
    return {
      canopyStatus: this.status,
      canopyMode: this.mode,
      canopyAnchorCount: this.anchorCount,
      canopyFallbackReason: this.fallbackReason,
      activeLeafCount: this.leafLayer?.renderedCount || 0,
      activeBlossomCount: this.blossomLayer?.renderedCount || 0,
      targetLeafCount: this.leafLayer?.targetCount || 0,
      targetBlossomCount: this.blossomLayer?.targetCount || 0,
      pendingCanopyShedEvents: this.pendingShedEvents.length,
      lastCanopyShedEventCount: this.lastShedEventCount,
      totalDetachedPetals: this.totalDetachedPetals,
      clinicalLeafTargetCount: this.clinicalLeafTargetCount,
      clinicalBlossomTargetCount: this.clinicalBlossomTargetCount,
      clinicalBlossomRenderBoundary: this.clinicalBlossomRenderBoundary,
      clinicalDetachmentAllowance: this.clinicalDetachmentAllowance,
      adaptiveCanopyScale: this.adaptiveCanopyScale,
      lastAdaptiveRetractionCount: this.lastAdaptiveRetractionCount,
      totalAdaptiveRetractions: this.totalAdaptiveRetractions,
      canopyIntegrityFailures: this.integrityFailures,
      canopyLastIntegrityIssue: this.lastIntegrityIssue,
      canopyComfortMode: 'persistent-canopy-independent-of-particle-toggle',
      canopyPresentation: 'sakura-blossoms-only',
      greenLeafLayerRendered: this.renderGreenLeafLayer,
      fullBloomBlend: this.fullBloomBlend,
      authoredCanopyReveal: this.fullBloomBlend,
      fullBloomLightPulse: this.fullBloomPulse,
      bloomCelebrationCount: this.bloomCelebrationCount,
      peakCanopyStatus: this.peakStatus,
      peakCanopyCardCount: this.peakCanopy?.cardCount || 0,
      peakCanopyTriangles: this.peakCanopy?.triangleCount || 0,
    };
  }

  dispose() {
    this.disposeDynamicResources();
    if (this.sourceBlossomMesh) this.sourceBlossomMesh.visible = true;
    this.status = 'disposed';
  }
}
