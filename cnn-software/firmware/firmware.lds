/* Firmware Linker Script Template
 * Preprocessed with memory configuration from config.mk
 */

ENTRY(_start)

MEMORY {
  ram : ORIGIN = RAM_START_ADDR, LENGTH = RAM_SIZE
}

SECTIONS
{
  .text : {
    KEEP(*(.text.boot)) 
    KEEP(*(.text.startup))
    KEEP(*(.init))
    *(.text*)
    _etext = .;
  } > ram

  . = ALIGN(4);

  .data : {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > ram
  
  . = ALIGN(4);

  .rodata : {
    *(.rodata*)
  } > ram

  . = ALIGN(4);

  .bss : {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    _bss_end = .;
  } > ram

  . = ALIGN(4);
  _end = .;
}

/* Symbol definitions outside of SECTIONS block */
PROVIDE(_stack_top = ORIGIN(ram) + LENGTH(ram));
PROVIDE(_data_load_start = _data_start);


