include "framebuffer.fy"
include "psf.fy"
include "../fy-efi/src/memory.fy" // EFI_MEMORY_DESCRIPTOR
include "../fy-efi/src/runtime-services.fy" // EFI_RUNTIME_SERVICES

struct BootInfo {
	framebuffer: Framebuffer,
	font: PSF2_Font,
	mem_map: *EFI_MEMORY_DESCRIPTOR,
	mem_map_size: UINTN,
	mem_desc_size: UINTN,
	runtime_services: *EFI_RUNTIME_SERVICES,
}

fun(*BootInfo) get_descriptor(i: UINTN)
	((this.mem_map as *uint8) + i * this.mem_desc_size) as *EFI_MEMORY_DESCRIPTOR
