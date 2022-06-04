const PSF1_MAGIC0  = 0x36
const PSF1_MAGIC1  = 0x04
const PSF1_MODE512 = 0x01
struct PSF1_Header {
	magic: uint8[2],
	mode: uint8,
	charsize: uint8, // bytes per char
}

struct PSF1_Font {
	header: PSF1_Header,
	glyphs: *uint8,
}

inline fun(PSF1_Font | *PSF1_Font) glyph(index: uint32): *uint8
	this.glyphs + index * this.header.charsize
