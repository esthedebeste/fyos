mov ah, 0x0e ; tty
mov al, 'H'
int 0x10 ; interrupt to print character
mov al, 'e'
int 0x10
mov al, 'l'
int 0x10
int 0x10
mov al, 'o'
int 0x10
mov al, '!'
int 0x10

loop:
    jmp loop

times 510-($-$$) db 0
dw 0xaa55