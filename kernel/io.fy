/** Read a byte from a port */
fun port_byte_in(port: uint16): uint8
    __asm__ uint8("inb %dx, %al" => al)(dx = port)

/** Write a byte to a port */
fun port_byte_out(port: uint16, data: uint8)
  __asm__("outb %al, %dx")(al = data, dx = port)

/** Read a word from a port */
fun port_word_in(port: uint16): uint16
  __asm__ uint16("inw %dx, %ax" => ax)(dx = port)

/** Write a word to a port */
fun port_word_out(port: uint16, data: uint16)
  __asm__("outw %ax, %dx")(ax = data, dx = port)

fun io_wait() port_byte_out(0x80, 0x00)
