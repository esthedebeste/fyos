print_0xhex:
    mov ah, 0x0e ; tty mode
    mov al, '0'
    int 0x10
    mov al, 'x'
    int 0x10
print_hex:
    pusha
    mov cx, 0
; dx is the number to print

hex_loop:
    cmp cx, 4
    jge print_hex_done

    mov ax, dx
    and ax, 0xf000 ; get the high nibble
    shr ax, 12 ; shift it down
    add al, '0'
    cmp al, '9'
    jle print_hex_digit
    add al, 'a' - '9' - 1 ; add offset if above 9 (10 => `a`)

print_hex_digit:
    mov ah, 0x0e ; tty mode
    int 0x10
    rol dx, 4 ; r = r << 4, get next nibble
    inc cx
    jmp hex_loop

print_hex_done:
    popa
    ret

