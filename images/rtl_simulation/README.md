# RTL Simulation

## Overview

This directory contains the standalone RTL simulation results for the custom CNN instruction interface implemented using the Pico Co-Processor Interface (PCPI).

The objective of these simulations is to verify the processor-to-accelerator communication interface before integration into the complete PicoRV32-based System-on-Chip (SoC).

The RTL simulations validate:

- Custom instruction decoding
- Configuration register updates
- PCPI request and response handshaking
- Accelerator configuration
- Generation of debug responses

---

# Directory Contents

| File | Description |
|------|-------------|
| `01_testbench.png` | RTL simulation testbench hierarchy. |
| `02_rtl_hierarchy.png` | RTL hierarchy showing the PCPI CNN module. |
| `03_pcpi_decode.png` | Custom instruction decode logic. |
| `04_configuration_registers.png` | CNN configuration registers. |
| `05_configuration_capture.png` | Sequential logic that captures instruction parameters. |
| `06_pcpi_response_logic.png` | PCPI response generation logic. |
| `07_weight_instruction_response.png` | Response logic for `CNN_LD_WT`. |
| `08_image_execute_response.png` | Response logic for `CNN_LD_IMG_EXE`. |
| `09_weight_instruction_waveform.png` | RTL waveform for the weight-loading instruction. |
| `10_image_execute_waveform.png` | RTL waveform for the image loading and execution instruction. |

---

# Simulation Objective

The RTL simulations verify the complete PCPI communication path between PicoRV32 and the CNN accelerator.

The verification includes:

- Instruction decoding
- Configuration register updates
- PCPI request detection
- PCPI response generation
- Register write-back
- Accelerator configuration

The simulations focus on validating the custom instruction interface independently before system-level integration.

---

# Testbench

**Image:** `01_testbench.png`

The standalone RTL testbench instantiates the CNN PCPI module and applies custom instruction transactions that emulate execution by the PicoRV32 processor.

The testbench verifies:

- Valid PCPI requests
- Correct instruction decoding
- Configuration register updates
- PCPI handshake signals
- Returned debug responses

---

# RTL Hierarchy

**Image:** `02_rtl_hierarchy.png`

The RTL hierarchy illustrates the organization of the CNN PCPI module.

Major functional blocks include:

- Instruction Decoder
- Configuration Registers
- Configuration Capture Logic
- PCPI Response Logic
- Control Signals

The hierarchy demonstrates the modular organization of the accelerator interface.

---

# PCPI Instruction Decode

**Image:** `03_pcpi_decode.png`

Instruction decoding is performed using the RISC-V CUSTOM-0 opcode (`0x2B`) together with the `funct3` field.

Two custom instructions are implemented:

## CNN_LD_WT

```
Opcode : 0x2B
funct3 : 000
```

Configures:

- Weight Base Address
- Input Channels
- Output Channels

---

## CNN_LD_IMG_EXE

```
Opcode : 0x2B
funct3 : 001
```

Configures:

- Image Base Address
- Output Feature Map Address
- Image Size

After updating the configuration registers, the accelerator asserts the internal `start_cnn` signal.

---

# Configuration Registers

**Image:** `04_configuration_registers.png`

The CNN accelerator contains dedicated configuration registers used during execution.

The registers include:

- Weight Base Address
- Image Base Address
- Result Base Address
- Input Channels
- Output Channels
- Image Size
- start_cnn

These registers are programmed directly through the custom instructions.

---

# Configuration Capture

**Image:** `05_configuration_capture.png`

Configuration values are captured synchronously on the rising edge of the clock.

### CNN_LD_WT

Stores:

- Weight Base Address
- Input Channels
- Output Channels

### CNN_LD_IMG_EXE

Stores:

- Image Base Address
- Result Base Address
- Image Size

After the image configuration has been captured, the accelerator asserts the `start_cnn` signal, allowing CNN processing to begin.

---

# PCPI Response Logic

**Image:** `06_pcpi_response_logic.png`

The PCPI response logic generates the standard PicoRV32 handshake signals.

Signals generated:

- `pcpi_ready`
- `pcpi_wr`
- `pcpi_rd`
- `pcpi_wait`

During verification of the custom instruction interface, the accelerator immediately acknowledged both custom instructions.

Therefore,

```
pcpi_ready = 1
pcpi_wr    = 1
pcpi_wait  = 0
```

The standard PCPI interface supports multi-cycle execution through the `pcpi_wait` signal.

For the custom instruction verification performed in this project, the objective was to validate instruction decoding, configuration register updates, and PCPI communication. Since the custom instructions only configured the accelerator and returned debug responses, `pcpi_wait` was intentionally left deasserted during these tests.

The RTL accelerator may assert `pcpi_wait` whenever multi-cycle execution is required.

---

# CNN_LD_WT Verification

**Image:** `07_weight_instruction_response.png`

The first custom instruction configures the accelerator with weight-related parameters.

Captured parameters:

- Weight Base Address
- Input Channel Count
- Output Channel Count

A unique debug signature is returned through `pcpi_rd`, allowing successful instruction execution to be verified from the waveform.

---

# CNN_LD_IMG_EXE Verification

**Image:** `08_image_execute_response.png`

The second custom instruction configures image-related parameters.

Captured parameters:

- Image Base Address
- Output Feature Map Address
- Image Size

After the configuration registers have been updated, the accelerator asserts the internal `start_cnn` signal.

A unique debug signature is returned through `pcpi_rd`, confirming successful execution.

---

# CNN_LD_WT Waveform

**Image:** `09_weight_instruction_waveform.png`

The waveform verifies successful execution of the weight-loading instruction.

Verified behavior:

- Valid PCPI request
- Correct instruction decoding
- Configuration register updates
- Successful PCPI handshake
- Debug response generation

---

# CNN_LD_IMG_EXE Waveform

**Image:** `10_image_execute_waveform.png`

The waveform verifies successful execution of the image configuration instruction.

Verified behavior:

- Valid PCPI request
- Configuration register updates
- Assertion of `start_cnn`
- Successful PCPI handshake
- Debug response generation

---

# Scope of Verification

The simulations presented in this directory focus on verifying the processor-to-accelerator communication interface.

Verification includes:

- Custom instruction decoding
- Configuration register updates
- PCPI request signals
- PCPI response signals
- Accelerator configuration

The internal functionality of the CNN accelerator datapath is verified independently as part of the RTL development.

---

# Summary

The standalone RTL simulations successfully verify the custom instruction interface implemented through the Pico Co-Processor Interface (PCPI).

Both `CNN_LD_WT` and `CNN_LD_IMG_EXE` correctly decode, update the accelerator configuration registers, generate the expected PCPI handshake signals, and return the appropriate debug responses.

These simulations validate the processor-to-accelerator communication path and provide the foundation for successful integration into the complete PicoRV32-based SoC.