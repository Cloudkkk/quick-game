"""Prepare a Godot export for static hosting with gzip response headers."""
from pathlib import Path
import gzip
import sys
import shutil

root = Path(sys.argv[1])
wasm = root / "index.wasm"
raw = wasm.read_bytes()
if raw[:4] != b"\x00asm":
    raise SystemExit("Expected freshly exported uncompressed WASM")
packed = gzip.compress(raw, compresslevel=9, mtime=0)
assert gzip.decompress(packed) == raw
wasm.write_bytes(packed)
(root / "_headers").write_text(
    "/index.wasm\n"
    "  Content-Type: application/wasm\n"
    "  Content-Encoding: gzip\n"
    "/index.pck\n"
    "  Content-Type: application/octet-stream\n"
)
print("WASM_RAW_BYTES", len(raw), "WASM_GZIP_BYTES", len(packed))

shutil.copy2(Path(__file__).with_name("wasm-loader.js"), root / "wasm-loader.js")

project_root = Path(__file__).resolve().parent.parent
for source, name in [
    (project_root / "assets/fonts/OFL.txt", "FONT-OFL.txt"),
    (project_root / "assets/fonts/COPYRIGHT.txt", "FONT-COPYRIGHT.txt"),
    (project_root / "assets/sounds/LICENSE.txt", "SOUND-LICENSE.txt"),
]:
    if source.is_file():
        shutil.copy2(source, root / name)
