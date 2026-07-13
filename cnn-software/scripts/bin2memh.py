#!/usr/bin/env python3
"""
Convert binary file to Vivado-friendly MEMH format.

Each memory element has fixed width; each line can contain one or more elements.

Format examples:
    8-bit width:
        00
        0f
        0c

    32-bit width:
        00000000
        00220222

Usage:
        python3 bin2memh.py <input.bin> [--output output.memh] \
                [--word-width-bits 32] [--word-byte-order reverse|as-is] [--words-per-line 1]

Arguments:
    input.bin         Input binary file
    --output          Output file path (default: input with .memh extension)
    --word-width-bits Width of each MEMH element in bits (default: 32)
    --word-byte-order Byte order per output word: reverse or as-is (default: reverse)
    --words-per-line  Number of memory elements per line (default: 1)
"""

import argparse
import sys


def parse_int(value: str) -> int:
    value = value.strip()
    if value.lower().startswith("0x"):
        return int(value, 16)
    return int(value, 10)


def bin2memh(
    input_file: str,
    output_file: str,
    word_width_bits=32,
    word_byte_order="reverse",
    words_per_line=1,
):
    if word_width_bits <= 0 or word_width_bits % 8 != 0:
        raise ValueError("word_width_bits must be a positive multiple of 8.")
    if words_per_line <= 0:
        raise ValueError("words_per_line must be > 0.")
    if word_byte_order not in ("reverse", "as-is"):
        raise ValueError("word_byte_order must be 'reverse' or 'as-is'.")

    with open(input_file, "rb") as f:
        raw = f.read()

    input_size = len(raw)
    word_bytes = word_width_bits // 8

    if input_size % word_bytes != 0:
        raise ValueError(
            f"Input size ({input_size}) must be a multiple of {word_bytes} bytes "
            f"for {word_width_bits}-bit word conversion."
        )

    hex_width = word_bytes * 2
    word_count = input_size // word_bytes

    with open(output_file, "w") as f:
        line_words = []
        for i in range(0, input_size, word_bytes):
            word = raw[i:i + word_bytes]
            if word_byte_order == "reverse":
                word = word[::-1]
            line_words.append(f"{int.from_bytes(word, byteorder='big', signed=False):0{hex_width}x}")

            if len(line_words) == words_per_line:
                f.write(" ".join(line_words) + "\n")
                line_words.clear()

        if line_words:
            f.write(" ".join(line_words) + "\n")

    print(f"Converted {input_file} to {output_file}")
    print(f"Input size: {input_size} bytes")
    print(f"Output words: {word_count}")
    print(f"Word width: {word_width_bits} bits")
    print(f"Word byte order: {word_byte_order}")
    print(f"Words/line: {words_per_line}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert binary to Vivado-friendly MEMH format",
    )
    parser.add_argument("input_file", help="Input binary file")
    parser.add_argument(
        "--output",
        "-o",
        dest="output_file",
        default=None,
        help="Output .memh path (default: input with .memh extension)",
    )
    parser.add_argument(
        "--word-width-bits",
        type=parse_int,
        default=32,
        help="Width of each MEMH word in bits (default: 32)",
    )
    parser.add_argument(
        "--word-byte-order",
        choices=["reverse", "as-is"],
        default="reverse",
        help="Byte order per output word (default: reverse)",
    )
    parser.add_argument(
        "--words-per-line",
        type=parse_int,
        default=1,
        help="Number of words written per line (default: 1)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    input_file = args.input_file
    output_file = args.output_file if args.output_file else input_file.rsplit('.', 1)[0] + '.memh'
    word_width_bits = args.word_width_bits
    word_byte_order = args.word_byte_order
    words_per_line = args.words_per_line

    if word_width_bits <= 0 or word_width_bits % 8 != 0:
        print("Error: word_width_bits must be a positive multiple of 8", file=sys.stderr)
        sys.exit(1)
    if words_per_line <= 0:
        print("Error: words_per_line must be > 0", file=sys.stderr)
        sys.exit(1)

    try:
        bin2memh(input_file, output_file, word_width_bits, word_byte_order, words_per_line)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
