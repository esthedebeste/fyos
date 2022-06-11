struct RGBAColor {
	blue: uint8,
	green: uint8,
	red: uint8,
	alpha: uint8,
}
struct Framebuffer {
	pixels: *RGBAColor,
	size: uint64,
	width: uint32,
	height: uint32,
	pixels_per_scanline: uint32,
}


fun(*Framebuffer) set_pixel(x: uint, y: uint, color: RGBAColor)
	this.pixels[y * this.pixels_per_scanline + x] = color

fun(Framebuffer | *Framebuffer) get_pixel(x: uint, y: uint)
	this.pixels[y * this.pixels_per_scanline + x]

fun(Framebuffer) move_up(up: uint) {
	for(let y = 0; y < this.height - up; y += 1)
		for(let x = 0; x < this.width; x += 1)
			this.pixels[y * this.pixels_per_scanline + x] = this.pixels[(y + up) * this.pixels_per_scanline + x]
	// black out the bottom
	for(let y = this.height - up; y < this.height; y += 1)
		for(let x = 0; x < this.width; x += 1)
			this.pixels[y * this.pixels_per_scanline + x] = create RGBAColor { red = 0, green = 0, blue = 0, alpha = 0 }
}

fun(Framebuffer) clear()
	for(let y = 0; y < this.height; y += 1)
		for(let x = 0; x < this.width; x += 1)
			this.pixels[y * this.pixels_per_scanline + x] = create RGBAColor { red = 0, green = 0, blue = 0, alpha = 0 }
