#!/usr/bin/env python3
"""
Convert binary file to a Verilog boot ROM lookup module
Usage: python bin2verilog.py <input.bin> [output.v] [module_name]
"""

import sys
import math
import datetime

def bin2verilog(input_file, output_file, module_name="bootrom"):
    """
    Convert binary file to a Verilog boot ROM lookup module.
    
    Args:
        input_file: Path to input binary file
        output_file: Path to output .v file
        module_name: Name of the Verilog module (default: bootrom)
    """
    with open(input_file, "rb") as f:
        bindata = f.read()
    
    # Pad to 4-byte alignment if needed
    padding_needed = (4 - (len(bindata) % 4)) % 4
    if padding_needed:
        bindata += b'\x00' * padding_needed
        print(f"Padded {padding_needed} bytes to align to 4-byte boundary")
    
    # Convert to 32-bit words
    num_words = len(bindata) // 4
    words = []
    for i in range(num_words):
        word_bytes = bindata[i*4 : i*4+4]
        # Little-endian: byte0 is LSB
        word = (word_bytes[3] << 24) | (word_bytes[2] << 16) | (word_bytes[1] << 8) | word_bytes[0]
        words.append(word)
    
    # Match the requested ROM lookup style while still supporting arbitrary image sizes.
    case_addr_width = max(12, max(1, (num_words - 1).bit_length()))
    case_addr_msb = case_addr_width - 1
    case_hex_digits = math.ceil(case_addr_width / 4)
    
    # Get current date for the header
    current_date = datetime.datetime.now().strftime("%d.%m.%Y")

    with open(output_file, "w") as f:
        # Write module header
        f.write("`timescale 1ns / 1ps\n")
        f.write("//////////////////////////////////////////////////////////////////////////////////\n")
        f.write("// Engineer: Shashank Tiwari, Samyak Nidhi, Tanish A Shet, Rakesh Patil, Rohith Suju\n")
        f.write(f"// Last Modified: {current_date}\n")
        f.write(f"// Module Name: {module_name}\n")
        f.write("// Project Name: Silicon SoC CNN\n")
        f.write("// Description: bootROM register file with simple read interface\n")
        f.write("//////////////////////////////////////////////////////////////////////////////////\n\n")

        f.write(f"module {module_name}\n")
        f.write("(\n")
        f.write("    input  wire        clk,\n")
        f.write("    input  wire        rst_n,\n")
        f.write("    input  wire [31:0] addr,  // word address from CPU\n")
        f.write("    input  wire        ce,    // Chip Enable\n")
        f.write("    output wire [31:0] dataout   // 32-bit instruction output\n")
        f.write(");\n\n\n")

        f.write("//----------------------------------//\n")
        f.write("// Intermediate internal signals\n")
        f.write("//----------------------------------//\n")
        f.write("reg [31:0] dout;\n\n")

        f.write("/*\n")
        f.write(" * Boot ROM lookup logic.\n")
        f.write(f" * When ce is asserted, returns the instruction mapped to addr[{case_addr_msb}:0].\n")
        f.write(" * When ce is deasserted, returns a NOP value.\n")
        f.write(" */\n\n")

        f.write("always @(*)\n")
        f.write("begin\n")
        f.write("    if (ce)\n")
        f.write(f"        case (addr[{case_addr_msb}:0])\n")

        for i, word in enumerate(words):
            # Formatted to match the uppercase hex addresses and lowercase hex data values
            f.write(f"            {case_addr_width}'h{i:0{case_hex_digits}X}: dout = 32'h{word:08x};\n")

        f.write("            default: dout = 32'h00000013; // RISC-V NOP\n")
        f.write("        endcase\n")
        f.write("    else\n")
        f.write("        dout = 32'h00000013; // Default to NOP when disabled\n")
        f.write("end\n\n")

        f.write("// Output mapping from internal ROM data register.\n")
        f.write("assign dataout = dout;\n\n")
        f.write("endmodule\n")
    
    print(f"Converted {input_file} to {output_file}")
    print(f"Module name: {module_name}")
    print(f"Memory size: {num_words} words ({len(bindata)} bytes)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bin2verilog.py <input.bin> [output.v] [module_name]", file=sys.stderr)
        print("\nExamples:", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin                    # output: bootrom.v, module: bootrom", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin bootrom_init.v     # custom output name", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin bootrom.v my_rom   # custom module name", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Default output filename: replace extension with .v
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    else:
        output_file = input_file.rsplit('.', 1)[0] + '.v'
    
    # Module name
    if len(sys.argv) > 3:
        module_name = sys.argv[3]
    else:
        module_name = "bootrom"
    
    bin2verilog(input_file, output_file, module_name)