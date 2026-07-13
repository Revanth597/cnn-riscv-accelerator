#!/usr/bin/env python3
"""
Convert binary file to Vivado .mem format for flash IP initialization
Usage: python bin2mem.py <input.bin> [output.mem] [base_address]
"""

import sys


def bin2mem(input_file, output_file, base_address=0x00000000):
    """
    Convert binary file to Vivado .mem format

    Args:
        input_file: Path to input binary file
        output_file: Path to output .mem file
        base_address: Starting address (default: 0x00000000)
    """
    with open(input_file, "rb") as f:
        bindata = f.read()

    with open(output_file, "w") as f:
        # Write address header
        f.write(f"@{base_address:06X}\n")

        # Write data bytes in hex format (one byte per line)
        for byte in bindata:
            f.write(f"{byte:02X}\n")

    print(f"Converted {input_file} to {output_file}")
    print(f"Size: {len(bindata)} bytes")
    print(f"Base address: 0x{base_address:08X}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(
            "Usage: python bin2mem.py <input.bin> [output.mem] [base_address]",
            file=sys.stderr,
        )
        print("\nExamples:", file=sys.stderr)
        print(
            "  python bin2mem.py firmware.bin                    # output: firmware.mem, addr: 0x00000000",
            file=sys.stderr,
        )
        print(
            "  python bin2mem.py firmware.bin firmware.mem        # custom output name",
            file=sys.stderr,
        )
        print(
            "  python bin2mem.py firmware.bin firmware.mem 0x20000 # custom base address",
            file=sys.stderr,
        )
        sys.exit(1)

    input_file = sys.argv[1]

    # Default output filename: replace .bin with .mem
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    else:
        output_file = input_file.rsplit(".", 1)[0] + ".mem"

    # Parse base address if provided
    if len(sys.argv) > 3:
        base_addr_str = sys.argv[3]
        if base_addr_str.startswith("0x") or base_addr_str.startswith("0X"):
            base_address = int(base_addr_str, 16)
        else:
            base_address = int(base_addr_str)
    else:
        base_address = 0x00000000

    bin2mem(input_file, output_file, base_address)
