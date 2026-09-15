extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://output/spatial_investigation")
	for number in [2, 3]:
		var chapter: Node = load(StoryData.get_scene_path(number)).instantiate()
		chapter.persistence_enabled = false
		root.add_child(chapter)
		await preload("res://tests/polish_support.gd").reach_exploration(chapter, chapter.player)
		if number == 3: chapter.apply_night_state()
		chapter.player.position = Vector2(1020, 640) if number == 2 else Vector2(1300, 640)
		chapter.begin_field_investigation(number, chapter._world_interactables() if number == 2 else chapter.targets.values(), func(_result): pass)
		if number == 3:
			chapter.field_investigation.lamp_on = true
		await create_timer(1.5).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/spatial_investigation/chapter-%d.png" % number)
		chapter.free()
		await process_frame
	quit()
