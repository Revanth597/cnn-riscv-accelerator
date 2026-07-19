# Architecture Figures

## Overview

This directory contains the architectural figures used throughout the documentation of the **CNN-RISC-V Accelerator**.

The figures illustrate the complete System-on-Chip (SoC) architecture, memory organization, processor-to-accelerator communication, CNN inference pipeline, and system boot process. Together, they provide a visual representation of how the hardware and firmware components interact during CNN inference.

---

# Figure Index

| Figure | Description |
|---------|-------------|
| **01_soc_block_design.png** | Complete Vivado System-on-Chip block design |
| **02_memory_mappings.png** | Memory organization of the CNN accelerator system |
| **03_pcpi_interface_diagram.png** | PCPI communication between PicoRV32 and the CNN accelerator |
| **04_cnn_process_flow.png** | Hardware/software CNN inference pipeline |
| **05_boot_process_flow.png** | System boot sequence from reset to CNN execution |

---

# 01_soc_block_design.png

## Description

This figure presents the complete Vivado block design of the CNN-RISC-V Accelerator System-on-Chip.

The architecture integrates the PicoRV32 processor with memory, peripherals, and the custom CNN accelerator to form a complete embedded inference platform.

Major components include:

- PicoRV32 Processor
- AXI Interconnect
- AXI BRAM Controller
- Block RAM
- AXI Quad SPI
- SPI Flash
- AXI UART Lite
- AXI GPIO
- Clock Wizard
- Processor System Reset

The processor communicates with memory and peripherals through the AXI subsystem while controlling the CNN accelerator through the Pico Co-Processor Interface (PCPI).

---

# 02_memory_mappings.png

## Description

This figure illustrates the memory organization used by the CNN-RISC-V Accelerator.

The memory map shows how firmware, BootROM, input images, CNN weights, intermediate feature maps, scaling factors, and output feature maps are organized within the system memory.

The figure helps explain:

- BootROM memory allocation
- BRAM organization
- Firmware storage
- CNN weight storage
- Input image buffers
- Intermediate feature maps
- Output feature maps

Understanding this memory organization is essential for following the interaction between firmware and the RTL accelerator.

---

# 03_pcpi_interface_diagram.png

## Description

This figure illustrates the communication interface between PicoRV32 and the CNN accelerator.

The PCPI interface enables software to configure and control the accelerator using two custom RISC-V instructions without requiring memory-mapped control registers.

The figure includes:

- Custom instruction decoder
- Configuration registers
- CNN control logic
- PCPI request interface
- PCPI response interface
- BRAM interface
- Accelerator datapath

### PCPI Request Signals

| Signal | Description |
|---------|-------------|
| `pcpi_valid` | Valid custom instruction |
| `pcpi_insn` | 32-bit instruction word |
| `pcpi_rs1` | Source Register 1 |
| `pcpi_rs2` | Source Register 2 |

### PCPI Response Signals

| Signal | Description |
|---------|-------------|
| `pcpi_ready` | Instruction complete |
| `pcpi_wr` | Register write enable |
| `pcpi_rd` | Return data |
| `pcpi_wait` | Processor stall request |

During verification, the implemented custom instructions completed immediately after decoding. Consequently, `pcpi_ready`, `pcpi_wr`, and `pcpi_rd` were asserted while `pcpi_wait` remained deasserted.

---

# 04_cnn_process_flow.png

## Description

This figure illustrates the complete CNN inference pipeline implemented by the project.

The pipeline is partitioned between dedicated RTL hardware and PicoRV32 firmware.

## RTL Accelerator

The hardware accelerator performs:

- Weight Loading
- Image Loading
- Convolution
- Multiply-Accumulate (MAC)
- ReLU Activation
- INT16 Feature Map Generation

The generated feature map is stored in BRAM.

---

## PicoRV32 Firmware

The firmware performs:

- Read INT16 Feature Map
- Max Pooling
- Intermediate Scaling
- Arithmetic Right Shift
- Quantization
- Clamping
- Store Final INT8 Feature Map

This hardware/software partition provides high computational throughput while maintaining flexibility for post-processing.

---

# 05_boot_process_flow.png

## Description

This figure illustrates the complete boot sequence of the CNN-RISC-V Accelerator system.

The execution begins after reset and continues until CNN inference is initiated.

The boot process includes:

- System Reset
- Clock Initialization
- BootROM Execution
- Firmware Initialization
- Peripheral Initialization
- CNN Parameter Configuration
- Execution of `CNN_LD_WT`
- Execution of `CNN_LD_IMG_EXE`
- Assertion of `start_cnn`
- CNN Accelerator Execution

The figure provides a high-level overview of the interaction between BootROM, firmware, and the hardware accelerator during system startup.

---

# Summary

The figures contained in this directory collectively document the architecture of the CNN-RISC-V Accelerator, including the complete SoC organization, memory architecture, processor-to-accelerator communication, CNN inference pipeline, and system boot sequence.

Together, they provide a comprehensive visual reference for understanding the hardware/software co-design implemented in this project.