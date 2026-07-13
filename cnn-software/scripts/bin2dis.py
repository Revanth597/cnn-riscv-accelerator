#!/usr/bin/env python3
"""
Generate disassembly from binary file using objdump
Usage: python bin2dis.py <input.bin> <output.dis> [objdump_path] [arch]
"""

import subprocess
import sys
import os

def generate_disassembly(input_file, output_file, objdump_path='objdump', arch='riscv:rv32'):
    """Generate disassembly using objdump"""
    try:
        # Use objdump to disassemble binary
        result = subprocess.run(
            [objdump_path, '-b', 'binary', '-m', arch, '-D', input_file],
            capture_output=True,
            text=True,
            check=True
        )
        
        with open(output_file, 'w') as f:
            f.write(result.stdout)
        
        print(f"Generated disassembly: {output_file}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error generating disassembly: {e.stderr}", file=sys.stderr)
        return False
    except FileNotFoundError:
        print(f"Error: objdump not found at '{objdump_path}'. Make sure binutils is installed.", file=sys.stderr)
        return False

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python bin2dis.py <input.bin> <output.dis> [objdump_path] [arch]", file=sys.stderr)
        print("Example: python bin2dis.py firmware.bin firmware.dis /path/to/riscv32-unknown-elf-objdump riscv:rv32", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    objdump_path = sys.argv[3] if len(sys.argv) > 3 else 'objdump'
    arch = sys.argv[4] if len(sys.argv) > 4 else 'riscv:rv32'
    
    if not generate_disassembly(input_file, output_file, objdump_path, arch):
        sys.exit(1)
