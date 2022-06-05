include "../bootloader/bootinfo.fy"
include "std/types"
include "./display"
include "./memory"

const WHITE = create RGBAColor { red = 255, green = 255, blue = 255 }
const BLACK = create RGBAColor { red = 0, green = 0, blue = 0 }

const RED = create RGBAColor { red = 255, green = 0, blue = 0 }
const PURPLE = create RGBAColor { red = 255, green = 0, blue = 255 }
const BLUE = create RGBAColor { red = 0, green = 0, blue = 255 }

let display: Display
const output = &display
fun main cc(X8664SysV) (boot_info: *BootInfo): uint32 {
	display = create Display {
		framebuffer = boot_info.framebuffer,
		font = boot_info.font,
		x = 0,
		y = 0,
		color = WHITE,
	}
	output.print("Hello,\nworld!\n")
	const entries = boot_info.mem_map_size / boot_info.mem_desc_size
	output.print("Memory entries: ") output.print(entries) output.print("\n")
	for(let i: uint64 = 0; i < entries; i += 1) {
		const desc = boot_info.get_descriptor(i)
		output.print("Memory entry ") output.print(i) output.print(": ")
		output.print(efi_mem_type_to_str(desc.Type))
		output.print(", ") output.print(desc.NumberOfPages) output.print(" pages\n")
	}
	for(let y = 50; y <= 200; y += 1)
	for(let x = 50; x <= 200; x += 1)
		display.framebuffer.set_pixel(x, y, create RGBAColor {
			red = x - 50,
			green = y - 50,
			blue = (y + x - 100) / 2,
		})
	1234
}
