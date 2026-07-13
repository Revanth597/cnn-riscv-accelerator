.equ GPIO_BASE, 0x05000000

.text
    li s0, GPIO_BASE

    # Set GPIO direction to output
    li   t0, 0x0
    sw   t0, 4(s0)

test_loop:
    li s1, 0x1
    sw s1, 0(s0) 						# Turn on LED 1
    call delay

    li s1, 0x2
    sw s1, 0(s0) 						# Turn on LED 2
    call delay

    li s1, 0x4
    sw s1, 0(s0) 						# Turn on LED 3
    call delay

    li s1, 0x8
    sw s1, 0(s0) 						# Turn on LED 4
    call delay

    li s1, 0xFF
    sw s1, 0(s0) 						# Turn on 8 LEDS
    call delay

    li s1, 0x0
    sw s1, 0(s0) 						# Turn off all LEDs
    call delay

    j test_loop

delay:
    li t0, 100000000  # 100 million cycles delay
    # li t0, 8
    srli t0, t0, 3    # Divide by 8 to account for the loop overhead (8 cycles per iteration)
delay_loop:
    addi t0, t0, -1
    bnez t0, delay_loop
    ret
