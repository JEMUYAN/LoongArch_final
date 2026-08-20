#!/usr/bin/env python3
"""Validate a post-run 12 KiB ExtRAM image for this exercise."""
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

actual_count = struct.unpack_from("<I", actual, 0x1000)[0]
expected_count = struct.unpack_from("<I", expected, 0x1000)[0]
if actual_count != expected_count:
    raise SystemExit(f"FAIL: count=0x{actual_count:08x}, expected {expected_count}")

used = expected_count * 4
actual_b = actual[0x2000:0x2000 + used]
expected_b = expected[0x2000:0x2000 + used]
if actual_b != expected_b:
    for index in range(expected_count):
        got = struct.unpack_from("<I", actual_b, index * 4)[0]
        want = struct.unpack_from("<I", expected_b, index * 4)[0]
        if got != want:
            raise SystemExit(
                f"FAIL: B[{index}]=0x{got:08x}, expected 0x{want:08x}"
            )
    raise SystemExit("FAIL: output bytes differ")

print(f"PASS: count={expected_count}; stable filtered output matches")
