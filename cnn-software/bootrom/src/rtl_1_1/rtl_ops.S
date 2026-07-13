#include "rtl_platform.inc"

.section .text
.global gpio_init
.global uart_init
.global uart_write_u8

gpio_init:
    ret
    
# UART base comes from rtl_platform.inc
uart_init:
    li   t0, UART_BASE
    li   t1, 0x80
    sb   t1, UART_LCR_OFFSET(t0)

    li   t1, 0x00
    sb   t1, UART_DL_IER_OFFSET(t0)
    li   t1, 0x36   # 115200 baud, assuming 100MHz clock
    sb   t1, UART_RHR_THR_DLL_OFFSET(t0)

    li   t1, 0x03
    sb   t1, UART_LCR_OFFSET(t0)

    li   t1, 0xC6
    sb   t1, UART_FCR_ISR_OFFSET(t0)
    ret

# a0 = byte
uart_write_u8:
    li   t0, UART_BASE
uart_wait_thre:
    lbu  t1, UART_LSR_OFFSET(t0)
    andi t1, t1, UART_LSR_THRE_MASK
    beqz t1, uart_wait_thre
    sb   a0, UART_RHR_THR_DLL_OFFSET(t0)
    ret

# returns byte in a0
uart_read_u8:
    li t0, UART_BASE
uart_wait_rx_valid:
    lbu t1, UART_LSR_OFFSET(t0)
    andi t1, t1, UART_RX_READY_MASK
    beq t1, zero, uart_wait_rx_valid

    lb t1, UART_RHR_THR_DLL_OFFSET(t0)
    mv a0, t1
    ret

#ifdef FLASH_PATH
.global flash_init
.global flash_prepare
.global flash_read_words

# Flash base comes from rtl_platform.inc
flash_init:
    ret

flash_prepare:
    # Save ret address 
    addi sp, sp, -4
    sw ra, 0(sp)

    # Wait for a bit to allow flash startup
    li   t0, FLASH_INIT_DELAY_LOOPS
flash_delay_loop:
    addi t0, t0, -1
    bnez t0, flash_delay_loop

    call flash_exit_quad_xip

#ifdef QUAD_XIP_LOAD
    call flash_enable_quad_xip
#endif

    # restore ret address
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Exit QUAD XIP mode if enabled
flash_exit_quad_xip:
    li   t0, FLASH_CSR_BASE

    # Send unknown command (6 times for good measure) to exit quad XIP mode
    li   t1, CFG_MODE | 0x0FF
    sw   t1, 0(t0)
    sw   t1, 0(t0)
    sw   t1, 0(t0)
    sw   t1, 0(t0)
    sw   t1, 0(t0)
    sw   t1, 0(t0)

    # Set CS high to complete transaction
    li   t1, CFG_MODE | CFG_CS_n
    sw   t1, 0(t0)
    ret

#ifdef QUAD_XIP_LOAD
# Put flash into QUAD I/O XIP mode
flash_enable_quad_xip:
    li   t0, FLASH_CSR_BASE

    # Send Write Enable cmd (06h)
    li   t1, CFG_MODE | 0x06
    sw   t1, 0(t0)      
    li   t1, CFG_MODE | CFG_CS_n
    sw   t1, 0(t0)  # Set CS back high
    
    # WRR (Write registers cmd) (01h)
    li   t1, CFG_MODE | 0x01
    sw   t1, 0(t0)
    li   t1, CFG_MODE | 0x00    # Status Reg 1 = 0b0
    sw   t1, 0(t0)
    li   t1, CFG_MODE | 0x02    # Cfg Reg = 0b10 (Quad enable = 1)
    sw   t1, 0(t0)
    li   t1, CFG_MODE | CFG_CS_n
    sw   t1, 0(t0)  # Set CS back high

    # Read registers cmd (05h)
    li   t1, CFG_MODE | 0x05
    sw   t1, 0(t0)
    li   t1, CFG_MODE | 0x00    
1:
    sw   t1, 0(t0)      # Dummy byte
    lw   t2, 0(t0)      # Read status reg 1
    andi t2, t2, 0x01   # Check WIP bit
    bnez t2, 1b         # back to previous 1: label

    li   t1, CFG_MODE | CFG_CS_n
    sw   t1, 0(t0)  # Set CS back high

    # Quad I/O Read cmd
    li   t1, CFG_MODE | 0x0EB
    sw   t1, 0(t0)

    # 24-bit dummy address in quad mode
    li   t1, CFG_MODE | CFG_QSPEED | CFG_DIR
    sw   t1, 0(t0)
    sw   t1, 0(t0)
    sw   t1, 0(t0)

    # Mode byte: 0xA0 for XIP
    li   t1, CFG_MODE | CFG_QSPEED | CFG_DIR | 0x0A0
    sw   t1, 0(t0)

    # 4 dummy cycles
    li   t1, CFG_MODE | CFG_QSPEED
    sw   t1, 0(t0)
    sw   t1, 0(t0)

    # Send dummy cycles to read a byte (unused)
    sw   t1, 0(t0)
    sw   t1, 0(t0)

    # Close cfg port and set CS high
    li   t1, CFG_CS_n
    sw   t1, 0(t0)

    ret
#endif

# a0 = flash_offset, a1 = dst_ptr, a2 = word_count
flash_read_words:

#ifdef QUAD_XIP_LOAD
    beqz a2, flash_read_done
    li   t2, FLASH_IF_BASE
    add  t0, t2, a0
flash_read_loop:
    lw   t1, 0(t0)
    sw   t1, 0(a1)
    addi t0, t0, 4
    addi a1, a1, 4
    addi a2, a2, -1
    bnez a2, flash_read_loop
#else 
    # Single bit SPI load
    beqz a2, flash_read_done

    li   t0, FLASH_CSR_BASE

    # Send READ command (0x03)
    li   t1, CFG_MODE | 0x03
    sw   t1, 0(t0)

    # Send 24-bit address (a0 = flash_offset)
    li   t5, CFG_MODE
    srli t2, a0, 16
    andi t2, t2, 0xFF
    or   t1, t5, t2     # CFG_MODE | (addr byte 2)
    sw   t1, 0(t0)                  

    srli t2, a0, 8
    andi t2, t2, 0xFF
    or   t1, t5, t2     # CFG_MODE | (addr byte 1)
    sw   t1, 0(t0)

    andi t2, a0, 0xFF
    or   t1, t5, t2     # CFG_MODE | (addr byte 0)
    sw   t1, 0(t0)

spi_read_loop:
    # byte 0
    sw   t5, 0(t0)      # Send dummy byte (CFG_MODE | 0x00)
    lw   t3, 0(t0)      # Read byte 0
    andi t4, t3, 0xFF   # t4 = b0

    # byte 1
    sw   t5, 0(t0)
    lw   t3, 0(t0)
    andi t3, t3, 0xFF
    slli t3, t3, 8
    or   t4, t4, t3     # t4 = (b1 << 8) | b0

    # byte 2
    sw   t5, 0(t0)
    lw   t3, 0(t0)
    andi t3, t3, 0xFF
    slli t3, t3, 16                 
    or   t4, t4, t3     # t4 = (b2 << 16) | (b1 << 8) | b0

    # byte 3
    sw   t5, 0(t0)
    lw   t3, 0(t0)
    andi t3, t3, 0xFF
    slli t3, t3, 24
    or   t4, t4, t3     # t4 = (b3 << 24) | ...

    # Write 32-bit word to SRAM
    sw   t4, 0(a1)
    addi a1, a1, 4
    addi a2, a2, -1
    bnez a2, spi_read_loop
#endif

flash_read_done:

#ifndef QUAD_XIP_LOAD
    li   t1, CFG_MODE | CFG_CS_n     # Set CS high again
    sw   t1, 0(t0)
#endif

    ret
#endif
