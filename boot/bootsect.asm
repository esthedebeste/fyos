[org 0x7c00] ; bootloader offset
[bits 16]
KERNEL_OFFSET equ 0x1000 ; the same one we use when linking the kernel
mov [BOOT_DRIVE], dl ; store boot drive
mov bp, 0x8000 ; set stack pointer
mov sp, bp

mov bx, startup_str
mov cx, startup_str_end
call println
mov bx, KERNEL_OFFSET ; Read from disk and store in 0x1000
mov dh, 16 ; read 16 sectors, kernel might get big
mov dl, [BOOT_DRIVE]
call disk_load
call switch_to_pm
[bits 32]
BEGIN_PM: ; after switch to 32-bit protected mode
    mov ebx, prot_mode_str
    mov ecx, prot_mode_str_end
    call print_string_pm
    call KERNEL_OFFSET ; Calls the C function. The linker will know where it is placed in memory

INF_LOOP: jmp INF_LOOP ; should never get here


%include "./print.asm"
%include "./print-hex.asm"
%include "./disk.asm"
%include "./gdt.asm"
%include "./32bit-print.asm"
%include "./switch-pm.asm"


BOOT_DRIVE: db 0
startup_str: db "Started in 16-bit real mode, loading kernel..."
startup_str_end:
prot_mode_str: db "In 32-bit protected mode, starting up kernel..."
prot_mode_str_end:

; bootsector, zero padding and magic bios number
times 510-($-$$) db 0
dw 0xaa55