#!/usr/bin/env python3
"""Check an ExtRAM dump for insertion_sort_u32_128."""
from pathlib import Path
import struct
import sys

N = 128
IN_OFFSET = 0x0000
OUT_OFFSET = 0x1000

if len(sys.argv) != 2:
    raise SystemExit(f"usage: {Path(sys.argv[0]).name} <extram_dump.bin>")

dump = Path(sys.argv[1]).read_bytes()
need = OUT_OFFSET + N * 4
if len(dump) < need:
    raise SystemExit(f"FAIL: dump too short ({len(dump)} bytes; need at least {need})")

expected = (Path(__file__).with_name("expected_u32_le.bin")).read_bytes()
actual = dump[OUT_OFFSET:OUT_OFFSET + N * 4]

for i, (got, want) in enumerate(zip(
        struct.unpack("<%dI" % N, actual), struct.unpack("<%dI" % N, expected))):
    if got != want:
        raise SystemExit(f"FAIL: B[{i}]=0x{got:08x}, expected 0x{want:08x}")

original = Path(__file__).resolve().parent.parent / "input_u32_le.bin"
if dump[IN_OFFSET:IN_OFFSET + N * 4] != original.read_bytes():
    raise SystemExit("FAIL: input A was modified")
print("PASS: B[0..127] is the unsigned ascending sort of A; A is unchanged")
