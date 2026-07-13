#!/usr/bin/env python3
"""
Append firmware header for bootrom loading
Usage: python append_firmware_header.py <input.bin> <output.bin> [magic] [load_addr]

Header format (little-endian, 16 bytes):
    word0: magic
    word1: payload size in bytes
    word2: load address
    word3: additive checksum of 32-bit payload words
"""

import struct
import sys


def parse_hex_or_int(value):
    """Parse hex (0x...) or decimal integer"""
    if isinstance(value, str):
        if value.startswith("0x") or value.startswith("0X"):
            return int(value, 16)
        else:
            return int(value)
    return value


# Default values
DEFAULT_MAGIC = 0xB007B007
DEFAULT_LOAD_ADDR = 0x00020000


def checksum32(payload):
    """32-bit additive checksum over little-endian 32-bit words."""
    if len(payload) % 4 != 0:
        raise ValueError("payload size must be a multiple of 4 bytes for checksum")

    total = 0
    for i in range(0, len(payload), 4):
        word = struct.unpack_from("<I", payload, i)[0]
        total = (total + word) & 0xFFFFFFFF
    return total


if len(sys.argv) < 3:
    print(
        "Usage: python append_firmware_header.py <input.bin> <output.bin> [magic] [load_addr]",
        file=sys.stderr,
    )
    print("\nExamples:", file=sys.stderr)
    print(
        "  python append_firmware_header.py firmware.bin firmware_hdr.bin",
        file=sys.stderr,
    )
    print(
        "  python append_firmware_header.py firmware.bin firmware_hdr.bin 0xB007B007 0x20000",
        file=sys.stderr,
    )
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

# Parse optional parameters
MAGIC = parse_hex_or_int(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_MAGIC
LOAD_ADDR = parse_hex_or_int(sys.argv[4]) if len(sys.argv) > 4 else DEFAULT_LOAD_ADDR

with open(input_file, "rb") as f:
    payload = f.read()

SIZE = len(payload)
CHECKSUM = checksum32(payload)

header = struct.pack(
    "<IIII",
    MAGIC,
    SIZE,
    LOAD_ADDR,
    CHECKSUM,
)

with open(output_file, "wb") as f:
    f.write(header)
    f.write(payload)

print(f"Created firmware with header: {output_file}")
print(f"  Magic:      0x{MAGIC:08X}")
print(f"  Size:       {SIZE} bytes")
print(f"  Load Addr:  0x{LOAD_ADDR:08X}")
print(f"  Checksum:   0x{CHECKSUM:08X}")
