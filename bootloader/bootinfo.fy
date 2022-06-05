include "framebuffer.fy"
include "psf.fy"
include "../fy-efi/src/memory" // EFI_MEMORY_DESCRIPTOR

struct BootInfo {
	framebuffer: Framebuffer,
	font: PSF1_Font,
	mem_map: *EFI_MEMORY_DESCRIPTOR,
	mem_map_size: UINTN,
	mem_desc_size: UINTN,
}

fun(*BootInfo) get_descriptor(i: UINTN)
	((this.mem_map as *uint8) + i * this.mem_desc_size) as *EFI_MEMORY_DESCRIPTOR
