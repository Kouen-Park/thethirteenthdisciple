extends SceneTree

func _initialize() -> void:
	for asset in ["trial", "golgotha", "tomb", "dawn"]:
		var image := Image.load_from_file("res://assets/art/late_chapters/source/" + asset + ".png")
		image.resize(2048, 720, Image.INTERPOLATE_NEAREST)
		image.convert(Image.FORMAT_RGB8)
		image.save_png("res://assets/art/late_chapters/" + asset + ".png")
	var fire := Image.load_from_file("res://assets/art/late_chapters/source/fireplace.png")
	fire = fire.get_region(fire.get_used_rect())
	fire.resize(96, 64, Image.INTERPOLATE_NEAREST)
	fire.save_png("res://assets/art/late_chapters/fireplace.png")
	quit()
