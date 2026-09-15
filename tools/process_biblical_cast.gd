extends SceneTree
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/art/biblical_cast/atlas_alpha.png")
	# Extract connected neutral checkerboard from imagegen output; preserve outlined figures.
	remove_backdrop(source)
	source.save_png("res://assets/art/biblical_cast/atlas_cutout.png")
	var names := ["soldier", "servant", "herald", "mother", "simon", "mary", "salome", "joseph"]
	for i in 8:
		var cell := source.get_region(Rect2i((i % 4) * source.get_width() / 4, (i / 4) * source.get_height() / 2, source.get_width() / 4, source.get_height() / 2))
		cell = cell.get_region(cell.get_used_rect())
		cell.resize(maxi(1, roundi(float(cell.get_width()) / cell.get_height() * 68)), 68, Image.INTERPOLATE_NEAREST)
		cell.save_png("res://assets/art/biblical_cast/" + names[i] + ".png")
	print("CAST: ", source.get_size(), " alpha=", source.detect_alpha())
	quit()

func remove_backdrop(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var w := image.get_width()
	var h := image.get_height()
	var visited := PackedByteArray()
	visited.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var index := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if visited[index]: continue
		visited[index] = 1
		var x := index % w
		var y := index / w
		var color := image.get_pixel(x, y)
		if color.s > 0.18 or color.v < 0.65: continue
		image.set_pixel(x, y, Color.TRANSPARENT)
		if x > 0: stack.append(index - 1)
		if x < w - 1: stack.append(index + 1)
		if y > 0: stack.append(index - w)
		if y < h - 1: stack.append(index + w)
