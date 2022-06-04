include "../bootloader/framebuffer.fy"
include "../bootloader/psf.fy"
include "std/types"

const FONT_WIDTH = 8
const FONT_HEIGHT = 18

const WHITE = create RGBAColor { red = 255, green = 255, blue = 255 }
const BLACK = create RGBAColor { red = 0, green = 0, blue = 0 }

const RED = create RGBAColor { red = 255, green = 0, blue = 0 }
const PURPLE = create RGBAColor { red = 255, green = 0, blue = 255 }
const BLUE = create RGBAColor { red = 0, green = 0, blue = 255 }

inline fun(Framebuffer | *Framebuffer) set_pixel(x: uint, y: uint, color: RGBAColor)
	this.pixels[y * this.pixels_per_scanline + x] = color

fun put_char(framebuffer: *Framebuffer, font: *PSF1_Font, color: RGBAColor, char: char, xpos: uint, ypos: uint) {
	let font_ptr = font.glyph(char)
	for(let y = ypos; y < ypos + FONT_HEIGHT; y += 1) {
		for(let x = xpos; x < xpos + FONT_WIDTH; x += 1)
			if(*font_ptr & (0b10000000 >> (x - xpos)) != 0)
				framebuffer.set_pixel(x, y, color)
		font_ptr += 1
	}
}

fun put_strl(str: *char, len: uint_ptrsize, framebuffer: *Framebuffer, font: *PSF1_Font, color: RGBAColor, xpos: uint, ypos: uint) {
	let y = ypos
	let x = xpos
	for(let i = 0; i < len; i += 1) {
		const char = str[i]
		if(char == '\n') {
			y += FONT_HEIGHT
			x = xpos
		} else {
			put_char(framebuffer, font, color, char, x, y)
			x += FONT_WIDTH
		}
		y = y % framebuffer.height
	}
}

inline fun put_str(str: char[generic Len] | *char[generic Len], framebuffer: *Framebuffer, font: *PSF1_Font, color: RGBAColor, xpos: uint, ypos: uint) {
	const strp = if(typeof(str) == char[generic Len]) &(let p = str) else str
	put_strl(strp, Len, framebuffer, font, color, xpos, ypos)
}

fun _start always_compile(true) cc(X8664SysV) (framebuffer: *Framebuffer, font: *PSF1_Font): uint32 {
	for(let y = 50; y <= 200; y += 1)
	for(let x = 50; x <= 200; x += 1)
		framebuffer.set_pixel(x, y, create RGBAColor {
			red = x - 50,
			green = y - 50,
			blue = (y + x - 100) / 2,
		})
	put_str("Hello,\nworld!", framebuffer, font, PURPLE, 100, 100)
	1234
}
