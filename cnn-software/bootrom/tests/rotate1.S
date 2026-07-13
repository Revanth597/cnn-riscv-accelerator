.section .text
.global _start

# Full-BRAM SRAM test - Rotate 1 (write rotate-left-by-1 of pattern)
# Writes every 32-bit word in BRAM, computes XOR checksum while writing,
# reads back entire BRAM, computes XOR of reads and compares to written checksum.
# On success sends `0x1` to UART; on failure sends `0xFF`.
.equ BRAM_BASE,0x00004000
.equ UART_BASE,0x20020000

_start:
    li sp,0x00003000

    # setup bases
    li s0,BRAM_BASE    # BRAM base
    li s2,UART_BASE    # UART base (write to 4(s2))

    # Registers usage:
    # t0: byte offset (0..0x3FFC step 4)
    # t1: end offset (0x4000)
    # t2: word index
    # t3: temporary full address (s0 + t0)
    # t4: value to write/read
    # t5: expected XOR checksum
    # t6: running/read XOR checksum / temp rotate

    li t0,0
    li t1,0x4000
    li t2,0
    li t5,0        # expected checksum

write_loop:
    beq t0,t1,write_done
    add t3,s0,t0

    # base pattern = word index (t2)
    mv t4,t2
    # rotate-left-by-1: (t4 << 1) | (t4 >> 31)
    slli t6,t4,1
    srli t4,t4,31
    or   t4,t6,t4

    sw t4,0(t3)
    xor t5,t5,t4       # accumulate expected checksum
    addi t0,t0,4
    addi t2,t2,1
    j write_loop

write_done:
    li t0,0
    li t6,0            # actual/read checksum

read_loop:
    beq t0,t1,read_done
    add t3,s0,t0
    lw t4,0(t3)
    xor t6,t6,t4
    addi t0,t0,4
    j read_loop

read_done:
    beq t5,t6,pass
    li t0,0xFF
    sw t0,4(s2)
    j hang

pass:
    li t0,1
    sw t0,4(s2)

hang:
    j hang
