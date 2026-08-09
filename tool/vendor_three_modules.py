#!/usr/bin/env python3
"""Vendor the minimal Three.js module graph used by BreathState WebXR."""

from __future__ import annotations

import argparse
import re
import shutil
from collections import deque
from pathlib import Path


THREE_VERSION = "0.164.1"
ENTRY_MODULES = (
    "loaders/GLTFLoader.js",
    "loaders/FBXLoader.js",
    "loaders/OBJLoader.js",
    "loaders/KTX2Loader.js",
    "loaders/DRACOLoader.js",
    "loaders/EXRLoader.js",
    "libs/meshopt_decoder.module.js",
    "webxr/VRButton.js",
)
RELATIVE_JS = re.compile(r"['\"](\.{1,2}/[^'\"]+\.js)['\"]")


def copy_module_graph(source_jsm: Path, target_jsm: Path) -> list[str]:
    queue = deque(ENTRY_MODULES)
    copied: set[str] = set()

    while queue:
        relative = Path(queue.popleft()).as_posix()
        if relative in copied:
            continue
        source = (source_jsm / relative).resolve()
        try:
            source.relative_to(source_jsm.resolve())
        except ValueError as error:
            raise ValueError(f"Three.js import escapes examples/jsm: {relative}") from error
        if not source.exists():
            raise FileNotFoundError(f"Missing Three.js module: {source}")

        destination = target_jsm / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        copied.add(relative)

        text = source.read_text(encoding="utf-8")
        for dependency in RELATIVE_JS.findall(text):
            resolved = (source.parent / dependency).resolve()
            try:
                queue.append(resolved.relative_to(source_jsm.resolve()).as_posix())
            except ValueError as error:
                raise ValueError(f"Three.js dependency escapes examples/jsm: {dependency}") from error

    return sorted(copied)


def verify_imports(target_jsm: Path, modules: list[str]) -> None:
    for relative in modules:
        module_path = target_jsm / relative
        text = module_path.read_text(encoding="utf-8")
        for dependency in RELATIVE_JS.findall(text):
            resolved = (module_path.parent / dependency).resolve()
            if not resolved.exists():
                raise FileNotFoundError(
                    f"Vendored module {relative} has missing dependency {dependency}"
                )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-package",
        type=Path,
        required=True,
        help="Extracted npm three package directory containing build/ and examples/.",
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=Path(f"web/vr/vendor/three/{THREE_VERSION}"),
        help="Vendored Three.js destination.",
    )
    args = parser.parse_args()

    source_package = args.source_package.resolve()
    target = args.target.resolve()
    source_jsm = source_package / "examples" / "jsm"
    target_jsm = target / "examples" / "jsm"

    core_source = source_package / "build" / "three.module.js"
    if not core_source.exists():
        raise FileNotFoundError(f"Missing Three.js core module: {core_source}")
    (target / "build").mkdir(parents=True, exist_ok=True)
    shutil.copy2(core_source, target / "build" / "three.module.js")

    license_source = source_package / "LICENSE"
    if license_source.exists():
        shutil.copy2(license_source, target / "LICENSE")

    modules = copy_module_graph(source_jsm, target_jsm)
    verify_imports(target_jsm, modules)
    (target / "VERSION").write_text(f"{THREE_VERSION}\n", encoding="ascii")
    print(f"Vendored Three.js {THREE_VERSION}: {len(modules)} addon modules.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
