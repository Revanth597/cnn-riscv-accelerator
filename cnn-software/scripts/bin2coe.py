#!/usr/bin/env python3
"""
Convert binary file to Xilinx COE (Coefficient) format for memory initialization
Usage: python bin2coe.py <input.bin> [output.coe]
"""

import sys

def bin2coe(input_file, output_file):
    """
    Convert binary file to Xilinx .coe format
    
    Args:
        input_file: Path to input binary file
        output_file: Path to output .coe file
    """
    with open(input_file, "rb") as f:
        bindata = f.read()
    
    # Pad to 4-byte alignment if needed
    padding_needed = (4 - (len(bindata) % 4)) % 4
    if padding_needed:
        bindata += b'\x00' * padding_needed
        print(f"Padded {padding_needed} bytes to align to 4-byte boundary")
    
    with open(output_file, "w") as f:
        # Write header
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        
        # Convert to 32-bit words (little-endian)
        num_words = len(bindata) // 4
        for i in range(num_words):
            # Read 4 bytes in little-endian order
            word_bytes = bindata[i*4 : i*4+4]
            # Convert to 32-bit hex value (little-endian: byte0 is LSB)
            word = f"{word_bytes[3]:02x}{word_bytes[2]:02x}{word_bytes[1]:02x}{word_bytes[0]:02x}"
            
            # Write with comma separator, except for the last word which ends with semicolon
            if i < num_words - 1:
                f.write(f"{word},\n")
            else:
                f.write(f"{word};\n")
    
    print(f"Converted {input_file} to {output_file}")
    print(f"Size: {len(bindata)} bytes ({num_words} words)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bin2coe.py <input.bin> [output.coe]", file=sys.stderr)
        print("\nExamples:", file=sys.stderr)
        print("  python bin2coe.py firmware.bin              # output: firmware.coe", file=sys.stderr)
        print("  python bin2coe.py firmware.bin custom.coe   # custom output name", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Default output filename: replace extension with .coe
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    else:
        output_file = input_file.rsplit('.', 1)[0] + '.coe'
    
    bin2coe(input_file, output_file)
