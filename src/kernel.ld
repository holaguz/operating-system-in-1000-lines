ENTRY(_start)

HEAP_PAGE_ALIGNMENT = 1024;

SECTIONS {
    . = 0x80200000;

    .text : ALIGN(4) {
        KEEP(*(.boot));
        *(.text .text.*)
    }

    .rodata : ALIGN(4) {
        *(.rodata .rodata.*);
    }

    .data : ALIGN(4) {
        *(.data .data.*);
    }

    .bss : ALIGN(4) {
        __bss_start = .;
        *(.bss .bss.* .sbss .sbss.*);
        __bss_end = .;
    }

    __bss_size = SIZEOF(.bss);
    . = ALIGN(8);
    __end = .;

    . = ALIGN(64);
    . += 128 * 1024; /* 128KB */
    __stack_top = .;


    . = ALIGN(4096);
    __free_ram = .;
    . += 64 * 1024 * 1024; /* 64 MB */
    __free_ram_end = .;
}
