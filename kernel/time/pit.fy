include "../io.fy"

let boot_time: double = 0
let time_since_boot: double = 0
let pit_divisor: double = 65536
const base_freq: double = 1193182

fun sleep(seconds: double) {
	const start = time_since_boot
	while (time_since_boot - start < seconds)
		__asm__("hlt")() // wait for the next interrupt tick
	null
}

fun set_pit_divisor(new_divisor: uint16) {
	pit_divisor = new_divisor
	port_byte_out(0x40, new_divisor & 0xff) io_wait()
	port_byte_out(0x40, (new_divisor & 0xff00) >> 8) io_wait()
}

fun pit_tick() {
	time_since_boot += 1d / (base_freq / pit_divisor)
	null
}
