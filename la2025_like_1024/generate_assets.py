"""Generate deterministic input, expected result, and a sparse boot image."""
from pathlib import Path
import struct

OUT = Path(__file__).parent
N = 1024
INPUT_ADDRESS = 0x1C400000
RESULT_ADDRESS = INPUT_ADDRESS + 4 * N
REFERENCE = 0xF2345678

# Exactly 19 hits, including index 0.  The irregular positions prevent an
# answer based on a guessed stride or a partial scan.
HIT_INDICES = {
    0, 3, 17, 63, 64, 127, 128, 191, 255, 256,
    383, 511, 512, 701, 767, 768, 900, 1000, 1023,
}

values = []
state = 0x13579BDF
for index in range(N):
    state = (1664525 * state + 1013904223) & 0xFFFFFFFF
    value = state
    # Keep non-hit values distinct from REFERENCE, deterministically.
    if value == REFERENCE:
        value ^= 0x00A5A5A5
    if index in HIT_INDICES:
        value = REFERENCE
    values.append(value)

assert values[0] == REFERENCE
assert sum(value == values[0] for value in values) == len(HIT_INDICES)

input_bin = b"".join(struct.pack("<I", value) for value in values)
expected_bin = struct.pack("<I", len(HIT_INDICES))
(OUT / "input_1024_u32_le.bin").write_bytes(input_bin)
(OUT / "expected_count_u32_le.bin").write_bytes(expected_bin)

# ExtRAM is distinct from BaseRAM. This image starts at the ExtRAM base and
# contains A followed by a zero-initialized 4-byte result cell.
(OUT / "extram_image.bin").write_bytes(input_bin + b"\x00\x00\x00\x00")

summary = "\n".join([
    f"N={N}",
    f"input_address=0x{INPUT_ADDRESS:08x}",
    f"result_address=0x{RESULT_ADDRESS:08x}",
    f"reference=0x{REFERENCE:08x}",
    f"expected_count={len(HIT_INDICES)}", 
    "hit_indices=" + ",".join(map(str, sorted(HIT_INDICES))),
    "",
])
(OUT / "answer.txt").write_text(summary, encoding="utf-8")
