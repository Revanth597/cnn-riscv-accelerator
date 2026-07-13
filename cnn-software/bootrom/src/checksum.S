#ifdef FLASH_PATH


.section .text
.global fw_checksum32

# a0 = base address, a1 = word count
# returns a0 = 32-bit additive checksum
fw_checksum32:
    li   t0, 0

fw_checksum_loop:
    beqz a1, fw_checksum_done
    lw   t1, 0(a0)
    add  t0, t0, t1
    addi a0, a0, 4
    addi a1, a1, -1
    j    fw_checksum_loop

fw_checksum_done:
    mv   a0, t0
    ret

#endif
