include "../drivers/vga-text.fy"

inline fun(char[generic Len]) ptr() &let alloc = this

fun main() {
    vga_clear_screen()
    vga_print("Hello from the kernel!\n".ptr())
    vga_print_at("X".ptr(), (1b, 6b))
    vga_print_at("This text spans multiple lines".ptr(), (75b, 10b))
    vga_print_at("There is a line\nbreak".ptr(), (0b0b, 20b))
    vga_print("There is a line\nbreak".ptr())
    vga_print_at("What happens when we run out of space?".ptr(), (45b, 24b))
    0
}