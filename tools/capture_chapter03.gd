extends SceneTree
const Support = preload("res://tests/polish_support.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var suffix := "" if OS.get_cmdline_user_args().is_empty() else "-" + OS.get_cmdline_user_args()[0]
	var chapter: Node = load("res://scenes/chapters/chapter_03_garden.tscn").instantiate()
	chapter.persistence_enabled = false
	root.add_child(chapter)
	await Support.reach_exploration(chapter, chapter.player)
	chapter.get_node("FadeLayer/Fade").color.a = 0
	chapter.player.position = Vector2(540, 585)
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/chapter03/day-left" + suffix + ".png")
	chapter.player.position = Vector2(1570, 585)
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/chapter03/day-right" + suffix + ".png")
	chapter.apply_night_state()
	chapter.director.current_beat = &"night_rumors"
	chapter._on_beat_changed(&"night_rumors")
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/chapter03/night-right" + suffix + ".png")
	chapter.director.current_beat = &"route"
	chapter._open_route()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/chapter03/route-puzzle" + suffix + ".png")
	chapter.route_puzzle.cancel_puzzle()
	chapter.director.current_beat = &"reflection"
	chapter._on_beat_changed(&"reflection")
	chapter._open_choice()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURE view=", root.get_visible_rect(), " pixels=", root.get_texture().get_size(), " choice=", chapter.choice_panel.get_rect(), " minimum=", chapter.choice_panel.get_combined_minimum_size())
	root.get_texture().get_image().save_png("res://output/chapter03/reflection" + suffix + ".png")
	chapter.choice_panel.hide()
	chapter.player.position = Vector2(650, 580)
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/chapter03/night-left" + suffix + ".png")
	chapter.free()
	quit()

