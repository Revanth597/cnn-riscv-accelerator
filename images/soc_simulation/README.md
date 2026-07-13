# SoC Simulation

## Overview

This directory contains the complete system-level simulation results of the CNN-enabled PicoRV32 System-on-Chip (SoC).

Unlike the standalone RTL simulations, these simulations verify the complete execution flow beginning from system reset, BootROM execution, firmware loading, custom instruction execution, and communication between the PicoRV32 processor and the CNN accelerator through the Pico Co-Processor Interface (PCPI).

The SoC consists of:

- PicoRV32 Processor
- BootROM
- Block RAM (BRAM)
- SPI Flash
- UART Lite
- GPIO
- CNN PCPI Accelerator

These simulations verify successful integration of the custom instruction interface into the complete processor system.

---

# Directory Contents

| File | Description |
|------|-------------|
| `01_soc_testbench.png` | Complete SoC simulation testbench. |
| `02_soc_hierarchy.png` | RTL hierarchy of the integrated PicoRV32 SoC. |
| `03_pcpi_decode.png` | PCPI instruction decode logic. |
| `04_configuration_registers.png` | CNN configuration registers. |
| `05_configuration_capture.png` | Configuration register update logic. |
| `06_pcpi_response_logic.png` | PCPI response generation logic. |
| `07_weight_instruction_response.png` | Response logic for `CNN_LD_WT`. |
| `08_image_execute_response.png` | Response logic for `CNN_LD_IMG_EXE`. |
| `09_weight_instruction_waveform.png` | SoC waveform verifying `CNN_LD_WT`. |
| `10_image_execute_waveform.png` | SoC waveform verifying `CNN_LD_IMG_EXE`. |
| `11_uart_console.png` | UART output during BootROM execution. |

---

# Simulation Objective

The SoC simulations verify successful communication between PicoRV32 firmware and the CNN accelerator through the PCPI interface.

The verification includes:

- BootROM execution
- Firmware loading
- Firmware execution
- Custom instruction decoding
- Configuration register updates
- PCPI communication
- Accelerator configuration
- UART debug output

---

# Overall SoC Boot Flow

```
Reset
   │
   ▼
BootROM Starts
   │
   ▼
BRAM Verification
   │
   ▼
SPI Flash Initialization
   │
   ▼
Firmware Loaded into SRAM
   │
   ▼
Jump to Firmware
   │
   ▼
Firmware Executes
   │
   ▼
CNN_LD_WT
   │
   ▼
CNN_LD_IMG_EXE
   │
   ▼
CNN Accelerator Begins Execution
```

---

# SoC Testbench

**Image:** `01_soc_testbench.png`

The complete SoC testbench instantiates:

- PicoRV32 Processor
- BootROM
- SPI Flash Model
- UART Receiver
- Block RAM
- CNN PCPI Accelerator

The testbench executes the complete boot sequence and firmware while monitoring the processor-to-accelerator communication.

---

# RTL Hierarchy

**Image:** `02_soc_hierarchy.png`

The RTL hierarchy illustrates the integrated SoC.

Major modules include:

- PicoRV32 Processor
- AXI Interconnect
- AXI BRAM Controller
- Block RAM
- AXI Quad SPI
- UART Lite
- GPIO
- CNN PCPI Accelerator

The CNN accelerator is connected directly to the PicoRV32 processor through the PCPI interface.

---

# PCPI Instruction Decode

**Image:** `03_pcpi_decode.png`

Instruction decoding is performed using:

```
Opcode = 0x2B
```

The `funct3` field distinguishes the implemented instructions.

### CNN_LD_WT

```
funct3 = 000
```

Updates:

- Weight Base Address
- Input Channels
- Output Channels

---

### CNN_LD_IMG_EXE

```
funct3 = 001
```

Updates:

- Image Base Address
- Output Feature Map Address
- Image Size

The accelerator then asserts the internal `start_cnn` signal.

---

# Configuration Registers

**Image:** `04_configuration_registers.png`

The CNN accelerator maintains dedicated configuration registers.

These include:

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

The sequential configuration logic captures accelerator parameters on the rising edge of the clock.

The first instruction stores weight-related parameters.

The second instruction stores image-related parameters and asserts `start_cnn`, allowing CNN execution to begin.

---

# PCPI Response Logic

**Image:** `06_pcpi_response_logic.png`

The PCPI response logic generates the standard PicoRV32 handshake signals.

Signals include:

- `pcpi_ready`
- `pcpi_wr`
- `pcpi_rd`
- `pcpi_wait`

During verification of the custom instruction interface:

```
pcpi_ready = 1
pcpi_wr    = 1
pcpi_wait  = 0
```

The standard PCPI interface supports multi-cycle execution through the `pcpi_wait` signal.

For the verification performed in this project, the objective was to validate instruction decoding, configuration register updates, and processor-to-accelerator communication. Since the custom instructions only configured the accelerator and returned debug responses, `pcpi_wait` remained deasserted during these tests.

The RTL accelerator may assert `pcpi_wait` whenever multi-cycle execution is required.

---

# CNN_LD_WT Verification

**Image:** `09_weight_instruction_waveform.png`

The waveform verifies successful execution of the first custom instruction.

Verified behavior:

- Instruction decode
- Configuration register updates
- Weight configuration
- Input channel configuration
- Output channel configuration
- Successful PCPI handshake
- Debug response generation

---

# CNN_LD_IMG_EXE Verification

**Image:** `10_image_execute_waveform.png`

The waveform verifies execution of the second custom instruction.

Verified behavior:

- Instruction decode
- Image configuration
- Result buffer configuration
- Image size configuration
- Assertion of `start_cnn`
- Successful PCPI handshake
- Debug response generation

---

# CNN Processing

After the accelerator receives both custom instructions, CNN execution begins.

The RTL accelerator performs:

- Weight Loading
- Image Loading
- Convolution
- Multiply-Accumulate (MAC)
- ReLU Activation

The generated INT16 feature map is written to BRAM.

PicoRV32 firmware subsequently performs:

- Max Pooling
- Intermediate Scaling
- Arithmetic Right Shift
- Quantization
- Clamping

before storing the final INT8 feature map back into BRAM.

---

# UART Console Output

**Image:** `11_uart_console.png`

During BootROM execution, status values are transmitted over UART to indicate boot progress.

| UART Output | Description |
|-------------|-------------|
| **0x0A** | BRAM verification using the first test value (decimal 10). |
| **0x14** | BRAM verification using the second test value (decimal 20). |
| **0xFE** | SPI Flash successfully initialized. BootROM begins loading the firmware image. |
| **0xFF** | Firmware image successfully loaded into SRAM, checksum verified, and control transferred to the firmware entry point. |

The UART output therefore represents the following execution sequence.

```
Reset
   │
BootROM Starts
   │
BRAM Verification
(0x0A)
   │
Second BRAM Verification
(0x14)
   │
SPI Flash Ready
(0xFE)
   │
Firmware Loaded
   │
Checksum Verified
   │
Jump to Firmware
(0xFF)
```

These UART values provide simple runtime checkpoints confirming successful BootROM execution before firmware begins.

---

# Scope of Verification

The simulations presented in this directory focus on verifying complete system integration between the PicoRV32 processor and the CNN accelerator.

Verification includes:

- BootROM execution
- Firmware loading
- Firmware execution
- Processor-to-accelerator communication
- Custom instruction decoding
- Configuration register updates
- PCPI request and response signals
- Accelerator configuration
- UART status reporting

The internal CNN accelerator datapath is verified independently as part of the RTL development.

---

# Summary

The SoC simulations demonstrate successful integration of the CNN accelerator with the PicoRV32 processor.

The complete system successfully executes the BootROM, loads the firmware, configures the CNN accelerator using two custom RISC-V instructions, and verifies processor-to-accelerator communication through the Pico Co-Processor Interface (PCPI).

These simulations validate the complete software-to-hardware control path and confirm successful system-level integration of the custom instruction interface within the PicoRV32-based SoC.