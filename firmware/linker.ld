ENTRY(Reset_Handler)

MEMORY {
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
  RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
}

_stack_top = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS {
  .vectors ORIGIN(ROM) : { KEEP(*(.vectors)) } > ROM
  .text : { *(.text*) *(.rodata*) . = ALIGN(4); _etext = .; } > ROM
  .data : AT(_etext) { . = ALIGN(4); _sdata = .; *(.data*) . = ALIGN(4); _edata = .; } > RAM
  _sidata = LOADADDR(.data);
  .bss (NOLOAD) { . = ALIGN(4); _sbss = .; *(.bss*) *(COMMON) . = ALIGN(4); _ebss = .; } > RAM
  . = ALIGN(8); _end = .;
}

ASSERT(SIZEOF(.vectors) >= 72, "vector table must include the two external Course 3 interrupts")
ASSERT(_end <= ORIGIN(RAM) + LENGTH(RAM), "RAM overflow")
