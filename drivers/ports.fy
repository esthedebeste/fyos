include "../util/types"

/** Read a byte from a port */
fun port_byte_in(port: uint16): uint8
    __asm__ uint8("in %dx, %al" => al)(dx = port)

/** Write a byte to a port */
fun port_byte_out(port: uint16, data: uint8): void
  __asm__("out %al, %dx")(al = data, dx = port)

/** Read a word from a port */
fun port_word_in(port: uint16): uint16
  __asm__ uint16("in %dx, %ax" => ax)(dx = port)

/** Write a word to a port */
fun port_word_out(port: uint16, data: uint16): void
  __asm__("out %ax, %dx")(ax = data, dx = port)