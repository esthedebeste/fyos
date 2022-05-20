include "./efi_globals"
include "./utils"

// pools are stored in memory as { size: uint_ptrsize, data: uint_ptrsize[generic length] }, a pointer to data is returned from malloc and calloc.
fun alloc_size(pool: *uint8): uint_ptrsize
	*((pool - sizeof(*uint_ptrsize)) as *uint_ptrsize) // go sizeof(uint_ptrsize) to the left of the pointer to get the size

fun malloc(size: uint_ptrsize): *uint8 {
	let pool: *uint8
	const status = boot_services.AllocatePool(EfiLoaderData, sizeof(uint_ptrsize) + size, &pool)
	if(status != EFI_SUCCESS) null as *uint8
	else {
		(pool as *uint_ptrsize)[0] = size // store size
		pool + sizeof(uint_ptrsize) // return pointer to data
	}
}

fun free(ptr: *uint8): EFI_STATUS
	boot_services.FreePool(ptr - sizeof(uint_ptrsize)) // go sizeof(uint_ptrsize) to the left of the pointer to get the start of the pool

fun memcpy(dst: *uint8, src: *uint8, size: uint_ptrsize) {
	CopyMem(dst, src, size)
	dst
}

fun memset(dst: *uint8, value: uint8, size: uint_ptrsize) {
	SetMem(dst, size, value)
	dst
}

fun calloc(amount: uint_ptrsize, size: uint_ptrsize): *uint8 {
	const total_size: uint_ptrsize = amount * size
	const pool: *uint8 = malloc(total_size)
	if(pool == nullptr) pool
	else memset(pool, 0, total_size)
}

fun realloc(ptr: *uint8, size: uint_ptrsize): *uint8 {
	const old_size: uint_ptrsize = alloc_size(ptr)
	const new_pool: *uint8 = malloc(size)
	if(new_pool == nullptr) new_pool
	else {
		memcpy(new_pool, ptr, if(old_size < size) old_size else size)
		free(ptr)
		new_pool
	}
}

fun reallocarray(ptr: *uint8, amount: uint_ptrsize, size: uint_ptrsize): *uint8 {
	const old_size: uint_ptrsize = alloc_size(ptr)
	const total_size: uint_ptrsize = amount * size
	const new_pool: *uint8 = malloc(total_size)
	if(new_pool == nullptr) new_pool
	else {
		memcpy(new_pool, ptr, if(total_size < old_size) total_size else old_size)
		free(ptr)
		memset(new_pool + old_size, 0, total_size - old_size)
		new_pool
	}
}
