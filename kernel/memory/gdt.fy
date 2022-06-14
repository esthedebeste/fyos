struct GDTDescriptor {
	size: uint16,
	base: uintn,
}

struct GDTEntry {
	limit: uint16,
	base0: uint16,
	base1: uint8,
	access: uint8,
	limit_flags: uint8,
	base2: uint8,
}

struct GDT {
	kernel_null: GDTEntry, // 0x00
	kernel_code: GDTEntry, // 0x08
	kernel_data: GDTEntry, // 0x10
	user_null: GDTEntry, // 0x18
	user_code: GDTEntry, // 0x20
	user_data: GDTEntry, // 0x28
}

const default_gdt = create GDT {
	kernel_null = null,
	kernel_code = create GDTEntry {
		access = 0b10011010,
		limit_flags = 0b10100000,
	},
	kernel_data = create GDTEntry {
		access = 0b10010010,
		limit_flags = 0b10100000,
	},
	user_null = null,
	user_code = create GDTEntry {
		access = 0b10011010,
		limit_flags = 0b10100000,
	},
	user_data = create GDTEntry {
		access = 0b10010010,
		limit_flags = 0b10100000,
	},
}

fun(*GDT) load() {
	let descriptor = create GDTDescriptor {
		size = sizeof(GDT) - 1,
		base = this,
	}
	__asm__("lgdt (%rdi)")(rdi = &descriptor)
	__asm__("mov $$0x10, %ax")() // kernel data segment
	__asm__("mov %ax, %ds")()
	__asm__("mov %ax, %es")()
	__asm__("mov %ax, %fs")()
	__asm__("mov %ax, %gs")()
	__asm__("mov %ax, %ss")()
	__asm__("pushq $$0x08
			leaq   1f(%rip), %rax
			pushq  %rax
			lretq
			1:")() // jump to next instruction, and set cs to 0x08 (kernel code segment)
	const cs = __asm__ uint16("mov %cs, %ax" => ax)()
	display.print("CS: "p) display.print_uint64(cs) display.print(" = "p) display.print_hex(cs) display.newline()
	const cr0 = __asm__ uint64("mov %cr0, %rax" => rax)()
	__asm__("mov %rax, %cr0")(rax = cr0 | 1)
	null
}
