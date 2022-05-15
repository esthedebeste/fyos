include "./ports.fy"

const screen_width: uint16 = 80
const screen_height: uint16 = 25
struct ScreenPos {
    x: uint8,
    y: uint8
}
inline fun(ScreenPos | *ScreenPos) index(): uint16
    this.x as uint16 + (this.y as uint16) * screen_width
inline fun ScreenPos(index: uint16) create ScreenPos { x = index % screen_width, y = index / screen_width }
const video_memory: { ch: char, style: uint8 }[] = 0xb8000
const white_fg_black_bg: uint8 = 0x0f

const reg_screen_ctrl: uint16 = 0x3d4
const reg_screen_data: uint16 = 0x3d5
fun vga_get_cursor_position(): uint16 {
    // ask VGA control register 0x3d4 for screen cursor position
    port_byte_out(reg_screen_ctrl, 14)
    const high: uint16 = port_byte_in(reg_screen_data)
    port_byte_out(reg_screen_ctrl, 15)
    const low: uint16 = port_byte_in(reg_screen_data);
    (high << 8) | low
}
inline fun vga_get_cursor_pos() ScreenPos(vga_get_cursor_position())

fun vga_set_cursor_position(pos: uint16): void {
    port_byte_out(reg_screen_ctrl, 14)
    port_byte_out(reg_screen_data, pos >> 8) // set high byte
    port_byte_out(reg_screen_ctrl, 15)
    port_byte_out(reg_screen_data, pos & 0xff) // set low byte
}
inline fun vga_set_cursor_pos(pos: ScreenPos) vga_set_cursor_position(pos.index())

fun vga_print_char_at(char: char, pos: *ScreenPos, style: uint8): void {
    if (char == '\n') {
        pos.x = 0
        pos.y += 1
    } else if(char == '\r') {
        pos.x = 0
    } else {
        const i = pos.index()
        video_memory[i].ch = char
        video_memory[i].style = white_fg_black_bg
        pos.x += 1
        if(pos.x >= screen_width) {
            pos.x = 0
            pos.y += 1
        }
    }
    pos.y %= screen_height // overflow from screen_height to 0
    null
}

fun vga_print_str_at(str: *char, len: uint, poss: ScreenPos | *ScreenPos) {
    const pos = if(typeof(poss) == ScreenPos) &let _ = poss else poss
    for(let i: uint = 0; i < len; i += 1)
        vga_print_char_at(str[i], pos, white_fg_black_bg)
    if(typeof(poss) == ScreenPos) *pos else poss
}

inline fun vga_print_at(str: *char[generic Len], poss: ScreenPos | *ScreenPos)
    vga_print_str_at(str, Len, poss)

inline fun vga_print(str: *char[generic Len])
    vga_set_cursor_pos(vga_print_str_at(str, Len, vga_get_cursor_pos()))

fun vga_clear_screen(): void {
    const size = screen_width * screen_height;
    for (let i = 0; i < size; i += 1) {
        video_memory[i].ch = ' ';
        video_memory[i].style = white_fg_black_bg;
    }
    vga_set_cursor_position(0);
    ()
}