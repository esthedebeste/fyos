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
