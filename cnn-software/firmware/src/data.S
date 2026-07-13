.section .data

.align 4

.global output_feature_map
output_feature_map:
.space 32768       # 32x32x16 (INT16) output


.align 4

.global clamped_output
clamped_output:
.space 4096  

