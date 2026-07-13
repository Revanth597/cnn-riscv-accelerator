# Custom CNN Instructions

## Overview

The CNN-RISC-V Accelerator extends the PicoRV32 processor by introducing two custom RISC-V instructions through the Pico Co-Processor Interface (PCPI).

These instructions provide a lightweight interface for configuring the CNN accelerator directly from firmware without relying on memory-mapped control registers.

The implemented instructions are:

- **CNN_LD_WT**
- **CNN_LD_IMG_EXE**

Both instructions use the RISC-V **CUSTOM-0** opcode (`0x2B`) and are decoded by the PCPI module integrated within the PicoRV32 processor.

The custom instructions are responsible for configuring the accelerator, updating internal configuration registers, and initiating CNN execution.

---

# Instruction Format

Both custom instructions follow a modified R-type instruction format.

```
31            25 24      20 19      15 14    12 11      7 6      0
+---------------+----------+----------+--------+----------+--------+
| cnn_param[6:0]|   rs2    |   rs1    | funct3 |    rd    | opcode |
+---------------+----------+----------+--------+----------+--------+
```

## Instruction Fields

| Field | Description |
|---------|-------------|
| opcode | CUSTOM-0 instruction opcode (`0x2B`) |
| funct3 | Selects the CNN instruction |
| rs1 | Source Register 1 |
| rs2 | Source Register 2 |
| cnn_param | Instruction-specific parameter |
| rd | Destination register |

---

# Opcode

Both instructions share the same RISC-V custom opcode.

| Field | Value |
|---------|-------|
| Opcode | `0101011` |
| Hex | `0x2B` |

Instruction selection is performed using the **funct3** field.

---

# CNN_LD_WT

## Purpose

The **CNN_LD_WT** instruction configures the weight-related parameters of the CNN accelerator.

It loads:

- Weight Base Address
- Number of Input Channels
- Number of Output Channels

The instruction updates the accelerator configuration registers without initiating CNN execution.

---

## Encoding

```
Opcode : 0101011
funct3 : 000
```

---

## Parameters

| Source | Description |
|---------|-------------|
| rs1 | Weight Base Address |
| rs2 | Number of Input Channels |
| cnn_param[6:0] | Number of Output Channels |

---

## Configuration Register Updates

The instruction updates:

```
weight_base      <= rs1
input_channels   <= rs2
output_channels  <= cnn_param
```

After these values are stored, the accelerator is configured to access the required CNN weights.

---

## Example

```assembly
CNN_LD_WT out_channels, input_channels, weight_base
```

Example

```assembly
CNN_LD_WT x8, x10, x3
```

Meaning

```
Weight Base Address = x3
Input Channels      = x10
Output Channels     = x8
```

---

# CNN_LD_IMG_EXE

## Purpose

The **CNN_LD_IMG_EXE** instruction configures image-related parameters and initiates CNN execution.

It loads:

- Image Base Address
- Output Feature Map Address
- Image Size

After the configuration registers have been updated, the accelerator asserts the internal `start_cnn` signal.

---

## Encoding

```
Opcode : 0101011
funct3 : 001
```

---

## Parameters

| Source | Description |
|---------|-------------|
| rs1 | Image Base Address |
| rs2 | Output Feature Map Address |
| cnn_param[6:0] | Image Size |

---

## Configuration Register Updates

The instruction updates:

```
image_base
result_base
image_size
```

The accelerator then asserts

```
start_cnn
```

to begin CNN execution.

---

## Example

```assembly
CNN_LD_IMG_EXE image_size, result_addr, image_addr
```

Example

```assembly
CNN_LD_IMG_EXE x32, x6, x5
```

Meaning

```
Image Base Address = x5
Result Address     = x6
Image Size         = 32
```

---

# Instruction Decode

Instruction decoding is performed entirely inside the PCPI module.

The decoder extracts

```
opcode    = pcpi_insn[6:0]
funct3    = pcpi_insn[14:12]
cnn_param = pcpi_insn[31:25]
```

The opcode identifies the instruction as a CUSTOM-0 instruction, while the `funct3` field distinguishes between the two CNN instructions.

Internal decode signals are generated:

```
instr_cnn_ld_wt
instr_cnn_ld_img_exe
```

These signals drive:

- Configuration register updates
- Accelerator control logic
- PCPI response generation

---

# Configuration Registers

The PCPI module contains dedicated configuration registers used by the CNN accelerator.

| Register | Description |
|-----------|-------------|
| weight_base | Weight memory base address |
| image_base | Input image base address |
| result_base | Output feature map address |
| input_channels | Number of input channels |
| output_channels | Number of output channels |
| image_size | Input image dimension |
| start_cnn | Accelerator start signal |

These registers are updated directly by the custom instructions and are subsequently used by the RTL accelerator during CNN execution.

---

# PCPI Interface

Communication between PicoRV32 and the CNN accelerator uses the standard Pico Co-Processor Interface (PCPI).

## Request Signals

| Signal | Description |
|---------|-------------|
| pcpi_valid | Indicates a valid custom instruction |
| pcpi_insn | 32-bit custom instruction |
| pcpi_rs1 | Source Register 1 |
| pcpi_rs2 | Source Register 2 |

---

## Response Signals

| Signal | Description |
|---------|-------------|
| pcpi_ready | Instruction completed |
| pcpi_wr | Enable register write-back |
| pcpi_rd | Data returned to PicoRV32 |
| pcpi_wait | Stall request for multi-cycle execution |

During verification of the custom instruction interface, the accelerator responded immediately after instruction decoding.

Therefore,

```
pcpi_ready = 1
pcpi_wr    = 1
pcpi_wait  = 0
```

The PCPI interface supports multi-cycle execution through the standard `pcpi_wait` signal.

For the custom instruction verification performed in this project, the objective was to validate instruction decoding, configuration register updates, and PCPI communication. Since the custom instructions only configured the accelerator and returned debug responses, `pcpi_wait` was intentionally left deasserted during these tests.

The RTL accelerator may assert `pcpi_wait` whenever multi-cycle execution is required.

# Debug Response

To simplify RTL and SoC verification, each custom instruction returns a unique debug response through the `pcpi_rd` signal.

The returned value allows the firmware developer to verify that the instruction has been decoded correctly and that the expected parameters have been captured by the accelerator.

---

## CNN_LD_WT Debug Response

After successfully decoding the instruction, the PCPI module returns a debug signature constructed from the instruction parameters.

```
pcpi_rd =
{
    cnn_param,
    pcpi_rs2[7:0],
    pcpi_rs1[7:0],
    9'h155
}
```

Returned information:

- Output Channel Count
- Input Channel Count
- Weight Base Address
- Debug Signature (`0x155`)

The unique signature allows the instruction to be easily identified in RTL waveforms.

---

## CNN_LD_IMG_EXE Debug Response

Similarly, the second instruction returns

```
pcpi_rd =
{
    cnn_param,
    pcpi_rs2[7:0],
    pcpi_rs1[7:0],
    9'h0AA
}
```

Returned information:

- Image Size
- Output Feature Map Address
- Image Base Address
- Debug Signature (`0x0AA`)

This unique value allows the second custom instruction to be distinguished from the weight-loading instruction during simulation.

---

# Execution Flow

The complete execution flow for both custom instructions is shown below.

---

## CNN_LD_WT

```
Firmware
    │
    ▼
Issue CNN_LD_WT
    │
    ▼
PCPI Instruction Decode
    │
    ▼
Update Configuration Registers
    │
    ▼
Generate Debug Response
    │
    ▼
Return pcpi_ready
    │
    ▼
Instruction Complete
```

The instruction configures all weight-related parameters required by the CNN accelerator.

---

## CNN_LD_IMG_EXE

```
Firmware
    │
    ▼
Issue CNN_LD_IMG_EXE
    │
    ▼
PCPI Instruction Decode
    │
    ▼
Update Configuration Registers
    │
    ▼
Assert start_cnn
    │
    ▼
Generate Debug Response
    │
    ▼
Return pcpi_ready
    │
    ▼
CNN Accelerator Begins Execution
```

This instruction completes the accelerator configuration and initiates CNN execution.

---

# Configuration Sequence

The firmware always configures the accelerator using the following sequence.

```
CNN_LD_WT
        │
Configure Weight Parameters
        │
        ▼
CNN_LD_IMG_EXE
        │
Configure Image Parameters
        │
Assert start_cnn
        ▼
CNN Accelerator Executes
```

This two-step configuration process separates weight configuration from image configuration, allowing the same weights to be reused for multiple input images if required.

---

# RTL Verification

The custom instructions were initially verified using standalone RTL simulation.

The verification focused on:

- Instruction decoding
- Opcode verification
- funct3 decoding
- Configuration register updates
- PCPI request detection
- PCPI response generation
- Register write-back
- Debug response generation

Waveforms confirmed that both instructions correctly updated their respective configuration registers and generated the expected PCPI handshake signals.

---

# SoC Verification

Following standalone RTL verification, the custom instructions were integrated into the complete PicoRV32-based SoC.

The integrated verification confirmed:

- Successful BootROM execution
- Firmware loading
- Firmware execution
- Custom instruction decoding
- Configuration register updates
- Assertion of `start_cnn`
- Correct PCPI responses
- Successful processor-to-accelerator communication

The SoC simulations demonstrated that the custom instructions operate correctly within the complete system and can be executed directly from firmware.

---

# Verification Images

The repository contains several figures illustrating the implementation and verification of the custom instructions.

Architecture:

- PCPI Interface Diagram

Instruction Format:

- CNN_LD_WT
- CNN_LD_IMG_EXE

RTL Verification:

- PCPI Decode Logic
- Configuration Registers
- Configuration Capture Logic
- PCPI Response Logic

Simulation Results:

- Weight Instruction Waveform
- Image Execute Waveform
- UART Console Output

These figures are available in the following directories:

```
images/
    architecture/
    custom_instruction/
    rtl_simulation/
    soc_simulation/
```

---

# Design Considerations

The custom instructions were designed with the following objectives:

- Simple instruction encoding
- Minimal processor modifications
- Direct hardware configuration
- Standard PCPI compatibility
- Easy RTL verification
- Straightforward firmware integration

Using custom instructions eliminates the need for memory-mapped configuration registers and provides a clean interface between software and hardware.

---

# Advantages

The implemented custom instruction interface provides several benefits.

### Hardware

- Simple RTL implementation
- Minimal processor modifications
- Standard PCPI interface
- Modular accelerator integration

### Software

- Direct accelerator configuration
- Simple assembly interface
- Reduced software overhead
- Easy firmware development

### Verification

- Straightforward RTL debugging
- Simple waveform analysis
- Easy identification using debug signatures
- Complete SoC validation

---

# Summary

Two custom RISC-V instructions were implemented to provide a simple and efficient software interface between the PicoRV32 processor and the CNN accelerator through the Pico Co-Processor Interface (PCPI).

- **CNN_LD_WT** configures the accelerator with weight memory information and channel configuration.
- **CNN_LD_IMG_EXE** configures image-related parameters and initiates CNN execution by asserting `start_cnn`.

Both instructions update dedicated configuration registers inside the accelerator and communicate with PicoRV32 using the standard PCPI handshake signals.

The custom instructions were successfully verified using standalone RTL simulations and complete SoC simulations, demonstrating correct instruction decoding, configuration register updates, PCPI communication, and successful integration of the processor with the CNN accelerator.

The implemented instruction interface provides a clean, modular, and extensible mechanism for controlling CNN hardware from software while remaining fully compatible with the PicoRV32 PCPI architecture.