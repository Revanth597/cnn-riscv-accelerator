#ifndef MAXPOOL_SCALE_QUANTIZE_H
#define MAXPOOL_SCALE_QUANTIZE_H

#include <stdint.h>

void maxpool_scale_quantize(
    const int16_t *input,
    int8_t *output,
    const uint16_t *scales,
    uint32_t width,
    uint32_t height,
    uint32_t out_channels
);

#endif