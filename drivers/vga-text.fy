include "./ports.fy"

struct VMem {
    ch: char,
    style: uint8
}
const screen_width = 80
const video_memory: VMem[] = 0xb8000
const white_fg_black_bg: uint8 = 0x0f

fun vga_get_cursor_position(): uint16 {
    // ask VGA control register (at 0x3d4) for screen cursor position
    port_byte_out(0x3d4, 14) // ask for high byte
    const high: uint16 = port_byte_in(0x3d5)
    port_byte_out(0x3d4, 15) // ask for low byte
    const low: uint16 = port_byte_in(0x3d5);
    (high << 8) | low
}

fun vga_set_cursor_position(pos: uint16): void {
    port_byte_out(0x3d4, 14)
    port_byte_out(0x3d5, pos >> 8) // set high byte
    port_byte_out(0x3d4, 15)
    port_byte_out(0x3d5, pos & 0xff) // set low byte
}

fun vga_print_str(str: *char, len: uint): uint16 {
    let pos: uint16 = vga_get_cursor_position()
    for(let i = 0; i < len; i += 1) {
        const ch = str[i]
        if(ch == '\n') // newline, go to next line
            pos += screen_width - pos % screen_width
        else {
            video_memory[pos].ch = ch
            video_memory[pos].style = white_fg_black_bg
            pos += 1
        }
    }
    vga_set_cursor_position(pos)
    pos
}

inline fun vga_print(str: *char[generic Len]): uint16
    vga_print_str(str, Len)