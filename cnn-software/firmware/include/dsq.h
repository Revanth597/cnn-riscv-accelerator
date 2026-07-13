#ifndef DSQ_H
#define DSQ_H

#define INSN_DSQ(rd, rs1, rs2) \
  .word (0x3f << 25) | ((rs2) << 20) | ((rs1) << 15) | (0x7 << 12) | ((rd) << 7) | 0x33

#endif
// this header file is used to define the "dsq" custom instruction 
// 0x33 is the opcode
// 0x7 is the func3 code
// 0x3f is the func7 code

