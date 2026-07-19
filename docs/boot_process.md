# Boot Process

## Overview

This document describes the complete boot sequence of the CNN-RISC-V Accelerator System-on-Chip (SoC), beginning from system reset and ending with CNN inference execution.

The boot process involves the coordinated operation of the BootROM, PicoRV32 processor, memory subsystem, peripherals, and the custom CNN accelerator connected through the Pico Co-Processor Interface (PCPI).

---

# Boot Sequence

The overall boot flow is illustrated below.

```text
Power-On / Reset
        │
        ▼
Clock Generation
        │
        ▼
Processor Reset Released
        │
        ▼
BootROM Execution
        │
        ▼
Firmware Initialization
        │
        ▼
Peripheral Initialization
        │
        ▼
CNN Parameter Configuration
        │
        ▼
Custom Instructions
        │
        ▼
CNN Accelerator Execution
        │
        ▼
Firmware Post-Processing
        │
        ▼
Program Completion
```

---

# 1. System Reset

System execution begins after a hardware reset.

During reset:

- PicoRV32 is held in reset.
- The CNN accelerator remains idle.
- Configuration registers are cleared.
- BRAM contents remain unchanged.
- Peripherals are initialized to their default state.

Once the reset signal is deasserted, the processor begins execution from the BootROM.

---

# 2. Clock Initialization

The clock generation circuitry provides the system clock used by:

- PicoRV32
- CNN Accelerator
- BRAM
- UART Lite
- GPIO
- SPI Controller

All synchronous components begin operating after the clock becomes stable.

---

# 3. BootROM Execution

The processor fetches its first instruction from the BootROM.

The BootROM is responsible for:

- Initializing the execution environment
- Setting the stack pointer
- Preparing memory for program execution
- Jumping to the main firmware

---

# 4. Firmware Initialization

After BootROM execution, the firmware initializes the software environment.

Typical initialization tasks include:

- Clearing software variables
- Initializing memory buffers
- Configuring runtime parameters
- Preparing CNN execution

---

# 5. Peripheral Initialization

The firmware initializes the required peripherals, including:

- UART Lite
- GPIO
- SPI Interface
- BRAM access

UART is primarily used for debugging during simulation and verification.

---

# 6. CNN Parameter Configuration

Before execution, the firmware prepares the CNN configuration.

This includes:

- Weight memory address
- Image memory address
- Result buffer address
- Input channel count
- Output channel count
- Image dimensions

These values are programmed into the accelerator through custom instructions.

---

# 7. Custom Instruction Execution

The firmware executes two custom RISC-V instructions.

## CNN_LD_WT

Configures:

- Weight Base Address
- Input Channels
- Output Channels

---

## CNN_LD_IMG_EXE

Configures:

- Image Base Address
- Result Buffer Address
- Image Size

After configuration, the accelerator asserts:

```text
start_cnn
```

which initiates CNN execution.

---

# 8. CNN Accelerator Execution

The RTL accelerator performs:

1. Weight Loading
2. Image Loading
3. Convolution
4. Multiply-Accumulate (MAC)
5. ReLU Activation
6. INT16 Feature Map Generation

The generated feature map is stored in BRAM.

---

# 9. Firmware Post-Processing

After accelerator execution completes, PicoRV32 firmware performs:

1. Read INT16 Feature Map
2. Max Pooling
3. Intermediate Scaling
4. Arithmetic Right Shift
5. Quantization
6. Clamping
7. Store Final INT8 Feature Map

This stage remains programmable, allowing post-processing algorithms to evolve without modifying the RTL accelerator.

---

# 10. Program Completion

After the final feature map is written to BRAM:

- CNN inference is complete.
- Firmware may output debug information through UART.
- The processor either terminates execution or waits for the next inference request, depending on the application.

---

# Boot Flow Summary

```text
Reset
 │
 ▼
Clock Stable
 │
 ▼
BootROM
 │
 ▼
Firmware Initialization
 │
 ▼
Peripheral Setup
 │
 ▼
CNN_LD_WT
 │
 ▼
CNN_LD_IMG_EXE
 │
 ▼
RTL Accelerator
 │
 ▼
INT16 Feature Map
 │
 ▼
Firmware Post-Processing
 │
 ▼
INT8 Output Feature Map
 │
 ▼
Program Complete
```

---

# Notes

- The BootROM executes only during system startup.
- The CNN accelerator remains idle until explicitly triggered by `CNN_LD_IMG_EXE`.
- Communication between the processor and accelerator is implemented entirely through the Pico Co-Processor Interface (PCPI).
- Post-processing is intentionally implemented in firmware to simplify experimentation with scaling and quantization algorithms.