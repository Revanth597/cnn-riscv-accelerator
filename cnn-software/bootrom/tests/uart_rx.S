#include "rtl_platform.inc"
#include "rtl_ops.S"

.section .text.startup
    call uart_init
    
loop:
    call uart_read_u8
    call uart_write_u8
    j loop

hang:
    j hang