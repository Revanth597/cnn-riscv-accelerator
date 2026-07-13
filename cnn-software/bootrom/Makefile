# Include project configuration
include ../config.mk

CC      := $(if $(wildcard $(RISCV_PREFIX)-gcc),$(RISCV_PREFIX)-gcc,riscv32-unknown-elf-gcc)
OBJDUMP := $(patsubst %gcc,%objdump,$(CC))
OBJCOPY := $(patsubst %gcc,%objcopy,$(CC))

SRC_DIR     := src
BUILD_DIR   := build
SCRIPT_DIR  := ../scripts
RTL_TAG     := $(subst .,_,${RTL_VERSION})
RTL_SRC_DIR := $(SRC_DIR)/rtl_$(RTL_TAG)

# MEMH output configuration for this image
MEMH_WORD_WIDTH_BITS ?= 32
MEMH_WORD_BYTE_ORDER ?= reverse
MEMH_WORDS_PER_LINE  ?= 1

ifeq ($(wildcard $(RTL_SRC_DIR)),)
$(error Unsupported RTL_VERSION $(RTL_VERSION). Missing $(RTL_SRC_DIR))
endif

CFLAGS  := $(OPT_LEVEL) -march=$(ARCH) -mabi=$(ABI) -ffreestanding $(EXTRA_CFLAGS)
LDFLAGS := -T$(BUILD_DIR)/bootrom.lds -nostdlib -lgcc

# Linker script preprocessor flags
LD_DEFINES := -DBOOTROM_START_ADDR=$(BOOTROM_START_ADDR) \
              -DBOOTROM_SIZE=$(BOOTROM_SIZE) \
			  -DRAM_START_ADDR=$(RAM_START_ADDR) \
			  -DRAM_SIZE=$(RAM_SIZE)

# Build type (FLASH_PATH or UART_PATH)
BUILD_MODE ?= FLASH_PATH
OBJ_DIR    := $(BUILD_DIR)/obj/$(BUILD_MODE)/rtl_$(RTL_TAG)
CFLAGS += -D$(BUILD_MODE) -DRTL_VERSION_$(RTL_TAG) -DTARGET_$(RUN_TARGET) -I$(RTL_SRC_DIR)

# Output suffix based on build mode (for UART_PATH, creates separate bootrom)
OUTPUT_SUFFIX := $(if $(filter UART_PATH,$(BUILD_MODE)),_UART_PATH,)

TARGET_NAME := bootrom$(OUTPUT_SUFFIX)
TARGET      := $(BUILD_DIR)/$(TARGET_NAME)

C_SRCS   := $(wildcard $(SRC_DIR)/*.c)
ASM_SRCS := $(wildcard $(SRC_DIR)/*.S) $(wildcard $(RTL_SRC_DIR)/*.S)
INC_SRCS := $(wildcard $(RTL_SRC_DIR)/*.inc)

OBJS := \
	$(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(C_SRCS)) \
	$(patsubst $(SRC_DIR)/%.S,$(OBJ_DIR)/%.o,$(ASM_SRCS))

# Default target
all: $(TARGET).elf $(TARGET).dis $(TARGET).bin $(TARGET).hex $(TARGET).coe $(TARGET).mem $(TARGET).memh $(TARGET).v

# Test binaries
TEST_DIR   := tests
TEST_BUILD_DIR := $(BUILD_DIR)/tests
TEST_SRCS := $(wildcard $(TEST_DIR)/*.S)
TEST_ELF_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(TEST_BUILD_DIR)/%_test.elf,$(TEST_SRCS))
TEST_COE_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(TEST_BUILD_DIR)/%_test.coe,$(TEST_SRCS))
TEST_BIN_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(TEST_BUILD_DIR)/%_test.bin,$(TEST_SRCS))
TEST_HEX_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(TEST_BUILD_DIR)/%_test.hex,$(TEST_SRCS))
TEST_DIS_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(TEST_BUILD_DIR)/%_test.dis,$(TEST_SRCS))

$(TEST_BUILD_DIR):
	mkdir -p $@

tests: $(TEST_COE_TARGETS) $(TEST_HEX_TARGETS) $(TEST_DIS_TARGETS)

$(TEST_BUILD_DIR)/%_test.elf: $(TEST_DIR)/%.S $(BUILD_DIR)/bootrom.lds | $(TEST_BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean-tests:
	rm -f $(TEST_ELF_TARGETS) $(TEST_COE_TARGETS) $(TEST_BIN_TARGETS) $(TEST_HEX_TARGETS) $(TEST_DIS_TARGETS)

# Ensure build folder exists
$(BUILD_DIR):
	mkdir -p $@

$(OBJ_DIR): | $(BUILD_DIR)
	mkdir -p $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(MAKEFILE_LIST) $(INC_SRCS) | $(OBJ_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@


$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S $(MAKEFILE_LIST) $(INC_SRCS) | $(OBJ_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

# Preprocess linker script
$(BUILD_DIR)/bootrom.lds: bootrom.lds $(MAKEFILE_LIST) | $(BUILD_DIR)
	$(CC) -E -P -x c $(LD_DEFINES) $< -o $@

$(TARGET).elf: $(OBJS) $(BUILD_DIR)/bootrom.lds
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

# Include generated dependency files (optional - missing files are ignored)
-include $(OBJS:.o=.d)

# Output binaries
%.dis: %.elf
	$(OBJDUMP) -d $< > $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.hex: %.bin $(SCRIPT_DIR)/makehex.py
	python3 $(SCRIPT_DIR)/makehex.py $< > $@

%.coe: %.bin $(SCRIPT_DIR)/bin2coe.py
	python3 $(SCRIPT_DIR)/bin2coe.py $< $@

%.mem: %.bin $(SCRIPT_DIR)/bin2mem.py
	python3 $(SCRIPT_DIR)/bin2mem.py $< $@ $(BOOTROM_START_ADDR)

%.memh: %.bin $(SCRIPT_DIR)/bin2memh.py
	python3 $(SCRIPT_DIR)/bin2memh.py $< \
		--output $@ \
		--word-width-bits $(MEMH_WORD_WIDTH_BITS) \
		--word-byte-order $(MEMH_WORD_BYTE_ORDER) \
		--words-per-line $(MEMH_WORDS_PER_LINE)

%.v: %.bin $(SCRIPT_DIR)/bin2verilog.py
	python3 $(SCRIPT_DIR)/bin2verilog.py $< $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
