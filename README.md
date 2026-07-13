# CNN Hardware Accelerator for RISC-V
### Summer Internship Project | CIE Silicon

> Firmware development, custom RISC-V ISA extensions, PicoRV32 processor modifications, RTL verification, and full SoC integration for CNN inference acceleration.

---

# Overview

This repository documents **my contributions** during a Summer Internship at **CIE Silicon** on a CNN Hardware Accelerator project built around the PicoRV32 RISC-V processor.

The objective of the project was to accelerate CNN inference by extending the RISC-V ISA with custom instructions, modifying the processor to support them, developing the required firmware, and validating the complete design through RTL behavioral simulation and full SoC simulation.

This repository focuses exclusively on the components that I designed and implemented during the internship.

---

# Project Context

The CNN Hardware Accelerator was developed as a collaborative internship project involving multiple contributors.

My work primarily focused on the **hardware/software co-design** aspects of the accelerator, including:

- Firmware development
- Boot ROM generation
- Custom instruction design
- PicoRV32 processor modifications
- RTL verification
- Full SoC simulation and validation

---

# My Responsibilities

## Firmware Development

- Developed firmware for CNN inference.
- Built the Boot ROM used during processor execution.
- Developed software utilities and build scripts.

---

## Custom RISC-V Instruction Design

Designed and implemented two custom RISC-V instructions for CNN acceleration.

| Instruction | Description |
|-------------|-------------|
| **CNN_LD_WT** | Loads CNN weights into the accelerator. |
| **CNN_LD_IMG_EXE** | Loads the input image and initiates CNN execution. |

The custom instructions use the RISC-V **Custom-0 opcode (`0x2B`)**.

- **CNN_LD_WT** → `funct3 = 000`
- **CNN_LD_IMG_EXE** → `funct3 = 001`

---

## Processor Modifications

Modified the PicoRV32 processor RTL to support the newly designed CNN instructions.

This included:

- ISA extension support
- Instruction decoding
- Processor integration
- RTL modifications

---

## RTL Behavioral Verification

Developed an RTL verification environment for validating the custom instructions.

Activities included:

- Testbench development
- Firmware execution in simulation
- Processor verification
- Instruction-level validation

---

## Full SoC Simulation

Integrated the modified PicoRV32 processor into the complete SoC environment used during the internship.

Performed system-level simulations to verify:

- Boot ROM execution
- Firmware execution
- Processor integration
- Correct operation of the custom instructions within the complete SoC

---

# Repository Structure

```
cnn-riscv-accelerator
│
├── cnn-software
│   ├── bootrom
│   ├── firmware
│   ├── scripts
│   ├── Makefile
│   ├── config.mk
│   └── TOOLCHAIN_SETUP.md
│
├── rtl-simulation
│   ├── testbench
│   └── README.md
│
├── soc-simulation
│   ├── modified-picorv32
│   └── README.md
│
├── docs
│   ├── architecture.md
│   ├── custom_instructions.md
│   └── firmware_design.md
│
├── images
│
├── results
│
├── LICENSE
├── .gitignore
└── README.md
```

---

# Development Workflow

```
Firmware Development
        │
        ▼
Custom Instruction Design
        │
        ▼
PicoRV32 Processor Modification
        │
        ▼
RTL Behavioral Verification
        │
        ▼
Full SoC Integration
        │
        ▼
CNN Execution
```

---

# Custom Instruction Flow

```
Firmware
      │
      ▼
CNN_LD_WT
      │
Loads CNN Weights
      │
      ▼
CNN_LD_IMG_EXE
      │
Loads Input Image
Starts CNN Execution
      │
      ▼
CNN Accelerator
```

---

# Repository Description

## cnn-software

Contains the software developed during the internship.

Includes:

- Boot ROM
- Firmware
- Build scripts
- Toolchain configuration

---

## rtl-simulation

Contains the RTL verification environment used for validating the custom instructions.

Includes:

- RTL testbench
- Firmware memory image
- Simulation RTL
- Verification environment

---

## soc-simulation

Contains the modified PicoRV32 processor used during complete SoC simulation.

This stage validates processor modifications within the complete hardware platform.

---

## docs

Contains project documentation including:

- Architecture
- Firmware design
- Custom instruction documentation

---

## images

Project figures, architecture diagrams and simulation screenshots.

---

## results

Simulation outputs and experimental results.

---

# Technical Skills Demonstrated

- RISC-V Computer Architecture
- ISA Extension Design
- Firmware Development
- Embedded Systems
- RTL Design
- RTL Verification
- Verilog HDL
- Computer Architecture
- Hardware/Software Co-design
- Processor Integration
- SoC Simulation

---

# Future Improvements

Potential future enhancements include:

- Additional CNN-specific custom instructions
- Performance benchmarking
- FPGA implementation
- Hardware performance analysis
- Automated verification framework
- Support for larger CNN architectures

---

# Acknowledgements

This work was completed during a **Summer Internship at CIE Silicon** as part of a collaborative CNN Hardware Accelerator project.

This repository documents **my individual contributions**, including firmware development, custom instruction design, PicoRV32 processor modifications, RTL verification, and system-level integration.