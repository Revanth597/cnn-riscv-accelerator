/* Bootrom Linker Script Template
 * Preprocessed with memory configuration from config.mk
 */

ENTRY(_start)

MEMORY {
  bootrom : ORIGIN = BOOTROM_START_ADDR, LENGTH = BOOTROM_SIZE
  sram : ORIGIN = RAM_START_ADDR, LENGTH = RAM_SIZE
}

SECTIONS
{
  .text : {
    KEEP(*(.text.boot))
    KEEP(*(.text.startup))
    KEEP(*(.init))
    *(.text*)
    _etext = .;
  } > bootrom

  . = ALIGN(4);

  .data : {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > bootrom
  
  . = ALIGN(4);

  .rodata : {
    *(.rodata*)
  } > bootrom

  . = ALIGN(4);
  _bootrom_image_end = .;

  .bss : {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    _bss_end = .;
  } > bootrom

  . = ALIGN(4);
  _end = .;
}

/* Symbol definitions outside of SECTIONS block */
PROVIDE(_stack_top = ORIGIN(sram) + LENGTH(sram));
PROVIDE(_data_load_start = _data_start);


