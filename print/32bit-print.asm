[bits 32] ; 32-bit protected mode

VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f

print_string_pm:
    pusha
    mov edx, VIDEO_MEMORY
; ebx is start ptr, ecx is end ptr

print_string_pm_loop:
    cmp ebx, ecx
    je print_string_pm_done
    mov al, [ebx]
    mov ah, WHITE_ON_BLACK
    mov [edx], ax
    add ebx, 1 ; next char
    add edx, 2 ; next video memory location
    jmp print_string_pm_loop

print_string_pm_done:
    popa
    ret