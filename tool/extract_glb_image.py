"""Extract an embedded image from a binary glTF without importing the model."""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path


GLB_MAGIC = b"glTF"
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942


def extract_image(input_path: Path, output_path: Path, image_index: int) -> None:
    data = input_path.read_bytes()
    magic, version, declared_length = struct.unpack_from("<4sII", data, 0)
    if magic != GLB_MAGIC or version != 2 or declared_length != len(data):
        raise ValueError(f"{input_path} is not a valid GLB 2.0 file")

    chunks: dict[int, bytes] = {}
    offset = 12
    while offset < len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunks[chunk_type] = data[offset : offset + chunk_length]
        offset += chunk_length

    document = json.loads(chunks[JSON_CHUNK].decode("utf-8").rstrip("\x00 \t\r\n"))
    images = document.get("images", [])
    if image_index < 0 or image_index >= len(images):
        raise IndexError(f"image index {image_index} is outside 0..{len(images) - 1}")

    image = images[image_index]
    if "bufferView" not in image:
        raise ValueError("Only embedded bufferView images are supported")
    view = document["bufferViews"][image["bufferView"]]
    if view.get("buffer", 0) != 0:
        raise ValueError("Only the primary GLB binary buffer is supported")

    binary = chunks[BIN_CHUNK]
    start = view.get("byteOffset", 0)
    end = start + view["byteLength"]
    if end > len(binary):
        raise ValueError("Embedded image range exceeds the GLB binary chunk")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(binary[start:end])
    print(
        f"Extracted image {image_index} ({image.get('mimeType', 'unknown')}, "
        f"{end - start} bytes) to {output_path}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--image-index", type=int, default=0)
    args = parser.parse_args()
    extract_image(args.input, args.output, args.image_index)


if __name__ == "__main__":
    main()
