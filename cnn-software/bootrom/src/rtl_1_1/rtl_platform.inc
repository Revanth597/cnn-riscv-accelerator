# RTL 1.1 platform map and protocol constants
.equ SRAM_BASE,                 0x06000000
.equ FLASH_IF_BASE,             0x01000000
.equ FLASH_CSR_BASE,            0x00100000
.equ UART_BASE,                 0x03000000
.equ GPIO_BASE,                 0x05000000
.equ SRAM_CSR_BASE,             0x00200000

# Some of these offsets are different from the UART 16550 spec due to memory alignment issues.
# They are remapped in the RTL. 
.equ UART_RHR_THR_DLL_OFFSET,   0x0 # Same offset for RHR, THR and DLL
.equ UART_DL_IER_OFFSET,       0x1 # Same offset for DLL/DLM and IER
.equ UART_FCR_ISR_OFFSET,       0x2
.equ UART_LCR_OFFSET,           0x3
.equ UART_LSR_OFFSET,           0xC

.equ UART_LSR_THRE_MASK,        0x20
.equ UART_RX_READY_MASK,    0x1

.equ FLASH_INIT_DELAY_LOOPS,    4000

# qflexpress flash controller config port bit assignments

# Enable/Disable cfg mode
#define CFG_MODE (1 << 12)
# Enable/Disable quad speed mode
#define CFG_QSPEED (1 << 11)
# Direction bit, 1 = write, 0 = read
#define CFG_DIR (1 << 9)
# Chip select bit, 1 = CS high, 0 = CS low (active)
#define CFG_CS_n (1 << 8)
