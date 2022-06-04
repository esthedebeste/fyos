include "./utils"

struct EfiResult<Ret> {
	status: EFI_STATUS,
	value: Ret,
}

inline fun EfiResult(status: EFI_STATUS, value: generic Ret)
	create EfiResult<Ret> { status = status, value = value }

fun(EfiResult<generic Ret>) unwrap(or_print: *CHAR16) {
	if(this.status != EFI_SUCCESS) {
		conout.println(or_print)
		shutdown(this.status)
		// shutdown stops execution here if status is not EFI_SUCCESS
	}
	this.value
}

inline fun(EfiResult<generic Ret>) failed() this.status != EFI_SUCCESS
