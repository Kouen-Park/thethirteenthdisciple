extends SceneTree
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/art/player_walk/atlas.png")
	var directions := ["down", "down_right", "right", "up_right", "up"]
	print("WALK ", source.get_size(), " alpha ", source.detect_alpha())
	for row in 5:
		var sheet := Image.create(320, 80, false, Image.FORMAT_RGBA8)
		var frames: Array[Image] = []
		var maximum_height := 1
		for frame in 4:
			var single := source.get_region(Rect2i(frame * source.get_width() / 4, row * source.get_height() / 5, source.get_width() / 4, source.get_height() / 5))
			single = single.get_region(single.get_used_rect())
			frames.append(single)
			maximum_height = maxi(maximum_height, single.get_height())
		var ratio := 68.0 / maximum_height
		for frame in 4:
			var single := frames[frame]
			single.resize(maxi(1, roundi(single.get_width() * ratio)), maxi(1, roundi(single.get_height() * ratio)), Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(single, Rect2i(Vector2i.ZERO, single.get_size()), Vector2i(frame * 80 + (80 - single.get_width()) / 2, 76 - single.get_height()))
		sheet.save_png("res://assets/art/player_walk/" + directions[row] + ".png")
		if row in [1, 2, 3]:
			var mirror := Image.create(320, 80, false, Image.FORMAT_RGBA8)
			for frame in 4:
				var single := sheet.get_region(Rect2i(frame * 80, 0, 80, 80))
				single.flip_x()
				mirror.blit_rect(single, Rect2i(0, 0, 80, 80), Vector2i(frame * 80, 0))
			mirror.save_png("res://assets/art/player_walk/" + directions[row].replace("right", "left") + ".png")
	quit()
