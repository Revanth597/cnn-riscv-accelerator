# Architecture Figures

This directory contains the architectural diagrams used throughout the project documentation. These figures illustrate the overall hardware architecture, the PCPI interface, the custom instruction mechanism, and the complete CNN inference dataflow.

---

## Figures

### 01_soc_block_design.png

Top-level Vivado block design of the complete CNN-RISC-V accelerator system.

This figure shows:
- PicoRV32 processor
- AXI Interconnect
- AXI BRAM Controller
- Block RAM
- AXI Quad SPI Flash
- UART Lite
- GPIO
- Clock Wizard
- Processor System Reset

The PicoRV32 processor communicates with external peripherals through the AXI interconnect while also containing the integrated PCPI CNN coprocessor.

---

### 02_pcpi_interface_diagram.png

PCPI interface between PicoRV32 and the CNN accelerator.

The diagram illustrates:

- Custom instruction decoding
- PCPI request interface
- Configuration registers
- Accelerator control path
- RTL datapath
- BRAM interaction
- PCPI response signals

Request Signals
- pcpi_valid
- pcpi_insn
- pcpi_rs1
- pcpi_rs2

Response Signals
- pcpi_ready
- pcpi_wr
- pcpi_rd
- pcpi_wait

During verification, only **pcpi_ready**, **pcpi_wr**, and **pcpi_rd** were asserted to validate instruction decoding and register updates.

The **pcpi_wait** signal was intentionally kept deasserted because the verification focused only on validating custom instruction functionality. The RTL architecture supports asserting `pcpi_wait` whenever multi-cycle execution is required.

---

### 03_cnn_process_flow.png

Complete CNN inference pipeline showing the interaction between hardware and firmware.

Hardware (RTL Accelerator)
- Load weights from BRAM
- Load input image from BRAM
- Convolution engine
- MAC array
- ReLU activation
- Store INT16 feature map to BRAM

Firmware (PicoRV32)
- Read INT16 feature map
- Multiply by per-channel intermediate scales (UINT16, Q16)
- INT16 × UINT16 → INT32
- Arithmetic right shift
- Max Pooling (2×2)
- Quantization to INT8
- Clamp to INT8 range
- Store final INT8 feature map back to BRAM

This partition allows computationally intensive convolution operations to execute in hardware while keeping post-processing programmable in firmware.

---

## Notes

The architecture is intentionally partitioned into:

- **RTL Accelerator**
  - Weight loading
  - Image loading
  - Convolution
  - MAC operations
  - ReLU
  - INT16 feature map generation

- **Firmware**
  - Intermediate scaling
  - Arithmetic shifting
  - Max Pooling
  - Quantization
  - Clamping
  - Final feature map storage

This hardware/software co-design keeps the RTL focused on compute-intensive operations while allowing configurable post-processing through firmware.
