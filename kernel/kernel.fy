include "../fy-efi/efi.fy"
include "./efi_globals"
include "./conin"

const SECONDS: UINTN = 1000000 // BootServices.Stall is in microseconds
const SHUTDOWN_DELAY: UINTN = 5 * SECONDS
fun shutdown(status: EFI_STATUS) {
	conout.print_string("Shutting down...\r\n"c 16)
	boot_services.Stall(SHUTDOWN_DELAY)
	runtime_services.ResetSystem(EfiResetShutdown, status, 0, null)
	null
}

fun main cc(EFIAPI) (ih: EFI_HANDLE, st: *EFI_SYSTEM_TABLE): EFI_STATUS {
	init_efi_globals(ih, st)
	conout.print_string("Echo kernel, \"\\q\" to exit!\r\n"c 16)
	while(true) {
		const read = conin.readline()
		if(read.status != EFI_SUCCESS) {
			conout.print_string("Error reading input\r\n"c 16)
			shutdown(read.status)
			return read.status
		}
		if(read.length == 2 && read.string[0] == '\\' && read.string[1] == 'q') {
			shutdown(EFI_SUCCESS)
			return EFI_SUCCESS
		}
		conout.print_string(read.string)
		conout.print_string("\r\n"c 16)
		free(read.string)
	}
	shutdown(EFI_SUCCESS)
	EFI_SUCCESS
}

fun __chkstk always_compile(true)() null
