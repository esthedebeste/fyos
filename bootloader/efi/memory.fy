include "./efi_globals"
include "./utils"

fun efi_malloc(size: uint_ptrsize): *uint8 {
	let pool: *uint8
	const status = boot_services.AllocatePool(EfiLoaderData, size, &pool)
	if(status != EFI_SUCCESS) null as *uint8
	else pool
}

fun efi_free(ptr: *uint8): EFI_STATUS
	boot_services.FreePool(ptr)

inline fun memcpy always_compile(true) (dst: *uint8, src: *uint8, size: uint_ptrsize): *uint8 {
	for(let i: uint_ptrsize = 0; i < size; i += 1)
		dst[i] = src[i]
	dst
}

fun efi_memcpy(dst: *uint8, src: *uint8, size: uint_ptrsize) memcpy(dst, src, size)

fun efi_memset(dst: *uint8, value: uint8, size: uint_ptrsize) {
	boot_services.SetMem(dst, size, value)
	dst
}

fun efi_calloc(amount: uint_ptrsize, size: uint_ptrsize): *uint8 {
	const total_size: uint_ptrsize = amount * size
	const pool: *uint8 = efi_malloc(total_size)
	if(pool == nullptr) pool
	else efi_memset(pool, 0, total_size)
}
