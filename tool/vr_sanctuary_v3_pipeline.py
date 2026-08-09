#!/usr/bin/env python3
"""Build-contract audit and validation for Sanctuary V3 WebXR assets."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path
from typing import Any, Iterable

from vr_scene_asset_pipeline import format_bytes, inspect_asset


DEFAULT_ROOT = Path("web/vr/assets/sanctuary_v3")
DEFAULT_MANIFEST = DEFAULT_ROOT / "manifest.json"
FORBIDDEN_RUNTIME_SUFFIXES = {
    ".blend",
    ".exr",
    ".fbx",
    ".obj",
    ".tif",
    ".tiff",
    ".usd",
    ".usda",
    ".usdc",
    ".usdz",
}
ASSET_SUFFIXES = {
    ".glb",
    ".gltf",
    ".jpg",
    ".jpeg",
    ".json",
    ".ktx2",
    ".png",
    ".webp",
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def iter_strings(value: Any) -> Iterable[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, list):
        for item in value:
            yield from iter_strings(item)
    elif isinstance(value, dict):
        for item in value.values():
            yield from iter_strings(item)


def runtime_asset_paths(manifest: dict[str, Any]) -> list[str]:
    values = []
    for value in iter_strings(manifest.get("runtimeAssets", {})):
        if Path(value).suffix.lower() in ASSET_SUFFIXES:
            values.append(Path(value).as_posix())
    return sorted(set(values))


def resolve_within(base: Path, relative: str) -> Path:
    path = (base / relative).resolve()
    try:
        path.relative_to(base.resolve())
    except ValueError as error:
        raise ValueError(f"Path escapes runtime root: {relative}") from error
    return path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def collect_runtime_files(root: Path, manifest: dict[str, Any]) -> list[Path]:
    vr_root = root.parents[1]
    files = [DEFAULT_MANIFEST.resolve() if root == DEFAULT_ROOT else (root / "manifest.json").resolve()]
    files.extend(resolve_within(root, path) for path in runtime_asset_paths(manifest))

    for dependency_root in manifest.get("buildPipeline", {}).get("dependencyRoots", []):
        dependency_path = (vr_root / dependency_root).resolve()
        try:
            dependency_path.relative_to(vr_root.resolve())
        except ValueError as error:
            raise ValueError(f"Dependency root escapes web/vr: {dependency_root}") from error
        if dependency_path.is_dir():
            files.extend(path for path in dependency_path.rglob("*") if path.is_file())
        elif dependency_path.exists():
            files.append(dependency_path)

    for dependency in manifest.get("buildPipeline", {}).get("runtimeDependencies", []):
        path = (vr_root / dependency).resolve()
        try:
            path.relative_to(vr_root.resolve())
        except ValueError as error:
            raise ValueError(f"Runtime dependency escapes web/vr: {dependency}") from error
        files.append(path)

    return sorted(set(files))


def build_inventory(root: Path, manifest: dict[str, Any]) -> dict[str, Any]:
    vr_root = root.parents[1].resolve()
    records = []
    for path in collect_runtime_files(root, manifest):
        if not path.exists():
            continue
        info = inspect_asset(path)
        record = {
            "path": path.resolve().relative_to(vr_root).as_posix(),
            "bytes": path.stat().st_size,
            "sha256": sha256(path),
            "type": info.get("type"),
        }
        for key in ("triangles", "vertices", "materials", "images", "extensionsUsed"):
            if info.get(key) is not None:
                record[key] = info[key]
        records.append(record)
    return {
        "version": 1,
        "assetPackage": manifest.get("assetPackage"),
        "manifestVersion": manifest.get("version"),
        "files": records,
    }


def validate_inventory(root: Path, manifest: dict[str, Any]) -> list[str]:
    inventory_path = root / manifest.get("buildPipeline", {}).get("inventory", "inventory.json")
    if not inventory_path.exists():
        return [f"Missing runtime inventory: {inventory_path}"]
    expected = load_json(inventory_path)
    actual = build_inventory(root, manifest)
    return [] if expected == actual else ["Runtime inventory is stale; regenerate it."]


def validate(root: Path, manifest_path: Path, manifest: dict[str, Any], strict: bool) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    vr_root = root.parents[1]

    for value in iter_strings(manifest):
        if value.startswith(("http://", "https://", "//")):
            errors.append(f"Remote runtime URL is forbidden: {value}")

    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in FORBIDDEN_RUNTIME_SUFFIXES:
            errors.append(f"Forbidden source format in runtime package: {path}")

    assets = runtime_asset_paths(manifest)
    for relative in assets:
        try:
            path = resolve_within(root, relative)
        except ValueError as error:
            errors.append(str(error))
            continue
        if not path.exists():
            errors.append(f"Missing runtime asset: {relative}")

    budget_assets = manifest.get("assetBudgets", {}).get("assets", {})
    for relative, budget in budget_assets.items():
        try:
            path = resolve_within(root, relative)
        except ValueError as error:
            errors.append(str(error))
            continue
        if not path.exists():
            errors.append(f"Missing budgeted asset: {relative}")
            continue
        info = inspect_asset(path)
        if budget.get("maxBytes") and info.get("bytes", 0) > budget["maxBytes"]:
            errors.append(
                f"{relative} exceeds size budget: {format_bytes(info['bytes'])} > "
                f"{format_bytes(budget['maxBytes'])}"
            )
        if budget.get("maxTriangles") and info.get("triangles", 0) > budget["maxTriangles"]:
            errors.append(
                f"{relative} exceeds triangle budget: {info['triangles']} > {budget['maxTriangles']}"
            )
        extensions = set(info.get("extensionsUsed", []))
        for extension in budget.get("requiredExtensions", []):
            if extension not in extensions:
                errors.append(f"{relative} is missing required extension {extension}")

    package_budget = manifest.get("assetBudgets", {}).get("maxRuntimeAssetBytes")
    runtime_bytes = sum(
        resolve_within(root, relative).stat().st_size
        for relative in assets
        if resolve_within(root, relative).exists()
    )
    if package_budget and runtime_bytes > package_budget:
        errors.append(
            f"Runtime assets exceed package budget: {format_bytes(runtime_bytes)} > "
            f"{format_bytes(package_budget)}"
        )

    html_path = vr_root / "webxr_scene.html"
    if html_path.exists():
        html = html_path.read_text(encoding="utf-8")
        if "unpkg.com" in html or "https://" in html or "http://" in html:
            errors.append("webxr_scene.html import map must not use remote runtime modules.")
    elif strict:
        errors.append(f"Missing WebXR entry page: {html_path}")

    for path in collect_runtime_files(root, manifest):
        if not path.exists():
            errors.append(f"Missing runtime dependency: {path}")

    if manifest_path.resolve() != (root / "manifest.json").resolve():
        warnings.append("Manifest is outside the runtime root; inventory records root/manifest.json.")
    return errors, warnings


def print_audit(root: Path, manifest: dict[str, Any]) -> None:
    print(f"Sanctuary package: {manifest.get('assetPackage')} v{manifest.get('version')}")
    print(f"Phase: {manifest.get('phase')} | Status: {manifest.get('status')}")
    print(f"Root: {root}")
    print("Runtime assets:")
    for relative in runtime_asset_paths(manifest):
        path = resolve_within(root, relative)
        if not path.exists():
            print(f"  - {relative}: MISSING")
            continue
        info = inspect_asset(path)
        details = [format_bytes(info.get("bytes"))]
        if info.get("triangles") is not None:
            details.append(f"{info['triangles']} tris")
        if info.get("extensionsUsed"):
            details.append("extensions=" + ",".join(info["extensionsUsed"]))
        print(f"  - {relative}: {', '.join(details)}")
    print("Tools:")
    npx = shutil.which("npx") or shutil.which("npx.cmd")
    tool_status = {
        "blender": shutil.which("blender") or "not installed",
        "gltf-transform": shutil.which("gltf-transform")
        or ("pinned @gltf-transform/cli@4.4.1 via npx" if npx else "not installed"),
        "toktx": shutil.which("toktx") or "not installed (WebP fallback remains available)",
    }
    for command, status in tool_status.items():
        print(f"  - {command}: {status}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--write-inventory", action="store_true")
    parser.add_argument("--check-inventory", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    manifest_path = args.manifest.resolve()
    manifest = load_json(manifest_path)

    if args.write_inventory:
        inventory = build_inventory(root, manifest)
        inventory_path = root / manifest.get("buildPipeline", {}).get("inventory", "inventory.json")
        inventory_path.write_text(
            json.dumps(inventory, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {inventory_path}")

    if args.audit or not any((args.validate, args.write_inventory, args.check_inventory)):
        print_audit(root, manifest)

    errors: list[str] = []
    warnings: list[str] = []
    if args.validate:
        errors, warnings = validate(root, manifest_path, manifest, args.strict)
    if args.check_inventory:
        errors.extend(validate_inventory(root, manifest))

    for warning in warnings:
        print(f"WARNING: {warning}", file=sys.stderr)
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if errors:
        return 1
    if args.validate or args.check_inventory:
        print("Sanctuary V3 validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
