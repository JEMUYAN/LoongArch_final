#!/usr/bin/env python3
"""Pack a reset program and a raw data blob into one BaseRAM binary image."""

from argparse import ArgumentParser
from pathlib import Path


def number(value: str) -> int:
    return int(value, 0)


parser = ArgumentParser(description=__doc__)
parser.add_argument("--program", required=True, type=Path,
                    help="raw program BIN, linked at --base")
parser.add_argument("--data", required=True, type=Path,
                    help="raw data BIN")
parser.add_argument("--output", required=True, type=Path,
                    help="combined raw BaseRAM image")
parser.add_argument("--base", type=number, default=0x1C000000,
                    help="BaseRAM physical base (default: 0x1c000000)")
parser.add_argument("--size", type=number, default=0x400000,
                    help="BaseRAM capacity in bytes (default: 0x400000)")
parser.add_argument("--data-address", type=number, default=0x1C010000,
                    help="physical address at which to place data")
parser.add_argument("--result-address", type=number, default=0x1C011000,
                    help="zero-initialized 4-byte result cell address")
args = parser.parse_args()

program = args.program.read_bytes()
data = args.data.read_bytes()
data_offset = args.data_address - args.base
result_offset = args.result_address - args.base

for label, offset in (("data", data_offset), ("result", result_offset)):
    if offset < 0 or offset >= args.size:
        raise SystemExit(f"{label} address is outside BaseRAM")
if len(program) > args.size:
    raise SystemExit("program is larger than BaseRAM")
if data_offset < len(program):
    raise SystemExit("data overlaps the program image")
if data_offset + len(data) > args.size:
    raise SystemExit("data exceeds BaseRAM")
if result_offset + 4 > args.size:
    raise SystemExit("result cell exceeds BaseRAM")
if not (result_offset + 4 <= data_offset or result_offset >= data_offset + len(data)):
    raise SystemExit("result cell overlaps input data")

image_size = max(len(program), data_offset + len(data), result_offset + 4)
image = bytearray(image_size)
image[:len(program)] = program
image[data_offset:data_offset + len(data)] = data
args.output.write_bytes(image)

print(f"wrote {args.output}: {image_size} B")
print(f"program: offset 0x00000000, {len(program)} B")
print(f"data:    offset 0x{data_offset:08x}, {len(data)} B")
print(f"result:  offset 0x{result_offset:08x}, 4 B (zero initialized)")
