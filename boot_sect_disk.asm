; load 'dh' sectors from drive 'dl' into es:bx
disk_load:
    pusha
    push dx ; save to restore later

    mov ah, 0x02 ; 0x02 = read
    mov al, dh ; number of sectors to read
    mov cl, 0x02 ; base sector, 0x02 = first sector that isn't boot sector
    ; mov dl, dl ; drive number
    mov dh, 0x00 ; head number (0x00 .. 0x0f)

    ; [es:bx] = pointer to buffer where the data will be stored
    ; caller sets it up, and int 13h uses it by default
    int 0x13
    jc disk_error ; if carry set, error occurred

    pop dx ; requested number of sectors read
    cmp al, dh
    jne sectors_error ; if not equal, error occurred
    popa
    ret

disk_error:
    mov bx, disk_error_str
    mov cx, disk_error_str_end
    call println
    mov dh, ah ; ah = error code
    call print_0xhex
    jmp inf_loop

sectors_error:
    mov bx, sectors_error_str
    mov cx, sectors_error_str_end
    call println
    mov dh, dh ; requested number of sectors
    call print_0xhex
    mov bx, sectors_error_str2
    mov cx, sectors_error_str2_end
    call println
    jmp inf_loop

inf_loop:
    jmp $

disk_error_str: db "disk read error, error code = "
disk_error_str_end:
sectors_error_str: db "disk read error, requested "
sectors_error_str_end:
sectors_error_str2: db " sectors, got "
sectors_error_str2_end:
