extends SceneTree

const Story = preload("res://story_data.gd")
const Support = preload("res://tests/polish_support.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func frames(count := 2) -> void:
	for i in count: await process_frame

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	Input.parse_input_event(event)
	await frames()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var settings: Node = root.get_node("GameState")
	var state: Node = root.get_node("StoryState")
	var before: Dictionary = state.get_state()
	var original_scale: float = settings.text_scale
	for number in range(1, 8):
		settings.text_scale = 1.3 if number >= 4 else original_scale
		var chapter: Node = load(Story.get_scene_path(number)).instantiate()
		chapter.persistence_enabled = false
		root.add_child(chapter)
		await create_timer(1.0).timeout
		var menu: Node = chapter.pause_menu
		var intro: Node = Support.interlude(chapter)
		if is_instance_valid(intro):
			await press(KEY_P)
			var time_before: float = intro.elapsed
			await create_timer(0.2).timeout
			check(paused and intro.elapsed == time_before, "P freezes the biblical transition scene")
			await press(KEY_P)
		if number < 7: check(await Support.reach_dialogue(chapter), "Opening reaches dialogue after the interlude")
		var bubble: Node = null
		if number < 7: bubble = chapter.speech_bubbles._active_bubble
		await press(KEY_P)
		check(paused and menu.active, "P pauses chapter %d during dialogue" % number)
		var count: int = bubble.text_label.visible_characters if is_instance_valid(bubble) else chapter.get_node("Panel/Box/Text").visible_characters
		await create_timer(0.25).timeout
		var count_after: int = bubble.text_label.visible_characters if is_instance_valid(bubble) else chapter.get_node("Panel/Box/Text").visible_characters
		check(count == count_after, "Paused chapter %d stops typewriter progress" % number)
		check(menu.panel.get_global_rect().end.y <= 720, "Pause menu fits the viewport")
		if is_instance_valid(bubble):
			settings.text_speed_changed.emit(42.0)
			check(bubble.characters_per_second == 42.0, "Reading speed reaches the current bubble")
			settings.text_speed_changed.emit(settings.text_speed)
		await press(KEY_ESCAPE)
		check(not paused and not menu.active, "Esc resumes the same chapter")
		if number < 7: check(is_instance_valid(chapter.speech_bubbles._active_bubble), "Resume does not dismiss dialogue")
		if number >= 4 and number <= 6:
			check(await Support.reach_exploration(chapter, chapter.player), "Opening restores movement")
			chapter.phase = "puzzle"
			chapter._open_puzzle()
			var field: Node = chapter.field_investigation
			var first: Dictionary = field.config.sources[0]
			chapter.player.global_position = field.stations[first.id].global_position + Vector2(0, 25)
			await frames()
			field.use(first.id)
			var done: Dictionary = field.accepted.duplicate()
			var carried: String = field.selected_id
			var position: Vector2 = chapter.player.global_position
			await press(KEY_P)
			var elapsed: float = field.feedback_seconds
			await create_timer(0.2).timeout
			check(field.feedback_seconds == elapsed, "Pause freezes field feedback timing")
			check(chapter.player.global_position == position, "Pause keeps the player in place")
			await press(KEY_P)
			check(field.active and field.accepted == done and field.selected_id == carried, "Resume retains field links and the selected record")
			check(chapter.player.input_enabled, "Field exploration resumes with movement")
		menu.open_menu()
		chapter.free()
		await frames()
		check(not paused, "Removing a paused chapter restores SceneTree processing")
	check(state.get_state() == before, "Pause validation preserves story progress")
	settings.text_scale = original_scale
	await create_timer(0.15).timeout
	print("PAUSE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(1 if failures else 0)
