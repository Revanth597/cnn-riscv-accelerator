
# CNN SoC Firmware

Bootrom and firmware for the CNN SoC project.

## Build System

### Prerequisites

- Linux host environment; this project is built and tested on Ubuntu/Debian-style systems
- GNU Make
- Python 3
- RISC-V GCC toolchain for `rv32im`, including `gcc`, `objdump`, and `objcopy`

    Set the toolchain prefix if it is not already on your `PATH`:

    ```bash
    export RISCV_PREFIX=/opt/riscv32im/bin/riscv32-unknown-elf
    ```
    Or let the Makefile auto-detect if the tools are in PATH.

    Refer to [TOOLCHAIN_SETUP.md](TOOLCHAIN_SETUP.md) for instructions on how to build the toolchain.

### Quick Start

```bash
make              # Build both bootrom and firmware
make bootrom      # Build bootrom only
make firmware     # Build firmware only
make clean        # Clean all build artifacts
make config       # Show current configuration
```

### Configuration

Edit `config.mk` to change memory layout, toolchain, or build settings:

```makefile
BOOTROM_START_ADDR := 0x00000000
BOOTROM_SIZE       := 16384          # 16KB
RAM_START_ADDR     := (derived from RTL_VERSION)
RAM_SIZE           := 131072          #128KB
RISCV_PREFIX       ?= $(HOME)/riscv/toolchain/bin/riscv32-unknown-elf
ARCH               := rv32im
ABI                := ilp32
```

Override at build time:
```bash
make BOOTROM_SIZE=8192 RAM_SIZE=32768
```

### Output Files

Each build produces:

| Extension | Format | Description |
|-----------|--------|-------------|
| `.elf`    | ELF    | Executable with symbols |
| `.dis`    | Text   | Disassembly listing |
| `.bin`    | Binary | Raw binary image |
| `.hex`    | Hex    | 32-bit hex words |
| `.coe`    | COE    | Xilinx memory initialization |
| `.mem`    | MEM    | Vivado flash initialization |
| `.memh`   | MEMH   | Vivado-friendly byte-hex initialization |
| `.v`      | Verilog| Register-based ROM (bootrom only) |

Firmware additionally generates `*_with_header.{bin,hex,coe,mem,memh}` with a 16-byte header:

| Offset | Size | Field       | Description |
|--------|------|-------------|-------------|
| 0x00   | 4    | Magic       | 0xB007B007 |
| 0x04   | 4    | Size        | Payload bytes |
| 0x08   | 4    | Load Addr   | FW_LOAD_ADDR (defaults to RAM_START_ADDR for selected RTL) |
| 0x0C   | 4    | Checksum    | 32-bit additive sum of payload words |

## Directory Structure

```
.
├── bootrom/
│   ├── src/           # Bootrom source files
│   ├── bootrom.lds    # Linker script (preprocessed)
│   └── Makefile
├── firmware/
│   ├── src/           # Firmware source files
│   ├── include/       # Firmware headers
│   ├── firmware.lds   # Linker script (preprocessed)
│   └── Makefile
├── scripts/
│   ├── makehex.py               # Binary to hex
│   ├── bin2coe.py               # Binary to COE
│   ├── bin2mem.py               # Binary to MEM
│   ├── bin2memh.py              # Binary to MEMH (byte-wise)
│   ├── bin2verilog.py           # Binary to Verilog module
│   └── append_firmware_header.py # Add firmware header
├── config.mk          # Central configuration
└── Makefile           # Top-level build
```

## Toolchain

Requires RISC-V GCC toolchain for `rv32im`:
```bash
export RISCV_PREFIX=$HOME/riscv/toolchain/bin/riscv32-unknown-elf
```

Or let the Makefile auto-detect if `riscv32-unknown-elf-gcc` is in PATH.
