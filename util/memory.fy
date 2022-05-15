include "./types.fy"
fun memcpy(src: *byte, dst: *byte, n: uint): void {
    for(let i = 0; i < n; i += 1)
        dst[i] = src[i]
    null
}
inline fun mem_copy(src: *generic T, dst: *T, n: uint): void
	memcpy(src, dst, n * sizeof(T))

fun memset(dst: *byte, c: byte, n: uint): void {
	for(let i = 0; i < n; i += 1)
		dst[i] = c
	null
}