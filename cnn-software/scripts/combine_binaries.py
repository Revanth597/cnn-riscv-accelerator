#!/usr/bin/env python3
"""
Combine multiple binary files into a single output file.
Useful for creating UART-loadable combined images.

Usage: python combine_binaries.py [-o output.bin] input1.bin input2.bin [input3.bin ...]
"""

import sys
import argparse
import os
import struct


def parse_int(value):
    if isinstance(value, str):
        if value.startswith('0x') or value.startswith('0X'):
            return int(value, 16)
        return int(value, 10)
    return int(value)


def combine_binaries(output_file, input_files, prepend_uartload_header=False, uart_header_magic16=0xA5D5):
    """
    Combine input binary files into a single output file.
    Files are concatenated in order.
    """
    combined_data = bytearray()
    
    for input_file in input_files:
        if not os.path.exists(input_file):
            print(f"Error: Input file not found: {input_file}", file=sys.stderr)
            sys.exit(1)
        
        with open(input_file, 'rb') as f:
            data = f.read()
            combined_data.extend(data)
            print(f"Added {input_file:40} ({len(data):8} bytes, total: {len(combined_data):8} bytes)")

    if prepend_uartload_header:
        if len(combined_data) % 4 != 0:
            print(
                f"Error: Combined payload size ({len(combined_data)}) must be a multiple of 4 bytes",
                file=sys.stderr,
            )
            sys.exit(1)
        if not (0 <= uart_header_magic16 <= 0xFFFF):
            print("Error: uart_header_magic16 must be in range 0..0xFFFF", file=sys.stderr)
            sys.exit(1)

        payload_words = len(combined_data) // 4
        if payload_words > 0xFFFF:
            print(
                f"Error: payload_words ({payload_words}) exceeds 16-bit field",
                file=sys.stderr,
            )
            sys.exit(1)

        header_word = ((uart_header_magic16 & 0xFFFF) << 16) | payload_words
        combined_data = bytearray(struct.pack("<I", header_word)) + combined_data
        print(
            f"Prepended UART header word 0x{header_word:08X} "
            f"(magic16=0x{uart_header_magic16:04X}, payload_words={payload_words})"
        )
    
    # Write combined output
    with open(output_file, 'wb') as f:
        f.write(combined_data)
    
    print()
    print(f"Created combined binary: {output_file}")
    print(f"Total size: {len(combined_data)} bytes")
    
    # Print component offset information
    print()
    print("Component layout:")
    offset = 0
    if prepend_uartload_header:
        print("  0x00000000: uart_header (4 bytes)")
        offset = 4
    for input_file in input_files:
        with open(input_file, 'rb') as f:
            size = len(f.read())
            print(f"  0x{offset:08X}: {input_file} ({size} bytes)")
            offset += size

def main():
    parser = argparse.ArgumentParser(
        description='Combine multiple binary files for UART loading',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python combine_binaries.py -o combined.bin bootrom.bin firmware.bin
    python combine_binaries.py -o combined.bin --prepend-uartload-header bootrom.bin firmware.bin
  python combine_binaries.py -o uart_image.bin test1.bin test2.bin firmware.bin
        """
    )
    
    parser.add_argument('-o', '--output', required=True,
                        help='Output binary file')
    parser.add_argument('--prepend-uartload-header', action='store_true',
                        help='Prepend UART header word {magic16, payload_words[15:0]}')
    parser.add_argument('--uart-header-magic16', default='0xA5D5',
                        help='16-bit header magic in dec or 0x... (default: 0xA5D5)')
    parser.add_argument('inputs', nargs='+',
                        help='Input binary files to combine')
    
    args = parser.parse_args()
    
    if len(args.inputs) < 2:
        print("Error: At least 2 input files required", file=sys.stderr)
        parser.print_help()
        sys.exit(1)
    
    try:
        magic16 = parse_int(args.uart_header_magic16)
    except ValueError:
        print(f"Error: invalid --uart-header-magic16 value: {args.uart_header_magic16}", file=sys.stderr)
        sys.exit(1)

    combine_binaries(
        args.output,
        args.inputs,
        prepend_uartload_header=args.prepend_uartload_header,
        uart_header_magic16=magic16,
    )

if __name__ == '__main__':
    main()
