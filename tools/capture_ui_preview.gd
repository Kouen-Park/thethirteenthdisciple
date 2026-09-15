extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	for item in [
		["res://scenes/menu/main_menu.tscn", "/tmp/disciple-main.png"],
		["res://scenes/menu/chapter_select.tscn", "/tmp/disciple-chapters.png"],
		["res://scenes/chapters/chapter_01_entry.tscn", "/tmp/disciple-world.png"]
	]:
		change_scene_to_file(item[0])
		for frame in 100:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(item[1])
		if item[0] == "res://scenes/menu/main_menu.tscn":
			current_scene.get_node("Center/SettingsButton").pressed.emit()
			for frame in 35:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/disciple-settings.png")
	quit()

