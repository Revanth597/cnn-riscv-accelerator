#ifndef INSN_WT
#define INSN_WT

// CNN_LD_WT
// wt_reg    = weight base register
// Cin_reg    = number of input channels
// out_ch    = number of feature maps
// funct3 = 000
// opcode = 0x2B (custom-0)
 
#define CNN_LD_WT(out_ch,Cin_reg,wt_reg) \
    .word (((out_ch) << 25) | ((Cin_reg) << 20) | ((wt_reg) << 15) | ((0) << 12) | 0x2B)

#endif