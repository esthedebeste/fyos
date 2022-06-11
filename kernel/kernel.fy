include "../shared/uintn.fy"

include "../shared/bootinfo"
include "../fy-efi/src/status" // main returns an EFI_STATUS
include "std/types"
include "./display"
include "./memory/allocator"
include "./memory/page-table"

const WHITE = create RGBAColor { red = 255, green = 255, blue = 255 }
const BLACK = create RGBAColor { red = 0, green = 0, blue = 0 }

const RED = create RGBAColor { red = 255, green = 0, blue = 0 }
const PURPLE = create RGBAColor { red = 255, green = 0, blue = 255 }
const BLUE = create RGBAColor { red = 0, green = 0, blue = 255 }

const NS_PER_SEC = 1000000000

fun show_gradient()
	for(let y = 50; y <= 200; y += 1)
	for(let x = 50; x <= 200; x += 1)
		display.framebuffer.set_pixel(display.width() - 250 + x, y, create RGBAColor {
			red = x - 50,
			green = y - 50,
			blue = (y + x - 100) / 2,
		})

let boot_info: BootInfo
let display: Display
let allocator: Allocator
let page_table_manager: PageTableManager

// initializes display, page allocator, and page table manager
fun init(bi: *BootInfo) {
	boot_info = *bi
	display = create Display {
		framebuffer = bi.framebuffer,
		font = bi.font,
		x = 0,
		y = 0,
		color = WHITE,
	}
	allocator = Allocator(bi.memmap)
	page_table_manager = PageTableManager(allocator.request_zerod_page())
	for(let page: uintn = 0; page < allocator.total_count; page += 1)
		page_table_manager.map_memory(page * PAGE_SIZE, page * PAGE_SIZE)

	const fbstart: uintn = bi.framebuffer.pixels
	const fbsize: uintn = bi.framebuffer.size
	for(let addr: uintn = fbstart; addr < fbstart + fbsize; addr += PAGE_SIZE)
		page_table_manager.map_memory(addr, addr)

	const fontstart: uintn = bi.font.glyphs
	const fontsize: uintn = bi.font.header.glyphsize * bi.font.header.numglyphs
	for(let addr: uintn = fontstart; addr < fontstart + fontsize; addr += PAGE_SIZE)
		page_table_manager.map_memory(addr, addr)

	page_table_manager.apply()
	display.clear()
	display.x = 0
	display.y = 0
}

fun main cc(X8664SysV) (bi: *BootInfo): EFI_STATUS {
	init(bi)

	show_gradient()
	display.print("Hello from the kernel! :)\n"p)


	display.print("Goodbye! :)"p)
	while(true) 0 // halt
	EFI_SUCCESS
}
