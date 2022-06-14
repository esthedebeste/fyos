struct interrupt_frame {}


fun zerodiv_handler cc(X86INTR) (frame: *interrupt_frame) {
	display.print("Zero division :("p)
	while (1) 0
	null
}

fun pagefault_handler cc(X86INTR) (frame: *interrupt_frame) {
	display.print("Page fault :("p)
	while (1) 0
	null
}

fun doublefault_handler cc(X86INTR) (frame: *interrupt_frame) {
	display.print("Double fault detected :("p)
	while (1) 0
	null
}

fun gpfault_handler cc(X86INTR) (frame: *interrupt_frame) {
	display.print("General protection fault :("p)
	while (1) 0
	null
}

fun pit_handler cc(X86INTR) (frame: *interrupt_frame) {
	pit_tick()
	pic_eoi(0x20)
	null
}

const PIC_EOI = 0x20
fun pic_eoi(source: uint8) {
	if(source >= 40)  port_byte_out(PIC2_COMMAND_PORT, PIC_EOI)
	port_byte_out(PIC1_COMMAND_PORT, PIC_EOI)
}


const PIC1_COMMAND_PORT = 0x20
const PIC1_DATA_PORT = 0x21
const PIC2_COMMAND_PORT = 0xA0
const PIC2_DATA_PORT = 0xA1
fun remap_pic() {
	const ICW1_ICW4 = 0x01
	const ICW1_INIT = 0x10
	const ICW4_8086 = 0x01

	const a1: uint8 = port_byte_in(PIC1_DATA_PORT) io_wait()
	const a2: uint8 = port_byte_in(PIC2_DATA_PORT) io_wait()

	port_byte_out(PIC1_COMMAND_PORT, ICW1_INIT | ICW1_ICW4) io_wait()
	port_byte_out(PIC2_COMMAND_PORT, ICW1_INIT | ICW1_ICW4) io_wait()

	port_byte_out(PIC1_DATA_PORT, 0x20) io_wait()
	port_byte_out(PIC2_DATA_PORT, 0x28) io_wait()

	port_byte_out(PIC1_DATA_PORT, 4) io_wait()
	port_byte_out(PIC2_DATA_PORT, 2) io_wait()

	port_byte_out(PIC1_DATA_PORT, ICW4_8086) io_wait()
	port_byte_out(PIC2_DATA_PORT, ICW4_8086) io_wait()

	port_byte_out(PIC1_DATA_PORT, a1) io_wait()
	port_byte_out(PIC2_DATA_PORT, a2) io_wait()
}
