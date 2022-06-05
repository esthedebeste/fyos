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
