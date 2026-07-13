# CNN SoC Configuration
# Central configuration file for memory layout and build settings

# =============================================================================
# Build Configuration
# =============================================================================

# RTL version
RTL_VERSION        ?= 0.1
RTL_TAG            := $(subst .,_,${RTL_VERSION})

# SIM or FPGA (in caps)
RUN_TARGET         ?= SIM

# =============================================================================
# Memory Configuration
# =============================================================================

# Bootrom memory region (read-only code)
BOOTROM_START_ADDR ?= 0x00000000
BOOTROM_SIZE       ?= 16384          # 16KB (0x4000 bytes)

# Per-RTL SRAM base defaults (must match bootrom/src/rtl_*/rtl_platform.inc)
RAM_START_ADDR_0_1 := 0x00020000
RAM_START_ADDR_1_1 := 0x06000000

# RAM memory region (firmware loads here)
RAM_START_ADDR     ?= $(RAM_START_ADDR_$(RTL_TAG))
RAM_SIZE           ?= 131072          # 128KB (0x20000 bytes)

ifeq ($(strip $(RAM_START_ADDR)),)
$(error Unsupported RTL_VERSION $(RTL_VERSION). Set RAM_START_ADDR explicitly or add RAM_START_ADDR_$(RTL_TAG) in config.mk)
endif

# =============================================================================
# Firmware Header Configuration
# =============================================================================

FW_MAGIC           ?= 0xB007B007
FW_LOAD_ADDR       ?= $(RAM_START_ADDR)

# =============================================================================
# Toolchain Configuration
# =============================================================================

# RISC-V toolchain prefix (can be overridden)
RISCV_PREFIX       ?= $(HOME)/riscv/toolchain/bin/riscv32-unknown-elf

# Architecture and ABI
ARCH               ?= rv32im
ABI                ?= ilp32

# Optimization level
OPT_LEVEL          ?= -Os

# Additional compiler flags
EXTRA_CFLAGS       ?= -Wall
