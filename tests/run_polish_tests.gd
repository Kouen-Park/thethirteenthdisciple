extends SceneTree

const Support = preload("res://tests/polish_support.gd")

var failures := 0
var chapter: Node
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func frames(count := 2) -> void:
	for i in count: await physics_frame
func settle() -> void:
	check(await Support.reach_exploration(chapter, chapter.player), "Opening restores exploration")
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	var state: Node = root.get_node("StoryState")
	var mix: Node = root.get_node("AudioMix")
	var snapshot: Dictionary = state.get_state()
	var original_scale: float = settings.text_scale
	var original_volume: float = settings.ambience_volume
	chapter = load("res://scenes/chapters/chapter_04_trial.tscn").instantiate()
	chapter.persistence_enabled = false
	root.add_child(chapter)
	chapter.journal.open_journal()
	check(not chapter.journal.active, "Journal must not interrupt opening dialogue")
	await settle()
	var journal: Node = chapter.journal
	state.record_observation(&"chapter_04", &"polish_test", {"title": "들은 말", "description": "질문이었다.", "data": {"lines": ["질문이었다.", "나중에는 단정이 되었다."]}})
	journal.open_journal()
	check(journal.active and not chapter.player.input_enabled and not chapter.interaction_scanner.input_enabled, "Journal owns both world inputs")
	check(journal.entries.get_child_count() > 0, "Journal renders saved observations")
	var rows: Array = journal.observation_rows({"observed": {"x": {"description": "첫 문장", "data": {"lines": ["첫 문장", "두 번째 문장"]}}}})
	check(rows[0].text == "첫 문장\n두 번째 문장", "Journal preserves full evidence without duplicate first lines")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_J
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	check(not journal.active and chapter.player.input_enabled, "J closes journal and restores exploration")
	chapter.acquire_input_lock(&"dialogue")
	journal.open_journal()
	check(not journal.active, "Cannot open journal over another input lock")
	chapter.release_input_lock(&"dialogue")
	chapter._request_leave_chapter()
	chapter.leave_confirmation.hide()
	chapter._cancel_leave_chapter()
	check(not chapter.is_input_locked() and chapter.player.input_enabled, "Leaving and canceling creates no stale lock")
	chapter.phase = "puzzle"
	chapter._open_puzzle()
	var field: Node = chapter.field_investigation
	var first: Dictionary = field.config.sources[0]
	chapter.player.global_position = field.stations[first.id].global_position + Vector2(0, 25)
	await frames()
	check(field.use(first.id), "A nearby field clue can be investigated")
	var progress: Dictionary = field.accepted.duplicate()
	var selection: String = field.selected_id
	journal.open_journal()
	check(journal.active and not chapter.player.input_enabled, "Field investigation can consult the journal")
	journal.close_journal()
	check(chapter.player.input_enabled and field.accepted == progress and field.selected_id == selection, "Closing the journal preserves field progress")
	chapter.speech_bubbles.show_bubble(chapter.player, "닫히지 않은 말풍선", &"protagonist")
	await frames()
	check(mix._dialogue_depth == 1, "Visible dialogue ducks ambience once")
	chapter.free()
	await create_timer(0.5).timeout
	check(mix._dialogue_depth == 0, "Removing a scene restores dialogue duck ownership")
	mix.begin_dialogue()
	mix.set_bus_linear(&"Ambience", 0.5)
	await create_timer(0.2).timeout
	var bus := AudioServer.get_bus_index("Ambience")
	check(is_equal_approx(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5) - 5.0), "Volume changes preserve active dialogue duck")
	mix.end_dialogue()
	await create_timer(0.5).timeout
	check(is_equal_approx(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5)), "Dialogue end returns to the new user volume")
	mix.set_bus_linear(&"Ambience", original_volume)
	# Chapter 2 uses a legacy interaction lock; the leave dialog must only release its own lock.
	chapter = load("res://scenes/chapters/chapter_02_temple.tscn").instantiate()
	chapter.persistence_enabled = false
	root.add_child(chapter)
	await settle()
	chapter.set_world_input(false)
	chapter._request_leave_chapter()
	chapter.leave_confirmation.hide()
	chapter._cancel_leave_chapter()
	check(chapter.is_input_locked(&"legacy") and not chapter.player.input_enabled, "Cancel leave must not release a puzzle lock")
	chapter.set_world_input(true)
	check(not chapter.is_input_locked(), "Finishing the interaction releases the remaining lock")
	chapter.free()
	var coins := CoinGatherPuzzle.new()
	root.add_child(coins)
	coins.start()
	var coin_start: Vector2 = coins._coins[0].position
	coins.collect_coin(0)
	check(root.gui_get_focus_owner() == coins._coins[1], "Coin collection focuses the next usable coin")
	await create_timer(0.3).timeout
	coins.start()
	check(coins._coins[0].position == coin_start, "Reopening coins restores their layout")
	coins.free()
	var cloth := PrayerClothPuzzle.new()
	root.add_child(cloth)
	cloth.start()
	var corner_start: Vector2 = cloth._corners[0].position
	cloth.unfold_corner(0)
	check(root.gui_get_focus_owner() == cloth._corners[1], "Unfolding focuses the next corner")
	await create_timer(0.3).timeout
	cloth.start()
	check(cloth._corners[0].position == corner_start, "Reopening cloth restores corner positions")
	cloth.free()
	settings.text_scale = 1.3
	var ending: Node = load("res://scenes/chapters/epilogue.tscn").instantiate()
	ending.persistence_enabled = false
	root.add_child(ending)
	ending._advance()
	check(not ending.typing and ending.get_node("Panel/Box/Text").visible_characters == -1, "Epilogue reveal is immediate")
	await frames()
	check(ending.get_node("Panel").get_rect().end.y <= 720, "Large ending text fits")
	check(ending.ambience.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Ending ambience loops during long reading")
	ending.free()
	settings.text_scale = original_scale
	state.load_state(snapshot)
	await create_timer(0.15).timeout
	print("POLISH TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(1 if failures else 0)
