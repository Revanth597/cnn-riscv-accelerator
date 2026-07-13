# =============================================================================
# Common boot flow for all RTL versions.
# Per-RTL behavior is implemented in:
#   src/rtl_0_1/rtl_platform.inc + rtl_ops.S
#   src/rtl_1_1/rtl_platform.inc + rtl_ops.S
# =============================================================================

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

#  --- BRAM TEST ---
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

#  --- GPIO STATUS: BRAM DONE (0x01) ---
    li   t0, 0x01
    sw   t0, 0(t6)

#ifdef FLASH_PATH
#  --- RTL-specific flash bring-up ---
    call flash_prepare

#  --- GPIO STATUS: FLASH READY (0x03) ---
    li   t0, 0x03
    sw   t0, 0(t6)

    li   s3, FW_FLASH_OFFSET
    li   s4, FW_HEADER_WORDS
    mv   s5, s0
    li   s6, 0

    li   a0, 0xFE
    call uart_write_u8

read_phase:
    mv   a0, s3     # flash_offset
    mv   a1, s5     # dst_ptr
    mv   a2, s4     # word_count
    call flash_read_words
    beqz s6, parse_header
    j    verify_payload

#  --- PARSE FIRMWARE HEADER (in BRAM at s0) ---
parse_header:
    lw   t0, 0(s0)
    li   t1, FW_MAGIC_WORD
    bne  t0, t1, done

    lw   t2, 4(s0)
    lw   t3, 8(s0)
    lw   s7, 12(s0)

    srli t2, t2, 2
    mv   s4, t2
    mv   s5, t3
    addi s3, s3, FW_HEADER_BYTES
    li   s6, 1
    j    read_phase

#  --- VERIFY PAYLOAD CHECKSUM ---
verify_payload:
    mv   a0, s5
    mv   a1, s4
    call fw_checksum32
    bne  a0, s7, done

#  --- GPIO STATUS: FLASH BURST READ DONE (0x04) ---
firmware_done:
    li   t0, 0x04
    sw   t0, 0(t6)

    li   a0, 0xFF
    call uart_write_u8

#if RTL_VERSION_1_1 && !DISABLE_CSR_UPDATE
    la   t0, SRAM_CSR_BASE
    li   t1, 0x4
    sw   t1, 0(t0)   # Mark firmware load as done
#endif

    mv   t0, s5
    jr   t0
#else
    li   a0, 0xFF
    call uart_write_u8

    # In UART_PATH, combined image layout is: [bootrom image][firmware image].
    # Jump to the first byte after the bootrom loadable image.
    la   t0, _bootrom_image_end
    jr   t0
#endif

done:
    j done
