# =============================================================================
# Common boot flow for all RTL versions.
# Per-RTL behavior is implemented in:
#   src/rtl_0_1/rtl_platform.inc + rtl_ops.S
#   src/rtl_1_1/rtl_platform.inc + rtl_ops.S
# =============================================================================
#include "irq.h"
#include "rtl_platform.inc"

# --- Firmware load parameters ---
.equ FW_FLASH_OFFSET,   0x00000000
.equ FW_MAGIC_WORD,     0xB007B007
.equ FW_HEADER_WORDS,   4
.equ FW_HEADER_BYTES,   16

# RTL hook ABI:
#   uart_init()
#   uart_write_u8(a0 = byte)
#   flash_init()
#   flash_prepare()
#   flash_read_words(a0 = flash_offset, a1 = dst_ptr, a2 = word_count)

.text
.global main

main:
    li   s0, SRAM_BASE
    li   t6, GPIO_BASE

    call gpio_init

    call uart_init

#ifdef FLASH_PATH
    call flash_init
#endif

# ---------------------------------------------------------------------
# BRAM TEST
# ---------------------------------------------------------------------

    li   t0, 10
    sw   t0, 0(s0)

    li   t0, 20
    sw   t0, 4(s0)

    lw   t1, 0(s0)
    mv   a0, t1
    call uart_write_u8

    li   t0, 5
delay1:
    addi t0, t0, -1
    bnez t0, delay1

    lw   t1, 4(s0)
    mv   a0, t1
    call uart_write_u8

    li   t0, 5
delay2:
    addi t0, t0, -1
    bnez t0, delay2

# ---------------------------------------------------------------------
# GPIO STATUS : BRAM VERIFIED
# ---------------------------------------------------------------------

    li   t0, 0x01
    sw   t0, 0(t6)

#ifdef TARGET_FPGA
    # ~0.5s delay for FPGA (assuming 100MHz clock)
    li   t1, 100000000 / 2
#else
    # 8 cycle delay for sim
    li   t1, 8
#endif

    picorv32_timer_insn(zero, t1) # Configure internal timer
.timer_wait_irq0:
    picorv32_waitirq_insn(t2)     # Sleep until an interrupt occurs
    andi t2, t2, 1                # Extract interrupt flag
    beqz t2, .timer_wait_irq0      # Check if it was specifically the timer (IRQ0). If not, wait again


#ifdef FLASH_PATH

# ---------------------------------------------------------------------
# FLASH INITIALIZATION
# ---------------------------------------------------------------------

    call flash_prepare

# GPIO STATUS : FLASH READY

    li   t0, 0x03
    sw   t0, 0(t6)

#ifdef TARGET_FPGA
    # ~0.5s delay for FPGA (assuming 100MHz clock)
    li   t1, 100000000 / 2
#else
    # 8 cycle delay for sim
    li   t1, 8
#endif

    picorv32_timer_insn(zero, t1) # Configure internal timer
timer_wait_irq1:
    picorv32_waitirq_insn(t2)     # Sleep until an interrupt occurs
    andi t2, t2, 1                # Extract interrupt flag
    beqz t2, timer_wait_irq1      # Check if it was specifically the timer (IRQ0). If not, wait again

    li   a0, 0x11
    call uart_write_u8

    li   s3, FW_FLASH_OFFSET
    li   s4, FW_HEADER_WORDS
    mv   s5, s0
    li   s6, 0

# UART : FLASH INITIALIZED

    li   a0, 0xFE
    call uart_write_u8

# ---------------------------------------------------------------------
# READ FROM FLASH
# ---------------------------------------------------------------------

read_phase:

    mv   a0, s3
    mv   a1, s5
    mv   a2, s4

    call flash_read_words

# DEBUG A0 : flash_read_words returned

    li   a0, 0xA0
    call uart_write_u8

    beqz s6, parse_header
    j    verify_payload

# ---------------------------------------------------------------------
# PARSE HEADER
# ---------------------------------------------------------------------

parse_header:
# DEBUG A1 : Header Read

    li   a0, 0xA1
    call uart_write_u8
    
    lw   t0, 0(s0)
    li   t1, FW_MAGIC_WORD
    beq  t0, t1, magic_ok

    li   a0, 0xEE
    call uart_write_u8
    j bad_magic
    
    magic_ok:
    li   a0, 0x55
    call uart_write_u8
       
    lw   t2, 4(s0)
    lw   t3, 8(s0)
    lw   s7, 12(s0)

# DEBUG A2 : Header Parsed

    li   a0, 0xA2
    call uart_write_u8

    srli t2, t2, 2
    mv   s4, t2
    mv   s5, t3

    addi s3, s3, FW_HEADER_BYTES

    li   s6, 1

    j    read_phase

    # ---------------------------------------------------------------------
# VERIFY PAYLOAD
# ---------------------------------------------------------------------

verify_payload:

# DEBUG A3 : Starting checksum calculation

    li   a0, 0xA3
    call uart_write_u8

    mv   a0, s5
    mv   a1, s4
    call fw_checksum32

# Save calculated checksum before UART overwrites a0

    mv   t4, a0

# DEBUG A4 : Checksum calculation completed

    li   a0, 0xA4
    call uart_write_u8

# Compare calculated checksum against header checksum

    bne  t4, s7, bad_checksum

# DEBUG A5 : Firmware checksum verified

    li   a0, 0xA5
    call uart_write_u8

# ---------------------------------------------------------------------
# FIRMWARE VERIFIED
# ---------------------------------------------------------------------

firmware_done:

# GPIO STATUS : Firmware Loaded

    li   t0, 0x04
    sw   t0, 0(t6)

#ifdef TARGET_FPGA
    # ~0.5s delay for FPGA (assuming 100MHz clock)
    li   t1, 100000000 / 2
#else
    # 8 cycle delay for sim
    li   t1, 8
#endif

    picorv32_timer_insn(zero, t1) # Configure internal timer
timer_wait_irq2:
    picorv32_waitirq_insn(t2)     # Sleep until an interrupt occurs
    andi t2, t2, 1                # Extract interrupt flag
    beqz t2, timer_wait_irq2      # Check if it was specifically the timer (IRQ0). If not, wait again

# UART : BootROM completed successfully

    li   a0, 0xFF
    call uart_write_u8

#if RTL_VERSION_1_1 && !DISABLE_CSR_UPDATE

    la   t0, SRAM_CSR_BASE
    li   t1, 0x4
    sw   t1, 0(t0)

#endif

# Jump to firmware entry point

    mv   t0, s5
    jr   t0

#else
    li   a0, 0xFF
    call uart_write_u8

    la   t0, _bootrom_image_end
    jr   t0

#endif

# ---------------------------------------------------------------------
# ERROR HANDLERS
# ---------------------------------------------------------------------

bad_magic:

# DEBUG E1 : Invalid firmware magic

    li   a0, 0xE1
    call uart_write_u8

    j done

bad_checksum:

# DEBUG E2 : Firmware checksum mismatch

    li   a0, 0xE2
    call uart_write_u8

    j done

# ---------------------------------------------------------------------
# HALT
# ---------------------------------------------------------------------

done:
    j done

//
//| UART Flag | Meaning                                                                      | Expected? |
//| --------- | ---------------------------------------------------------------------------- | --------- |
//| **0x0A**  | BRAM test #1 passed (value 10 read back)                                     | ✅         |
//| **0x14**  | BRAM test #2 passed (value 20 read back)                                     | ✅         |
//| **0x11**  | GPIO written with `0x01` (LED status updated to BRAM VERIFIED)               | ✅         |
//| **0xFE**  | Flash initialization (`flash_prepare`) completed                             | ✅         |
//| **0xA0**  | `flash_read_words()` returned successfully                                   | ✅         |
//| **0xA1**  | Beginning firmware header parsing                                            | ✅         |
//| **0x55**  | Magic word matched (`t0 == 0xB007B007`)                                      | ✅         |
//| **0xA2**  | Header parsed successfully (payload size, entry address, checksum extracted) | ✅         |
//| **0xA0**  | Second call to `flash_read_words()` (payload read)                           | ✅         |
//| **0xA3**  | Starting checksum calculation                                                | ✅         |
//| **0xA4**  | Checksum calculation completed                                               | ✅         |
//| **0xA5**  | Checksum matched the header                                                  | ✅         |
//| **0xFF**  | BootROM finished; jumping to firmware                                        | ✅         |