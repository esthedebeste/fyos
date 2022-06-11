struct PageDirectoryEntry {
	content: uint64,
}

const PDE_FLAG_PRESENT:			uint64 = 0b1
const PDE_FLAG_RW:				uint64 = 0b10
const PDE_FLAG_USER:			uint64 = 0b100
const PDE_FLAG_WRITETHROUGH:	uint64 = 0b1000
const PDE_FLAG_CACHE_DISABLE:	uint64 = 0b10000
const PDE_FLAG_ACCESSED:		uint64 = 0b100000
const PDE_FLAG_LARGER_PAGES:	uint64 = 0b10000000
const PDE_FLAG_CUSTOM_1:		uint64 = 0b1000000000
const PDE_FLAG_CUSTOM_2:		uint64 = 0b10000000000
const PDE_FLAG_CUSTOM_3:		uint64 = 0b100000000000
const PDE_FLAG_NX:				uint64 = 1 as uint64 << 63

fun(PageDirectoryEntry | *PageDirectoryEntry) get_bitflag(flag: uint64)
	(this.content & flag) != 0

fun(*PageDirectoryEntry) set_bitflag(flag: uint64, value: bool)
	if(value) this.content |= flag
	else this.content &= ~flag

fun(PageDirectoryEntry | *PageDirectoryEntry) get_address()
	this.content & 0x000ffffffffff000l

fun(*PageDirectoryEntry) set_address(value: uint64)
	this.content = (this.content & 0xfff0000000000fffl) | (value & 0x000ffffffffff000l)

struct PageTable {
	entries: PageDirectoryEntry[512],
}

struct PageMapIndex {
	pdp_index:  uint64,
	pd_index:   uint64,
	pt_index:   uint64,
	page_index: uint64,
}

fun PageMapIndex(vaddr: uint64) {
	let vad = vaddr >> 12
	let page_index = vad & 0x1ff
	vad = vad >> 9
	let pt_index = vad & 0x1ff
	vad = vad >> 9
	let pd_index = vad & 0x1ff
	vad = vad >> 9
	let pdp_index = vad & 0x1ff
	create PageMapIndex {
		page_index = page_index,
		pt_index = pt_index,
		pd_index = pd_index,
		pdp_index = pdp_index,
	}
}

struct PageTableManager {
	pml4: *PageTable,
}

fun PageTableManager(pml4: *PageTable)
	create PageTableManager { pml4 = pml4 }

fun(PageTableManager | *PageTableManager) apply() {
	__asm__ uint64("mov %rdx, %cr3" => cr3)(rdx = this.pml4)
	const cr0 = __asm__ uint64("mov %cr0, %rax" => rax)() | 0x80000000l // Enable paging bit in CR0
	__asm__ uint64("mov %rax, %cr0" => cr0)(rax = cr0)
	null
}

fun(*PageTableManager) map_memory(virtual: *uint8, physical: *uint8) {
	const index = PageMapIndex(virtual as uint64)

	const pde = &this.pml4.entries[index.pdp_index]
	const pdp: *PageTable = if(!pde.get_bitflag(PDE_FLAG_PRESENT)) {
		const prev = allocator.used_count
		const page = allocator.request_zerod_page()
		pde.set_address(page)
		pde.set_bitflag(PDE_FLAG_PRESENT, true)
		pde.set_bitflag(PDE_FLAG_RW, true)
		page as *PageTable
	} else (pde.get_address() as uintn << 12) as *PageTable


	const pde = &pdp.entries[index.pd_index]
	const pd: *PageTable = if(!pde.get_bitflag(PDE_FLAG_PRESENT)) {
		const prev = allocator.used_count
		const page = allocator.request_zerod_page()
		pde.set_address(page)
		pde.set_bitflag(PDE_FLAG_PRESENT, true)
		pde.set_bitflag(PDE_FLAG_RW, true)
		page as *PageTable
	} else (pde.get_address() as uintn << 12) as *PageTable

	const pde = &pd.entries[index.pt_index]
	const pt: *PageTable = if(!pde.get_bitflag(PDE_FLAG_PRESENT)) {
		const prev = allocator.used_count
		const page = allocator.request_zerod_page()
		pde.set_address(page)
		pde.set_bitflag(PDE_FLAG_PRESENT, true)
		pde.set_bitflag(PDE_FLAG_RW, true)
		page as *PageTable
	} else (pde.get_address() as uintn << 12) as *PageTable

	const pde = &pt.entries[index.page_index]
	pde.set_address(physical)
	pde.set_bitflag(PDE_FLAG_PRESENT, true)
	pde.set_bitflag(PDE_FLAG_RW, true)

	null
}
