#!/usr/bin/env python3
"""Validate quotient and remainder regions in a post-run ExtRAM dump."""
from argparse import ArgumentParser
from pathlib import Path
import struct

parser = ArgumentParser()
parser.add_argument("image", type=Path, help="ExtRAM dump beginning at 0x1c400000")
args = parser.parse_args()

actual = args.image.read_bytes()
expected = (Path(__file__).parent / "extram_expected.bin").read_bytes()
if len(actual) < 0x3000:
    raise SystemExit(f"image too short: {len(actual)} B, need at least 12288 B")

for name, offset in (("Q", 0x1000), ("R", 0x2000)):
    for index in range(128):
        got = struct.unpack_from("<I", actual, offset + 4 * index)[0]
        want = struct.unpack_from("<I", expected, offset + 4 * index)[0]
        if got != want:
            raise SystemExit(
                f"FAIL: {name}[{index}]=0x{got:08x}, expected 0x{want:08x}"
            )
print("PASS: all 128 unsigned quotient/remainder pairs match")
