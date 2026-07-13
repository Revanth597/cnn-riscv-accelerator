#include <stdint.h>
#include "maxpool_scale_quantize.h"

void maxpool_scale_quantize(
    const int16_t *input,
    int8_t *output,
    const uint16_t *scales,
    uint32_t width,
    uint32_t height,
    uint32_t channels)
{
    uint32_t pooled_width  = width >> 1;
    uint32_t pooled_height = height >> 1;

    uint32_t input_channel_size  = width * height;
    uint32_t output_channel_size = pooled_width * pooled_height;

    for (uint32_t ch = 0; ch < channels; ch++)
    {
        const int16_t *in =
            input + ch * input_channel_size;

        int8_t *out =
            output + ch * output_channel_size;

        uint16_t scale = scales[ch];

        for (uint32_t y = 0; y < pooled_height; y++)
        {
            uint32_t row0 = (y << 1) * width;
            uint32_t row1 = ((y << 1) + 1) * width;

            for (uint32_t x = 0; x < pooled_width; x++)
            {
                int16_t a = in[row0 + (x << 1)];
                int16_t b = in[row0 + (x << 1) + 1];
                int16_t c = in[row1 + (x << 1)];
                int16_t d = in[row1 + (x << 1) + 1];

                int16_t max = a;

                if (b > max) max = b;
                if (c > max) max = c;
                if (d > max) max = d;

                int32_t product =
                    (int32_t)max * (int32_t)scale;

                product >>= 16;

                if (product > 127)
                    product = 127;
                else if (product < -128)
                    product = -128;

                out[y * pooled_width + x] =
                    (int8_t)product;
            }
        }
    }
}