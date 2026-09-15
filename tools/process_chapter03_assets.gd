extends SceneTree

const OUT := "res://assets/art/chapter03/"

func _initialize() -> void:
	var background := Image.load_from_file(OUT + "source/courtyard.png")
	background.resize(2048, 720, Image.INTERPOLATE_NEAREST)
	background.convert(Image.FORMAT_RGB8)
	background.save_png(OUT + "courtyard.png")
	var atlas := Image.load_from_file(OUT + "source/props.png")
	var names := ["well", "waiting_cloth", "broken_lantern", "drag_marks", "abandoned_sandal", "closed_door"]
	var sizes := [Vector2i(152, 152), Vector2i(90, 64), Vector2i(86, 52), Vector2i(118, 96), Vector2i(36, 32), Vector2i(54, 100)]
	for index in names.size():
		var left := roundi(index * atlas.get_width() / 6.0)
		var right := roundi((index + 1) * atlas.get_width() / 6.0)
		var cell := atlas.get_region(Rect2i(left, 0, right - left, atlas.get_height()))
		cell.convert(Image.FORMAT_RGBA8)
		# Harden generated edge coverage and discard isolated chroma spill.
		for y in cell.get_height():
			for x in cell.get_width():
				var c := cell.get_pixel(x, y)
				if c.a < 0.6 or (c.r > 0.6 and c.r > c.g * 2.8 and c.r > c.b * 2.8):
					cell.set_pixel(x, y, Color.TRANSPARENT)
				else:
					c.a = 1.0
					cell.set_pixel(x, y, c)
		var used := cell.get_used_rect()
		if used.has_area():
			cell = cell.get_region(used)
		var size: Vector2i = sizes[index]
		var ratio := minf(float(size.x) / cell.get_width(), float(size.y) / cell.get_height())
		cell.resize(maxi(1, roundi(cell.get_width() * ratio)), maxi(1, roundi(cell.get_height() * ratio)), Image.INTERPOLATE_NEAREST)
		if names[index] == "closed_door": cell.resize(54, 108, Image.INTERPOLATE_NEAREST)
		cell.save_png(OUT + names[index] + ".png")
	print("Chapter 3 art: imported 2048x720 RGB background and six 1x RGBA sprites")
	quit()
