extends SceneTree

const SOURCE := "res://assets/art/chapter02/investigation_props.png"
const OUTPUT := "res://assets/art/chapter02/investigation_props_clean.png"

func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Could not load Chapter 2 prop sheet")
		quit(1)
		return
	var cleaned := source.duplicate()
	var replacements := 0
	for y in source.get_height():
		for x in source.get_width():
			var color := source.get_pixel(x, y)
			# Generated transparent PNGs can retain bright RGB values under alpha
			# zero. Texture sampling then leaks those values into the visible edge.
			if color.a <= 0.05:
				if color.r > 0.0 or color.g > 0.0 or color.b > 0.0 or color.a > 0.0:
					replacements += 1
				cleaned.set_pixel(x, y, Color.TRANSPARENT)
				continue
			if not _is_red_fringe(color) or not _touches_transparency(source, x, y):
				continue
			var outline := _nearest_dark_outline(source, x, y)
			if outline.a > 0.0:
				outline.a = color.a
				cleaned.set_pixel(x, y, outline)
			else:
				cleaned.set_pixel(x, y, Color.TRANSPARENT)
			replacements += 1
	var error: Error = cleaned.save_png(OUTPUT)
	print("Chapter 2 prop fringe pixels cleaned: %d" % replacements)
	quit(0 if error == OK else 1)

func _is_red_fringe(color: Color) -> bool:
	return color.a > 0.05 and color.r > 0.70 and color.g < 0.36 and color.b < 0.62 and color.r - color.g > 0.34 and color.r - color.b > 0.12

func _touches_transparency(image: Image, center_x: int, center_y: int) -> bool:
	for offset_y in range(-6, 7):
		for offset_x in range(-6, 7):
			var x := center_x + offset_x
			var y := center_y + offset_y
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				return true
			if image.get_pixel(x, y).a < 0.05:
				return true
	return false

func _nearest_dark_outline(image: Image, center_x: int, center_y: int) -> Color:
	var best := Color.TRANSPARENT
	var best_value := INF
	for radius in range(1, 6):
		for offset_y in range(-radius, radius + 1):
			for offset_x in range(-radius, radius + 1):
				if absi(offset_x) != radius and absi(offset_y) != radius:
					continue
				var x := center_x + offset_x
				var y := center_y + offset_y
				if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
					continue
				var candidate := image.get_pixel(x, y)
				if candidate.a < 0.5 or _is_red_fringe(candidate):
					continue
				var value := candidate.r * 0.30 + candidate.g * 0.59 + candidate.b * 0.11
				if value > 0.48:
					continue
				if value < best_value:
					best = candidate
					best_value = value
		if best.a > 0.0:
			return best
	return best
