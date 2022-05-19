include "../fy-efi/efi.fy"

let image_handle: EFI_HANDLE
let system_table: *EFI_SYSTEM_TABLE
let conin: *EFI_SIMPLE_TEXT_INPUT_PROTOCOL
let conout: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL
let stderr: *EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL
let runtime_services: *EFI_RUNTIME_SERVICES
let boot_services: *EFI_BOOT_SERVICES
fun init_efi_globals(ih: EFI_HANDLE, st: *EFI_SYSTEM_TABLE) {
	image_handle = ih
	system_table = st
	conin = st.ConIn
	conout = st.ConOut
	stderr = st.StdErr
	runtime_services = st.RuntimeServices
	boot_services = st.BootServices
	null
}

fun shutdown(status: EFI_STATUS) runtime_services.ResetSystem(EfiResetShutdown, EFI_SUCCESS, 0, null)

const SECONDS = 1000000 // BootServices.Stall is in microseconds
fun main cc(EFIAPI) (ih: EFI_HANDLE, st: *EFI_SYSTEM_TABLE): EFI_STATUS {
	init_efi_globals(ih, st)
    conout.OutputString(conout, "Hello World!\r\n"c 16)
    conout.OutputString(conout, "Stalling for 10 seconds...\r\n"c 16)
	boot_services.Stall(SECONDS * 10)
	conout.OutputString(conout, "Bye!\r\n"c 16)
	boot_services.Stall(SECONDS * 2)
	shutdown(EFI_SUCCESS)
    EFI_SUCCESS
}
