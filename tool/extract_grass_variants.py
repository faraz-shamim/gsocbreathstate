"""Extract intact lightweight grass components from the supplied dense GLB."""

from __future__ import annotations

import argparse
import json
import math
import struct
from array import array
from collections import defaultdict
from pathlib import Path


JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942
COMPONENT_FORMATS = {5123: "H", 5125: "I", 5126: "f"}
TYPE_SIZES = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise ValueError(f"Invalid GLB 2.0 file: {path}")
    document = None
    binary = None
    offset = 12
    while offset < len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset : offset + chunk_length]
        offset += chunk_length
        if chunk_type == JSON_CHUNK:
            document = json.loads(chunk.decode("utf-8").rstrip("\x00 \t\r\n"))
        elif chunk_type == BIN_CHUNK:
            binary = chunk
    if document is None or binary is None:
        raise ValueError("GLB is missing JSON or binary data")
    return document, binary


def read_accessor(document: dict, binary: bytes, accessor_index: int) -> list[tuple]:
    accessor = document["accessors"][accessor_index]
    view = document["bufferViews"][accessor["bufferView"]]
    component_type = accessor["componentType"]
    component_format = COMPONENT_FORMATS[component_type]
    component_size = struct.calcsize(component_format)
    width = TYPE_SIZES[accessor["type"]]
    packed = struct.Struct("<" + component_format * width)
    stride = view.get("byteStride", component_size * width)
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    return [packed.unpack_from(binary, start + index * stride) for index in range(accessor["count"])]


def connected_components(indices: list[int], vertex_count: int) -> dict[int, list[tuple[int, int, int]]]:
    parent = list(range(vertex_count))
    sizes = [1] * vertex_count

    def find(value: int) -> int:
        while parent[value] != value:
            parent[value] = parent[parent[value]]
            value = parent[value]
        return value

    def union(left: int, right: int) -> None:
        left = find(left)
        right = find(right)
        if left == right:
            return
        if sizes[left] < sizes[right]:
            left, right = right, left
        parent[right] = left
        sizes[left] += sizes[right]

    for offset in range(0, len(indices), 3):
        a, b, c = indices[offset : offset + 3]
        union(a, b)
        union(a, c)

    components: dict[int, list[tuple[int, int, int]]] = defaultdict(list)
    for offset in range(0, len(indices), 3):
        triangle = tuple(indices[offset : offset + 3])
        components[find(triangle[0])].append(triangle)
    return components


def component_record(root: int, triangles: list[tuple[int, int, int]], positions: list[tuple]) -> dict:
    vertices = sorted({index for triangle in triangles for index in triangle})
    xs = [positions[index][0] for index in vertices]
    ys = [positions[index][1] for index in vertices]
    zs = [positions[index][2] for index in vertices]
    return {
        "root": root,
        "triangles": triangles,
        "vertices": vertices,
        "height": max(ys) - min(ys),
        "width": max(xs) - min(xs),
        "depth": max(zs) - min(zs),
        "min_y": min(ys),
    }


def select_variants(records: list[dict]) -> list[dict]:
    candidates = [
        record
        for record in records
        if record["height"] >= 0.28
        and len(record["triangles"]) >= 10
        and max(record["width"], record["depth"]) <= 0.9
    ]
    if len(candidates) < 3:
        raise ValueError("Dense grass source does not contain three usable components")
    candidates.sort(key=lambda record: record["height"])
    targets = [0.25, 0.58, 0.9]
    selected = []
    for target in targets:
        desired = candidates[round((len(candidates) - 1) * target)]["height"]
        choice = min(
            (record for record in candidates if record not in selected),
            key=lambda record: abs(record["height"] - desired),
        )
        selected.append(choice)
    return selected


def align4(buffer: bytearray) -> None:
    while len(buffer) % 4:
        buffer.append(0)


def write_variants(
    output: Path,
    selected: list[dict],
    positions: list[tuple],
    normals: list[tuple],
    texcoords: list[tuple],
) -> None:
    binary = bytearray()
    buffer_views = []
    accessors = []
    meshes = []
    nodes = []

    def add_buffer_view(payload: bytes, target: int) -> int:
        align4(binary)
        offset = len(binary)
        binary.extend(payload)
        buffer_views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(payload), "target": target})
        return len(buffer_views) - 1

    def add_accessor(view: int, component_type: int, count: int, accessor_type: str, values=None) -> int:
        accessor = {
            "bufferView": view,
            "componentType": component_type,
            "count": count,
            "type": accessor_type,
        }
        if values is not None:
            dimensions = list(zip(*values))
            accessor["min"] = [min(axis) for axis in dimensions]
            accessor["max"] = [max(axis) for axis in dimensions]
        accessors.append(accessor)
        return len(accessors) - 1

    for variant_index, record in enumerate(selected):
        source_vertices = record["vertices"]
        remap = {source: index for index, source in enumerate(source_vertices)}
        variant_positions = [positions[index] for index in source_vertices]
        variant_normals = [normals[index] for index in source_vertices]
        variant_uvs = [texcoords[index] for index in source_vertices]
        center_x = sum(value[0] for value in variant_positions) / len(variant_positions)
        center_z = sum(value[2] for value in variant_positions) / len(variant_positions)
        min_y = min(value[1] for value in variant_positions)
        variant_positions = [
            (value[0] - center_x, value[1] - min_y, value[2] - center_z)
            for value in variant_positions
        ]
        variant_indices = [
            remap[index]
            for triangle in record["triangles"]
            for index in triangle
        ]

        position_payload = b"".join(struct.pack("<3f", *value) for value in variant_positions)
        normal_payload = b"".join(struct.pack("<3f", *value) for value in variant_normals)
        uv_payload = b"".join(struct.pack("<2f", *value) for value in variant_uvs)
        index_component = 5123 if len(source_vertices) <= 65535 else 5125
        index_format = "H" if index_component == 5123 else "I"
        index_payload = array(index_format, variant_indices).tobytes()

        position_accessor = add_accessor(
            add_buffer_view(position_payload, 34962), 5126, len(variant_positions), "VEC3", variant_positions
        )
        normal_accessor = add_accessor(
            add_buffer_view(normal_payload, 34962), 5126, len(variant_normals), "VEC3"
        )
        uv_accessor = add_accessor(
            add_buffer_view(uv_payload, 34962), 5126, len(variant_uvs), "VEC2"
        )
        index_accessor = add_accessor(
            add_buffer_view(index_payload, 34963), index_component, len(variant_indices), "SCALAR"
        )
        meshes.append({
            "name": f"AnimatedGrassVariant_{variant_index + 1}",
            "primitives": [{
                "attributes": {
                    "POSITION": position_accessor,
                    "NORMAL": normal_accessor,
                    "TEXCOORD_0": uv_accessor,
                },
                "indices": index_accessor,
                "material": 0,
            }],
        })
        nodes.append({"name": f"AnimatedGrassVariant_{variant_index + 1}", "mesh": variant_index})

    document = {
        "asset": {"version": "2.0", "generator": "BreathState grass variant extractor"},
        "scene": 0,
        "scenes": [{"nodes": list(range(len(nodes)))}],
        "nodes": nodes,
        "meshes": meshes,
        "materials": [{
            "name": "BreathState_Animated_Grass",
            "doubleSided": True,
            "pbrMetallicRoughness": {
                "baseColorFactor": [0.18, 0.48, 0.2, 1.0],
                "metallicFactor": 0,
                "roughnessFactor": 0.94,
            },
        }],
        "buffers": [{"byteLength": len(binary)}],
        "bufferViews": buffer_views,
        "accessors": accessors,
    }
    json_payload = json.dumps(document, separators=(",", ":")).encode("utf-8")
    while len(json_payload) % 4:
        json_payload += b" "
    align4(binary)
    total_length = 12 + 8 + len(json_payload) + 8 + len(binary)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(
        struct.pack("<4sII", b"glTF", 2, total_length)
        + struct.pack("<II", len(json_payload), JSON_CHUNK)
        + json_payload
        + struct.pack("<II", len(binary), BIN_CHUNK)
        + binary
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    document, binary = read_glb(args.input)
    primitive = document["meshes"][0]["primitives"][0]
    positions = read_accessor(document, binary, primitive["attributes"]["POSITION"])
    normals = read_accessor(document, binary, primitive["attributes"]["NORMAL"])
    texcoords = read_accessor(document, binary, primitive["attributes"]["TEXCOORD_0"])
    indices = [value[0] for value in read_accessor(document, binary, primitive["indices"])]
    components = connected_components(indices, len(positions))
    records = [component_record(root, triangles, positions) for root, triangles in components.items()]
    selected = select_variants(records)
    write_variants(args.output, selected, positions, normals, texcoords)
    summary = ", ".join(
        f"{len(record['triangles'])} tris/{record['height']:.2f}m"
        for record in selected
    )
    print(f"Wrote {args.output} with variants: {summary}")


if __name__ == "__main__":
    main()
