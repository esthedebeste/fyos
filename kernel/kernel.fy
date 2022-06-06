include "../bootloader/bootinfo.fy"
include "../fy-efi/src/status" // main returns an EFI_STATUS
include "std/types"
include "./display"
include "./memory"

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
	null
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

let boot_info: BootInfo
let display: Display
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

	display.print("Hello from the kernel! :)\n")
	let entries = boot_info.mem_map_size / boot_info.mem_desc_size
	display.print("Memory entries: ") display.print(entries) display.print("\n")
	if(entries > 20) {
		display.print("Truncating to 20 entries\n")
		entries = 20
	}
	for(let i: uint64 = 0; i < entries; i += 1) {
		const desc = boot_info.get_descriptor(i)
		display.print("Memory entry ") if(i < 10 && entries >= 10) display.print('0') display.print(i) display.print(": ")
		display.print(desc.NumberOfPages * 4) display.print(" KiB")
		display.print(", ") display.print(efi_mem_type_to_str(desc.Type)) display.print("\n")
	}
	for(let y = 50; y <= 200; y += 1)
	for(let x = 50; x <= 200; x += 1)
		display.framebuffer.set_pixel(display.width() - 250 + x, y, create RGBAColor {
			red = x - 50,
			green = y - 50,
			blue = (y + x - 100) / 2,
		})

	display.print("Goodbye! :)")
	EFI_SUCCESS
}
