const PSF2_MAGIC: uint32 = 0x864ab572
struct PSF2_Header {
	magic: uint32,
	version: uint32,
	headersize: uint32,
	flags: uint32,
	numglyphs: uint32,
	glyphsize: uint32,
	height: uint32,
	width: uint32,
}

struct PSF2_Font {
	header: PSF2_Header,
	glyphs: *uint8,
}

fun(PSF2_Font | *PSF2_Font) glyph(index: uint32): *uint8
	this.glyphs + index * this.header.glyphsize
