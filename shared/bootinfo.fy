include "framebuffer.fy"
include "psf2.fy"
include "memory_map.fy"
include "../fy-efi/src/runtime-services.fy" // EFI_RUNTIME_SERVICES

struct BootInfo {
	framebuffer: Framebuffer,
	font: PSF2_Font,
	memmap: MemoryMap,
	runtime_services: *EFI_RUNTIME_SERVICES,
}
