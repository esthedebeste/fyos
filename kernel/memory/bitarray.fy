struct BitArray {
	size: uintn,
	bits: *uint8,
}

fun(BitArray | *BitArray) get(index: uintn): bool
	this.bits[index / 8] & (0b10000000 >> (index % 8)) != 0

fun(*BitArray) set(index: uintn, value: bool)
	if(value) {
		// turn on bit
		this.bits[index / 8] |= 0b10000000 >> (index % 8)
	} else {
		// turn off bit
		this.bits[index / 8] &= ~(0b10000000 >> (index % 8))
	}
