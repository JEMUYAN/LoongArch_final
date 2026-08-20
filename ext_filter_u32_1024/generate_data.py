"""Generate deterministic ExtRAM input and hidden expected output."""
from pathlib import Path
import struct

ROOT = Path(__file__).parent
ANSWER = ROOT / "answer"
N = 1024
THRESHOLD = 0x80000000

values = []
state = 0xC001D00D
for _ in range(N):
    state = (1664525 * state + 1013904223) & 0xFFFFFFFF
    values.append(state)

# Boundary values make signed-vs-unsigned and >= vs > mistakes observable.
values[0:8] = [
    0x00000000, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF,
    0x00000001, 0x80000001, 0x7FFFFFFE, 0xFFFFFFFE,
]
filtered = [value for value in values if value >= THRESHOLD]

input_blob = b"".join(struct.pack("<I", value) for value in values)
assert len(input_blob) == 4096

# ExtRAM image offsets: A=0x0000, count=0x1000, B=0x2000.
initial = bytearray(0x3000)
initial[0:0x1000] = input_blob
expected = bytearray(initial)
struct.pack_into("<I", expected, 0x1000, len(filtered))
for index, value in enumerate(filtered):
    struct.pack_into("<I", expected, 0x2000 + 4 * index, value)

(ROOT / "input_A_1024_u32_le.bin").write_bytes(input_blob)
(ROOT / "extram_init.bin").write_bytes(initial)
(ANSWER / "extram_expected.bin").write_bytes(expected)
(ANSWER / "answer.txt").write_text(
    "\n".join([
        f"threshold=0x{THRESHOLD:08x}",
        f"N={N}",
        f"expected_count={len(filtered)}",
        "",
    ]),
    encoding="utf-8",
)
