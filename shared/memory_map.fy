include "../fy-efi/src/memory.fy" // EFI_MEMORY_DESCRIPTOR

struct MemoryMap {
	descriptors: *EFI_MEMORY_DESCRIPTOR,
	full_size: uintn, // size of the buffer
	descriptor_size: uintn, // size of each descriptor
	page_count: uintn, // full amount of pages
}

fun(MemoryMap | *MemoryMap) get_descriptor(i: uintn)
	((this.descriptors as *uint8) + i * this.descriptor_size) as *EFI_MEMORY_DESCRIPTOR

fun(MemoryMap | *MemoryMap) descriptor_count()
	this.full_size / this.descriptor_size

fun page_count(descriptors: *EFI_MEMORY_DESCRIPTOR, full_size: uintn, descriptor_size: uintn): uintn {
	let total: uintn = 0
	const end = descriptors as *uint8 + full_size
	for(let iter: *uint8 = descriptors; iter < end; iter += descriptor_size) {
		const descriptor: *EFI_MEMORY_DESCRIPTOR = iter
		total += descriptor.NumberOfPages
	}
	total
}

fun(MemoryMap | *MemoryMap) largest_segment() {
	let largest_segment: *EFI_MEMORY_DESCRIPTOR
	let largest_size: uintn = 0
	const end = this.descriptors as *uint8 + this.full_size
	const desc_size = this.descriptor_size
	for(let iter: *uint8 = this.descriptors; iter < end; iter += desc_size) {
		const descriptor: *EFI_MEMORY_DESCRIPTOR = iter
		if(descriptor.Type == EfiConventionalMemory && descriptor.NumberOfPages > largest_size) {
			largest_size = descriptor.NumberOfPages
			largest_segment = descriptor
		}
	}
	create { descriptor: *EFI_MEMORY_DESCRIPTOR, size: uintn } {
		descriptor = largest_segment,
		size = largest_size
	}
}
