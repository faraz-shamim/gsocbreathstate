export const CANOPY_QUALITY_PROFILES = Object.freeze({
  quest: Object.freeze({ maxLeaves: 900, maxBlossoms: 720 }),
  high: Object.freeze({ maxLeaves: 1400, maxBlossoms: 1080 }),
});

export function clamp(value, minimum = 0, maximum = 1) {
  return Math.min(maximum, Math.max(minimum, value));
}

export function smoothstep(value, minimum, maximum) {
  if (minimum === maximum) return value < minimum ? 0 : 1;
  const normalised = clamp((value - minimum) / (maximum - minimum));
  return normalised * normalised * (3 - 2 * normalised);
}

export function approach(current, target, rate, deltaTime) {
  return current + (target - current) * (1 - Math.exp(-rate * deltaTime));
}

export function treeCoverageTargets(vitality) {
  const value = clamp(vitality);
  return {
    leafCoverage: 0.12 + 0.88 * smoothstep(value, 0.08, 0.78),
    blossomCoverage: 0.04 + 0.96 * smoothstep(value, 0.12, 0.86),
    canopyHealth: smoothstep(value, 0.16, 0.86),
  };
}

   
                                                                                 
                                                                              
                                                                         
                                                                            
   
export function trendResponsiveCoverageTargets(vitality, coherenceTrend = 0) {
  const base = treeCoverageTargets(vitality);
  const trend = clamp(coherenceTrend, -1, 1);
  const rising = Math.max(0, trend);
  const falling = Math.max(0, -trend);
  return {
    leafCoverage: clamp(base.leafCoverage + rising * 0.1 - falling * 0.08, 0.12, 1),
    blossomCoverage: clamp(
      base.blossomCoverage + rising * 0.24 - falling * 0.2,
      0.03,
      1,
    ),
    canopyHealth: clamp(base.canopyHealth + rising * 0.12 - falling * 0.12),
  };
}

export function deterministicUnit(index, salt = 0) {
  const value = Math.sin((index + 1) * 12.9898 + (salt + 1) * 78.233) * 43758.5453;
  return value - Math.floor(value);
}

export function advanceCanopyCount(
  current,
  target,
  capacity,
  deltaTime,
  { growthRate = 0.1, declineRate = 0.07 } = {},
) {
  const safeTarget = clamp(target, 0, capacity);
  const rate = safeTarget >= current ? growthRate : declineRate;
  const maximumChange = Math.max(0, capacity * rate * Math.max(0, deltaTime));
  if (Math.abs(safeTarget - current) <= maximumChange) return safeTarget;
  return current + Math.sign(safeTarget - current) * maximumChange;
}

export function advanceFullBloomBlend(
  current,
  active,
  deltaTime,
  { enterSeconds = 4, exitSeconds = 3 } = {},
) {
  const duration = Math.max(active ? enterSeconds : exitSeconds, 0.001);
  const direction = active ? 1 : -1;
  return clamp(current + direction * Math.max(0, deltaTime) / duration);
}

export function fullBloomPulseValue(elapsed, duration = 4) {
  if (!Number.isFinite(elapsed) || elapsed < 0 || elapsed >= duration) return 0;
  const progress = clamp(elapsed / Math.max(duration, 0.001));
  return Math.sin(progress * Math.PI) ** 2;
}

export function didEnterFullBloom(active, wasActive) {
  return active === true && wasActive !== true;
}

export function clinicalShedEventRate({
  shedImpulse,
  signalAccepted,
  coverageDelta,
}) {
  if (!signalAccepted || coverageDelta >= -0.00001) return 0;
  const impulse = clamp(shedImpulse);
  if (impulse < 0.025) return 0;
  return 4 + impulse * 28;
}

export function isClinicalDetachment({
  instanceIndex,
  clinicalRenderBoundary,
  shedEventsPerSecond,
  shedEventBudget,
  clinicalDetachmentAllowance,
}) {
  return shedEventsPerSecond > 0
    && shedEventBudget >= 1
    && clinicalDetachmentAllowance >= 1
    && instanceIndex >= Math.max(0, Math.ceil(clinicalRenderBoundary));
}

export function advanceClinicalDetachmentAllowance({
  currentAllowance,
  previousClinicalTarget,
  currentClinicalTarget,
  previousPerformanceScale,
  clinicalDeclineActive,
  deltaTime,
  maximumAllowance = 24,
}) {
  if (!clinicalDeclineActive) {
    return Math.max(0, currentAllowance - Math.max(0, deltaTime) * 12);
  }
  const clinicalLoss = Math.max(
    0,
    previousClinicalTarget - currentClinicalTarget,
  ) * clamp(previousPerformanceScale, 0.1, 1);
  return clamp(currentAllowance + clinicalLoss, 0, maximumAllowance);
}

export function canopyIntegrityIssue({
  activeLeafCount,
  activeBlossomCount,
  targetLeafCount,
  targetBlossomCount,
  maxLeaves,
  maxBlossoms,
  fullBloomBlend,
  materialHealth,
} = {}) {
  const checks = [
    ['active leaves', activeLeafCount, maxLeaves],
    ['active blossoms', activeBlossomCount, maxBlossoms],
    ['target leaves', targetLeafCount, maxLeaves],
    ['target blossoms', targetBlossomCount, maxBlossoms],
  ];
  for (const [label, value, maximum] of checks) {
    if (!Number.isFinite(value) || value < 0 || value > maximum) {
      return `${label} out of range`;
    }
  }
  if (!Number.isFinite(fullBloomBlend) || fullBloomBlend < 0 || fullBloomBlend > 1) {
    return 'full-bloom reveal out of range';
  }
  if (!Number.isFinite(materialHealth) || materialHealth < 0 || materialHealth > 1) {
    return 'canopy material health out of range';
  }
  return null;
}

function positionKey(positions, index, precision) {
  const offset = index * 3;
  return [
    Math.round(positions[offset] * precision),
    Math.round(positions[offset + 1] * precision),
    Math.round(positions[offset + 2] * precision),
  ].join(':');
}

                                                                     
export function extractConnectedTriangleComponents({
  positions,
  indices = null,
  weldPrecision = 100000,
}) {
  const vertexCount = Math.floor((positions?.length || 0) / 3);
  if (!vertexCount) return [];

  const parent = new Int32Array(vertexCount);
  for (let index = 0; index < vertexCount; index++) parent[index] = index;

  const find = (value) => {
    let root = value;
    while (parent[root] !== root) root = parent[root];
    while (parent[value] !== value) {
      const next = parent[value];
      parent[value] = root;
      value = next;
    }
    return root;
  };
  const union = (left, right) => {
    const leftRoot = find(left);
    const rightRoot = find(right);
    if (leftRoot !== rightRoot) parent[rightRoot] = leftRoot;
  };

  if (!indices) {
    const welded = new Map();
    for (let index = 0; index < vertexCount; index++) {
      const key = positionKey(positions, index, weldPrecision);
      const existing = welded.get(key);
      if (existing === undefined) welded.set(key, index);
      else union(existing, index);
    }
  }

  const triangleCount = Math.floor((indices?.length || vertexCount) / 3);
  const triangleVertices = new Array(triangleCount);
  for (let triangle = 0; triangle < triangleCount; triangle++) {
    const offset = triangle * 3;
    const a = indices ? indices[offset] : offset;
    const b = indices ? indices[offset + 1] : offset + 1;
    const c = indices ? indices[offset + 2] : offset + 2;
    if (a >= vertexCount || b >= vertexCount || c >= vertexCount) continue;
    union(a, b);
    union(a, c);
    triangleVertices[triangle] = [a, b, c];
  }

  const groups = new Map();
  for (let triangle = 0; triangle < triangleVertices.length; triangle++) {
    const vertices = triangleVertices[triangle];
    if (!vertices) continue;
    const root = find(vertices[0]);
    let group = groups.get(root);
    if (!group) {
      group = { triangleIndices: [], vertexSet: new Set() };
      groups.set(root, group);
    }
    group.triangleIndices.push(triangle);
    for (const vertex of vertices) group.vertexSet.add(vertex);
  }

  return [...groups.values()]
    .map((group) => ({
      triangleIndices: group.triangleIndices,
      vertexIndices: [...group.vertexSet],
    }))
    .sort((left, right) => left.triangleIndices[0] - right.triangleIndices[0]);
}

export function shouldUseAnchorFallback(anchorCount) {
  return anchorCount < 400;
}

                                                                                
export function stratifyCanopyAnchors(anchors, { preferTips = false } = {}) {
  if (!anchors.length) return [];
  const bounds = {
    minX: Infinity,
    minY: Infinity,
    minZ: Infinity,
    maxX: -Infinity,
    maxY: -Infinity,
    maxZ: -Infinity,
  };
  for (const anchor of anchors) {
    const { x, y, z } = anchor.position;
    bounds.minX = Math.min(bounds.minX, x);
    bounds.minY = Math.min(bounds.minY, y);
    bounds.minZ = Math.min(bounds.minZ, z);
    bounds.maxX = Math.max(bounds.maxX, x);
    bounds.maxY = Math.max(bounds.maxY, y);
    bounds.maxZ = Math.max(bounds.maxZ, z);
  }
  const sizeX = Math.max(bounds.maxX - bounds.minX, 0.0001);
  const sizeY = Math.max(bounds.maxY - bounds.minY, 0.0001);
  const sizeZ = Math.max(bounds.maxZ - bounds.minZ, 0.0001);
  const centreX = (bounds.minX + bounds.maxX) * 0.5;
  const centreZ = (bounds.minZ + bounds.maxZ) * 0.5;
  const maximumRadius = Math.max(Math.hypot(sizeX, sizeZ) * 0.5, 0.0001);
  const cells = new Map();

  anchors.forEach((anchor, index) => {
    const xCell = Math.min(3, Math.floor(((anchor.position.x - bounds.minX) / sizeX) * 4));
    const yCell = Math.min(2, Math.floor(((anchor.position.y - bounds.minY) / sizeY) * 3));
    const zCell = Math.min(3, Math.floor(((anchor.position.z - bounds.minZ) / sizeZ) * 4));
    const key = `${xCell}:${yCell}:${zCell}`;
    const radial = clamp(
      Math.hypot(anchor.position.x - centreX, anchor.position.z - centreZ) / maximumRadius,
    );
    const height = clamp((anchor.position.y - bounds.minY) / sizeY);
    const score = radial * 0.7 + height * 0.3 + deterministicUnit(index, 31) * 0.08;
    if (!cells.has(key)) cells.set(key, []);
    cells.get(key).push({ index, score });
  });

  const buckets = [...cells.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([, entries]) => entries.sort((left, right) => (
      preferTips ? right.score - left.score : left.score - right.score
    )));
  const order = [];
  let depth = 0;
  while (order.length < anchors.length) {
    for (const bucket of buckets) {
      if (bucket[depth]) order.push(bucket[depth].index);
    }
    depth++;
  }
  return order;
}
