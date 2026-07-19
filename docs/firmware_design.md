# Firmware Design

## Overview

The firmware provides the software control layer for the CNN-RISC-V Accelerator and is responsible for coordinating communication between the PicoRV32 processor and the custom CNN hardware accelerator.

Rather than implementing the complete CNN inference pipeline in hardware, the design adopts a hardware/software co-design approach. Computationally intensive operations such as convolution, multiply-accumulate (MAC), and ReLU activation are accelerated in dedicated RTL hardware, while configurable post-processing is executed in firmware.

This partitioning combines the high throughput of dedicated hardware with the flexibility of software, allowing quantization parameters and post-processing algorithms to be modified without requiring RTL changes.

The firmware is implemented using a combination of **RISC-V assembly** and **C**, providing direct access to hardware resources while maintaining portability for algorithmic processing.

---

# Design Philosophy

The firmware was designed around three primary objectives:

- Provide a lightweight software interface to the CNN accelerator.
- Keep computationally intensive operations inside dedicated RTL hardware.
- Maintain flexibility by implementing configurable post-processing in software.

Instead of using memory-mapped accelerator control registers, the firmware communicates with the accelerator through two custom RISC-V instructions implemented using the Pico Co-Processor Interface (PCPI). This approach minimizes software overhead while maintaining compatibility with the PicoRV32 processor architecture.

The firmware therefore serves as both the software controller and the post-processing engine of the complete CNN inference pipeline.

---

# Firmware Responsibilities

The firmware performs all software-controlled operations required during CNN inference.

Its responsibilities include:

- Configuring CNN weight parameters
- Configuring image parameters
- Starting CNN execution
- Reading accelerator-generated feature maps
- Performing Max Pooling
- Applying intermediate scaling
- Performing arithmetic right shifts
- Quantizing feature maps to INT8
- Clamping output values to the valid INT8 range
- Writing processed feature maps back into BRAM

By separating these operations from the RTL accelerator, the firmware enables future improvements to quantization and post-processing algorithms without requiring hardware redesign.

---

# Firmware Organization

The firmware is organized into multiple source files, each responsible for a specific stage of execution.

| File | Description |
|------|-------------|
| `start.S` | Processor startup, stack initialization, and firmware entry point |
| `cnn.S` | CNN inference program and execution of custom instructions |
| `data.S` | Input image buffers and output feature-map buffers |
| `weights_INT4_16_channel.S` | Quantized CNN weights stored in assembly format |
| `intermediate_scales.S` | Fixed-point per-channel scaling factors |
| `cifar10_TEST_gray_100_images.S` | CIFAR-10 grayscale test dataset |
| `maxpool_scale_quantize.c` | Software implementation of Max Pooling, scaling, quantization, and clamping |

This modular organization separates startup code, inference logic, datasets, and post-processing into independent source files, simplifying maintenance and verification.

---

# Firmware Architecture

The firmware interacts directly with both the PicoRV32 processor and the CNN accelerator.

Its responsibilities can be divided into two stages.

## Accelerator Control

Responsible for:

- Loading CNN configuration
- Executing custom instructions
- Managing CNN execution
- Monitoring accelerator completion

---

## Software Post-Processing

Responsible for:

- Reading INT16 feature maps
- Max Pooling
- Intermediate scaling
- Arithmetic right shift
- Quantization
- Output clamping
- Writing INT8 feature maps

This architecture allows the RTL accelerator to remain focused on high-performance convolution while the firmware performs configurable numerical processing.

---

# Firmware Execution Flow

The complete firmware execution sequence is illustrated below.

```text
Firmware Start
        │
        ▼
Initialize Runtime
        │
        ▼
Load CNN Parameters
        │
        ▼
Execute CNN_LD_WT
        │
        ▼
Execute CNN_LD_IMG_EXE
        │
        ▼
CNN Accelerator Executes
        │
        ▼
INT16 Feature Map Generated
        │
        ▼
Read Feature Map
        │
        ▼
Software Post-Processing
        │
        ▼
Store Final INT8 Feature Map
        │
        ▼
Program Complete
```

The firmware remains responsible for orchestrating the complete inference process while delegating convolutional computation to the RTL accelerator.

---

# Firmware Startup

Execution begins after the BootROM transfers control to the firmware entry point.

The startup code performs the following initialization tasks:

- Initialize the processor execution environment
- Configure the runtime stack
- Initialize memory used by the firmware
- Prepare the CNN inference environment
- Transfer execution to the main inference program

After initialization, control passes to the CNN firmware, where accelerator configuration and inference execution begin.

---

# Interaction with the CNN Accelerator

The firmware communicates with the CNN accelerator exclusively through two custom RISC-V instructions.

| Instruction | Purpose |
|-------------|---------|
| **CNN_LD_WT** | Configure weight-related parameters |
| **CNN_LD_IMG_EXE** | Configure image parameters and begin CNN execution |

The firmware does not directly manipulate internal accelerator registers. Instead, configuration parameters are transferred through the PCPI interface, where they are captured by dedicated configuration registers inside the accelerator.

This instruction-driven communication mechanism minimizes processor modifications while providing a clean and modular interface between software and hardware.

# Memory Organization

The firmware manages multiple memory regions during CNN inference. Each region stores a specific type of data required by either the RTL accelerator or the software post-processing pipeline.

The memory organization is illustrated below.

```text
Input Image (INT8)
        │
        ▼
CNN Weights (INT4)
        │
        ▼
Intermediate Scales (UINT16)
        │
        ▼
INT16 Feature Map
        │
        ▼
INT8 Output Feature Map
```

The firmware exchanges data with the CNN accelerator through Block RAM (BRAM). While the accelerator produces intermediate feature maps, the firmware retrieves these results for software-based post-processing before writing the final quantized output back into memory.

---

# CNN Accelerator Output

The RTL accelerator performs the computationally intensive stages of CNN inference.

Operations executed in hardware include:

- Weight Loading
- Image Loading
- Convolution
- Multiply-Accumulate (MAC)
- ReLU Activation

After completing these operations, the accelerator stores the generated feature map in BRAM using **INT16** precision.

The firmware then retrieves this feature map for software-based post-processing.

---

# Firmware Post-Processing Pipeline

Unlike convolution and MAC operations, post-processing is intentionally implemented in software.

This design enables quantization parameters and scaling algorithms to be modified without requiring changes to the RTL accelerator.

The complete software pipeline is shown below.

```text
Read INT16 Feature Map
        │
        ▼
Max Pooling (2×2)
        │
        ▼
Read Intermediate Scale
        │
        ▼
INT16 × UINT16 (Q16)
        │
        ▼
INT32
        │
        ▼
Arithmetic Right Shift
        │
        ▼
Quantization
        │
        ▼
Clamp
        │
        ▼
Store INT8 Feature Map
```

Each stage progressively converts the accelerator output into the quantized feature map required for subsequent CNN layers.

---

# Max Pooling

Max Pooling is the first software operation performed after accelerator execution.

The firmware applies channel-wise **2 × 2 Max Pooling** with a stride of **2**, reducing the spatial dimensions of the feature map while preserving the strongest activation within each pooling window.

### Pooling Parameters

| Parameter | Value |
|-----------|------:|
| Window Size | 2 × 2 |
| Stride | 2 |
| Operation | Channel-wise |

For every pooling window, the maximum of the four neighboring pixels is selected.

```text
┌─────┬─────┐
│  12 │  18 │
├─────┼─────┤
│   9 │  15 │
└─────┴─────┘

Maximum = 18
```

The pooled feature map remains in **INT16** format.

---

# Intermediate Scaling

After Max Pooling, the firmware applies per-channel intermediate scaling.

Each output channel is associated with an independent scaling factor represented using **16-bit fixed-point (Q16)** format.

The firmware multiplies every pooled feature-map value by its corresponding scaling factor.

```text
INT16 × UINT16 (Q16)
          │
          ▼
        INT32
```

Intermediate scaling compensates for the quantization applied during CNN model generation and preserves numerical accuracy before the final INT8 conversion.

---

# Arithmetic Right Shift

The multiplication performed during intermediate scaling produces a 32-bit fixed-point result.

To restore the correct numerical range, the firmware performs an arithmetic right shift by sixteen bits.

```c
product >>= 16;
```

This operation effectively removes the fractional portion of the Q16 fixed-point representation while preserving the sign of the value.

---

# Quantization

Following the arithmetic right shift, the firmware converts the scaled INT32 values into **INT8**.

```text
INT32
   │
   ▼
INT8
```

Reducing the numerical precision significantly decreases memory usage and bandwidth while maintaining sufficient inference accuracy for subsequent CNN layers.

The quantized feature map forms the primary output of the firmware processing stage.

---

# Clamping

Because quantization may produce values outside the valid INT8 range, every output value is saturated before storage.

The firmware performs clamping according to the following limits.

```text
-128 ≤ Output ≤ 127
```

Values exceeding these limits are clipped to the nearest valid INT8 value.

This guarantees that the generated feature map remains compatible with subsequent inference stages.

---

# Output Feature Map

After completing all post-processing operations, the firmware stores the final feature map back into BRAM.

Output format:

```text
INT8
```

The stored feature map can be:

- Used as the input to the next CNN layer
- Read by software for verification
- Compared against reference software implementations
- Examined during RTL and SoC simulations

---

# Data Representation

The firmware processes multiple numerical formats throughout the inference pipeline.

| Processing Stage | Data Type |
|------------------|-----------|
| Input Image | INT8 |
| CNN Weights | INT4 |
| Accelerator Output | INT16 |
| Max Pool Output | INT16 |
| Intermediate Scale | UINT16 (Q16) |
| After Scaling | INT32 |
| Final Output | INT8 |

The transition between these formats is intentionally designed to balance computational accuracy, memory usage, and hardware efficiency while maintaining compatibility with the RTL accelerator.

# Hardware–Software Partitioning

The CNN inference pipeline is intentionally divided between dedicated RTL hardware and PicoRV32 firmware. This hardware/software co-design allows computationally intensive operations to execute in specialized hardware while preserving software flexibility for configurable post-processing.

## RTL Accelerator

The RTL accelerator is responsible for the following operations:

- Weight Loading
- Image Loading
- Convolution
- Multiply-Accumulate (MAC)
- ReLU Activation
- INT16 Feature Map Generation

These operations dominate the computational workload of CNN inference and therefore benefit significantly from dedicated hardware implementation.

---

## PicoRV32 Firmware

The firmware is responsible for all configurable post-processing operations.

These include:

- Reading the INT16 feature map from BRAM
- Max Pooling
- Intermediate Scaling
- Arithmetic Right Shift
- Quantization
- Clamping
- Writing the final INT8 feature map back into BRAM

Implementing these operations in software allows numerical parameters and quantization strategies to be modified without changing the RTL design.

---

# Firmware Build Process

The firmware is assembled, compiled, and linked into several output formats used throughout development, simulation, and FPGA deployment.

The overall build flow is shown below.

```text
Assembly Files (.S)
        │
        ▼
C Source Files (.c)
        │
        ▼
RISC-V GCC Toolchain
        │
        ▼
Linker
        │
        ▼
Firmware Executable (.elf)
        │
        ├─────────────┐
        ▼             ▼
Binary (.bin)     Hex (.hex)
        │             │
        ▼             ▼
BRAM Images     FPGA Memory Files
```

The generated files support software development, RTL simulation, SoC simulation, and FPGA deployment.

---

# Firmware Build Outputs

| File | Purpose |
|------|----------|
| `firmware.elf` | Executable firmware with symbols for debugging |
| `firmware.bin` | Raw binary firmware image |
| `firmware.hex` | Hexadecimal image used during RTL simulation |
| `firmware.mem` | BRAM initialization file |
| `firmware.memh` | Hex memory initialization file |
| `firmware.coe` | Xilinx BRAM initialization file |
| `firmware_with_header.bin` | BootROM-compatible firmware image |

Each output format targets a different stage of development, allowing the same firmware source to be used across simulation and hardware platforms.

---

# Firmware Verification

The firmware was verified through both standalone software validation and complete hardware/software integration.

Verification confirmed:

- Successful firmware compilation
- Correct BootROM execution
- Proper runtime initialization
- Correct execution of custom instructions
- Successful accelerator configuration
- Correct BRAM accesses
- Generation of INT16 feature maps
- Successful software post-processing
- Correct generation of INT8 output feature maps

UART debug messages were used extensively during simulation to monitor execution progress and verify correct interaction between the processor and the CNN accelerator.

---

# End-to-End Firmware Execution

The complete firmware execution sequence is summarized below.

```text
BootROM
    │
    ▼
Firmware Startup
    │
    ▼
Runtime Initialization
    │
    ▼
Load CNN Parameters
    │
    ▼
CNN_LD_WT
    │
    ▼
CNN_LD_IMG_EXE
    │
    ▼
RTL CNN Accelerator
    │
    ▼
INT16 Feature Map
    │
    ▼
Max Pooling
    │
    ▼
Intermediate Scaling
    │
    ▼
Arithmetic Right Shift
    │
    ▼
Quantization
    │
    ▼
Clamp
    │
    ▼
Store INT8 Feature Map
    │
    ▼
Inference Complete
```

This execution flow illustrates the interaction between firmware and hardware throughout a complete inference cycle.

---

# Design Considerations

The firmware was designed with the following objectives:

- Minimize processor overhead
- Keep convolutional computation in dedicated RTL hardware
- Provide programmable post-processing
- Support efficient memory access
- Simplify verification
- Maintain compatibility with PicoRV32
- Enable future accelerator extensions

By separating accelerator control from numerical post-processing, the firmware provides a flexible software layer while allowing the RTL accelerator to remain focused on high-performance computation.

---

# Advantages

The implemented firmware architecture provides several benefits.

## Performance

- Hardware acceleration for computationally intensive CNN operations
- Reduced processor workload
- Efficient BRAM utilization
- Lightweight accelerator configuration

---

## Flexibility

- Software-controlled post-processing
- Easy modification of scaling parameters
- Adjustable quantization algorithms
- No RTL changes required for firmware updates

---

## Verification

- Straightforward RTL debugging
- Easy software debugging through UART
- Independent validation of firmware and hardware
- Complete end-to-end SoC verification

---

## Scalability

The modular firmware architecture can be extended to support:

- Additional CNN layers
- Alternative pooling algorithms
- Different quantization schemes
- Additional custom instructions
- Future accelerator revisions

---

# Figures

The following figures accompany this document.

### Architecture

- Firmware Execution Flow
- Hardware–Software Partitioning
- Memory Organization

### Processing Pipeline

- Firmware Post-Processing Flow
- Quantization Pipeline
- Data Representation

### Verification

- RTL Simulation Results
- SoC Simulation Results
- UART Debug Output

All figures are available in the `images/firmware/` directory.

---

# Summary

The firmware serves as the software control layer of the CNN-RISC-V Accelerator, coordinating communication between the PicoRV32 processor and the custom RTL accelerator through two PCPI-based custom instructions.

While the RTL accelerator performs weight loading, image loading, convolution, multiply-accumulate operations, and ReLU activation, the firmware executes all programmable post-processing, including Max Pooling, intermediate scaling, arithmetic right shifting, quantization, clamping, and final feature map generation.

This hardware/software partition combines the computational efficiency of dedicated RTL hardware with the flexibility of software, enabling algorithmic modifications without requiring hardware redesign. The modular firmware architecture, together with comprehensive RTL and SoC verification, provides a scalable foundation for future CNN accelerator development and embedded AI applications.

