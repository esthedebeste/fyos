[org 0x7c00] ; set memory offset

mov bp, 0x8000 ; set stack pointer
mov sp, bp
mov bx, 0x9000 ; write after 0x9000
mov dh, 2      ; read 2 sectors
call disk_load
mov dx, [0x9000] ; get first word in first sector, should be 0xcafe
call print_0xhex
call print_newline
mov dx, [0x9000 + 512] ; get first word in second sector, should be 0xbeef
call print_0xhex
call print_newline

loop: jmp loop ; infinite loop

%include "./print/boot_sect_print.asm"
%include "./print/boot_sect_print_hex.asm"
%include "./boot_sect_disk.asm"

; zero padding and magic bios number
times 510-($-$$) db 0
dw 0xaa55

; 2 more sectors
times 256 dw 0xcafe ; sector 2 = 512 bytes
times 256 dw 0xbeef ; sector 3 = 512 bytes