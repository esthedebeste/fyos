include "../shared/uintn.fy"

include "../shared/bootinfo"
include "../fy-efi/src/status" // main returns an EFI_STATUS
include "std/types"
include "./display"
include "./memory"
include "./allocator"

const WHITE = create RGBAColor { red = 255, green = 255, blue = 255 }
const BLACK = create RGBAColor { red = 0, green = 0, blue = 0 }

const RED = create RGBAColor { red = 255, green = 0, blue = 0 }
const PURPLE = create RGBAColor { red = 255, green = 0, blue = 255 }
const BLUE = create RGBAColor { red = 0, green = 0, blue = 255 }

const NS_PER_SEC = 1000000000
fun sleep(nanoseconds: uint64) {
	let prev: EFI_TIME
	boot_info.runtime_services.GetTime(&prev, null)
	let curr: EFI_TIME
	let diff: uint64 = 0
	while (diff < nanoseconds) {
		boot_info.runtime_services.GetTime(&curr, null)
		diff += (curr.Nanosecond - prev.Nanosecond)
		prev = curr
	}
}

fun shutdown(status: EFI_STATUS) {
	if(status != EFI_SUCCESS) {
		display.print("Error :(")
		while(true) 0 // halt
	}
	display.print("Shutting down! 10 second sleep...")
	sleep(10 * NS_PER_SEC)
	runtime_services.ResetSystem(EfiResetShutdown, status, 0, null)
}

fun show_gradient()
	for(let y = 50; y <= 200; y += 1)
	for(let x = 50; x <= 200; x += 1)
		display.framebuffer.set_pixel(display.width() - 250 + x, y, create RGBAColor {
			red = x - 50,
			green = y - 50,
			blue = (y + x - 100) / 2,
		})

fun print_kib(kib: uint64) {
	display.print(kib) display.print(" KiB")
	if(kib > 1024) { display.print(" | ") display.print(kib / 1024) display.print(" MiB") }
	if(kib > 1024 * 1024) { display.print(" | ") display.print(kib / (1024 * 1024)) display.print(" GiB") }
	null
}

let boot_info: BootInfo
let display: Display
let allocator: Allocator
fun main cc(X8664SysV) (bi: *BootInfo): EFI_STATUS {
	boot_info = *bi
	display = create Display {
		framebuffer = boot_info.framebuffer,
		font = boot_info.font,
		x = 0,
		y = 0,
		color = WHITE,
	}

	display.framebuffer.clear()
	show_gradient()
	display.print("Hello from the kernel! :)\n")

	allocator = Allocator(boot_info.memmap)
	print_memory_info()

	display.print("Free pages: ") display.print(allocator.free_count) display.print("\n")
	display.print("Allocated pages: ") display.print(allocator.used_count) display.print("\n")
	display.print("Reserved pages: ") display.print(allocator.reserved_count) display.print("\n")
	display.print("Total pages: ") display.print(allocator.total_count) display.print("\n")
	const alloc = allocator.request_pages(5)
	display.print("Allocated 5 pages at ") display.print_hex(alloc) display.print("\n")
	display.print("Free pages: ") display.print(allocator.free_count) display.print("\n")
	display.print("Allocated pages: ") display.print(allocator.used_count) display.print("\n")
	display.print("Reserved pages: ") display.print(allocator.reserved_count) display.print("\n")
	display.print("Total pages: ") display.print(allocator.total_count) display.print("\n")


	display.print("Goodbye! :)")
	while(true) 0 // halt
	EFI_SUCCESS
}
