[org 0x7c00] ; set memory offset
mov ah, 0x0e ; tty mode

mov al, [the_chars] ; use [addr] to load
int 0x10
mov al, [the_chars + 1]
int 0x10

loop:
    jmp loop

the_chars:
    db ":)"

; zero padding and magic bios number
times 510-($-$$) db 0
dw 0xaa55