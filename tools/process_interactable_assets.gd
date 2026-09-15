extends SceneTree

const ASSETS := [
	{"path": "res://assets/art/pixel/interactables/palm_leaf.png", "size": Vector2i(120, 80)},
	{"path": "res://assets/art/pixel/interactables/discarded_cloak.png", "size": Vector2i(120, 80)},
	{"path": "res://assets/art/pixel/interactables/footprints.png", "size": Vector2i(88, 96)}
]

func _initialize() -> void:
	for spec in ASSETS:
		var path: String = spec["path"]
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			push_error("Could not load %s" % path)
			quit(1)
			return
		image.resize(spec["size"].x, spec["size"].y, Image.INTERPOLATE_NEAREST)
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var color := image.get_pixel(x, y)
				if color.a < 0.72:
					image.set_pixel(x, y, Color(0, 0, 0, 0))
				else:
					color.a = 1.0
					image.set_pixel(x, y, color)
		var result := image.save_png(ProjectSettings.globalize_path(path))
		if result != OK:
			push_error("Could not save %s" % path)
			quit(1)
			return
		print("Processed %s" % path)
	quit(0)
