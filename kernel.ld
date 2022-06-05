OUTPUT_FORMAT(elf64-x86-64)
ENTRY(main)
SECTIONS {
    .text : {
        *(.text)
    }
    .data : {
        *(.data)
    }
    .rodata : {
        *(.rodata)
    }
    .bss : {
        *(COMMON)
        *(.bss)
    }
}