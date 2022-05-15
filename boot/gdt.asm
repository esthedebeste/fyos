gdt_start:
    dd 0x0 ; 4 byte
    dd 0x0 ; 4 byte

; GDT for code segment. 0x00000-0xfffff
gdt_code: 
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    ; 1st flags: (present)1 (privilege)00 ( descriptor type )1 -> 1001b
    ; type flags: (code)1 (conforming)0 (readable)1 (accessed)0 -> 1010b
    db 10011010b ; flags (8 bits)
    ; 2nd flags: (granularity)1 (32 - bit default)1 (64 - bit seg)0 (AVL)0 -> 1100b
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

; GDT for data segment. Almost the same as code segment, but with different type flags
gdt_data:
    dw 0xffff
    dw 0x0
    db 0x0
    ; type flags: (code)0 (expand down)0 (writable)1 (accessed)0 -> 0010 b
    db 10010010b
    db 11001111b
    db 0x0

gdt_end:

; GDT descriptor
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; size (16-bit) - 1
    dd gdt_start ; base address (32-bit)

CODE_SEGMENT equ gdt_code - gdt_start
DATA_SEGMENT equ gdt_data - gdt_start