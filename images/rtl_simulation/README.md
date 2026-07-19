# RTL Simulation

## Overview

This directory contains the standalone RTL simulation results used to verify the custom CNN instruction interface implemented through the Pico Co-Processor Interface (PCPI).

The simulations validate the processor-to-accelerator communication logic before integration into the complete PicoRV32-based System-on-Chip (SoC). Verification at the RTL level allows each hardware module to be tested independently, ensuring correct functionality prior to system-level integration.

The RTL simulations focus on:

- Custom instruction decoding
- Configuration register programming
- PCPI request detection
- PCPI response generation
- Accelerator control logic
- Debug response generation

Together, these simulations verify the correctness of the hardware interface between the processor and the CNN accelerator.

---

# Simulation Flow

The standalone RTL verification follows the sequence shown below.

```text
RTL Testbench
        │
        ▼
Apply Custom Instruction
        │
        ▼
PCPI Instruction Decode
        │
        ▼
Configuration Register Update
        │
        ▼
Generate PCPI Response
        │
        ▼
Return Debug Signature
        │
        ▼
Verification Complete
```

---

# Directory Contents

| Figure | Description |
|---------|-------------|
| **01_testbench.png** | Standalone RTL simulation testbench |
| **02_rtl_hierarchy.png** | RTL module hierarchy |
| **03_pcpi_decode.png** | Custom instruction decode logic |
| **04_configuration_registers.png** | Accelerator configuration registers |
| **05_configuration_capture.png** | Configuration register capture logic |
| **06_pcpi_response_logic.png** | PCPI response generation logic |
| **07_weight_instruction_response.png** | RTL verification of `CNN_LD_WT` |
| **08_image_execute_response.png** | RTL verification of `CNN_LD_IMG_EXE` |
| **09_weight_instruction_waveform.png** | Waveform for weight configuration instruction |
| **10_image_execute_waveform.png** | Waveform for image configuration and execution instruction |

---

# 01_testbench.png

## Description

This figure shows the standalone RTL simulation testbench used during verification.

The testbench instantiates the CNN PCPI module and emulates PicoRV32 by generating custom instruction transactions.

The testbench verifies:

- Valid PCPI requests
- Instruction decoding
- Configuration register updates
- PCPI handshake signals
- Returned debug responses

The testbench isolates the accelerator interface from the remainder of the SoC, enabling focused functional verification.

---

# 02_rtl_hierarchy.png

## Description

This figure illustrates the internal RTL hierarchy of the CNN PCPI module.

Major functional blocks include:

- Instruction Decoder
- Configuration Registers
- Configuration Capture Logic
- PCPI Response Logic
- Accelerator Control Logic

The modular hierarchy simplifies development, debugging, and future hardware extensions.

---

# 03_pcpi_decode.png

## Description

This figure shows the custom instruction decoding logic implemented inside the PCPI module.

Instruction decoding is performed using the **CUSTOM-0** opcode (`0x2B`) together with the `funct3` field.

Two custom instructions are implemented.

### CNN_LD_WT

| Field | Value |
|---------|-------|
| Opcode | `0x2B` |
| funct3 | `000` |

Configures:

- Weight Base Address
- Input Channels
- Output Channels

---

### CNN_LD_IMG_EXE

| Field | Value |
|---------|-------|
| Opcode | `0x2B` |
| funct3 | `001` |

Configures:

- Image Base Address
- Output Feature Map Address
- Image Size

After configuration, the accelerator asserts `start_cnn` to begin CNN execution.

---

# 04_configuration_registers.png

## Description

This figure illustrates the internal configuration registers programmed by the custom instructions.

The registers store:

- Weight Base Address
- Image Base Address
- Result Base Address
- Input Channel Count
- Output Channel Count
- Image Size
- `start_cnn`

These registers remain programmed until updated by subsequent custom instructions.

---

# 05_configuration_capture.png

## Description

Configuration parameters are captured synchronously on the rising edge of the system clock.

### CNN_LD_WT

Captures:

- Weight Base Address
- Input Channels
- Output Channels

### CNN_LD_IMG_EXE

Captures:

- Image Base Address
- Result Base Address
- Image Size

Following successful parameter capture, the accelerator asserts the internal `start_cnn` signal.

---

# 06_pcpi_response_logic.png

## Description

This figure illustrates the generation of the standard PicoRV32 PCPI response signals.

Generated signals include:

- `pcpi_ready`
- `pcpi_wr`
- `pcpi_rd`
- `pcpi_wait`

During verification, both custom instructions completed immediately after instruction decoding.

Consequently,

```text
pcpi_ready = 1
pcpi_wr    = 1
pcpi_wait  = 0
```

Although `pcpi_wait` remained deasserted during verification, the implemented interface remains fully compatible with multi-cycle accelerator execution.

---

# 07_weight_instruction_response.png

## Description

This figure verifies the execution of the `CNN_LD_WT` instruction.

The simulation confirms:

- Correct instruction decoding
- Weight parameter capture
- Configuration register updates
- Generation of the expected debug response
- Correct PCPI handshake

Successful execution demonstrates proper configuration of weight-related accelerator parameters.

---

# 08_image_execute_response.png

## Description

This figure verifies the execution of the `CNN_LD_IMG_EXE` instruction.

The simulation confirms:

- Image parameter capture
- Configuration register updates
- Assertion of `start_cnn`
- Generation of the expected debug response
- Correct PCPI handshake

Successful execution confirms proper initiation of CNN processing.

---

# 09_weight_instruction_waveform.png

## Description

This waveform illustrates the execution of the weight configuration instruction.

The waveform verifies:

- Valid PCPI request
- Correct instruction decode
- Configuration register programming
- Successful PCPI response
- Correct debug signature

---

# 10_image_execute_waveform.png

## Description

This waveform illustrates execution of the image configuration and execution instruction.

The waveform verifies:

- Valid PCPI request
- Configuration register programming
- Assertion of `start_cnn`
- Successful PCPI response
- Correct debug signature

---

# Verification Coverage

The standalone RTL simulations validate the complete processor-to-accelerator communication interface.

The verified functionality includes:

- Custom instruction decoding
- Configuration register programming
- PCPI request detection
- PCPI response generation
- Accelerator control signals
- Debug response generation

Verification of the convolution datapath and arithmetic hardware is performed separately during accelerator development.

---

# Summary

The RTL simulations successfully verify the custom instruction interface implemented through the Pico Co-Processor Interface (PCPI).

Both `CNN_LD_WT` and `CNN_LD_IMG_EXE` correctly decode, update accelerator configuration registers, generate the expected PCPI handshake signals, and return the appropriate debug responses.

These standalone simulations establish the correctness of the processor-to-accelerator communication interface and provide the foundation for successful integration into the complete PicoRV32-based System-on-Chip.