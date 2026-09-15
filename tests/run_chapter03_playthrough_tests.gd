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
	for i in count:
		await physics_frame
		if is_instance_valid(chapter): Support.advance_interlude(chapter)

func settle(lock: StringName, limit := 720) -> void:
	for i in limit:
		if is_instance_valid(chapter.speech_bubbles._active_bubble):
			chapter.speech_bubbles.close_bubble()
		await frames()
		if not chapter.is_input_locked(lock): return
	check(false, "Timed out while waiting for input lock: %s" % lock)

func press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func interact(id: StringName) -> void:
	var target: InteractableComponent = chapter.targets[id]
	chapter.player.global_position = target.get_interaction_anchor() + Vector2(0, 32)
	await frames(5)
	check(chapter.interaction_scanner.current_target == target, "Scanner must reach %s from the walkable approach" % id)
	await press(&"interact")
	await settle(&"interaction")

func _run() -> void:
	var state := root.get_node("StoryState")
	var before: Dictionary = state.get_state()
	for choice in 3:
		chapter = load("res://scenes/chapters/chapter_03_garden.tscn").instantiate()
		chapter.persistence_enabled = false
		root.add_child(chapter)
		await settle(&"opening")
		check(chapter.director.current_beat == &"day_waiting", "Opening must begin daylight exploration")
		check(not chapter.targets[&"broken_lantern"].can_interact(), "Night clues must be unavailable during daylight")
		check(not chapter.targets[&"court_road"].can_interact(), "The exit must not skip the chapter")
		# Test different discovery orders with the same mandatory conditions.
		var day_order := [&"waiting_well", &"miriam_day", &"waiting_cloth"] if choice == 0 else [&"waiting_cloth", &"waiting_well", &"miriam_day"]
		for id in day_order: await interact(id)
		check(chapter.director.current_beat == &"dusk", "All daytime evidence must unlock waiting")
		if choice == 0:
			await interact(&"waiting_traveler")
			await interact(&"jonah_day")
		await interact(&"wait_until_night")
		await settle(&"time_change")
		check(chapter.night and chapter.director.current_beat == &"night_rumors", "Waiting must change the same world to night")
		check(not chapter.targets[&"miriam_day"].visible, "Daytime witnesses must leave")
		check(chapter.targets[&"closed_door"].visible, "Door state must change at night")
		var night_order := [&"abandoned_sandal", &"broken_lantern", &"drag_marks"] if choice == 1 else [&"broken_lantern", &"drag_marks", &"abandoned_sandal"]
		for id in night_order: await interact(id)
		check(chapter.director.current_beat == &"night_rumors", "Physical traces alone must not replace testimony")
		await interact(&"jonah_night" if choice == 1 else &"miriam_night")
		check(chapter.director.current_beat == &"route", "Three traces plus either witness must unlock the route")
		if choice == 0:
			await interact(&"closed_door")
			await interact(&"frightened_runner")
			await interact(&"guard_relative")
		await interact(&"route_start")
		var field: Node = chapter.field_investigation
		check(field.active and chapter.player.input_enabled, "Route investigation preserves world movement")
		await interact(&"miriam_night")
		check(chapter.field_investigation == field and field.active and chapter.director.current_beat == &"route", "Revisiting witness keeps the same investigation and phase")
		chapter._open_route()
		check(chapter.field_investigation == field, "Repeated route entry does not duplicate investigation")
		chapter._request_leave_chapter()
		check(not chapter.player.input_enabled, "Leave confirmation suspends field input")
		chapter.leave_confirmation.hide()
		chapter._cancel_leave_chapter()
		check(chapter.player.input_enabled and field.active, "Cancel returns to the same field investigation")
		check(await Support.finish_field(field, chapter.player), "Physical lamp investigation completes")
		await settle(&"dialogue")
		check(chapter.director.current_beat == &"reflection" and chapter.route_line.visible, "Solved route must remain visible in the world")
		await interact(&"court_road")
		check(chapter.choice_panel.visible, "The court road must present three equal choices")
		await frames()
		check(chapter.choice_panel.get_rect().end.y <= root.get_visible_rect().size.y - 16, "Reflection panel must keep its bottom safety margin")
		chapter._unhandled_key_input(_cancel_event())
		check(not chapter.choice_panel.visible and chapter.player.input_enabled, "Closing reflection must allow further exploration")
		await interact(&"court_road")
		var button_names := ["Order", "Prayer", "Uncertain"]
		chapter.get_node("UILayer/ChoicePanel/Box/" + button_names[choice]).pressed.emit()
		await settle(&"choice")
		check(chapter.chosen_action == ChapterThreeData.CHOICES[choice], "Choice buttons must preserve semantic action IDs")
		check(chapter.director.current_beat == &"aftermath", "Every action must return to a reachable exit")
		if choice == 2:
			check(chapter.targets[&"frightened_runner"].modulate.a < 0.05, "Helping must let the runner leave")
		await interact(&"court_road")
		for i in 300:
			await frames()
			if chapter.director.current_beat == &"complete": break
		check(chapter.director.current_beat == &"complete", "All three routes must complete without a blocked cinematic")
		await frames(60)
		chapter.free()
		await frames()
	# A test/review run must never write over the user's story.
	check(state.get_state() == before, "Persistence-disabled playthrough must preserve saved observations and choices")
	var replay := LanternRoutePuzzle.new()
	root.add_child(replay)
	var replay_results: Array[Dictionary] = []
	replay.completed.connect(func(result: Dictionary): replay_results.append(result))
	replay.start({"completed": true, "orientations": [0, 3, 0]})
	check(replay.use_saved.visible, "A completed prior route must offer reuse")
	replay.use_saved.pressed.emit()
	check(replay_results.size() == 1 and replay_results[0].get("reused", false), "Reuse must emit the same completed puzzle contract")
	replay.free()
	check(StoryData.get_definition(3).reflection_choices == ChapterThreeData.CHOICES, "Chapter definitions must expose the three saved action IDs")
	print("Chapter 3 playthrough tests: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _cancel_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	return event
