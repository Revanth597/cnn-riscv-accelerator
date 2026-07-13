#ifndef INSN_IMG_EXE
#define INSN_IMG_EXE

// CNN_LD_IMG
// img_addr    = image base register
// dst_addr    = destination base register 
// img_size    = image size
// funct3 = 001
// opcode = 0x2B (custom-0)

#define CNN_LD_IMG_EXE(img_size, dst_addr, img_addr) \
    .word (((img_size) << 25) | ((dst_addr) << 20) | ((img_addr) << 15) | ((1) << 12) | 0x2B)

#endif