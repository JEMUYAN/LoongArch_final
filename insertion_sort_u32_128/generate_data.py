#!/usr/bin/env python3
"""Generate a deterministic ExtRAM image for this exercise."""
from pathlib import Path
import random
import struct

N = 128
IN_OFFSET = 0x0000
OUT_OFFSET = 0x1000

# Include duplicates and unsigned boundary values; do not rely on signed ordering.
edge = [0, 1, 2, 0x7fffffff, 0x80000000, 0x80000001, 0xfffffffe, 0xffffffff]
rng = random.Random(20260821)
values = edge + [rng.getrandbits(32) for _ in range(N - len(edge))]
rng.shuffle(values)

root = Path(__file__).resolve().parent
(root / "input_u32_le.bin").write_bytes(struct.pack("<%dI" % N, *values))
(root / "answer" / "expected_u32_le.bin").write_bytes(
    struct.pack("<%dI" % N, *sorted(values))
)

image = bytearray(OUT_OFFSET + N * 4)
image[IN_OFFSET:IN_OFFSET + N * 4] = struct.pack("<%dI" % N, *values)
(root / "extram_init.bin").write_bytes(image)
print("generated input_u32_le.bin, answer/expected_u32_le.bin, extram_init.bin")
