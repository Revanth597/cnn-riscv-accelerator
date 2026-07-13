#include "INSN_WT.h"
#include "INSN_IMG_EXE.h"

.section .text
.global main

.extern maxpool_scale_quantize

main:

    ####################################################
    # Load Weights
    ####################################################

    la      x10, weight_data
    li      x11, 1

    CNN_LD_WT(16,11,10)

    ####################################################
    # Execute CNN
    ####################################################

    la      x12, image_0
    la      x13, output_feature_map

    CNN_LD_IMG_EXE(32,13,12)

 

    la      a0, output_feature_map
    la      a1, clamped_output
    la      a2, intermediate_scales

    li      a3, 32
    li      a4, 32
    li      a5, 16

    call    maxpool_scale_quantize

hang:
    j hang