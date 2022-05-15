[bits 16]
print:
    pusha

; bx is base string address, cx is end of string address
print_body:
    ; check current != end
    cmp bx, cx
    jge print_done
    ; print char
    mov al, [bx]
    mov ah, 0x0e ; tty mode
    int 0x10
    ; increment bx, next char
    inc bx
    jmp print_body
    
print_done:
    ; return to caller
    popa
    ret

print_newline:
    pusha
    mov ah, 0x0e ; tty mode
    mov al, 0x0a ; newline
    int 0x10
    mov al, 0x0d ; carriage return
    int 0x10
    popa
    ret

println:
    call print
    call print_newline
    ret