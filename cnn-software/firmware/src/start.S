.section .text.startup
.global _start

#include "irq.h"

_start:
    
    call main

.global hang

hang:
    j hang

