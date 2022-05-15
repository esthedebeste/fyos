include "../drivers/vga-text.fy"

fun main() {
    let str = "Hello from the kernel!\n"
    vga_print(&str)
}