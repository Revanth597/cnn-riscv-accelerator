# Custom CNN Instructions

## Overview

The CNN-RISC-V Accelerator extends the standard PicoRV32 processor by introducing two application-specific RISC-V custom instructions through the Pico Co-Processor Interface (PCPI).

Rather than configuring the accelerator using conventional memory-mapped control registers, the processor communicates directly with the CNN accelerator through dedicated instructions. This approach minimizes software overhead, simplifies firmware development, and provides a clean interface between software and hardware.

The custom instruction interface was designed to satisfy three primary objectives:

- Configure accelerator parameters directly from software.
- Minimize modifications to the PicoRV32 processor.
- Maintain compatibility with the standard PCPI protocol.

Only two instructions are required to completely configure and execute the CNN accelerator.

| Instruction | Purpose |
|-------------|---------|
| **CNN_LD_WT** | Configure weight-related parameters |
| **CNN_LD_IMG_EXE** | Configure image parameters and begin CNN execution |

Both instructions use the RISC-V **CUSTOM-0** opcode (`0x2B`) and are decoded entirely inside the PCPI coprocessor without modifying the standard PicoRV32 instruction pipeline.

---

# Design Philosophy

Unlike many embedded accelerators that rely on memory-mapped configuration registers, this design adopts an instruction-driven configuration model.

The processor communicates with the accelerator by executing dedicated RISC-V instructions, allowing accelerator configuration to become part of the software instruction stream.

This approach provides several advantages:

- Lower software overhead
- Simplified firmware
- Reduced bus transactions
- Modular accelerator integration
- Cleaner RTL implementation
- Easier RTL verification

Separating accelerator configuration into custom instructions also enables the accelerator to remain largely independent of the processor core while leveraging the standard PCPI interface.

---

# PCPI Overview

The Pico Co-Processor Interface (PCPI) is the standard coprocessor interface provided by PicoRV32 for integrating application-specific hardware accelerators.

Whenever PicoRV32 encounters a custom instruction, the instruction is forwarded to the PCPI module instead of being executed by the processor itself.

The PCPI module is responsible for:

- Decoding the instruction
- Reading source operands
- Updating accelerator configuration registers
- Returning status information
- Initiating CNN execution when required

The communication sequence is illustrated below.

```text
PicoRV32
    │
    │ Custom Instruction
    ▼
PCPI Interface
    │
    ▼
Instruction Decode
    │
    ▼
Configuration Registers
    │
    ▼
CNN Accelerator
```

The processor resumes normal execution once the PCPI module asserts the appropriate completion signals.

---

# Instruction Set Overview

The CNN accelerator requires only two custom instructions for complete configuration.

The first instruction configures all weight-related parameters, while the second instruction configures image-related parameters and initiates CNN execution.

This separation allows the same weight configuration to be reused across multiple images without repeatedly transmitting identical parameters.

| Instruction | Weight Configuration | Image Configuration | Starts CNN |
|-------------|:-------------------:|:------------------:|:----------:|
| CNN_LD_WT | ✔ | ✘ | ✘ |
| CNN_LD_IMG_EXE | ✘ | ✔ | ✔ |

The two-instruction design minimizes firmware complexity while providing sufficient flexibility for CNN execution.

---

# Instruction Format

Both instructions follow a modified R-type instruction format.

```text
31            25 24      20 19      15 14    12 11      7 6      0
+---------------+----------+----------+--------+----------+--------+
| cnn_param[6:0]|   rs2    |   rs1    | funct3 |    rd    | opcode |
+---------------+----------+----------+--------+----------+--------+
```

Unlike a standard R-type instruction, the upper seven bits are repurposed as a dedicated parameter field used to pass CNN configuration information directly to the accelerator.

---

# Instruction Fields

| Field | Width | Description |
|---------|------:|-------------|
| opcode | 7 | CUSTOM-0 instruction opcode |
| funct3 | 3 | Selects the CNN instruction |
| rs1 | 5 | First source register |
| rs2 | 5 | Second source register |
| rd | 5 | Destination register |
| cnn_param | 7 | Instruction-specific CNN parameter |

The opcode identifies the instruction as belonging to the CUSTOM-0 instruction space, while the `funct3` field distinguishes between the two supported CNN instructions.

---

# Opcode Assignment

Both instructions share the same RISC-V custom opcode.

| Field | Value |
|---------|-------|
| Binary | `0101011` |
| Hexadecimal | `0x2B` |

Instruction selection is determined by the `funct3` field.

| funct3 | Instruction |
|---------|-------------|
| `000` | CNN_LD_WT |
| `001` | CNN_LD_IMG_EXE |

This approach allows multiple CNN-specific instructions to coexist under a single custom opcode while maintaining a compact instruction encoding.

# CNN_LD_WT

## Purpose

`CNN_LD_WT` configures all weight-related parameters required by the CNN accelerator.

The instruction captures the memory location of the convolution weights together with the input and output channel configuration. These values are stored in dedicated configuration registers and remain unchanged until explicitly updated by another `CNN_LD_WT` instruction.

Separating weight configuration from image execution allows the accelerator to reuse the same weights across multiple inference runs without repeatedly transmitting identical configuration information.

The instruction **does not** initiate CNN execution.

---

## Instruction Encoding

| Field | Value |
|---------|-------|
| Opcode | `0101011` (CUSTOM-0) |
| funct3 | `000` |

---

## Parameters

| Source | Description |
|---------|-------------|
| `rs1` | Weight Base Address |
| `rs2` | Number of Input Channels |
| `cnn_param[6:0]` | Number of Output Channels |

---

## Configuration Register Updates

After instruction decoding, the following configuration registers are updated.

```text
weight_base      <= rs1
input_channels   <= rs2
output_channels  <= cnn_param
```

No CNN computation begins after this instruction.

The accelerator simply stores the supplied configuration for later use.

---

## Example Assembly

```assembly
CNN_LD_WT x8, x10, x3
```

### Meaning

| Register | Value |
|----------|-------|
| Weight Base Address | `x3` |
| Input Channels | `x10` |
| Output Channels | `x8` |

After execution, the accelerator is fully configured to access the required CNN weights.

---

# CNN_LD_IMG_EXE

## Purpose

`CNN_LD_IMG_EXE` configures all image-related parameters required for CNN execution.

Unlike `CNN_LD_WT`, this instruction completes accelerator configuration and immediately starts CNN inference.

The instruction captures:

- Input image location
- Output feature map location
- Image dimensions

Once these parameters have been stored, the accelerator asserts the internal `start_cnn` signal.

---

## Instruction Encoding

| Field | Value |
|---------|-------|
| Opcode | `0101011` (CUSTOM-0) |
| funct3 | `001` |

---

## Parameters

| Source | Description |
|---------|-------------|
| `rs1` | Image Base Address |
| `rs2` | Output Feature Map Address |
| `cnn_param[6:0]` | Image Size |

---

## Configuration Register Updates

```text
image_base   <= rs1
result_base  <= rs2
image_size   <= cnn_param
```

After these registers have been updated, the accelerator asserts

```text
start_cnn
```

which begins CNN execution.

---

## Example Assembly

```assembly
CNN_LD_IMG_EXE x32, x6, x5
```

### Meaning

| Register | Value |
|----------|-------|
| Image Base Address | `x5` |
| Output Feature Map Address | `x6` |
| Image Size | `32 × 32` |

The instruction completes accelerator configuration and immediately initiates CNN inference.

---

# Configuration Registers

The PCPI module contains a collection of configuration registers that are programmed through the custom instruction interface.

These registers provide all information required by the CNN accelerator before execution begins.

| Register | Description |
|-----------|-------------|
| `weight_base` | Base address of CNN weights |
| `image_base` | Base address of the input image |
| `result_base` | Base address of the output feature map |
| `input_channels` | Number of input channels |
| `output_channels` | Number of output channels |
| `image_size` | Width/height of the input image |
| `start_cnn` | Internal execution trigger |

The accelerator reads these registers during execution and uses them to control memory accesses and convolution operations.

---

# Instruction Decode

Instruction decoding is performed entirely inside the PCPI module.

Whenever PicoRV32 executes a CUSTOM-0 instruction, the instruction is forwarded to the coprocessor for decoding.

The PCPI decoder extracts the required instruction fields.

```text
opcode    = pcpi_insn[6:0]
funct3    = pcpi_insn[14:12]
cnn_param = pcpi_insn[31:25]
```

The opcode identifies the instruction as belonging to the CUSTOM-0 instruction space, while the `funct3` field determines which CNN instruction is being executed.

Two internal decode signals are generated.

```text
instr_cnn_ld_wt
instr_cnn_ld_img_exe
```

These signals drive:

- Configuration register updates
- Accelerator control logic
- PCPI handshake generation
- Debug response generation

Keeping all decoding inside the PCPI module minimizes modifications to the PicoRV32 processor and allows the accelerator to remain modular.

# PCPI Interface

Communication between PicoRV32 and the CNN accelerator is implemented using the **Pico Co-Processor Interface (PCPI)**. The PCPI is a standard coprocessor interface provided by PicoRV32 that enables the integration of application-specific hardware accelerators through custom RISC-V instructions.

When PicoRV32 encounters a CUSTOM-0 instruction, the instruction and its operands are forwarded to the PCPI module instead of being executed by the processor core.

The PCPI module is responsible for:

- Detecting valid custom instructions
- Decoding the instruction
- Capturing instruction parameters
- Updating accelerator configuration registers
- Generating completion signals
- Initiating CNN execution when required

The processor resumes normal execution once the PCPI module acknowledges instruction completion.

---

# PCPI Request Signals

The following signals are driven by PicoRV32 whenever a custom instruction is encountered.

| Signal | Width | Description |
|---------|------:|-------------|
| `pcpi_valid` | 1 | Indicates that the current instruction is a valid PCPI instruction |
| `pcpi_insn` | 32 | Complete instruction word |
| `pcpi_rs1` | 32 | Value stored in source register 1 |
| `pcpi_rs2` | 32 | Value stored in source register 2 |

These signals provide all information required by the accelerator to decode and execute the instruction.

---

# PCPI Response Signals

After processing the instruction, the PCPI module responds to PicoRV32 using the following signals.

| Signal | Width | Description |
|---------|------:|-------------|
| `pcpi_ready` | 1 | Indicates instruction completion |
| `pcpi_wr` | 1 | Enables register write-back |
| `pcpi_rd` | 32 | Data returned to PicoRV32 |
| `pcpi_wait` | 1 | Requests processor stall during multi-cycle execution |

During verification, the implemented custom instructions completed immediately after decoding and configuration register updates.

Therefore,

```text
pcpi_ready = 1
pcpi_wr    = 1
pcpi_wait  = 0
```

The PCPI protocol, however, supports multi-cycle accelerators by allowing the coprocessor to assert `pcpi_wait` until execution is complete. This capability remains available for future extensions of the CNN accelerator.

---

# Instruction Lifecycle

Every custom instruction follows the same execution sequence.

```text
Firmware
    │
    ▼
Execute Custom Instruction
    │
    ▼
PicoRV32 Detects CUSTOM-0 Opcode
    │
    ▼
Forward Instruction to PCPI
    │
    ▼
Instruction Decode
    │
    ▼
Capture Parameters
    │
    ▼
Update Configuration Registers
    │
    ▼
Generate Debug Response
    │
    ▼
Assert pcpi_ready
    │
    ▼
Firmware Continues Execution
```

This standardized execution sequence ensures that every instruction follows a predictable control flow while maintaining compatibility with the PicoRV32 execution pipeline.

---

# Debug Response Generation

To simplify RTL and SoC verification, each custom instruction generates a unique debug response through the `pcpi_rd` signal.

Rather than returning computation results, the PCPI module constructs a response containing selected instruction parameters together with a unique debug signature.

This allows firmware developers to verify:

- Correct instruction decoding
- Correct operand capture
- Proper configuration register updates
- Successful PCPI communication

without requiring waveform inspection of every internal signal.

---

## CNN_LD_WT Debug Response

After successfully decoding `CNN_LD_WT`, the PCPI module returns

```text
pcpi_rd =
{
    cnn_param,
    pcpi_rs2[7:0],
    pcpi_rs1[7:0],
    9'h155
}
```

The returned value contains:

| Field | Description |
|--------|-------------|
| `cnn_param` | Output Channel Count |
| `pcpi_rs2[7:0]` | Input Channel Count |
| `pcpi_rs1[7:0]` | Weight Base Address |
| `9'h155` | Debug Signature |

The signature `0x155` uniquely identifies the weight configuration instruction during simulation.

---

## CNN_LD_IMG_EXE Debug Response

Similarly, the image execution instruction returns

```text
pcpi_rd =
{
    cnn_param,
    pcpi_rs2[7:0],
    pcpi_rs1[7:0],
    9'h0AA
}
```

The returned value contains:

| Field | Description |
|--------|-------------|
| `cnn_param` | Image Size |
| `pcpi_rs2[7:0]` | Output Feature Map Address |
| `pcpi_rs1[7:0]` | Image Base Address |
| `9'h0AA` | Debug Signature |

The signature `0x0AA` distinguishes the image execution instruction from the weight configuration instruction during both RTL and SoC simulations.

---

# Execution Sequence

The firmware always configures the accelerator using the same sequence.

```text
Firmware
    │
    ▼
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
CNN Accelerator Begins Execution
```

This two-stage configuration process enables a single set of CNN weights to be reused for multiple input images, reducing configuration overhead during repeated inference.

---

# Design Decisions

The custom instruction interface was designed with several architectural objectives in mind.

- Minimize modifications to PicoRV32
- Eliminate memory-mapped accelerator configuration registers
- Reduce firmware complexity
- Maintain compatibility with the standard PCPI protocol
- Simplify RTL verification
- Support future accelerator extensions

Using custom instructions instead of memory-mapped registers provides a clean and modular interface between software and hardware while preserving the standard RISC-V programming model.

---

# Summary

The CNN accelerator is controlled through two custom RISC-V instructions implemented using the Pico Co-Processor Interface (PCPI). Rather than relying on memory-mapped control registers, the processor configures and starts the accelerator by executing application-specific instructions, providing a lightweight and modular hardware/software interface.

The `CNN_LD_WT` instruction configures weight-related parameters, while `CNN_LD_IMG_EXE` configures image parameters and initiates CNN execution. Both instructions update dedicated configuration registers within the PCPI module and communicate with PicoRV32 using the standard PCPI handshake protocol.

The instruction interface was verified through standalone RTL simulations and complete System-on-Chip simulations, confirming correct instruction decoding, configuration register updates, debug response generation, and successful processor-to-accelerator communication.

This instruction-based control mechanism minimizes processor modifications, simplifies firmware development, and provides a scalable foundation for integrating future CNN accelerator extensions while maintaining compatibility with the standard PicoRV32 architecture.
