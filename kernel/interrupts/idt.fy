struct IDTDescriptorEntry {
	handler0: uint16,
	segment: uint16,
	ist: uint8,
	type_attr: uint8,
	handler1: uint16,
	handler2: uint32,
	unused: uint32,
}

fun(IDTDescriptorEntry | *IDTDescriptorEntry) get_handler()
	(this.handler0 as uint64) | (this.handler1 as uint64 << 16) | (this.handler2 as uint64 << 32)

fun(*IDTDescriptorEntry) set_handler(handler: *fun cc(X86INTR)(frame: *interrupt_frame): typeof(null)) {
	const hand = handler as uint64
	this.handler0 = hand & 0xFFFF
	this.handler1 = (hand >> 16) & 0xFFFF
	this.handler2 = (hand >> 32) & 0xFFFFFFFF
}

struct IDTR {
	limit: uint16,
	base: *IDTDescriptorEntry,
}

const IDT_InterruptGate = 0b10001110 as uint8
const IDT_CallGate 		= 0b10001100 as uint8
const IDT_TrapGate 		= 0b10001111 as uint8
