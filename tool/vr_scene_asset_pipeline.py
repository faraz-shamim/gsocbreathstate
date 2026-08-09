#!/usr/bin/env python3
"""Audit and validate BreathState WebXR scene_v2 assets.

Phase 1 of the Quest optimization work is intentionally non-destructive:
this script inventories the current local assets, checks source availability,
and validates optimized outputs when they exist. Later phases can add build
steps that generate the optimized GLB/KTX2/WebP assets listed in the manifest.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import Any

try:
    from PIL import Image
except Exception:  # pragma: no cover - optional local dependency
    Image = None


DEFAULT_ROOT = Path("web/vr/assets/scene_v2")
DEFAULT_MANIFEST = DEFAULT_ROOT / "manifest.json"
ASSET_SUFFIXES = {
    ".blend",
    ".fbx",
    ".glb",
    ".hdr",
    ".obj",
    ".webp",
    ".ktx2",
    ".exr",
    ".jpg",
    ".jpeg",
    ".png",
}


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def read_glb_json(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError(f"{path} is too small to be a GLB")

    magic, _version, _length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF":
        raise ValueError(f"{path} is not a GLB file")

    offset = 12
    while offset + 8 <= len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset:offset + chunk_length]
        offset += chunk_length
        if chunk_type == 0x4E4F534A:
            return json.loads(chunk.decode("utf-8"))

    raise ValueError(f"{path} has no JSON chunk")


def inspect_glb(path: Path) -> dict[str, Any]:
    gltf = read_glb_json(path)
    vertices = 0
    triangles = 0
    primitives = 0

    for mesh in gltf.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            primitives += 1
            attributes = primitive.get("attributes", {})
            position_accessor = attributes.get("POSITION")
            if position_accessor is not None:
                vertices += gltf["accessors"][position_accessor].get("count", 0)
            index_accessor = primitive.get("indices")
            if index_accessor is not None:
                triangles += gltf["accessors"][index_accessor].get("count", 0) // 3

    return {
        "type": "glb",
        "bytes": path.stat().st_size,
        "nodes": len(gltf.get("nodes", [])),
        "meshes": len(gltf.get("meshes", [])),
        "materials": len(gltf.get("materials", [])),
        "images": len(gltf.get("images", [])),
        "primitives": primitives,
        "vertices": vertices,
        "triangles": triangles,
        "extensionsUsed": gltf.get("extensionsUsed", []),
        "extensionsRequired": gltf.get("extensionsRequired", []),
    }


def inspect_image(path: Path) -> dict[str, Any]:
    result: dict[str, Any] = {
        "type": path.suffix.lower().lstrip("."),
        "bytes": path.stat().st_size,
    }
    if Image is None:
        return result
    try:
        with Image.open(path) as image:
            result.update({
                "width": image.width,
                "height": image.height,
                "mode": image.mode,
            })
    except Exception:
        result["note"] = "dimensions unavailable"
    return result


def inspect_asset(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"missing": True}
    if path.is_dir():
        files = [item for item in path.rglob("*") if item.is_file()]
        return {
            "type": "directory",
            "bytes": sum(item.stat().st_size for item in files),
            "files": len(files),
        }
    suffix = path.suffix.lower()
    if suffix == ".glb":
        return inspect_glb(path)
    if suffix in {".webp", ".jpg", ".jpeg", ".png", ".ktx2", ".exr"}:
        return inspect_image(path)
    return {
        "type": suffix.lstrip(".") or "unknown",
        "bytes": path.stat().st_size,
    }


def iter_manifest_asset_paths(manifest: dict[str, Any]) -> dict[str, str]:
    assets: dict[str, str] = {}

    def looks_like_asset_reference(value: str) -> bool:
        return value == "sakura" or Path(value).suffix.lower() in ASSET_SUFFIXES

    def add(label: str, value: Any) -> None:
        if isinstance(value, str):
            if looks_like_asset_reference(value):
                assets[label] = value
        elif isinstance(value, list):
            for index, item in enumerate(value):
                add(f"{label}[{index}]", item)
        elif isinstance(value, dict):
            for key, item in value.items():
                add(f"{label}.{key}", item)

    add("sourceAssets", manifest.get("sourceAssets", {}))
    add("generatedAssets.current", manifest.get("generatedAssets", {}).get("current", []))
    add("generatedAssets.planned", manifest.get("generatedAssets", {}).get("planned", []))
    add("runtimeProfiles", manifest.get("runtimeProfiles", {}))
    add("fallbackFiles", manifest.get("fallbackFiles", []))
    return assets


def audit_assets(root: Path, manifest: dict[str, Any]) -> dict[str, Any]:
    assets: dict[str, Any] = {}
    manifest_paths = iter_manifest_asset_paths(manifest)
    unique_paths = sorted(set(manifest_paths.values()))
    for relative in unique_paths:
        if not relative or relative.startswith("quality="):
            continue
        path = root / relative
        assets[relative] = inspect_asset(path)

    current_files: dict[str, Any] = {}
    for path in sorted(root.glob("*")):
        if path.is_file():
            current_files[path.name] = inspect_asset(path)

    return {
        "assetPackage": manifest.get("assetPackage"),
        "version": manifest.get("version"),
        "root": str(root),
        "manifestAssetCount": len(assets),
        "assets": assets,
        "currentTopLevelFiles": current_files,
    }


def format_bytes(value: int | None) -> str:
    if value is None:
        return "n/a"
    units = ["B", "KB", "MB", "GB"]
    amount = float(value)
    for unit in units:
        if amount < 1024 or unit == units[-1]:
            return f"{amount:.1f} {unit}" if unit != "B" else f"{int(amount)} B"
        amount /= 1024
    return f"{value} B"


def validate_assets(root: Path, manifest: dict[str, Any], strict: bool = False) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    budgets = manifest.get("assetBudgets", {})
    generated = manifest.get("generatedAssets", {})
    current = generated.get("current", [])
    planned = generated.get("planned", [])
    source_assets = manifest.get("sourceAssets", {})

    def require(path_value: str, label: str) -> None:
        if not (root / path_value).exists():
            errors.append(f"Missing required {label}: {path_value}")

    for label, path_value in source_assets.items():
        if isinstance(path_value, str):
            require(path_value, f"source asset {label}")

    for path_value in current:
        path = root / path_value
        if not path.exists():
            errors.append(f"Missing current generated asset: {path_value}")

    repo_root = root.parents[3] if len(root.parents) >= 4 else Path(".")
    for group, paths in manifest.get("runtimeDecoders", {}).items():
        if isinstance(paths, str):
            paths = [paths]
        if not isinstance(paths, list):
            continue
        for decoder in paths:
            if not isinstance(decoder, str) or not decoder.startswith("../"):
                continue
            decoder_path = (root / decoder).resolve()
            try:
                decoder_path.relative_to(repo_root.resolve())
            except ValueError:
                errors.append(f"Decoder path escapes repo: {decoder}")
                continue
            if not decoder_path.exists():
                errors.append(f"Missing runtime decoder {group}: {decoder}")

    for path_value in [*current, *planned]:
        path = root / path_value
        if not path.exists():
            message = f"Planned optimized asset not generated yet: {path_value}"
            if strict:
                errors.append(message)
            else:
                warnings.append(message)
            continue

        info = inspect_asset(path)
        if path_value.startswith("sakura_quest_lod0"):
            max_triangles = budgets.get("sakuraTree", {}).get("lod0MaxTriangles")
            if max_triangles and info.get("triangles", 0) > max_triangles:
                errors.append(f"{path_value} exceeds LOD0 triangle budget: {info.get('triangles')} > {max_triangles}")
        if path_value.startswith("sakura_quest_lod1"):
            max_triangles = budgets.get("sakuraTree", {}).get("lod1MaxTriangles")
            if max_triangles and info.get("triangles", 0) > max_triangles:
                errors.append(f"{path_value} exceeds LOD1 triangle budget: {info.get('triangles')} > {max_triangles}")
        if path_value.startswith("moon_quest"):
            max_bytes = budgets.get("moon", {}).get("maxBytes")
            if max_bytes and info.get("bytes", 0) > max_bytes:
                errors.append(f"{path_value} exceeds moon size budget: {format_bytes(info.get('bytes'))} > {format_bytes(max_bytes)}")
        if path_value.startswith("aurora_quest"):
            max_bytes = budgets.get("aurora", {}).get("maxBytes")
            if max_bytes and info.get("bytes", 0) > max_bytes:
                errors.append(f"{path_value} exceeds aurora size budget: {format_bytes(info.get('bytes'))} > {format_bytes(max_bytes)}")
        if path_value.startswith("nightsky_quest"):
            max_bytes = budgets.get("nightSky", {}).get("questMaxBytes")
            if max_bytes and info.get("bytes", 0) > max_bytes:
                errors.append(f"{path_value} exceeds quest sky budget: {format_bytes(info.get('bytes'))} > {format_bytes(max_bytes)}")
        if path_value.startswith("night_sky_quest"):
            max_bytes = budgets.get("nightSky", {}).get("modelMaxBytes")
            if max_bytes and info.get("bytes", 0) > max_bytes:
                errors.append(f"{path_value} exceeds quest sky model budget: {format_bytes(info.get('bytes'))} > {format_bytes(max_bytes)}")

    return errors, warnings


def print_audit(report: dict[str, Any]) -> None:
    print(f"Scene package: {report['assetPackage']} v{report['version']}")
    print(f"Root: {report['root']}")
    print("")
    print("Manifest assets:")
    for name, info in report["assets"].items():
        if info.get("missing"):
            print(f"  - {name}: MISSING")
            continue
        details = [format_bytes(info.get("bytes"))]
        if info.get("triangles") is not None:
            details.append(f"{info['triangles']} tris")
        if info.get("width") and info.get("height"):
            details.append(f"{info['width']}x{info['height']}")
        if info.get("extensionsUsed"):
            details.append("extensions=" + ",".join(info["extensionsUsed"]))
        print(f"  - {name}: {', '.join(details)}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit BreathState WebXR scene_v2 assets.")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="Scene asset directory.")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST, help="Scene manifest path.")
    parser.add_argument("--audit", action="store_true", help="Print a human-readable asset audit.")
    parser.add_argument("--json", action="store_true", help="Print audit as JSON.")
    parser.add_argument("--validate", action="store_true", help="Validate required sources and generated asset budgets.")
    parser.add_argument("--strict", action="store_true", help="Treat missing planned optimized assets as errors.")
    args = parser.parse_args()

    manifest = load_manifest(args.manifest)
    report = audit_assets(args.root, manifest)

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_audit(report)

    if args.validate:
        errors, warnings = validate_assets(args.root, manifest, args.strict)
        for warning in warnings:
            print(f"WARNING: {warning}", file=sys.stderr)
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        if errors:
            return 1
        print("Validation passed.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
