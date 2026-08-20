#!/usr/bin/env python3
"""Validate the 128 lower_bound indices in an ExtRAM dump."""
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
for index in range(128):
    got = struct.unpack_from("<I", actual, 0x2000 + 4 * index)[0]
    want = struct.unpack_from("<I", expected, 0x2000 + 4 * index)[0]
    if got != want:
        raise SystemExit(f"FAIL: index[{index}]={got}, expected {want}")
print("PASS: all 128 lower_bound indices match")
