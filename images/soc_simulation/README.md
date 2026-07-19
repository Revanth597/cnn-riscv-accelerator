# SoC Simulation

## Overview

This directory contains the complete System-on-Chip (SoC) simulation results for the CNN-RISC-V Accelerator.

Unlike the standalone RTL simulations, which verify individual hardware modules in isolation, these simulations validate the complete embedded system from power-on reset through firmware execution and CNN accelerator configuration.

The simulations demonstrate successful integration of the modified PicoRV32 processor, BootROM, firmware, peripherals, and the custom CNN accelerator connected through the Pico Co-Processor Interface (PCPI).

The verified system includes:

- PicoRV32 RISC-V Processor
- BootROM
- Block RAM (BRAM)
- SPI Flash
- AXI UART Lite
- AXI GPIO
- CNN PCPI Accelerator

These simulations verify that the processor, firmware, and hardware accelerator operate correctly as a unified embedded system.

---

# Simulation Flow

The complete SoC verification follows the execution sequence shown below.

```text
Power-On Reset
        │
        ▼
BootROM Execution
        │
        ▼
Firmware Loading
        │
        ▼
Firmware Execution
        │
        ▼
CNN_LD_WT
        │
        ▼
CNN_LD_IMG_EXE
        │
        ▼
CNN Accelerator Configuration
        │
        ▼
CNN Execution
        │
        ▼
Firmware Post-Processing
        │
        ▼
Simulation Complete
```

---

# Directory Contents

| Figure | Description |
|---------|-------------|
| **01_testbench.png** | Complete SoC simulation testbench |
| **02_rtl_hierarchy.png** | Integrated PicoRV32 SoC RTL hierarchy |
| **03_pcpi_decode.png** | PCPI instruction decode logic |
| **04_configuration_registers.png** | CNN accelerator configuration registers |
| **05_configuration_capture.png** | Configuration register capture logic |
| **06_pcpi_response_logic.png** | PCPI response generation logic |
| **07_weight_instruction_pcpi_response.png** | Verification of `CNN_LD_WT` |
| **08_image_execute_pcpi_response.png** | Verification of `CNN_LD_IMG_EXE` |
| **09_weight_instruction_waveform.png** | Waveform for `CNN_LD_WT` |
| **10_image_execute_waveform.png** | Waveform for `CNN_LD_IMG_EXE` |
| **11_uart_console.png** | UART output during BootROM and firmware execution |

---

# 01_testbench.png

## Description

This figure illustrates the complete SoC simulation testbench.

The testbench instantiates the complete embedded platform, including:

- PicoRV32 Processor
- BootROM
- SPI Flash Model
- BRAM
- UART Receiver
- CNN PCPI Accelerator

Unlike the standalone RTL testbench, this environment executes the complete software stack beginning from reset.

---

# 02_rtl_hierarchy.png

## Description

This figure illustrates the RTL hierarchy of the integrated System-on-Chip.

Major modules include:

- PicoRV32 Processor
- AXI Interconnect
- AXI BRAM Controller
- Block RAM
- AXI Quad SPI
- AXI UART Lite
- AXI GPIO
- CNN PCPI Accelerator

The CNN accelerator is integrated directly with PicoRV32 through the Pico Co-Processor Interface (PCPI).

---

# 03_pcpi_decode.png

## Description

This figure illustrates the custom instruction decoding logic used by the CNN accelerator.

Instruction decoding is performed using:

| Field | Value |
|---------|-------|
| Opcode | `0x2B (CUSTOM-0)` |

Instruction selection is determined by the `funct3` field.

| Instruction | funct3 |
|-------------|---------|
| `CNN_LD_WT` | `000` |
| `CNN_LD_IMG_EXE` | `001` |

These instructions configure the accelerator before CNN execution begins.

---

# 04_configuration_registers.png

## Description

This figure illustrates the accelerator configuration registers.

The registers store:

- Weight Base Address
- Image Base Address
- Result Base Address
- Input Channel Count
- Output Channel Count
- Image Size
- `start_cnn`

These registers are programmed directly by the custom instructions.

---

# 05_configuration_capture.png

## Description

This figure shows the sequential logic responsible for capturing accelerator parameters.

The first instruction configures weight parameters.

The second instruction configures image parameters and asserts the internal `start_cnn` signal, initiating CNN execution.

---

# 06_pcpi_response_logic.png

## Description

This figure illustrates generation of the standard PCPI response signals.

Generated signals include:

- `pcpi_ready`
- `pcpi_wr`
- `pcpi_rd`
- `pcpi_wait`

During verification:

```text
pcpi_ready = 1
pcpi_wr    = 1
pcpi_wait  = 0
```

The implementation nevertheless remains compatible with multi-cycle accelerator execution through the standard `pcpi_wait` mechanism.

---

# 07_weight_instruction_pcpi_response.png

## Description

This figure verifies execution of the `CNN_LD_WT` instruction.

The simulation confirms:

- Correct instruction decoding
- Configuration register updates
- Weight parameter capture
- PCPI handshake generation
- Debug response generation

---

# 08_image_execute_pcpi_response.png

## Description

This figure verifies execution of the `CNN_LD_IMG_EXE` instruction.

The simulation confirms:

- Image parameter capture
- Configuration register updates
- Assertion of `start_cnn`
- PCPI handshake generation
- Debug response generation

---

# 09_weight_instruction_waveform.png

## Description

This waveform verifies successful execution of the weight configuration instruction.

Verified functionality includes:

- Instruction decode
- Weight configuration
- Register updates
- PCPI response
- Debug signature generation

---

# 10_image_execute_waveform.png

## Description

This waveform verifies successful execution of the image configuration instruction.

Verified functionality includes:

- Image configuration
- Register updates
- Assertion of `start_cnn`
- PCPI response
- Debug signature generation

---

# 11_uart_console.png

## Description

This figure shows the UART messages transmitted during system boot.

The UART output provides runtime checkpoints confirming successful execution of the BootROM before firmware begins.

| UART Value | Meaning |
|------------|---------|
| `0x0A` | First BRAM verification |
| `0x14` | Second BRAM verification |
| `0xFE` | SPI Flash initialized; firmware loading begins |
| `0xFF` | Firmware loaded successfully; control transferred to firmware |

These values provide a simple mechanism for monitoring system startup during simulation.

---

# Verification Coverage

The SoC simulations validate complete hardware/software integration.

Verified functionality includes:

- System reset
- BootROM execution
- Firmware loading
- Firmware execution
- Custom instruction execution
- Processor-to-accelerator communication
- Configuration register programming
- PCPI request and response signals
- CNN accelerator configuration
- UART status reporting

The arithmetic datapath of the CNN accelerator is verified independently during standalone RTL development.

---

# Summary

The SoC simulations demonstrate successful integration of the CNN-RISC-V Accelerator into the complete PicoRV32-based embedded system.

Beginning from system reset, the simulations verify BootROM execution, firmware loading, execution of the custom RISC-V instructions, configuration of the CNN accelerator, and processor-to-accelerator communication through the Pico Co-Processor Interface (PCPI).

Together with the standalone RTL simulations, these results confirm that the hardware and software components operate correctly as an integrated System-on-Chip, providing a complete validation of the accelerator control path and embedded execution flow.