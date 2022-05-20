include "./efi_globals"

inline fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) print_string(string: *CHAR16): EFI_STATUS
	this.OutputString(this, string)

inline fun(*EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL) clear_screen(): EFI_STATUS
	this.ClearScreen(this)
