"""Generate deterministic unsigned division records and expected ExtRAM image."""
from pathlib import Path
import struct

ROOT = Path(__file__).parent
ANSWER = ROOT / "answer"
N = 128

records = [
    (0x00000000, 0x00000001),
    (0x00000001, 0x00000001),
    (0xFFFFFFFF, 0x00000001),
    (0xFFFFFFFF, 0xFFFFFFFF),
    (0xFFFFFFFF, 0x00000002),
    (0x80000000, 0x00000002),
    (0x80000000, 0x80000000),
    (0x00000007, 0x00000003),
    (0x00000002, 0x00000003),
    (0x80000001, 0x7FFFFFFF),
]
state = 0x31415926
while len(records) < N:
    state = (1664525 * state + 1013904223) & 0xFFFFFFFF
    dividend = state
    state = (1664525 * state + 1013904223) & 0xFFFFFFFF
    divisor = state or 1
    records.append((dividend, divisor))

input_blob = b"".join(struct.pack("<II", a, b) for a, b in records)
assert len(input_blob) == N * 8
q = [a // b for a, b in records]
r = [a % b for a, b in records]

# ExtRAM image offsets: records=0x0000, Q=0x1000, R=0x2000.
initial = bytearray(0x3000)
initial[:len(input_blob)] = input_blob
expected = bytearray(initial)
for index, value in enumerate(q):
    struct.pack_into("<I", expected, 0x1000 + 4 * index, value)
for index, value in enumerate(r):
    struct.pack_into("<I", expected, 0x2000 + 4 * index, value)

(ROOT / "input_records_u32_le.bin").write_bytes(input_blob)
(ROOT / "extram_init.bin").write_bytes(initial)
(ANSWER / "extram_expected.bin").write_bytes(expected)
(ANSWER / "answer.txt").write_text(
    "\n".join([
        "N=128",
        "semantics=uint32_t unsigned division and remainder",
        "divisor_zero=not present in test data",
        "boundary_cases=0/1, UINT_MAX/1, UINT_MAX/UINT_MAX, UINT_MAX/2, INT_MIN-like bit patterns",
        "",
    ]), encoding="utf-8")
