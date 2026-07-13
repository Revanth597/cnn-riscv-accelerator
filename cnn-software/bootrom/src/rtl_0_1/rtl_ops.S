#include "rtl_platform.inc"

.section .text
.global gpio_init
.global uart_init
.global uart_write_u8

gpio_init:
    li   t0, GPIO_BASE

    # AXI GPIO direction register: 0 = output.
    li   t1, 0x0
    sw   t1, GPIO_DIR_OFFSET(t0)
    ret

uart_init:
    ret

# a0 = byte
uart_write_u8:
    li   t0, UART_BASE
    # Wait for an empty tx fifo slot
uart_wait_tx_fifo_free:
    lw   t1, UART_SR_OFFSET(t0)
    andi t1, t1, UART_TX_FIFO_FULL_MASK 
    bnez t1, uart_wait_tx_fifo_free
    sb   a0, UART_TX_OFFSET(t0)
    ret

# returns byte in a0
uart_read_u8:
    li t0, UART_BASE
uart_wait_rx_valid:
    lw t1, UART_SR_OFFSET(t0)
    andi t1, t1, RX_NOT_EMPTY_MASK
    beq t1, zero, uart_wait_rx_valid

    lw t1, UART_RX_OFFSET(t0)
    andi a0, t1, 0xFF
    ret

#ifdef FLASH_PATH
.global flash_init
.global flash_prepare
.global flash_read_words

# Flash base comes from rtl_platform.inc
flash_init:
    li   t4, FLASH_IF_BASE
    li   t0, 0x1E6
    sw   t0, 0x60(t4)
    li   t0, 0x13C
    sw   t0, 0x60(t4)
    li   t0, 0x086
    sw   t0, 0x60(t4)
    ret

# No dynamic arguments needed
flash_prepare:
    li   t4, FLASH_IF_BASE
    li   t5, UART_BASE

    li   t0, -2
    sw   t0, SPI_SSR_OFFSET(t4)
wren_tx_wait:
    lw   t0, SPI_RX_FIFO_OFFSET(t4)
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wren_tx_wait
    li   t0, 0x06
    sw   t0, SPI_TX_FIFO_OFFSET(t4)

wren_end_wait:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wren_end_wait
    li   t0, -1
    sw   t0, SPI_SSR_OFFSET(t4)

    li   t0, -2
    sw   t0, SPI_SSR_OFFSET(t4)
wrr_tx_wait_1:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_tx_wait_1
    li   t0, 0x01
    sw   t0, SPI_TX_FIFO_OFFSET(t4)

wrr_tx_wait_2:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_tx_wait_2
    sw   zero, SPI_TX_FIFO_OFFSET(t4)

wrr_tx_wait_3:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_tx_wait_3
    li   t0, 0xC2
    sw   t0, SPI_TX_FIFO_OFFSET(t4)

wrr_end_wait:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_end_wait
    li   t0, -1
    sw   t0, SPI_SSR_OFFSET(t4)

wip_poll_loop:
    li   t0, 0x0C6
    sw   t0, 0x60(t4)
    li   t0, -2
    sw   t0, SPI_SSR_OFFSET(t4)

wip_tx_wait_1:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wip_tx_wait_1
    li   t0, 0x05
    sw   t0, SPI_TX_FIFO_OFFSET(t4)

wip_tx_wait_2:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wip_tx_wait_2
    sw   zero, SPI_TX_FIFO_OFFSET(t4)

wip_tx_wait_3:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wip_tx_wait_3

    li   t0, -1
    sw   t0, SPI_SSR_OFFSET(t4)
    li   t0, 0x186
    sw   t0, 0x60(t4)

    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    andi t1, t1, WIP_BIT_MASK
    bnez t1, wip_poll_loop

uart_tx_ready:
    lw   t2, 0x8(t5)
    andi t2, t2, TX_EMPTY_MASK
    beq  t2, zero, uart_tx_ready
    sw   zero, UART_TX_OFFSET(t5)
    sw   zero, UART_TX_OFFSET(t5)
    # UART Rx and Tx FIFO reset 
    li   t0, 0x03
    sw   t0, 0xC(t5)
    ret

# a0 = flash_offset, a1 = dst_ptr, a2 = word_count
flash_read_words:
    addi sp, sp, -16
    sw   ra, 12(sp)

    beqz a2, flash_read_done

    call drain_rx_fifo

    li   t4, FLASH_IF_BASE
    li   t0, 0x1E6
    sw   t0, 0x60(t4)

qio_tx_wait_cmd:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, qio_tx_wait_cmd
    li   t0, 0x6B
    sw   t0, SPI_TX_FIFO_OFFSET(t4)

qio_tx_addr_1:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, 0x8
    bnez t0, qio_tx_addr_1
    srli t0, a0, 16
    sw   t0, SPI_TX_FIFO_OFFSET(t4)

qio_tx_addr_2:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, 0x8
    bnez t0, qio_tx_addr_2
    srli t0, a0, 8
    sw   t0, SPI_TX_FIFO_OFFSET(t4)

qio_tx_addr_3:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, 0x8
    bnez t0, qio_tx_addr_3
    sw   a0, SPI_TX_FIFO_OFFSET(t4)

qio_tx_dummy_1:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, 0x8
    bnez t0, qio_tx_dummy_1
    sw   zero, SPI_TX_FIFO_OFFSET(t4)

qio_tx_dummy_2:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, 0x8
    bnez t0, qio_tx_dummy_2
    sw   zero, SPI_TX_FIFO_OFFSET(t4)

qio_tx_dummy_3:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, 0x8
    bnez t0, qio_tx_dummy_3
    sw   zero, SPI_TX_FIFO_OFFSET(t4)

qio_tx_dummy_4:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, 0x8
    bnez t0, qio_tx_dummy_4
    sw   zero, SPI_TX_FIFO_OFFSET(t4)

    li   t0, -2
    sw   t0, SPI_SSR_OFFSET(t4)

    li   t0, 0x086
    sw   t0, 0x60(t4)

wait_tx_empty:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wait_tx_empty

    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    lw   t1, SPI_RX_FIFO_OFFSET(t4)

    li   t3, 0
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    slli t3, t1, 0
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    slli t1, t1, 8
    add  t3, t3, t1
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    slli t1, t1, 16
    add  t3, t3, t1
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    slli t1, t1, 24
    add  t3, t3, t1

    sw   t3, 0(a1)
    addi a1, a1, 4
    addi a2, a2, -1

read_burst_loop:
    beq  a2, zero, read_burst_end
    li   t3, 4

tx_dummy_for_read:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beqz t0, tx_dummy_for_read
    sw   zero, SPI_TX_FIFO_OFFSET(t4)
    addi t3, t3, -1
    bnez t3, tx_dummy_for_read

qio_rx_wait_tx:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, qio_rx_wait_tx

qio_rx_wait_data:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, RX_NOT_EMPTY_MASK
    bnez t0, qio_rx_wait_data

    li   t3, 0
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    slli t3, t1, 0
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    slli t1, t1, 8
    add  t3, t3, t1
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    slli t1, t1, 16
    add  t3, t3, t1
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    slli t1, t1, 24
    add  t3, t3, t1

    sw   t3, 0(a1)
    addi a1, a1, 4
    addi a2, a2, -1
    j    read_burst_loop

read_burst_end:
    li   t0, -1
    sw   t0, SPI_SSR_OFFSET(t4)

    call drain_rx_fifo

flash_read_done:
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

drain_rx_fifo:
    li   t4, FLASH_IF_BASE
drain_rx_fifo_loop:
    lw   t0, SPI_SR_OFFSET(t4)
    andi t0, t0, RX_NOT_EMPTY_MASK
    bnez t0, drain_rx_done
    lw   t1, SPI_RX_FIFO_OFFSET(t4)
    j    drain_rx_fifo_loop
drain_rx_done:
    ret
#endif
