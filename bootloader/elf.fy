const ELF_MAGIC = "\x7fELF"
const ELF_CLASS_32 = 1
const ELF_CLASS_64 = 2
const ELF_LITTLE_ENDIAN = 1
const ELF_BIG_ENDIAN = 2
const ELF_TYPE_EXEC = 2
const ELF_MACHINE_X86_64 = 0x3e
const ELF_VERSION_CURRENT = 1
const ELF_PT_LOAD = 1

const osabi_eos = 0x13
struct ElfHeaderIdent {
	magic: typeof(ELF_MAGIC),
	class: uint8, // 1 = 32-bit, 2 = 64-bit
	endianness: uint8, // 1 = little, 2 = big
	version: uint8, // 1 = current
	osabi: uint8,
	abiversion: uint8,
	pad: uint8[7],
}
struct ElfHeader<U> {
	ident: ElfHeaderIdent,
	elf_type: uint16, // 1 = relocatable, 2 = executable, 3 = shared, 4 = core
	machine: uint16, // 0x03 = x86, 0x3e = x86-64
	version: uint32, // 1 = current
	entry: U,
	phoff: U,
	shoff: U,
	flags: uint32,
	ehsize: uint16,
	phentsize: uint16,
	phnum: uint16,
	shentsize: uint16,
	shnum: uint16,
	shstrndx: uint16,
	__padding: uint8[2],
}

type Elf32Header = ElfHeader<uint32>
type Elf64Header = ElfHeader<uint64>

struct Elf32ProgramHeader {
	ptype: uint32,
	offset: uint32,
	vaddr: uint32,
	paddr: uint32,
	filesz: uint32,
	memsz: uint32,
	flags: uint32,
	align: uint32,
}

struct Elf64ProgramHeader {
	ptype: uint32,
	flags: uint32,
	offset: uint64,
	vaddr: uint64,
	paddr: uint64,
	filesz: uint64,
	memsz: uint64,
	align: uint64,
}

struct ElfSectionHeader<U> {
	name: uint32,
	stype: uint32,
	flags: U,
	addr: U,
	offset: U,
	size: U,
	link: uint32,
	info: uint32,
	addralign: U,
	entsize: U,
}

type Elf32SectionHeader = ElfSectionHeader<uint32>
type Elf64SectionHeader = ElfSectionHeader<uint64>
