"""Generate deterministic sorted data, queries, and expected lower_bounds."""
from bisect import bisect_left
from pathlib import Path
import struct

ROOT = Path(__file__).parent
ANSWER = ROOT / "answer"
N, Q = 1024, 128
state = 0x13579BDF
values = []
for _ in range(N):
    state = (1664525 * state + 1013904223) & 0xFFFFFFFF
    values.append(state)
values.sort()
values[0] = 0
values[-1] = 0xFFFFFFFF
# Create several duplicate runs while preserving sorted order.
for start, length in ((100, 5), (320, 9), (700, 4)):
    values[start:start + length] = [values[start]] * length

queries = [
    0, 1, values[100], (values[100] + 1) & 0xFFFFFFFF,
    values[320], values[700], 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF,
]
while len(queries) < Q:
    state = (1664525 * state + 1013904223) & 0xFFFFFFFF
    queries.append(state)
answers = [bisect_left(values, target) for target in queries]

assert values == sorted(values)
assert len(values) == N and len(queries) == Q
array_blob = b"".join(struct.pack("<I", item) for item in values)
query_blob = b"".join(struct.pack("<I", item) for item in queries)
initial = bytearray(0x3000)
initial[0:0x1000] = array_blob
initial[0x1000:0x1000 + len(query_blob)] = query_blob
expected = bytearray(initial)
for index, value in enumerate(answers):
    struct.pack_into("<I", expected, 0x2000 + 4 * index, value)

(ROOT / "array_A_1024_u32_le.bin").write_bytes(array_blob)
(ROOT / "query_128_u32_le.bin").write_bytes(query_blob)
(ROOT / "extram_init.bin").write_bytes(initial)
(ANSWER / "extram_expected.bin").write_bytes(expected)
(ANSWER / "answer.txt").write_text(
    "\n".join([
        "N=1024", "queries=128", "semantics=uint32_t lower_bound", 
        "return=first i with A[i] >= query, or 1024", "",
    ]), encoding="utf-8")
