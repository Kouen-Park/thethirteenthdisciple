extends SceneTree
const Support = preload("res://tests/polish_support.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	print("CAPTURE START")
	var scenes := [] if "epilogue" in OS.get_cmdline_user_args() else ["chapter_04_trial", "chapter_05_golgotha", "chapter_06_resurrection"]
	for scene in scenes:
		var chapter: Node = load("res://scenes/chapters/" + scene + ".tscn").instantiate()
		chapter.persistence_enabled = false
		root.add_child(chapter)
		await Support.reach_exploration(chapter, chapter.player)
		chapter.get_node("FadeLayer/Fade").color.a = 0
		for x in [540, 1510]:
			chapter.player.position = Vector2(x, 580)
			await create_timer(1.6).timeout
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://output/late_chapters/" + scene + "-" + str(x) + ".png")
		chapter.phase = "puzzle"
		chapter._open_puzzle()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/late_chapters/" + scene + "-puzzle.png")
		chapter.field_investigation.active = false
		chapter.field_investigation.queue_free()
		chapter.field_investigation = null
		await process_frame
		chapter.phase = "choice"
		chapter._open_choice()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/late_chapters/" + scene + "-choice.png")
		chapter.free()
	var epilogue: Node = load("res://scenes/chapters/epilogue.tscn").instantiate()
	epilogue.persistence_enabled = false
	root.add_child(epilogue)
	await create_timer(1.0).timeout
	epilogue.typing = false
	epilogue.get_node("Panel/Box/Text").visible_characters = -1
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/late_chapters/epilogue.png")
	epilogue._show_credits()
	await create_timer(2.1).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/late_chapters/credits.png")
	epilogue.free()
	print("CAPTURE COMPLETE")
	quit()
