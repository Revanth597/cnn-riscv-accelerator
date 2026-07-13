#include "rtl_platform.inc"
#include "rtl_ops.S"

# --- Firmware load parameters ---
.equ FW_FLASH_OFFSET,           0x00000000
.equ FLASH_IF_BASE,             0x01000000
.equ FLASH_CSR_BASE,            0x00100000
.equ FLASH_INIT_DELAY_LOOPS,    16000

.section .text.startup

main:      

    call uart_init

    # Loop for FLASH_INIT_DELAY_LOOPS iterations to allow flash startup
    li  t0, FLASH_INIT_DELAY_LOOPS
loop:
    addi    t0, t0, -1    # decrement counter
    bne     t0, x0, loop

    # Signal GPIO after flash init delay
    li  a0, 0x1
    call uart_write_u8

    call flash_exit_quad_xip

flash_spi_read:
    li   s0, FLASH_CSR_BASE
    li   s1, SRAM_BASE

    li   t1, CFG_MODE | 0x03         # USERMODE + 0x03
    sw   t1, 0(s0)

    li   t1, CFG_MODE | 0x00         # USERMODE + 0x00
    sw   t1, 0(s0)                   # 24 bit address
    sw   t1, 0(s0)
    sw   t1, 0(s0)

    li   s2, 0x40                    # Word count (256 bytes / 4 = 64 words)
spi_read_loop:
    # Read Byte 0 (bits 0-7)
    sw   t1, 0(s0)                   # Send dummy byte
    lw   t3, 0(s0)                   # Read byte 0
    andi s4, t3, 0xFF                # s4 = b0 (Accumulator initialization)

    # Read Byte 1 (bits 8-15)
    sw   t1, 0(s0)                   # Send dummy byte
    lw   t3, 0(s0)                   # Read byte 1
    andi t3, t3, 0xFF
    slli t3, t3, 8                   # Shift to byte 1 position
    or   s4, s4, t3                  # s4 = (b1 << 8) | b0

    # Read Byte 2 (bits 16-23)
    sw   t1, 0(s0)                   # Send dummy byte
    lw   t3, 0(s0)                   # Read byte 2
    andi t3, t3, 0xFF
    slli t3, t3, 16                  # Shift to byte 2 position
    or   s4, s4, t3                  # s4 = (b2 << 16) | (b1 << 8) | b0

    # Read Byte 3 (bits 24-31)
    sw   t1, 0(s0)                   # Send dummy byte
    lw   t3, 0(s0)                   # Read byte 3
    andi t3, t3, 0xFF
    slli t3, t3, 24                  # Shift to byte 3 position
    or   s4, s4, t3                  # s4 = (b3 << 24) | ...

    sw   s4, 0(s1)                   # Write completed 32-bit word to SRAM
    addi s1, s1, 4                   # Increment SRAM pointer by 4 bytes
    addi s2, s2, -1                  # Decrement word counter
    bnez s2, spi_read_loop           # Repeat until all 64 words are read

    li   t1, CFG_MODE | CFG_CS_n     # Set CS high again
    sw   t1, 0(s0)

flash_readid:
    li   s0, FLASH_CSR_BASE

    li   t1, CFG_MODE | 0x9F         # USERMODE + 0x9F
    sw   t1, 0(s0)

    # Send dummy byte for each byte read
    li   t1, CFG_MODE | 0x00         
    sw   t1, 0(s0)
    lw   t3, 0(s0)           # byte 1 
    sw   t1, 0(s0)
    lw   t4, 0(s0)           # byte 2
    sw   t1, 0(s0)
    lw   t5, 0(s0)           # byte 3 
    
    li   t1, CFG_MODE | CFG_CS_n     # Set CS high again
    sw   t1, 0(s0)

    # UART debug
    mv a0, t3
    call uart_write_u8
    mv a0, t4
    call uart_write_u8
    mv a0, t5
    call uart_write_u8

    call flash_enable_quad_xip

# XIP read
flash_read:
    li   t3, 100
    li   t0, SRAM_BASE
    li   t2, FLASH_IF_BASE
read_loop:
    lw   t1, 0(t2)
    sw   t1, 0(t0)
    addi   t3, t3, -1
    addi  t0, t0, 4
    addi  t2, t2, 4
    bnez   t3, read_loop

    li a0, 0xFF
    call uart_write_u8

done:
    j done