# SoC Simulation Source

## Overview

This directory contains the modified PicoRV32 processor used during complete System-on-Chip (SoC) simulation of the CNN-RISC-V Accelerator.

The processor has been extended to support the custom CNN accelerator through the Pico Co-Processor Interface (PCPI). These modifications enable the execution of application-specific RISC-V instructions that configure and control the accelerator during CNN inference.

Unlike the standalone RTL verification environment, this directory represents the processor source used during complete SoC simulation, where the processor, BootROM, firmware, peripherals, and CNN accelerator operate together as a unified embedded system.

---

# Directory Structure

| File | Description |
|------|-------------|
| `picorv32.v` | Modified PicoRV32 processor with CNN PCPI integration |
| `picorv32_core.v` | PicoRV32 processor core implementing the execution pipeline |

---

# Purpose

The purpose of this directory is to provide the processor implementation used during complete SoC verification.

The modified processor enables:

- Execution of standard RV32I instructions
- Detection of custom CNN instructions
- Communication with the CNN accelerator through PCPI
- BootROM execution
- Firmware execution
- Complete embedded system simulation

This processor serves as the software execution engine of the CNN-RISC-V Accelerator platform.

---

# Processor Architecture

The modified processor consists of two primary modules.

```text
                 PicoRV32 Processor
                        │
         ┌──────────────┴──────────────┐
         │                             │
         ▼                             ▼
   picorv32_core.v              PCPI Interface
                                       │
                                       ▼
                           CNN PCPI Accelerator
```

The processor core executes standard RISC-V instructions while the PCPI interface forwards custom instructions to the CNN accelerator.

---

# Processor Modifications

The original PicoRV32 processor was extended to support hardware acceleration through the Pico Co-Processor Interface (PCPI).

The modifications include:

- Custom instruction detection
- PCPI request generation
- PCPI response handling
- Accelerator configuration support
- CNN execution control

These additions enable accelerator integration while preserving compatibility with the standard PicoRV32 architecture.

---

# PCPI Integration

Communication between PicoRV32 and the CNN accelerator occurs through the standard Pico Co-Processor Interface.

## Request Signals

| Signal | Description |
|---------|-------------|
| `pcpi_valid` | Indicates a valid custom instruction |
| `pcpi_insn` | Complete instruction word |
| `pcpi_rs1` | Source Register 1 |
| `pcpi_rs2` | Source Register 2 |

---

## Response Signals

| Signal | Description |
|---------|-------------|
| `pcpi_ready` | Instruction completed |
| `pcpi_wr` | Register write-back enable |
| `pcpi_rd` | Returned debug data |
| `pcpi_wait` | Requests processor stall during multi-cycle execution |

The processor communicates with the accelerator exclusively through these standard PCPI signals.

---

# Custom Instruction Support

The modified processor supports two custom CNN instructions.

## CNN_LD_WT

Responsible for configuring:

- Weight Base Address
- Input Channel Count
- Output Channel Count

---

## CNN_LD_IMG_EXE

Responsible for configuring:

- Image Base Address
- Result Buffer Address
- Image Size

After configuration, the accelerator asserts the internal `start_cnn` signal to begin CNN execution.

---

# Execution Flow

The interaction between the processor and the CNN accelerator follows the sequence below.

```text
Reset
    │
    ▼
BootROM
    │
    ▼
Firmware Execution
    │
    ▼
CNN_LD_WT
    │
    ▼
Update Accelerator Registers
    │
    ▼
CNN_LD_IMG_EXE
    │
    ▼
Assert start_cnn
    │
    ▼
CNN Accelerator Executes
```

The processor continues normal execution after the accelerator acknowledges each custom instruction through the PCPI interface.

---

# Role Within the Project

This directory provides the processor implementation used throughout the complete hardware/software co-design.

It enables:

- BootROM execution
- Firmware execution
- Custom instruction support
- Accelerator configuration
- Complete SoC verification

The processor therefore serves as the central controller of the CNN-RISC-V Accelerator platform.

---

# Related Directories

| Directory | Purpose |
|------------|---------|
| `rtl-simulation/` | Standalone RTL verification environment |
| `images/soc_simulation/` | SoC simulation waveforms and verification figures |
| `cnn-software/` | Firmware executed by the processor |
| `docs/` | Detailed architecture and firmware documentation |

---

# Summary

This directory contains the modified PicoRV32 processor used during complete System-on-Chip simulation of the CNN-RISC-V Accelerator.

By extending the standard PicoRV32 architecture with Pico Co-Processor Interface (PCPI) support, the processor is able to execute custom CNN instructions, configure the hardware accelerator, and coordinate embedded CNN inference while maintaining compatibility with the standard RISC-V execution model.

Together with the BootROM, firmware, and CNN accelerator, these processor modifications form the software control layer of the complete embedded AI platform.