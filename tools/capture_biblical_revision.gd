extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://output/biblical_revision")
	for number in [4, 5, 6]:
		var chapter: Node = load(StoryData.get_scene_path(number)).instantiate()
		chapter.persistence_enabled = false
		root.add_child(chapter)
		await create_timer(1.5).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/biblical_revision/context-%d.png" % number)
		await preload("res://tests/polish_support.gd").reach_exploration(chapter, chapter.player)
		chapter.player.position = Vector2(1280, 630)
		chapter.phase = "puzzle"
		chapter._open_puzzle()
		await create_timer(1.5).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/biblical_revision/field-%d.png" % number)
		if number == 5:
			BibleInterlude.present(chapter, BiblicalContext.DEATH)
			await create_timer(4).timeout
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://output/biblical_revision/death.png")
		chapter.free()
		await process_frame
	print("REVISION CAPTURES COMPLETE")
	quit()
