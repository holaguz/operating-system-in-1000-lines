ENTRY(_start)

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

    . = ALIGN(64);
    . += 128 * 1024; /* 128KB */
    __stack_top = .;
}
