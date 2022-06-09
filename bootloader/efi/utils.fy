include "../../fy-efi/efi" // char16, efi_time, efi_simple_text_output_protocol, efi_status
const nullptr = null as *uint8

const SECONDS: uintn = 1000000 // BootServices.Stall is in microseconds
const SHUTDOWN_DELAY: uintn = 5 * SECONDS

fun shutdown(status: EFI_STATUS) {
	if(status != EFI_SUCCESS) {
		print("Error: "c 16)
		println(status_to_cstr(status))
		while(true) 0 // halt
	}
	let time: EFI_TIME
	runtime_services.GetTime(&time, null)
	let target = time
	target.Second += 10
	while(time.Second < target.Second)
		runtime_services.GetTime(&time, null)

	runtime_services.ResetSystem(EfiResetShutdown, status, 0, null)
}

fun uint64tohex(num: uint64): CHAR16[19] {
	let n: uint64 = num
	let str: CHAR16[19]
	str[0] = ("0" 16)[0]
	str[1] = ("x" 16)[0]
	str[18] = 0
	for (let i = 0; i < 16; i += 1) {
		const c = (n & 0xf) + '0'
		str[17 - i] = if (c > '9') c - '9' + 'a' - 1 else c
		n = n >> 4
	}
	str
}
fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) print_hex(num: uint64) {
	let str = uint64tohex(num)
	this.print(&str)
}
fun print_hex(num: uint64) conout.print_hex(num)
// '0'-padded at the start
fun uint64tostr(num: uint64): CHAR16[21] {
	let n: uint64 = num
	let str: CHAR16[21]
	str[20] = 0
	for(let i = 0; i < 20; i += 1) {
		str[19 - i] = (n % 10) + 0x30
		n = n / 10
	}
	str
}
fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) print_uint64(num: uint64) {
	let str = uint64tostr(num)
	let strptr: *CHAR16 = &str
	// remove '0'-padding
	while(strptr[0] == '0') strptr += 1
	if(strptr[0] == 0) strptr = "0"c 16
	this.print(strptr)
}
fun print_uint64(num: uint64) conout.print_uint64(num)

// DD-MM-YYYY HH:MM:SS.mmm
fun time_to_str(time: EFI_TIME): CHAR16[24] {
	const y = uint64tostr(time.Year)
	const m = uint64tostr(time.Month)
	const d = uint64tostr(time.Day)
	const h = uint64tostr(time.Hour)
	const min = uint64tostr(time.Minute)
	const s = uint64tostr(time.Second)
	const ms = uint64tostr(time.Nanosecond / 1000000)
	return (
		d[18], d[19],				// DD
		("-" 16)[0],				// -
		m[18], m[19],				// MM
		("-" 16)[0],				// -
		y[16], y[17], y[18], y[19]	// YYYY
		(" " 16)[0],				// -
		h[18], h[19],				// HH
		(":" 16)[0],				// :
		min[18], min[19],			// MM
		(":" 16)[0],				// :
		s[18], s[19],				// SS
		("." 16)[0],				// .
		ms[17], ms[18], ms[19],		// mmm
		0 // null-terminator
	)
}
fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) print_time(time: EFI_TIME) {
	let str = time_to_str(time)
	this.print(&str)
}
fun print_time(time: EFI_TIME) conout.print_time(time)
fun newline() conout.newline()

fun print(v: uint64 | *CHAR16 | *CHAR16[generic Len] | EFI_TIME)
		 if(typeof(v) == uint64)				conout.print_uint64(v)
	else if(typeof(v) == *CHAR16)				conout.print(v)
	else if(typeof(v) == *CHAR16[generic Len])	conout.print(v)
	else if(typeof(v) == EFI_TIME)				conout.print_time(v)

fun println(v: generic V) {
	print(v)
	newline()
}

// From table D-3 in the UEFI 2.9 spec
fun status_to_cstr(status: EFI_STATUS): *CHAR16
		 if(status == EFI_SUCCESS) 				"SUCCESS: The operation completed successfully."c 16 as *CHAR16
	else if(status == EFI_LOAD_ERROR) 			"LOAD_ERROR: The image failed to load."c 16 as *CHAR16
	else if(status == EFI_INVALID_PARAMETER)	"INVALID_PARAMETER: A parameter was incorrect."c 16 as *CHAR16
	else if(status == EFI_UNSUPPORTED) 			"UNSUPPORTED: The operation is not supported."c 16 as *CHAR16
	else if(status == EFI_BAD_BUFFER_SIZE) 		"BAD_BUFFER_SIZE: The buffer was not the proper size for the request."c 16 as *CHAR16
	else if(status == EFI_BUFFER_TOO_SMALL) 	"BUFFER_TOO_SMALL: The buffer is not large enough to hold the requested data."c 16 as *CHAR16
	else if(status == EFI_NOT_READY) 			"NOT_READY: There is no data pending upon return."c 16 as *CHAR16
	else if(status == EFI_DEVICE_ERROR) 		"DEVICE_ERROR: The physical device reported an error while attempting the operation."c 16 as *CHAR16
	else if(status == EFI_WRITE_PROTECTED) 		"WRITE_PROTECTED: The device cannot be written to."c 16 as *CHAR16
	else if(status == EFI_OUT_OF_RESOURCES) 	"OUT_OF_RESOURCES: A resource has run out."c 16 as *CHAR16
	else if(status == EFI_VOLUME_CORRUPTED) 	"VOLUME_CORRUPTED: An inconstency was detected on the file system causing the operating to fail."c 16 as *CHAR16
	else if(status == EFI_VOLUME_FULL) 			"VOLUME_FULL: There is no more space on the file system."c 16 as *CHAR16
	else if(status == EFI_NO_MEDIA) 			"NO_MEDIA: The device does not contain any medium to perform the operation."c 16 as *CHAR16
	else if(status == EFI_MEDIA_CHANGED) 		"MEDIA_CHANGED: The medium in the device has changed since the last access."c 16 as *CHAR16
	else if(status == EFI_NOT_FOUND) 			"NOT_FOUND: The item was not found."c 16 as *CHAR16
	else if(status == EFI_ACCESS_DENIED) 		"ACCESS_DENIED: Access was denied."c 16 as *CHAR16
	else if(status == EFI_NO_RESPONSE) 			"NO_RESPONSE: The server was not found or did not respond to the request."c 16 as *CHAR16
	else if(status == EFI_NO_MAPPING) 			"NO_MAPPING: A mapping to a device does not exist."c 16 as *CHAR16
	else if(status == EFI_TIMEOUT) 				"TIMEOUT: The timeout time expired."c 16 as *CHAR16
	else if(status == EFI_NOT_STARTED) 			"NOT_STARTED: The protocol has not been started."c 16 as *CHAR16
	else if(status == EFI_ALREADY_STARTED) 		"ALREADY_STARTED: The protocol has already been started."c 16 as *CHAR16
	else if(status == EFI_ABORTED) 				"ABORTED: The operation was aborted."c 16 as *CHAR16
	else if(status == EFI_ICMP_ERROR) 			"ICMP_ERROR: An ICMP error occurred during the network operation."c 16 as *CHAR16
	else if(status == EFI_TFTP_ERROR) 			"TFTP_ERROR: A TFTP error occurred during the network operation."c 16 as *CHAR16
	else if(status == EFI_PROTOCOL_ERROR) 		"PROTOCOL_ERROR: A protocol error occurred during the network operation."c 16 as *CHAR16
	else if(status == EFI_INCOMPATIBLE_VERSION)	"INCOMPATIBLE_VERSION: The function encountered an internal version that was incompatible with a version requested by the caller."c 16 as *CHAR16
	else if(status == EFI_SECURITY_VIOLATION) 	"SECURITY_VIOLATION: The function was not performed due to a security violation."c 16 as *CHAR16
	else if(status == EFI_CRC_ERROR) 			"CRC_ERROR: A CRC error was detected."c 16 as *CHAR16
	else if(status == EFI_END_OF_MEDIA) 		"END_OF_MEDIA: Beginning or end of media was reached"c 16 as *CHAR16
	else if(status == EFI_END_OF_FILE) 			"END_OF_FILE: The end of the file was reached."c 16 as *CHAR16
	else if(status == EFI_INVALID_LANGUAGE) 	"INVALID_LANGUAGE: The language specified was invalid."c 16 as *CHAR16
	else if(status == EFI_COMPROMISED_DATA) 	"COMPROMISED_DATA: The security status of the data is unknown or compromised and the data must be updated or replaced to restore a valid security status."c 16 as *CHAR16
	else if(status == EFI_IP_ADDRESS_CONFLICT) 	"IP_ADDRESS_CONFLICT: There is an address conflict address allocation"c 16 as *CHAR16
	else if(status == EFI_HTTP_ERROR) 			"HTTP_ERROR: A HTTP error occurred during the network operation."c 16 as *CHAR16
	else "Unknown Error"c 16 as *CHAR16
