include "./efi_globals"

inline fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) print(string: *CHAR16): EFI_STATUS
	this.OutputString(this, string)

const NEWLINE = "\r\n"c 16
inline fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) newline() this.print(NEWLINE)

fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) println(string: *CHAR16): EFI_STATUS {
	this.print(string)
	this.newline()
}

inline fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) clear_screen(): EFI_STATUS
	this.ClearScreen(this)
