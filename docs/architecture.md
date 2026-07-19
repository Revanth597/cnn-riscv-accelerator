# CNN-RISC-V Accelerator Architecture

## Overview

The **CNN-RISC-V Accelerator** is a hardware/software co-designed CNN inference engine developed during the Summer Internship. The system integrates a modified **PicoRV32 RISC-V processor** with a custom RTL CNN accelerator through the **Pico Co-Processor Interface (PCPI)**.

The architecture accelerates computationally intensive CNN operations in dedicated hardware while retaining configurable post-processing within firmware. This partitioning provides a lightweight, modular, and extensible platform for embedded CNN inference.

---

# System Architecture

The complete System-on-Chip (SoC) consists of the following major components:

- PicoRV32 RISC-V Processor
- CNN PCPI Accelerator
- BootROM
- Block RAM (BRAM)
- AXI Interconnect
- AXI BRAM Controller
- AXI UART Lite
- AXI GPIO
- AXI Quad SPI
- External SPI Flash

The PicoRV32 processor configures and controls the CNN accelerator using custom RISC-V instructions, while the accelerator independently performs the computationally intensive stages of CNN inference.

---

# Hardware–Software Partitioning

CNN inference is intentionally divided between dedicated RTL hardware and PicoRV32 firmware.

## RTL Accelerator

The RTL accelerator is responsible for the computationally intensive stages of inference.

Operations performed in hardware include:

- Weight Loading
- Image Loading
- Convolution
- Multiply-Accumulate (MAC)
- ReLU Activation
- INT16 Feature Map Generation

---

## PicoRV32 Firmware

The firmware performs configurable post-processing after the RTL accelerator completes execution.

Operations include:

- Max Pooling
- Intermediate Scaling
- Arithmetic Right Shift
- Quantization
- Clamping
- INT8 Output Feature Map Storage

Keeping these operations in firmware allows quantization parameters and post-processing algorithms to be modified without requiring RTL redesign.

---

# SoC Architecture

The complete architecture is centered around the PicoRV32 processor and an AXI-based peripheral subsystem.

The processor communicates with memory and peripherals through the AXI interconnect while interacting with the CNN accelerator through the Pico Co-Processor Interface (PCPI).

The overall architecture is illustrated below.

> **Figure:** SoC Block Diagram

---

# CNN Accelerator

The CNN accelerator is implemented entirely in RTL and performs the computationally intensive stages of CNN inference.

The accelerator performs the following operations:

1. Load CNN Weights
2. Load Input Image
3. Convolution
4. Multiply-Accumulate (MAC)
5. ReLU Activation
6. Store INT16 Feature Map into BRAM

The generated INT16 feature map is subsequently processed by PicoRV32 firmware.

---

# Firmware

After the accelerator completes execution, PicoRV32 firmware performs software-based post-processing.

Execution sequence:

1. Read INT16 Feature Map from BRAM
2. Perform Max Pooling (2 × 2)
3. Read Intermediate Scaling Factors
4. Multiply pooled INT16 values by UINT16 (Q16) scaling factors
5. Produce INT32 intermediate values
6. Perform Arithmetic Right Shift
7. Quantize to INT8
8. Clamp to the valid INT8 range
9. Store the final INT8 feature map into BRAM

Separating these operations into firmware enables rapid modification of scaling and quantization algorithms without requiring hardware changes.

---

# PCPI Interface

Communication between PicoRV32 and the CNN accelerator is implemented using the **Pico Co-Processor Interface (PCPI)**.

## Request Signals

| Signal | Description |
|----------|-------------|
| `pcpi_valid` | Indicates a valid custom instruction |
| `pcpi_insn` | 32-bit instruction word |
| `pcpi_rs1` | Source Register 1 |
| `pcpi_rs2` | Source Register 2 |

---

## Response Signals

| Signal | Description |
|----------|-------------|
| `pcpi_ready` | Accelerator has completed execution |
| `pcpi_wr` | Register write-back enable |
| `pcpi_rd` | Data returned to PicoRV32 |
| `pcpi_wait` | Requests processor stall during multi-cycle execution |

During accelerator verification, the custom instructions completed without asserting `pcpi_wait`. The interface nevertheless remains compatible with multi-cycle accelerator implementations whenever processor stalling is required.

---

# Custom Instructions

Two custom RISC-V instructions were designed to configure and control the CNN accelerator.

## CNN_LD_WT

Purpose:

Configure CNN weight parameters.

The instruction stores:

- Weight Base Address
- Input Channel Count
- Output Channel Count

These parameters are written into internal accelerator configuration registers.

---

## CNN_LD_IMG_EXE

Purpose:

Configure image parameters and initiate CNN execution.

The instruction stores:

- Image Base Address
- Result Buffer Address
- Image Size

After updating the configuration registers, the accelerator asserts

```text
start_cnn
```

to begin CNN execution.

---

# Configuration Registers

The accelerator contains dedicated configuration registers programmed entirely through the custom instructions.

| Register | Description |
|-----------|-------------|
| `weight_base` | Weight memory base address |
| `image_base` | Input image base address |
| `result_base` | Output feature map address |
| `input_channels` | Number of input channels |
| `output_channels` | Number of output channels |
| `image_size` | Input image dimension |
| `start_cnn` | Accelerator start signal |

---

# CNN Processing Pipeline

```text
Input Image (INT8)
        │
        ▼
CNN_LD_WT
        │
        ▼
CNN_LD_IMG_EXE
        │
        ▼
start_cnn
        │
        ▼
──────────────────────────────
RTL CNN Accelerator
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
──────────────────────────────
        │
        ▼
BRAM
        │
        ▼
──────────────────────────────
PicoRV32 Firmware
──────────────────────────────
Read INT16 Feature Map
        │
Max Pooling
        │
Intermediate Scaling
        │
INT16 × UINT16 (Q16)
        │
INT32
        │
Arithmetic Right Shift
        │
Quantization
        │
Clamp
        │
Store INT8 Feature Map
──────────────────────────────
```

---

# Data Representation

The inference pipeline uses multiple numerical formats.

| Processing Stage | Data Type |
|------------------|-----------|
| Input Image | INT8 |
| Accelerator Output | INT16 |
| Intermediate Scale | UINT16 (Q16) |
| After Scaling | INT32 |
| Final Output | INT8 |

---

# End-to-End Execution

The complete execution flow is summarized below.

1. BootROM initializes the system.
2. Firmware begins execution.
3. Firmware loads CNN parameters.
4. `CNN_LD_WT` configures weight parameters.
5. `CNN_LD_IMG_EXE` configures image parameters.
6. The accelerator asserts `start_cnn`.
7. CNN weights are loaded.
8. Input image data are loaded.
9. Convolution is performed.
10. MAC computation is executed.
11. ReLU activation is applied.
12. The INT16 feature map is written to BRAM.
13. Firmware reads the INT16 feature map.
14. Firmware performs Max Pooling.
15. Intermediate scaling is applied.
16. Arithmetic right shift is performed.
17. Results are quantized to INT8.
18. Values are clamped to the valid INT8 range.
19. The final INT8 feature map is stored back into BRAM.

---

# Verification

The architecture was verified using both RTL simulation and complete SoC simulation.

## RTL Verification

The following components were verified:

- Custom instruction decoding
- Configuration register programming
- PCPI request detection
- PCPI response generation
- Accelerator control logic
- Register write-back
- Debug signature generation

---

## SoC Verification

The complete embedded system was verified, including:

- BootROM execution
- Firmware loading
- PicoRV32 execution
- CNN custom instruction execution
- Accelerator configuration
- UART debug output
- End-to-end processor-to-accelerator communication

---

# Figures

The following figures accompany this document:

- SoC Block Diagram
- CNN Processing Flow
- PCPI Interface
- RTL Simulation Results
- SoC Simulation Results

All figures are available in the `images/architecture/` directory.

---

# Summary

The CNN-RISC-V Accelerator demonstrates a hardware/software co-designed embedded CNN inference architecture built around a modified PicoRV32 processor and a custom RTL accelerator.

The RTL accelerator performs weight loading, image loading, convolution, MAC computation, ReLU activation, and INT16 feature map generation, while PicoRV32 firmware performs Max Pooling, intermediate scaling, quantization, clamping, and final output generation.

Communication between the processor and accelerator is implemented through two custom RISC-V instructions using the Pico Co-Processor Interface (PCPI), providing a modular and extensible architecture suitable for embedded CNN acceleration.