inline fun memcpy always_compile(true) (to: *uint8, from: *uint8, len: uintn) {
	for(let i: uintn = 0; i < len; i += 1)
		to[i] = from[i]
	to
}

inline fun memset always_compile(true) (to: *uint8, intval: int, len: uintn) {
	const val: uint8 = intval
	for(let i: uintn = 0; i < len; i += 1)
		to[i] = val
	to
}
