include "../fy-efi/src/memory.fy"

fun print_memory_info() {
	display.print("Full memory size: ") print_kib(boot_info.memmap.page_count * 4) display.print("\n")
	const entries: uint64 = boot_info.memmap.full_size / boot_info.memmap.descriptor_size
	display.print("Memory entries: ") display.print(entries) display.print("\n")
	const trunc_entries = if(entries > 40) {
		display.print("Truncating to 40 entries\n")
		40 as uint64
	} else entries
	for(let i: uint64 = 0; i < trunc_entries; i += 1) {
		const desc: *EFI_MEMORY_DESCRIPTOR = boot_info.memmap.get_descriptor(i)
		display.print("Memory entry ") if(i < 10 && trunc_entries >= 10) display.print('0') display.print(i) display.print(" at ") display.print_hex(desc.PhysicalStart) display.print(": ")
		const KiB = desc.NumberOfPages * 4
		print_kib(KiB) display.print(", ") display.print(efi_mem_type_to_str(desc.Type)) display.print("\n")
	}
}

fun efi_mem_type_to_str(mem_type: EFI_MEMORY_TYPE): *char
		 if(mem_type == EfiReservedMemoryType)		"Reserved Memory Type"c as *char
	else if(mem_type == EfiLoaderCode)				"Loader Code"c as *char
	else if(mem_type == EfiLoaderData)				"Loader Data"c as *char
	else if(mem_type == EfiBootServicesCode)		"Boot Services Code"c as *char
	else if(mem_type == EfiBootServicesData)		"Boot Services Data"c as *char
	else if(mem_type == EfiRuntimeServicesCode)		"Runtime Services Code"c as *char
	else if(mem_type == EfiRuntimeServicesData)		"Runtime Services Data"c as *char
	else if(mem_type == EfiConventionalMemory)		"Conventional Memory"c as *char
	else if(mem_type == EfiUnusableMemory)			"Unusable Memory"c as *char
	else if(mem_type == EfiACPIReclaimMemory)		"ACPI Reclaim Memory"c as *char
	else if(mem_type == EfiACPIMemoryNVS)			"ACPI Memory NVS"c as *char
	else if(mem_type == EfiMemoryMappedIO)			"Memory Mapped IO"c as *char
	else if(mem_type == EfiMemoryMappedIOPortSpace)	"Memory Mapped IO Port Space"c as *char
	else if(mem_type == EfiPalCode)					"Pal Code"c as *char
	else if(mem_type == EfiPersistentMemory)		"Persistent Memory"c as *char
	else if(mem_type == EfiUnacceptedMemoryType)	"Unaccepted Memory Type"c as *char
	else if(mem_type == EfiMaxMemoryType)			"Max Memory Type"c as *char
	else											"Unknown Memory Type"c as *char
