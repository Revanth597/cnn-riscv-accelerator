# Simple program to load 2 numbers into SRAM, add them, and store the result back in SRAM. This tests the path to SRAM.

.equ SRAM_BASE, 0x06000000
.data
    nums: .word 1, 2
    ans: .space 4

.text
    li s3, SRAM_BASE
    li s4, 1
    li s5, 2

    sw s4, 0(s3) 						# Store first number in SRAM
    sw s5, 4(s3) 						# Store second number in SRAM

    lw s6, 0(s3) 						# Load first number from SRAM
    lw s7, 4(s3) 						# Load second number from SRAM
    add s6, s6, s7 						# Add the two numbers
    sw  s6, 0(s3)          				# Store the result

