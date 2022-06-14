include "../shared/uintn.fy"

include "../shared/bootinfo"
include "../fy-efi/src/status" // main returns an EFI_STATUS
include "std/types"
include "./display"
include "./memory/allocator"
include "./memory/page-table"
include "./memory/gdt"
include "./interrupts/idt"
include "./interrupts/interrupts"
include "./time/pit"

const WHITE = create RGBAColor { red = 255, green = 255, blue = 255 }
const BLACK = create RGBAColor { red = 0, green = 0, blue = 0 }

const RED = create RGBAColor { red = 255, green = 0, blue = 0 }
const PURPLE = create RGBAColor { red = 255, green = 0, blue = 255 }
const BLUE = create RGBAColor { red = 0, green = 0, blue = 255 }

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
let idtr: IDTR

fun enable_interrupts() {
	idtr = create IDTR {
		base = allocator.request_page(),
		limit = 0x0fff,
	}

	const zerodiv: *IDTDescriptorEntry = &idtr.base[0]
	zerodiv.set_handler(zerodiv_handler)
	zerodiv.type_attr = IDT_InterruptGate
	zerodiv.segment = 0x08

	const doublefault: *IDTDescriptorEntry = &idtr.base[8]
	doublefault.set_handler(doublefault_handler)
	doublefault.type_attr = IDT_InterruptGate
	doublefault.segment = 0x08

	const gpfault: *IDTDescriptorEntry = &idtr.base[13]
	gpfault.set_handler(gpfault_handler)
	gpfault.type_attr = IDT_InterruptGate
	gpfault.segment = 0x08

	const pagefault: *IDTDescriptorEntry = &idtr.base[14]
	pagefault.set_handler(pagefault_handler)
	pagefault.type_attr = IDT_InterruptGate
	pagefault.segment = 0x08

	const timer: *IDTDescriptorEntry = &idtr.base[32]
	timer.set_handler(pit_handler)
	timer.type_attr = IDT_InterruptGate
	timer.segment = 0x08

	__asm__("lidt (%rax)"p)(rax = &idtr)
}

fun(EFI_TIME) to_epoch_seconds(): uint64 {
  const a: uint64 = (14 - this.Month as uint64) / 12
  const y: uint64 = this.Year as uint64 + 4800 - a
  const m: uint64 = this.Month as uint64 + (12 * a) - 3
  const d: uint64 = this.Day as uint64 + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 2472633
  d * 86400 + this.Hour as uint64 * 3600 + this.Minute as uint64 * 60 + this.Second as uint64
}

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
	display.println("Initializing page allocator"p)
	allocator = Allocator(bi.memmap)
	display.println("Initializing table manager"p)
	page_table_manager = PageTableManager(allocator.request_zerod_page())
	display.println("Mapping memory"p)
	for(let page: uintn = 0; page < allocator.total_count; page += 1)
		page_table_manager.map_memory(page * PAGE_SIZE, page * PAGE_SIZE)

	display.println("Mapping framebuffer"p)
	const fbstart: uintn = bi.framebuffer.pixels
	const fbsize: uintn = bi.framebuffer.size
	for(let addr: uintn = fbstart; addr < fbstart + fbsize; addr += PAGE_SIZE)
		page_table_manager.map_memory(addr, addr)

	display.println("Mapping font glyphs"p)
	const fontstart: uintn = bi.font.glyphs
	const fontsize: uintn = bi.font.header.glyphsize * bi.font.header.numglyphs
	for(let addr: uintn = fontstart; addr < fontstart + fontsize; addr += PAGE_SIZE)
		page_table_manager.map_memory(addr, addr)

	display.println("Loading GDT"p)
	default_gdt.load()
	display.println("Applying PTM"p)
	page_table_manager.apply()
	display.println("Enabling interrupts"p)
	enable_interrupts()
	display.println("Remapping PIC"p)
	remap_pic()
	port_byte_out(PIC1_DATA_PORT, 0b11111110)
	port_byte_out(PIC2_DATA_PORT, 0b11111111)
	__asm__("sti")()
	display.println("Setting PIT divisor"p)
	set_pit_divisor(0xffff)
	display.println("Getting startup time..."p)
	let time: EFI_TIME
	const status = bi.runtime_services.GetTime(&time, 0)
	if(status != 0) { display.println("Getting startup time failed"p) null }
	else { boot_time = time.to_epoch_seconds() null }
	display.println("Clearing screen"p)
	display.clear()
	display.x = 0
	display.y = 0
}

fun main cc(X8664SysV) (bi: *BootInfo): EFI_STATUS {
	init(bi)

	show_gradient()
	display.println("Hello from the kernel! :)"p)
	display.print("Startup time (in seconds since 01/01/1970, 00:00): "p) display.println(boot_time as uint64)
	for(let i: uint64 = 0; i <= 20; i += 1) {
		display.print("Current time: "p) display.println((boot_time + time_since_boot) as uintn)
		sleep(1)
	}

	display.print("Goodbye! :)"p)
	while(true) 0 // halt
	EFI_SUCCESS
}
