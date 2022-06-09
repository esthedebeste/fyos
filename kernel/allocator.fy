include "./memory"
include "./bitarray"
include "./utils"

const PAGE_SIZE = 4096
struct Allocator {
	memmap: MemoryMap,
	bitmap: BitArray,
	free_count: uintn, // amount of free pages
	used_count: uintn, // amount of used pages
	reserved_count: uintn, // amount of reserved (unusable) pages
	total_count: uintn, // amount of total pages
}

fun Allocator(memmap: MemoryMap): Allocator {
	const bitmap_size = (memmap.page_count + 7) / 8
	const bitmap_page_size = (bitmap_size + PAGE_SIZE - 1) / PAGE_SIZE
	const memmap_end = memmap.descriptors as *uint8 + memmap.full_size
	let bitmap_loc: *uint8
	let found = false
	for(let iter: *uint8 = memmap.descriptors; iter < memmap_end; iter += memmap.descriptor_size) {
		const descriptor: *EFI_MEMORY_DESCRIPTOR = iter
		if(descriptor.Type == EfiConventionalMemory && descriptor.NumberOfPages >= bitmap_page_size) {
			bitmap_loc = descriptor.PhysicalStart
			found = true
			break
		}
	}
	if(!found) {
		display.print("Could not find a large enough region to put the allocator bitmap.")
		return null
	}

	display.print("Putting allocator bitmap at ") display.print_hex(bitmap_loc) display.print(" - ") display.print_hex(bitmap_loc + bitmap_page_size * PAGE_SIZE) display.print("\n")

	const bitmap = create BitArray {
		size = bitmap_size,
		bits = bitmap_loc,
	}
	memset(bitmap_loc, 0, bitmap_size)

	let allocator = create Allocator {
		memmap = memmap,
		bitmap = bitmap,
		free_count = memmap.page_count,
		reserved_count = 0,
		used_count = 0,
		total_count = memmap.page_count,
	}

	allocator.use_pages(bitmap_loc, bitmap_page_size)

	for(let iter: *uint8 = memmap.descriptors; iter < memmap_end; iter += memmap.descriptor_size) {
		const descriptor: *EFI_MEMORY_DESCRIPTOR = iter
		if(descriptor.Type != EfiConventionalMemory)
			allocator.reserve_pages(descriptor.PhysicalStart, descriptor.NumberOfPages)
	}
	allocator
}


fun(*Allocator) request_page(): *uint8 {
	const FREE = false
	for(let page: uintn = 0; page < this.total_count; page += 1) {
		if(this.bitmap.get(page) == FREE) {
			this.use_page(page)
			return (page * PAGE_SIZE) as *uint8
		}
	}
}

fun(*Allocator) request_pages(count: uintn): *uint8 {
	const FREE = false
	const USED = true
	for(let i: uintn = 0; i < this.total_count; i += 1) {
		const from = i
		const to = i + count
		let free = true
		for(0; i < to; i += 1) {
			if(this.bitmap.get(i) == USED) {
				free = false
				break
			}
		}
		if(free) {
			this.use_pages(from, count)
			return (from * PAGE_SIZE) as *uint8
		}
	}
	null // didn't find enough sequential free pages
}


fun(*Allocator) free_page(address: *uint8) {
	const index = address / PAGE_SIZE
	this.bitmap.set(index, false)
	this.free_count += 1
	this.used_count -= 1
	null
}

fun(*Allocator) free_pages(address: *uint8, count: uintn) {
	const page = address / PAGE_SIZE
	for (let i: uintn = 0; i < count; i += 1)
		this.bitmap.set(page + i, false)
	this.used_count -= count
	this.free_count += count
	null
}

fun(*Allocator) use_page(address: uintn) {
	const index = address / PAGE_SIZE
	this.bitmap.set(index, true)
	this.used_count += 1
	this.free_count -= 1
	null
}

fun(*Allocator) use_pages(address: uintn, count: uintn) {
	const page = address / PAGE_SIZE
	for (let i: uintn = 0; i < count; i += 1)
		this.bitmap.set(page + i, true)
	this.used_count += count
	this.free_count -= count
	null
}

fun(*Allocator) reserve_page(address: uintn) {
	const index = address / PAGE_SIZE
	this.bitmap.set(index, true)
	this.reserved_count += 1
	this.free_count -= 1
	null
}

fun(*Allocator) reserve_pages(address: uintn, count: uintn) {
	const page = address / PAGE_SIZE
	for (let i: uintn = 0; i < count; i += 1)
		this.bitmap.set(page + i, true)
	this.reserved_count += count
	this.free_count -= count
	null
}
