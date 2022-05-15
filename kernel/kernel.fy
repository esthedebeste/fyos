include "../drivers/vga-text.fy"
include "../util/types"
include "../util/memory"
include "../util/stringify"

inline fun(char[generic Len]) ptr() &let alloc = this

fun main() {
    vga_clear_screen()
    for (let i: uint = 0; i < 24; i += 1) {
        let str: char[5]
        const len = i.to_strbuf(&str)
		str[len] = '\n'
        vga_print_str(str, len + 1)
    }

    vga_print("Hello from the kernel!\n".ptr())
    vga_print("This\nwill\nscroll\ndown\na\ncouple\nlines".ptr())
	;&memset; // always include memset because llvm optimizations want it
	0
}