extends SceneTree

const Support = preload("res://tests/polish_support.gd")

func end_field_preview(chapter: Node) -> void:
	var field: Node = chapter.field_investigation
	field.active = false
	for target in field.disabled_targets:
		if is_instance_valid(target): target.interaction_enabled = field.disabled_targets[target]
	field.queue_free()

func _initialize() -> void:
	call_deferred("_run")

func capture(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var suffix := "-1600" if "wide" in OS.get_cmdline_user_args() else ""
	root.get_texture().get_image().save_png("res://output/polish/" + name + suffix + ".png")

func _run() -> void:
	root.size = Vector2i(1600, 900) if "wide" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var settings: Node = root.get_node("GameState")
	var state: Node = root.get_node("StoryState")
	var before: Dictionary = state.get_state()
	var before_scale: float = settings.text_scale
	var menu: Node = load("res://scenes/menu/main_menu.tscn").instantiate()
	root.add_child(menu)
	await create_timer(1.1).timeout
	await capture("menu")
	menu._open_settings()
	await create_timer(0.4).timeout
	await capture("settings")
	menu.free()
	var selection: Node = load("res://scenes/menu/chapter_select.tscn").instantiate()
	root.add_child(selection)
	selection._preview(3)
	await capture("chapters")
	selection.free()
	var chapter: Node = load("res://scenes/chapters/chapter_04_trial.tscn").instantiate()
	chapter.persistence_enabled = false
	root.add_child(chapter)
	await Support.reach_exploration(chapter, chapter.player)
	chapter.player.position = Vector2(590, 585)
	await create_timer(1.0).timeout
	await capture("world")
	chapter.pause_menu.open_menu()
	await capture("pause")
	chapter.pause_menu.close_menu()
	state.record_observation(&"chapter_04", &"fireplace", {"title": "식어 가는 불자리", "description": "재가 식어 간다. 불을 쬐던 사람이 같은 이를 세 번 모른다고 했다는 말만 남았다."})
	chapter.journal.open_journal()
	await capture("journal")
	chapter.journal.close_journal()
	chapter.phase = "puzzle"
	chapter._update_phase()
	chapter._open_puzzle()
	await capture("field-investigation")
	end_field_preview(chapter)
	chapter.phase = "choice"
	chapter._update_phase()
	chapter._open_choice()
	await capture("choice")
	chapter.free()
	settings.text_scale = 1.3
	chapter = load("res://scenes/chapters/chapter_06_resurrection.tscn").instantiate()
	chapter.persistence_enabled = false
	root.add_child(chapter)
	await Support.reach_exploration(chapter, chapter.player)
	chapter.pause_menu.open_menu()
	await capture("large-pause")
	chapter.pause_menu.close_menu()
	chapter.phase = "puzzle"
	chapter._update_phase()
	chapter._open_puzzle()
	await capture("large-field")
	end_field_preview(chapter)
	chapter.phase = "choice"
	chapter._update_phase()
	chapter._open_choice()
	await capture("large-choice")
	chapter.free()
	var ending: Node = load("res://scenes/chapters/epilogue.tscn").instantiate()
	ending.persistence_enabled = false
	root.add_child(ending)
	await create_timer(1.0).timeout
	ending._advance()
	await capture("epilogue")
	ending._show_credits()
	await create_timer(2.2).timeout
	await capture("credits")
	ending.free()
	settings.text_scale = before_scale
	state.load_state(before)
	print("POLISH CAPTURE COMPLETE")
	quit()
