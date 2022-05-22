include "./efi_globals"
include "./memory"
include "./conout"

fun(*EFI_SIMPLE_TEXT_INPUT_PROTOCOL) wait_for_key(): { status: EFI_STATUS, key: EFI_INPUT_KEY } {
	let idx: UINTN // unused
	let status: EFI_STATUS = EFI_NOT_READY
	let key: EFI_INPUT_KEY
	while (status == EFI_NOT_READY) {
		while (status == EFI_NOT_READY)
			status = boot_services.WaitForEvent(1, &this.WaitForKey, &idx)
		if(status != EFI_SUCCESS) return (status, null as EFI_INPUT_KEY)
		status = this.ReadKeyStroke(this, &key)
	}
	return (status, key)
}

fun(*EFI_SIMPLE_TEXT_INPUT_PROTOCOL) readline(): { status: EFI_STATUS, string: *CHAR16, length: UINTN } {
	let string: *CHAR16 = calloc(1024, sizeof(CHAR16))
	let capacity: uint_ptrsize = 1024
	let length: uint_ptrsize = 0
	let char_str: CHAR16[2] = null
	while(true) {
		const key_status = this.wait_for_key()
		const status = key_status.status
		if(status != EFI_SUCCESS) return (status, null as *CHAR16, null as UINTN)
		const key = key_status.key
		if(length >= capacity) {
			capacity *= 2
			string = reallocarray(string, capacity, sizeof(CHAR16))
		}
		if(key.UnicodeChar == '\n' || key.UnicodeChar == '\r') {
			conout.print_string("\r\n"c 16)
			return (EFI_SUCCESS, string, length) 0
		} else if(key.UnicodeChar == '\x08') {
			// backspace character
			if(length > 0) {
				length -= 1
				// move cursor back one character and overwrite with space
				conout.print_string("\x08 \x08"c 16)
			} 0
		} else {
			string[length] = key.UnicodeChar
			length += 1
			char_str[0] = key.UnicodeChar
			conout.print_string(&char_str) 0
		}
	}
	null // unreachable
}
