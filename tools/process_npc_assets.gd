extends SceneTree

const TARGETS := {
	"res://assets/art/pixel/npcs/merchant_jonah.png": 96,
	"res://assets/art/pixel/npcs/miriam.png": 96,
	"res://assets/art/pixel/npcs/ambient_crowd.png": 116,
}

func _initialize() -> void:
	for resource_path: String in TARGETS:
		if not _process_sprite(resource_path, TARGETS[resource_path]):
			quit(1)
			return
	print("Processed chapter 1 NPC sprites")
	quit(0)

func _process_sprite(resource_path: String, target_height: int) -> bool:
	var absolute_path := ProjectSettings.globalize_path(resource_path)
	var image := Image.load_from_file(absolute_path)
	if image.is_empty():
		push_error("Could not load %s" % resource_path)
		return false
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.72:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)
	var used_rect := image.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		push_error("No opaque sprite pixels in %s" % resource_path)
		return false
	image = image.get_region(used_rect)
	var target_width := maxi(1, roundi(float(image.get_width()) * float(target_height) / float(image.get_height())))
	image.resize(target_width, target_height, Image.INTERPOLATE_NEAREST)
	return image.save_png(absolute_path) == OK
