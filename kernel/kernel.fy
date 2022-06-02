include "../fy-efi/efi.fy"
include "../fy-efi/protocols/file-system"
include "./efi_globals"
include "./conin"
include "./conout"
include "./utils"

const SECONDS: UINTN = 1000000 // BootServices.Stall is in microseconds
const SHUTDOWN_DELAY: UINTN = 5 * SECONDS
fun shutdown(status: EFI_STATUS) {
	conout.print_string("Shutting down...\r\n"c 16)
	if(status != EFI_SUCCESS) {
		conout.print_string("Error: "c 16)
		conout.print_string(status_to_cstr(status))
		conout.print_string("\r\n"c 16)
	}
	boot_services.Stall(SHUTDOWN_DELAY)
	runtime_services.ResetSystem(EfiResetShutdown, status, 0, null)
	null
}

fun(*EFI_FILE_PROTOCOL) print_fs_info(): EFI_STATUS {
	// stack allocate 128 char16s for the volume label
	const infoptr: *EFI_FILE_SYSTEM_INFO = &(let info: { EFI_FILE_SYSTEM_INFO, CHAR16[128] })
	let size: UINTN = sizeof(EFI_FILE_SYSTEM_INFO) + sizeof(CHAR16) * 128
	const status = this.GetInfo(this, &EFI_FILE_SYSTEM_INFO_ID, &size, infoptr)
	if(status != EFI_SUCCESS) return status
	conout.print_string("File system name: '"c 16)
	conout.print_string(&infoptr.VolumeLabel)
	conout.print_string("'\r\n - Read Only: "c 16)
	conout.print_string(if(infoptr.ReadOnly) "True "c 16 else "False"c 16)
	conout.print_string("\r\n - Volume Size: "c 16)
	conout.print_uint64(infoptr.VolumeSize)
	conout.print_string("\r\n - Free space: "c 16)
	conout.print_uint64(infoptr.FreeSpace)
	conout.print_string("\r\n - Block Size: "c 16)
	conout.print_uint64(infoptr.BlockSize)
	conout.print_string("\r\n"c 16)
}

fun(*EFI_FILE_INFO) print() {
	conout.print_string("File name: '"c 16)
	conout.print_string(&this.FileName)
	conout.print_string("'\r\n - Size: "c 16)
	conout.print_uint64(this.FileSize)
	conout.print_string("\r\n - Create Time:       "c 16)
	conout.print_time(this.CreateTime)
	conout.print_string("\r\n - Last Access Time:  "c 16)
	conout.print_time(this.LastAccessTime)
	conout.print_string("\r\n - Modification Time: "c 16)
	conout.print_time(this.ModificationTime)
	if(this.Attribute != 0) {
		conout.print_string("\r\n - Attributes: "c 16)
		if(this.Attribute & EFI_FILE_READ_ONLY) conout.print_string("Read-Only "c 16)
		if(this.Attribute & EFI_FILE_HIDDEN) conout.print_string("Hidden "c 16)
		if(this.Attribute & EFI_FILE_SYSTEM) conout.print_string("System "c 16)
		if(this.Attribute & EFI_FILE_RESERVED) conout.print_string("Reserved "c 16)
		if(this.Attribute & EFI_FILE_DIRECTORY) conout.print_string("Directory "c 16)
		if(this.Attribute & EFI_FILE_ARCHIVE) conout.print_string("Archive "c 16)
	}
	conout.print_string("\r\n"c 16)
	null
}

fun print_all_files(dir: *EFI_FILE_PROTOCOL): EFI_STATUS {
    while (true) {
		const infoptr: *EFI_FILE_INFO = &(let info: { EFI_FILE_INFO, CHAR16[128] })
		let buf_size = sizeof(EFI_FILE_INFO) + sizeof(CHAR16) * 128
		const status = dir.Read(dir, &buf_size, infoptr)
		if(status != EFI_SUCCESS) return status
		if(buf_size == 0) return EFI_SUCCESS
		if(infoptr.FileName[0] == '.' && (infoptr.FileName[1] == 0 || (infoptr.FileName[1] == '.' && infoptr.FileName[2] == 0)))
			null // skip . and ..
		else {
			infoptr.print()
			if(infoptr.Attribute & EFI_FILE_DIRECTORY) {
				let subdir: *EFI_FILE_PROTOCOL
				const status = dir.Open(dir, &subdir, &infoptr.FileName, EFI_FILE_MODE_READ, 0)
				if(status != EFI_SUCCESS) return status
				const status = print_all_files(subdir)
				subdir.Close(subdir)
				if(status != EFI_SUCCESS) return status
			}
			null
		}
    }
	null
}

fun main cc(EFIAPI) (ih: EFI_HANDLE, st: *EFI_SYSTEM_TABLE): EFI_STATUS {
	init_efi_globals(ih, st)
	conout.clear_screen()
	let handles: *EFI_HANDLE = null;
	let handleCount: UINTN = 0;
	const status = boot_services.LocateHandleBuffer(ByProtocol, &EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID, null, &handleCount, &handles)
	if(status != EFI_SUCCESS) {
		conout.print_string("Failed to locate file system handles\r\n"c 16)
		shutdown(status)
	}
	for(let i: UINTN = 0; i < handleCount; i += 1) {
		let fs: *EFI_SIMPLE_FILE_SYSTEM_PROTOCOL = null
		const status = boot_services.HandleProtocol(handles[i], &EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID, &fs)
		if(status != EFI_SUCCESS) {
			conout.print_string("Failed to get file system protocol\r\n"c 16)
			shutdown(status)
		}
		let root: *EFI_FILE_PROTOCOL = null
		const status = fs.OpenVolume(fs, &root)
		if(status != EFI_SUCCESS) {
			conout.print_string("Failed to open volume\r\n"c 16)
			shutdown(status)
		}
		const status = root.print_fs_info()
		if(status != EFI_SUCCESS) {
			conout.print_string("Failed to get file system info\r\n"c 16)
			shutdown(status)
		}
		conout.print_string("Select this drive? (y/n) "c 16)
		const read = conin.readline()
		if(read.status != EFI_SUCCESS) {
			conout.print_string("Failed to read input\r\n"c 16)
			shutdown(read.status)
		}
		if(read.length > 0 && read.string[0] == 'y') {
			const status = print_all_files(root)
			if(status != EFI_SUCCESS) {
				conout.print_string("Failed to list files\r\n"c 16)
				shutdown(status)
			}
			const status = print_all_files(root)
			if(status != EFI_SUCCESS) {
				conout.print_string("Failed to print files\r\n"c 16)
				shutdown(status)
			}
			let file: *EFI_FILE_PROTOCOL
			const status = root.Open(root, &file, "hello.txt"c 16, EFI_FILE_MODE_CREATE | EFI_FILE_MODE_READ | EFI_FILE_MODE_WRITE, 0)
			if(status != EFI_SUCCESS) {
				conout.print_string("Failed to open hello.txt\r\n"c 16)
				shutdown(status)
			}
			conout.print_string("Successfully opened hello.txt, what should be written?\r\n> "c 16)
			const read = conin.readline()
			if(read.status != EFI_SUCCESS) {
				conout.print_string("Failed to read input\r\n"c 16)
				shutdown(read.status)
			}
			let length = read.length
			const utf8: *CHAR8 = malloc(sizeof(CHAR8) * read.length)
			for(let i: UINTN = 0; i < read.length; i += 1)
				utf8[i] = (read.string[i] as CHAR8) // trim characters (UTF-16 to ASCII conversion, assume that non-ascii chars won't be entered)
			const status = file.Write(file, &length, utf8)
			if(status != EFI_SUCCESS) {
				conout.print_string("Failed to write to hello.txt\r\n"c 16)
				shutdown(status)
			}
			conout.print_string("Successfully wrote "c 16)
			conout.print_uint64(read.length)
			conout.print_string(" bytes to hello.txt\r\n"c 16)
			file.Close(file)
			root.Close(root)
		}
	}
	conout.print_string("Exiting...\r\n"c 16)
	boot_services.Stall(SHUTDOWN_DELAY)
	EFI_SUCCESS
}

fun __chkstk always_compile(true)() null
