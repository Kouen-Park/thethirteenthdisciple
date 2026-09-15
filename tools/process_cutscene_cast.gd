extends SceneTree

const SOURCE := "res://assets/art/biblical_cast/cutscene_cast_atlas.png"
const OUTPUT := "res://assets/art/cutscene_cast"
const NAMES := [
	"jesus", "peter", "judas", "disciple",
	"priest", "pilate", "barabbas", "merchant",
	"male_pilgrim", "female_pilgrim", "tomb_messenger", "escort_soldier",
]

func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	_remove_backdrop(source)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	source.save_png(OUTPUT + "/atlas_cutout.png")
	for index in NAMES.size():
		var column := index % 4
		var row := index / 4
		var x0 := roundi(float(column) * source.get_width() / 4.0)
		var x1 := roundi(float(column + 1) * source.get_width() / 4.0)
		var y0 := roundi(float(row) * source.get_height() / 3.0)
		var y1 := roundi(float(row + 1) * source.get_height() / 3.0)
		var cell := source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
		_keep_largest_component(cell)
		var used := cell.get_used_rect()
		if used.size == Vector2i.ZERO:
			push_error("Empty cast cell: " + NAMES[index])
			continue
		cell = cell.get_region(used)
		var width := maxi(1, roundi(float(cell.get_width()) / cell.get_height() * 68.0))
		cell.resize(width, 68, Image.INTERPOLATE_LANCZOS)
		cell.save_png(OUTPUT + "/" + NAMES[index] + ".png")
	print("CUTSCENE CAST: ", NAMES.size(), " sprites")
	quit()

func _remove_backdrop(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var stack := PackedInt32Array()
	for x in width:
		stack.append(x)
		stack.append((height - 1) * width + x)
	for y in height:
		stack.append(y * width)
		stack.append(y * width + width - 1)
	while not stack.is_empty():
		var pixel_index := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if visited[pixel_index]:
			continue
		visited[pixel_index] = 1
		var x := pixel_index % width
		var y := pixel_index / width
		var color := image.get_pixel(x, y)
		if color.s > 0.16 or color.v < 0.68:
			continue
		image.set_pixel(x, y, Color.TRANSPARENT)
		if x > 0: stack.append(pixel_index - 1)
		if x < width - 1: stack.append(pixel_index + 1)
		if y > 0: stack.append(pixel_index - width)
		if y < height - 1: stack.append(pixel_index + width)

func _keep_largest_component(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var components: Array[PackedInt32Array] = []
	for y in height:
		for x in width:
			var start := y * width + x
			if visited[start] or image.get_pixel(x, y).a < 0.05:
				continue
			var component := PackedInt32Array()
			var stack := PackedInt32Array([start])
			while not stack.is_empty():
				var pixel_index := stack[stack.size() - 1]
				stack.resize(stack.size() - 1)
				if visited[pixel_index]:
					continue
				visited[pixel_index] = 1
				var px := pixel_index % width
				var py := pixel_index / width
				if image.get_pixel(px, py).a < 0.05:
					continue
				component.append(pixel_index)
				if px > 0: stack.append(pixel_index - 1)
				if px < width - 1: stack.append(pixel_index + 1)
				if py > 0: stack.append(pixel_index - width)
				if py < height - 1: stack.append(pixel_index + width)
			components.append(component)
	var largest := PackedInt32Array()
	for component in components:
		if component.size() > largest.size():
			largest = component
	var keep := PackedByteArray()
	keep.resize(width * height)
	for pixel_index in largest:
		keep[pixel_index] = 1
	for y in height:
		for x in width:
			if not keep[y * width + x]:
				image.set_pixel(x, y, Color.TRANSPARENT)
