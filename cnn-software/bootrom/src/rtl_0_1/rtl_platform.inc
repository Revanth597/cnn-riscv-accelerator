# RTL 0.1 platform map and protocol constants
.equ SRAM_BASE,            0x00020000
.equ FLASH_IF_BASE,        0x20000000
.equ UART_BASE,            0x20020000
.equ GPIO_BASE,            0x05000000

.equ GPIO_DIR_OFFSET,      0x4

.equ UART_RX_OFFSET,  0x00 # Receive FIFO register
.equ UART_TX_OFFSET,       0x4 # Transmit FIFO register
.equ UART_SR_OFFSET,       0x08 # Status register offset
.equ UART_CTRLR_OFFSET,     0x0C # Control register offset
.equ UART_RX_FIFO_VALID_MASK, 0x1 # Mask to check if RX FIFO has valid data
.equ UART_TX_FIFO_FULL_MASK, 0x8 # Mask to check if TX FIFO is full

.equ SPI_SR_OFFSET,        0x64
.equ SPI_TX_FIFO_OFFSET,   0x68
.equ SPI_RX_FIFO_OFFSET,   0x6C
.equ SPI_SSR_OFFSET,       0x70

.equ TX_EMPTY_MASK,        0x4
.equ RX_NOT_EMPTY_MASK,    0x1
.equ WIP_BIT_MASK,         0x1
