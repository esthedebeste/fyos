[org 0x7c00] ; set memory offset
mov ah, 0x0e ; tty mode

; bp register stores bottom of the stack, sp stores the top
mov bp, 0x8000 ; far enough away from the base 0x7c00
mov sp, bp ; initially, the bottom is the top

push 'A'
push 'B'
push 'C'

; you can only access the top of the stack
mov al, [0x7ffe] ; 0x8000 - 2, top of the stack is A
int 0x10 

pop bx ; C
mov al, bl
int 0x10

pop bx ; B
mov al, bl
int 0x10

pop bx ; A
mov al, bl
int 0x10

; popped data is garbage
mov al, [0x8000]
int 0x10

loop:
    jmp loop

; zero padding and magic bios number
times 510-($-$$) db 0
dw 0xaa55