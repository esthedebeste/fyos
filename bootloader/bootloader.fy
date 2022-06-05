include "../fy-efi/efi.fy"
include "../fy-efi/protocols/file-system"
include "../fy-efi/protocols/loaded-image"
include "../fy-efi/protocols/graphics"
include "./efi/result"
include "./efi/efi_globals"
include "./efi/conin"
include "./efi/conout"
include "./efi/utils"

fun loaded_image_protocol(): EfiResult<*EFI_LOADED_IMAGE_PROTOCOL> {
	let loaded_image: *EFI_LOADED_IMAGE_PROTOCOL
	const status = boot_services.HandleProtocol(image_handle, &EFI_LOADED_IMAGE_PROTOCOL_GUID, &loaded_image)
	EfiResult(status, loaded_image)
}

fun load_root_image_dir(loaded_image: *EFI_LOADED_IMAGE_PROTOCOL): EfiResult<*EFI_FILE_PROTOCOL> {
	let file_system: *EFI_SIMPLE_FILE_SYSTEM_PROTOCOL
	const status = boot_services.HandleProtocol(loaded_image.DeviceHandle, &EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID, &file_system)
	if(status != EFI_SUCCESS)
		return create EfiResult<*EFI_FILE_PROTOCOL> { status = status }
	let root: *EFI_FILE_PROTOCOL
	const status = file_system.OpenVolume(file_system, &root)
	EfiResult(status, root)
}

inline fun(*EFI_FILE_PROTOCOL) open(path: *CHAR16): EfiResult<*EFI_FILE_PROTOCOL> {
	let file: *EFI_FILE_PROTOCOL
	const status = this.Open(this, &file, path, EFI_FILE_MODE_READ, EFI_FILE_READ_ONLY)
	EfiResult(status, file)
}

// remember to efi_free the result
fun(*EFI_FILE_PROTOCOL) get_info(): EfiResult<*EFI_FILE_INFO> {
	let info_size: UINTN
	this.GetInfo(this, &EFI_FILE_INFO_ID, &info_size, nullptr)
	const file_info: *EFI_FILE_INFO = efi_malloc(info_size)
	const status = this.GetInfo(this, &EFI_FILE_INFO_ID, &info_size, file_info)
	EfiResult(status, file_info)
}

include "./elf.fy"
fun check_kernel_header(header: Elf64Header) {
	if(header.ident.magic[0] != 0x7f ||
	   header.ident.magic[1] != 'E' ||
	   header.ident.magic[2] != 'L' ||
	   header.ident.magic[3] != 'F') {
		println("Kernel file is not an ELF file"c 16)
		return false
	}
	if(header.ident.class != ELF_CLASS_64) {
		println("Kernel file is not 64-bit"c 16)
		return false
	}
	if(header.ident.endianness != ELF_LITTLE_ENDIAN) {
		println("Kernel file is not little-endian"c 16)
		return false
	}
	if(header.ident.version != ELF_VERSION_CURRENT || header.version != ELF_VERSION_CURRENT) {
		println("Kernel file is not version 1"c 16)
		return false
	}
	if(header.machine != ELF_MACHINE_X86_64) {
		println("Kernel file is not x86_64"c 16)
		return false
	}
	if(header.elf_type != ELF_TYPE_EXEC) {
		println("Kernel file is not an executable"c 16)
		return false
	}
	if(header.phentsize != sizeof(Elf64ProgramHeader)) {
		print("Kernel file has invalid program header size, expected"c 16)
		print_uint64(sizeof(Elf64ProgramHeader))
		print("but got"c 16)
		print_uint64(header.phentsize)
		conout.newline()
		return false
	}
	true
}

include "./framebuffer.fy"
fun init_framebuffer(): EfiResult<Framebuffer> {
	let gop: *EFI_GRAPHICS_OUTPUT_PROTOCOL
	const status = boot_services.LocateProtocol(&EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID, null, &gop)
	if(status != EFI_SUCCESS)
		return create EfiResult<Framebuffer> { status = status }

	EfiResult(EFI_SUCCESS, create Framebuffer {
		pixels = gop.Mode.FrameBufferBase,
		size = gop.Mode.FrameBufferSize,
		width = gop.Mode.Info.HorizontalResolution,
		height = gop.Mode.Info.VerticalResolution,
		pixels_per_scanline = gop.Mode.Info.PixelsPerScanLine,
	})
}

include "./psf.fy"
fun load_psf1_font(dir: *EFI_FILE_PROTOCOL, path: *CHAR16): EfiResult<PSF1_Font> {
	const file = dir.open(path).unwrap("Failed to open PSF1 font file"c 16)
	const info = file.get_info().unwrap("Failed to get info of PSF1 font file"c 16)
	const size = info.FileSize
	if(size < sizeof(PSF1_Header)) {
		println("PSF1 font file is too small for a valid PSF1 header"c 16)
		return create EfiResult<PSF1_Font> { status = EFI_INVALID_PARAMETER }
	}
	let header: PSF1_Header
	let header_size = sizeof(PSF1_Header)
	const status = file.Read(file, &header_size, &header)
	if(status != EFI_SUCCESS) {
		println("Failed to read PSF1 font file header"c 16)
		return create EfiResult<PSF1_Font> { status = status }
	}
	if(header.magic[0] != PSF1_MAGIC0 || header.magic[1] != PSF1_MAGIC1) {
		println("PSF1 font file has invalid magic"c 16)
		return create EfiResult<PSF1_Font> { status = EFI_INVALID_PARAMETER }
	}

	const glyph_count: uint = if(header.mode & PSF1_MODE512) 512 else 256
	let glyph_size = header.charsize as uint * glyph_count
	if(size < sizeof(PSF1_Header) + glyph_size) {
		println("PSF1 font file is too small to fit all glyphs"c 16)
		return create EfiResult<PSF1_Font> { status = EFI_INVALID_PARAMETER }
	}
	file.SetPosition(file, sizeof(PSF1_Header))
	const glyphs: *uint8 = efi_malloc(glyph_size)
	const status = file.Read(file, &glyph_size, glyphs)
	if(status != EFI_SUCCESS) {
		println("Failed to read PSF1 font file glyphs"c 16)
		return create EfiResult<PSF1_Font> { status = status }
	}
	efi_free(info)
	EfiResult(EFI_SUCCESS, create PSF1_Font {
		header = header,
		glyphs = glyphs,
	})
}

include "./bootinfo.fy"
fun efi_main(ih: EFI_HANDLE, st: *EFI_SYSTEM_TABLE): EFI_STATUS {
	conout.clear_screen()
	const loaded_image = loaded_image_protocol().unwrap("Failed to get loaded image protocol"c 16)
	const root_dir = load_root_image_dir(loaded_image).unwrap("Failed to get root directory of image"c 16)
	const kernel_file = root_dir.open("kernel.elf"c 16).unwrap("Failed to open kernel.elf"c 16)
	println("Opened kernel.elf"c 16)
	let header: Elf64Header;
	{
		const file_info = kernel_file.get_info().unwrap("Failed to get kernel.elf info"c 16)
		let header_size = sizeof(Elf64Header)
		if(file_info.Size < header_size) {
			println("Kernel file is too small"c 16)
			return EFI_ERR
		}
		efi_free(file_info)
		const status = kernel_file.Read(kernel_file, &header_size, &header)
		if(status != EFI_SUCCESS) {
			println("Failed to read header"c 16)
			return status
		}
	}
	if(!check_kernel_header(header)) return EFI_ERR
	println("Kernel file is valid"c 16)

	let program_headers: *Elf64ProgramHeader = efi_malloc(header.phnum * header.phentsize)
	{
		const status = kernel_file.SetPosition(kernel_file, header.phoff)
		if(status != EFI_SUCCESS) {
			conout.println("Failed to set position in kernel file"c 16)
			return status
		}
		let phsize = header.phnum * header.phentsize
		const status = kernel_file.Read(kernel_file, &phsize, program_headers)
		if(status != EFI_SUCCESS) {
			println("Failed to read kernel program headers"c 16)
			return status
		}
	}
	const max_program_header = program_headers + header.phnum
	let kernel_start_addr: uint64 = 0
	let total_bytes: uint64 = 0
	let alloc_points: *uint64 = efi_malloc(sizeof(uint64) * header.phnum)
	let requested_bytes: *uint64 = efi_malloc(sizeof(uint64) * header.phnum)
	let requested_points: *uint64 = efi_malloc(sizeof(uint64) * header.phnum)
	let pt_load_headers: *uint1 = efi_malloc(sizeof(uint1) * header.phnum)
	for(let i: uint64 = 0; i < header.phnum; i += 1) {
		const pheader: *Elf64ProgramHeader = (program_headers as *uint8) + i * header.phentsize
		if(pheader.ptype == ELF_PT_LOAD) {
			const bytes = pheader.memsz
			let alloc_point: uint64 = 0
			print("Allocating "c 16) print_uint64(bytes) print(" bytes at "c 16) print_hex(pheader.vaddr) conout.newline()
			alloc_point = efi_malloc(bytes)
			print("Allocated at "c 16) print_hex(alloc_point) conout.newline()
			alloc_points[i] = alloc_point
			requested_bytes[i] = bytes
			requested_points[i] = pheader.vaddr
			total_bytes += bytes
			pt_load_headers[i] = true
			if(alloc_point == nullptr) {
				println("Failed to allocate memory for segment"c 16)
				return EFI_ERR
			}
			const status = kernel_file.SetPosition(kernel_file, pheader.offset)
			if(status != EFI_SUCCESS) {
				println("Failed to set position in kernel file"c 16)
				return status
			}
			const status = kernel_file.Read(kernel_file, &pheader.filesz, alloc_point)
			if(status != EFI_SUCCESS) {
				println("Failed to read segment"c 16)
				return status
			}
		} else {
			pt_load_headers[i] = false
			print("Skipping program header of non PT_LOAD type: "c 16)
			print_hex(pheader.ptype)
			conout.newline()
		}
	}

	print("Allocating "c 16) print_uint64(total_bytes) print(" bytes for the full kernel"c 16) conout.newline()
	let full_kernel_mem: *uint8 = efi_malloc(total_bytes)
	if(full_kernel_mem == nullptr) {
		println("Failed to allocate memory for kernel"c 16)
		return EFI_ERR
	}
	println("Copying kernel parts to final location"c 16)
	for(let i: uint64 = 0; i < header.phnum; i += 1)
	if(pt_load_headers[i]) {
		print("Copying "c 16) print_uint64(requested_bytes[i]) print(" bytes from "c 16) print_hex(alloc_points[i]) print(" to "c 16) print_hex(full_kernel_mem + requested_points[i]) conout.newline()
		efi_memcpy(full_kernel_mem + requested_points[i], alloc_points[i], requested_bytes[i])
		print("Freeing "c 16) print_uint64(requested_bytes[i]) print(" bytes at "c 16) print_hex(alloc_points[i]) conout.newline()
		boot_services.FreePages(alloc_points[i], requested_bytes[i])
	}
	println("Kernel loaded"c 16)
	const kernel_start: *fun cc(X8664SysV)(*BootInfo): uint32 = full_kernel_mem + header.entry
	let framebuffer: Framebuffer = init_framebuffer().unwrap("Failed to initialize framebuffer"c 16)
	println("Framebuffer initialized"c 16)
	print("Framebuffer pixel base: "c 16) print_hex(framebuffer.pixels) conout.newline()
	print("Framebuffer size: "c 16) print_uint64(framebuffer.size) conout.newline()
	print("Framebuffer width: "c 16) print_uint64(framebuffer.width) conout.newline()
	print("Framebuffer height: "c 16) print_uint64(framebuffer.height) conout.newline()
	print("Framebuffer pixels per scanline: "c 16) print_uint64(framebuffer.pixels_per_scanline) conout.newline()

	println("Loading PSF1 font..."c 16)
	let font: PSF1_Font = load_psf1_font(root_dir, "font.psf"c 16).unwrap("Failed to load PSF1 font"c 16)
	println("Loaded PSF1 font"c 16)

	println("Exiting boot services..."c 16)
	let memory_map_size: UINTN = 0
	let memory_map: *EFI_MEMORY_DESCRIPTOR = nullptr
	let memory_map_key: UINTN = 0
	let descriptor_size: UINTN = 0
	let descriptor_version: UINT32 = 0
	{
		const status = boot_services.GetMemoryMap(&memory_map_size, memory_map, &memory_map_key, &descriptor_size, &descriptor_version)
		if(status != EFI_BUFFER_TOO_SMALL) {
			println("Failed to get memory map size"c 16)
			return status
		}
		memory_map_size += descriptor_size * 2
		memory_map = efi_malloc(memory_map_size)
		const status = boot_services.GetMemoryMap(&memory_map_size, memory_map, &memory_map_key, &descriptor_size, &descriptor_version)
		if(status != EFI_SUCCESS) {
			println("Failed to get memory map"c 16)
			return status
		}
	}
	const status = boot_services.ExitBootServices(image_handle, memory_map_key)
	if(status != EFI_SUCCESS) {
		println("Failed to exit boot services"c 16)
		return status
	}

	let boot_info = create BootInfo {
		framebuffer = framebuffer,
		font = font,
		mem_map = memory_map,
		mem_map_size = memory_map_size,
		mem_desc_size = descriptor_size,
	}

	const kernel_ret = kernel_start(&boot_info)
	EFI_SUCCESS
}

fun main cc(EFIAPI) (ih: EFI_HANDLE, st: *EFI_SYSTEM_TABLE): EFI_STATUS {
	init_efi_globals(ih, st)
	const status = efi_main(ih, st)
	shutdown(status)
	status
}

fun __chkstk always_compile(true)() null
