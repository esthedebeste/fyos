[org 0x7c00] ; set memory offset

mov bx, hello_str ; string ptr
mov cx, hello_str_end ; end of string
call println

mov bx, goodbye_str ; string ptr
mov cx, goodbye_str_end ; end of string
call println

mov dx, 0xcafe
call print_0xhex

loop: jmp loop ; infinite loop

%include "boot_sect_print.asm"
%include "boot_sect_print_hex.asm"

hello_str:
    db "Hello, world!"
hello_str_end:

goodbye_str:
    db "Goodbye"
goodbye_str_end:

; zero padding and magic bios number
times 510-($-$$) db 0
dw 0xaa55