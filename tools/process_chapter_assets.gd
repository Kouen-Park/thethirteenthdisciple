extends SceneTree

func _initialize() -> void:
	var background_path := ProjectSettings.globalize_path("res://assets/art/pixel/chapter01_jerusalem_gate_clean.png")
	var background := Image.load_from_file(background_path)
	background.resize(2560, 1440, Image.INTERPOLATE_NEAREST)
	if background.save_png(background_path) != OK:
		quit(1)
		return

	var jesus_path := ProjectSettings.globalize_path("res://assets/art/pixel/jesus_donkey_chibi.png")
	var jesus := Image.load_from_file(jesus_path)
	jesus.resize(150, 138, Image.INTERPOLATE_NEAREST)
	jesus.convert(Image.FORMAT_RGBA8)
	for y in jesus.get_height():
		for x in jesus.get_width():
			var color := jesus.get_pixel(x, y)
			if color.a < 0.72:
				jesus.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = 1.0
				jesus.set_pixel(x, y, color)
	if jesus.save_png(jesus_path) != OK:
		quit(1)
		return
	print("Processed chapter 1 background and Jesus sprite")
	quit(0)
