# RTL Simulation

## Overview

This directory contains the standalone RTL testbench used to verify the custom CNN accelerator integrated with the PicoRV32 processor through the Pico Co-Processor Interface (PCPI).

Unlike the complete System-on-Chip (SoC) simulation, this environment focuses exclusively on verifying the processor-to-accelerator communication interface in isolation. The standalone testbench provides a lightweight verification platform for validating custom instruction decoding, configuration register programming, PCPI handshaking, and accelerator control logic before system-level integration.

The testbench loads the firmware memory image, instantiates the modified PicoRV32 processor together with the CNN PCPI module, and executes custom RISC-V instructions under simulation.

---

# Directory Contents

| File | Description |
|------|-------------|
| `pcpi_cnn_tb.v` | Standalone RTL simulation testbench |
| `picorv32.v` | Modified PicoRV32 processor containing PCPI support |
| `picorv32_pcpi_cnn.v` | CNN PCPI coprocessor implementing the custom instructions |
| `firmware.memh` | Firmware memory image loaded during simulation |

---

# Verification Architecture

The standalone RTL verification environment consists of the following components.

```text
                    firmware.memh
                          │
                          ▼
                  Instruction Memory
                          │
                          ▼
                   Modified PicoRV32
                          │
                    PCPI Interface
                          │
                          ▼
                CNN PCPI Accelerator
                          │
                    Debug Responses
```

The processor executes firmware stored in `firmware.memh`, while custom instructions are intercepted by the PCPI interface and forwarded to the CNN accelerator for verification.

---

# Testbench

The testbench (`pcpi_cnn_tb.v`) provides the complete standalone verification environment.

Major responsibilities include:

- Clock generation
- Reset generation
- Firmware memory initialization
- Instruction memory emulation
- PicoRV32 instantiation
- CNN PCPI module instantiation
- Memory response generation
- Simulation control

The testbench emulates the minimum hardware required for the processor to execute firmware and interact with the CNN accelerator.

---

# Clock and Reset

The simulation begins by generating the processor clock and reset signals.

The testbench is responsible for:

- Generating the system clock
- Applying reset
- Releasing reset after initialization
- Starting processor execution

Once reset is released, PicoRV32 begins fetching instructions from the firmware memory image.

---

# Firmware Memory

The firmware program is loaded from

```text
firmware.memh
```

The memory image contains:

- Boot code
- CNN inference firmware
- Custom instruction execution
- Test data

During simulation, this file is loaded into the instruction memory used by the processor.

---

# Modified PicoRV32

The modified PicoRV32 processor executes the firmware and forwards custom instructions to the CNN accelerator through the Pico Co-Processor Interface (PCPI).

The processor provides:

- Instruction fetch
- Register file
- Memory interface
- PCPI request interface
- PCPI response interface

Only the custom CNN instructions are handled by the coprocessor. All other instructions continue to execute normally within PicoRV32.

---

# CNN PCPI Coprocessor

The file

```text
picorv32_pcpi_cnn.v
```

implements the custom CNN coprocessor connected through the Pico Co-Processor Interface.

The module is responsible for:

- Detecting custom instructions
- Decoding CNN instructions
- Updating configuration registers
- Generating PCPI handshake signals
- Returning debug responses
- Initiating CNN execution

This module represents the hardware interface between software and the CNN accelerator.

---

# PCPI Communication

Communication between PicoRV32 and the accelerator uses the standard Pico Co-Processor Interface.

## Request Signals

| Signal | Description |
|---------|-------------|
| `pcpi_valid` | Valid custom instruction |
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
| `pcpi_wait` | Processor stall request |

During standalone verification, the implemented custom instructions complete immediately after configuration register updates. Consequently, `pcpi_ready` and `pcpi_wr` are asserted while `pcpi_wait` remains deasserted.

---

# Custom Instructions

Two custom RISC-V instructions are verified.

## CNN_LD_WT

Responsible for configuring:

- Weight Base Address
- Input Channel Count
- Output Channel Count

The instruction updates the accelerator configuration registers without initiating CNN execution.

---

## CNN_LD_IMG_EXE

Responsible for configuring:

- Image Base Address
- Result Buffer Address
- Image Size

After configuration, the accelerator asserts the internal

```text
start_cnn
```

signal to begin CNN execution.

---

# Simulation Flow

The standalone RTL verification follows the execution sequence below.

```text
Start Simulation
        │
        ▼
Load firmware.memh
        │
        ▼
Generate Clock
        │
        ▼
Release Reset
        │
        ▼
PicoRV32 Executes Firmware
        │
        ▼
CNN_LD_WT
        │
        ▼
Configuration Registers Updated
        │
        ▼
CNN_LD_IMG_EXE
        │
        ▼
start_cnn Asserted
        │
        ▼
Return Debug Response
        │
        ▼
Simulation Complete
```

---

# Verification Objectives

The standalone RTL simulation verifies:

- Processor reset
- Firmware execution
- Custom instruction decoding
- Configuration register programming
- PCPI request generation
- PCPI response generation
- Debug response generation
- Accelerator control logic

The arithmetic datapath of the CNN accelerator is verified separately during accelerator development.

---

# Advantages of Standalone RTL Verification

Performing standalone RTL verification before complete SoC integration provides several advantages.

- Faster simulation time
- Simplified debugging
- Independent module verification
- Easier waveform analysis
- Isolation of PCPI communication
- Early validation of custom instructions

This methodology reduces debugging effort before integrating the accelerator into the complete embedded system.

---

# Summary

The standalone RTL testbench provides a dedicated verification environment for the CNN custom instruction interface implemented through the Pico Co-Processor Interface (PCPI).

By executing firmware on the modified PicoRV32 processor and validating processor-to-accelerator communication in isolation, the testbench confirms correct custom instruction decoding, configuration register programming, PCPI handshake generation, and accelerator control before full System-on-Chip integration.

This verification environment forms the foundation for the complete RTL and SoC validation flow used throughout the project.