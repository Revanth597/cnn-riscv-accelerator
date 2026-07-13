# Simple program to test the UART path by adding two numbers and storing the result in memory. 
.data
    nums: .word 1, 2
    ans: .space 4

.text
    la   s4, nums
    la   s5, ans
    lw   s6, 0(s4) 						# Load first number
    lw   s7, 4(s4) 						# Load second number
    add s6, s6, s7 						# Add the two numbers
    sw  s6, 0(s5)          			    # Store the result to ans
