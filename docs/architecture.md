# CNN-RISC-V Accelerator Architecture

## Overview

The CNN-RISC-V Accelerator is a hardware/software co-design developed during the Summer Internship to accelerate Convolutional Neural Network (CNN) inference on a RISC-V processor.

The system integrates a modified PicoRV32 processor with a custom CNN coprocessor through the Pico Co-Processor Interface (PCPI). The architecture partitions CNN inference between dedicated RTL hardware and PicoRV32 firmware, allowing computationally intensive operations to execute in hardware while programmable post-processing remains in software.

This approach provides a modular, scalable, and easily verifiable architecture suitable for embedded CNN inference.

---

# System Architecture

The complete system consists of the following major components:

- PicoRV32 RISC-V Processor
- CNN PCPI Coprocessor
- BootROM
- Block RAM (BRAM)
- SPI Flash
- UART Lite
- GPIO
- AXI Interconnect

The PicoRV32 processor controls the accelerator through custom RISC-V instructions while the accelerator performs CNN computation.

---

# Overall Architecture

The complete inference pipeline is divided into two execution domains.

## RTL Hardware

Responsible for computationally intensive CNN operations.

Operations include:

- Weight Loading
- Image Loading
- Convolution
- Multiply-Accumulate (MAC)
- ReLU Activation
- INT16 Feature Map Generation

---

## Firmware

Responsible for configurable post-processing.

Operations include:

- Max Pooling
- Intermediate Scaling
- Arithmetic Right Shift
- Quantization
- Clamping
- Output Feature Map Storage

This partition keeps the accelerator focused on high-throughput computation while maintaining software flexibility for quantization and output processing.

---

# Hardware Architecture

The CNN accelerator is connected directly to PicoRV32 using the Pico Co-Processor Interface (PCPI).

The accelerator receives configuration information from the processor and performs CNN computation independently.

The RTL accelerator performs:

1. Load CNN Weights
2. Load Input Feature Map
3. Convolution
4. Multiply-Accumulate (MAC)
5. ReLU Activation
6. Store INT16 Feature Map into BRAM

The accelerator output is stored as an INT16 feature map.

---

# Firmware Architecture

After the RTL accelerator finishes execution, PicoRV32 firmware performs post-processing on the generated INT16 feature map.

The firmware executes the following sequence:

1. Read INT16 Feature Map from BRAM
2. Perform Max Pooling (2 × 2)
3. Read Intermediate Scaling Factors
4. Multiply pooled INT16 values by UINT16 (Q16) scales
5. Produce INT32 intermediate values
6. Arithmetic Right Shift
7. Quantize to INT8
8. Clamp to the valid INT8 range
9. Store the final INT8 feature map into BRAM

Separating these operations into firmware allows quantization parameters and post-processing algorithms to be modified without requiring RTL changes.

---

# PCPI Interface

Communication between PicoRV32 and the CNN accelerator occurs through the Pico Co-Processor Interface (PCPI).

## Request Signals

| Signal | Description |
|----------|-------------|
| pcpi_valid | Indicates a valid custom instruction |
| pcpi_insn | 32-bit custom instruction |
| pcpi_rs1 | Source Register 1 |
| pcpi_rs2 | Source Register 2 |

---

## Response Signals

| Signal | Description |
|----------|-------------|
| pcpi_ready | Instruction completed |
| pcpi_wr | Register write-back enable |
| pcpi_rd | Data returned to PicoRV32 |
| pcpi_wait | Processor stall request |

During verification, the accelerator immediately acknowledged each custom instruction.

Therefore,

- pcpi_ready = 1
- pcpi_wr = 1
- pcpi_wait = 0

The standard PCPI interface supports asserting `pcpi_wait` whenever multi-cycle accelerator execution is required. During custom instruction verification, it remained deasserted because the objective was to validate instruction decoding, configuration register updates, and PCPI communication.

---

# Custom Instructions

Two custom RISC-V instructions were designed for accelerator configuration.

## CNN_LD_WT

Purpose:

Configure CNN weight parameters.

The instruction stores:

- Weight Base Address
- Input Channel Count
- Output Channel Count

The captured values are stored in internal configuration registers.

---

## CNN_LD_IMG_EXE

Purpose:

Configure image parameters and initiate CNN execution.

The instruction stores:

- Image Base Address
- Result Buffer Address
- Image Size

After updating these registers, the accelerator asserts:

```
start_cnn
```

to begin CNN execution.

---

# Configuration Registers

The accelerator contains dedicated configuration registers.

| Register | Description |
|-----------|-------------|
| weight_base | Weight memory base address |
| image_base | Input image address |
| result_base | Output feature map address |
| input_channels | Number of input channels |
| output_channels | Number of output channels |
| image_size | Input image dimension |
| start_cnn | Accelerator start signal |

These registers are programmed entirely through the custom instructions.

---

# CNN Processing Pipeline

The complete CNN inference pipeline is shown below.

```
Input Image (INT8)
        │
        ▼
CNN_LD_WT
        │
Load Weight Configuration
        ▼
CNN_LD_IMG_EXE
        │
Load Image Configuration
        │
start_cnn
        ▼
──────────────────────────────
CNN Accelerator (RTL)
──────────────────────────────
Weight Loader
        │
Image Loader
        │
Convolution
        │
MAC
        │
ReLU
        │
Store INT16 Feature Map
        ▼
BRAM
──────────────────────────────
        │
Read INT16 Feature Map
        ▼
PicoRV32 Firmware
──────────────────────────────
Max Pooling
        │
Multiply by Intermediate Scale
        │
INT16 × UINT16 (Q16)
        ▼
INT32
        │
Arithmetic Right Shift
        ▼
Quantization
        ▼
Clamp
        ▼
Store INT8 Feature Map
        ▼
BRAM
```

---

# Data Representation

The inference pipeline uses multiple numerical formats.

| Stage | Data Type |
|----------|-----------|
| Input Image | INT8 |
| Convolution Output | INT16 |
| Max Pool Output | INT16 |
| Intermediate Scale | UINT16 (Q16) |
| Scaling Result | INT32 |
| Final Output | INT8 |

---

# End-to-End Execution

The complete execution flow is:

1. BootROM initializes the system.
2. Firmware starts execution.
3. Firmware loads CNN parameters.
4. Firmware executes `CNN_LD_WT`.
5. Firmware executes `CNN_LD_IMG_EXE`.
6. Accelerator receives configuration.
7. Accelerator asserts `start_cnn`.
8. Accelerator loads weights.
9. Accelerator loads image data.
10. Accelerator performs convolution.
11. Accelerator performs MAC operations.
12. Accelerator performs ReLU activation.
13. Accelerator stores the INT16 feature map into BRAM.
14. Firmware reads the INT16 feature map.
15. Firmware performs Max Pooling.
16. Firmware applies per-channel intermediate scaling.
17. Firmware performs arithmetic right shift.
18. Firmware quantizes the output.
19. Firmware clamps the output to the valid INT8 range.
20. Firmware stores the final INT8 feature map back into BRAM.

---

# Hardware / Software Partitioning

## RTL Accelerator

Responsible for:

- Weight Loading
- Image Loading
- Convolution
- MAC Computation
- ReLU Activation
- INT16 Feature Map Generation

---

## PicoRV32 Firmware

Responsible for:

- Max Pooling
- Intermediate Scaling
- Arithmetic Right Shift
- Quantization
- Clamping
- Output Feature Map Storage

This partition enables computationally intensive operations to execute in dedicated hardware while maintaining programmable post-processing in firmware.

---

# Verification

The architecture was verified using both RTL and complete SoC simulations.

## RTL Verification

Verified:

- Custom instruction decoding
- Configuration register updates
- PCPI request detection
- PCPI response generation
- Debug signature generation
- Register write-back

---

## SoC Verification

Verified:

- BootROM execution
- Firmware loading
- PicoRV32 execution
- CNN custom instruction execution
- Accelerator configuration
- UART debug messages
- Complete processor-to-accelerator communication

---

# Figures

The following figures illustrate the architecture.

- Overall SoC Block Diagram
- PCPI Interface Diagram
- CNN Processing Flow
- RTL Simulation Results
- SoC Simulation Results

All figures are available in the `images/architecture` directory.

---

# Summary

The CNN-RISC-V Accelerator combines a custom RTL accelerator with PicoRV32 firmware to implement an efficient hardware/software co-design for CNN inference.

The RTL accelerator performs computationally intensive operations including weight loading, convolution, MAC computation, and ReLU activation, while firmware performs Max Pooling, intermediate scaling, quantization, and output formatting.

Communication between hardware and software is achieved using two custom RISC-V instructions implemented through the Pico Co-Processor Interface (PCPI), providing a clean and extensible interface between the processor and the CNN accelerator.