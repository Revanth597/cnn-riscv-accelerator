# Boot Process

This document describes the complete boot sequence of the CNN Hardware Accelerator SoC, from processor reset to CNN inference execution. It explains the responsibilities of the BootROM, firmware loading process, firmware execution flow, and the generated boot artifacts.

---

# Overview

After power-on or reset, execution begins from the BootROM stored in on-chip ROM. The BootROM is responsible for initializing the system, verifying the firmware image stored in external SPI Flash, copying it into SRAM, and transferring execution to the firmware.

The firmware then configures the CNN accelerator using custom instructions, executes the convolution pipeline, and performs firmware-based post-processing before storing the final INT8 output back into BRAM.

---

# Complete Boot Flow

<p align="center">
<img src="../images/architecture/04_boot_process_flow.png" width="95%">
</p>

The complete execution sequence is:

```
Power-On / Reset
        │
        ▼
BootROM (ROM)
        │
        ▼
start.S
        │
        ▼
boot.S
        │
Hardware Initialization
        │
        ▼
checksum.S
        │
Firmware Verification
        │
        ▼
Copy Firmware
(SPI Flash → SRAM)
        │
        ▼
Jump to Firmware Entry
        │
═══════════════════════════════════════
 Firmware (SRAM)
═══════════════════════════════════════
        │
        ▼
start.S
        │
        ▼
cnn.S
        │
CNN_LD_WT
        │
CNN_LD_IMG_EXE
        │
CNN Accelerator
        │
INT16 Feature Map
        │
Firmware Post Processing
(MaxPool + Scaling + Quantization)
        │
INT8 Output
```

---

# BootROM Responsibilities

The BootROM performs all initialization before firmware execution.

Its responsibilities include:

- Initialize processor state
- Initialize stack pointer
- Configure runtime environment
- Perform BRAM verification
- Initialize SPI Flash interface
- Read firmware header
- Verify firmware checksum
- Copy firmware image into SRAM
- Transfer execution to firmware entry point

The BootROM itself performs no CNN computation. Its only responsibility is safely loading and starting the firmware.

---

# BootROM Source Files

| File | Purpose |
|------|---------|
| `start.S` | Reset entry point and stack initialization |
| `boot.S` | Hardware initialization and boot control |
| `checksum.S` | Firmware header verification and checksum validation |
| `rtl_ops.S` | RTL-version specific helper routines |

---

# Firmware Source Files

After BootROM transfers control, firmware execution begins.

| File | Purpose |
|------|---------|
| `start.S` | Firmware entry point |
| `cnn.S` | Main CNN inference program |
| `data.S` | Input image data |
| `weights_INT4_16_channel.S` | CNN weights |
| `intermediate_scales.S` | Per-channel scaling constants |
| `maxpool_scale_quantize.c` | Firmware post-processing |

---

# Firmware Execution Flow

Firmware executes the CNN inference in the following order.

```
start.S
    │
    ▼
cnn.S
    │
    ▼
CNN_LD_WT
(Configure CNN)
    │
    ▼
CNN_LD_IMG_EXE
(Start Accelerator)
    │
    ▼
CNN Accelerator (RTL)
    │
    ▼
INT16 Feature Map
Stored in BRAM
    │
    ▼
Read Feature Map
    │
    ▼
Max Pooling
    │
    ▼
Multiply by Intermediate Scales
(INT16 × UINT16 → INT32)
    │
    ▼
Arithmetic Right Shift
(Q16 Scaling)
    │
    ▼
Quantization
    │
    ▼
Clamp to INT8
    │
    ▼
Store Final Output to BRAM
```

---

# Hardware / Firmware Partition

The CNN inference pipeline is shared between hardware and firmware.

## RTL Accelerator

The hardware accelerator performs:

- Weight loading
- Image loading
- Sliding-window convolution
- MAC operations
- ReLU activation

Output:

```
INT16 Feature Map
```

stored into BRAM.

---

## PicoRV32 Firmware

Firmware performs:

- Read INT16 feature map
- Max Pooling
- Multiply by intermediate scales
- Arithmetic right shift
- Quantization
- Clamp to INT8
- Store final feature map into BRAM

This division keeps the accelerator focused on computationally intensive operations while firmware performs flexible post-processing.

---

# Firmware Header

During firmware generation, an additional bootable image is created.

The firmware header consists of:

| Offset | Field | Description |
|---------|---------|-------------|
| 0x00 | Magic | Boot image signature |
| 0x04 | Size | Firmware payload size |
| 0x08 | Load Address | SRAM destination |
| 0x0C | Checksum | Firmware checksum |

Example:

```
Magic      : 0xB007B007
Load Addr  : 0x00020000
Checksum   : Generated during build
```

The BootROM validates this header before copying the firmware.

---

# Firmware Build Pipeline

The firmware is generated through the following build stages.

```
Assembly Sources
(.S / .c)
        │
        ▼
RISC-V GCC
        │
        ▼
Object Files
(.o)
        │
        ▼
Linker
        │
        ▼
firmware.elf
        │
        ▼
Objcopy
        │
        ▼
firmware.bin
        │
        ▼
Python Conversion Scripts
        │
        ├── firmware.hex
        ├── firmware.coe
        ├── firmware.mem
        ├── firmware.memh
        ├── firmware_with_header.bin
        ├── firmware_with_header.hex
        ├── firmware_with_header.mem
        └── firmware_with_header.memh
```

These generated files are used for FPGA memory initialization, simulation, and BootROM loading.

---

# Generated Boot Artifacts

## BootROM

| File | Description |
|------|-------------|
| bootrom.elf | Executable with symbols |
| bootrom.bin | Raw binary |
| bootrom.hex | Hex image |
| bootrom.coe | BRAM initialization |
| bootrom.mem | Memory initialization |
| bootrom.memh | Memory hex |
| bootrom.v | Verilog ROM module |

---

## Firmware

| File | Description |
|------|-------------|
| firmware.elf | Executable |
| firmware.bin | Binary image |
| firmware.hex | Hex image |
| firmware.coe | COE initialization |
| firmware.mem | Memory initialization |
| firmware.memh | Memory hex |
| firmware_with_header.bin | Bootable firmware |
| firmware_with_header.hex | Bootable HEX |
| firmware_with_header.coe | Bootable COE |
| firmware_with_header.mem | Bootable MEM |
| firmware_with_header.memh | Bootable MEMH |

---

# UART Boot Messages

During SoC simulation, the BootROM prints diagnostic values through UART.

| UART Output | Description |
|------------|-------------|
| **0x0A** | First BRAM verification test |
| **0x14** | Second BRAM verification test |
| **0xFE** | SPI Flash successfully initialized |
| **0xFF** | Firmware execution completed |

These values are useful for verifying successful boot and firmware execution during simulation.

---

# Summary

The BootROM provides a secure and deterministic startup process by verifying and loading the firmware into SRAM before execution.

Once started, the firmware configures the CNN accelerator using custom PCPI instructions, executes the convolution pipeline, performs firmware-based post-processing (Max Pooling, scaling, quantization, and clamping), and stores the final INT8 output feature map back into BRAM.

This hardware/software co-design combines the performance of a dedicated RTL accelerator with the flexibility of firmware-based post-processing, resulting in an efficient CNN inference pipeline.