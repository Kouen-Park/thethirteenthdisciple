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
func settle(lock: StringName) -> void:
	for i in 900:
		if is_instance_valid(chapter.speech_bubbles._active_bubble): chapter.speech_bubbles.close_bubble()
		await frames()
		if not chapter.is_input_locked(lock): return
	check(false, "Input lock timed out: " + String(lock))
func interact(id: StringName) -> void:
	var target: InteractableComponent = chapter.targets[id]
	chapter.player.global_position = target.get_interaction_anchor() + Vector2(0, 25)
	await frames(5)
	check(chapter.interaction_scanner.current_target == target, "Scanner reaches " + String(id))
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventAction.new()
	event.action = &"interact"
	event.pressed = false
	Input.parse_input_event(event)
	await settle(&"interaction")
func _run() -> void:
	var state := root.get_node("StoryState")
	var before: Dictionary = state.get_state().duplicate(true)
	var paths := ["chapter_04_trial", "chapter_05_golgotha", "chapter_06_resurrection"]
	for number in range(4, 7):
		for choice in 3:
			chapter = load("res://scenes/chapters/" + paths[number - 4] + ".tscn").instantiate()
			chapter.persistence_enabled = false
			root.add_child(chapter)
			await settle(&"opening")
			check(chapter.phase == "explore", "Opening unlocks exploration")
			check(not chapter.targets[&"exit"].can_interact(), "Cannot skip evidence or reflection")
			var ids: Array = chapter.config.required.duplicate()
			if choice == 1: ids.reverse()
			for id in ids: await interact(id)
			check(chapter.phase == "puzzle", "Required evidence unlocks puzzle")
			await interact(&"reflection")
			check(chapter.field_investigation.active and chapter.player.input_enabled, "Field puzzle allows walking")
			var field: Node = chapter.field_investigation
			var wrong_a: String = field.config.sources[0].id
			var wrong_b: String = field.config.sources[2].id
			chapter.player.global_position = field.stations[wrong_a].global_position + Vector2(0, 25)
			await frames(3)
			field.use(wrong_a)
			chapter.player.global_position = field.stations[wrong_b].global_position + Vector2(0, 25)
			await frames(3)
			field.use(wrong_b)
			check(field.accepted.is_empty() and field.mistakes == 1, "Unrelated records do not count as evidence")
			check(await Support.finish_field(chapter.field_investigation, chapter.player), "All on-site actions finish")
			check(chapter.phase == "choice", "Puzzle unlocks reflection")
			await interact(&"reflection")
			check(chapter.choice_panel.visible, "Choice visible")
			var cancel := InputEventAction.new()
			cancel.action = &"ui_cancel"
			cancel.pressed = true
			chapter._unhandled_key_input(cancel)
			check(not chapter.choice_panel.visible and chapter.player.input_enabled, "Choice can be canceled")
			await interact(&"reflection")
			chapter._choose_action(choice)
			await settle(&"aftermath")
			check(chapter.chosen_action == chapter.choice_data.choice_ids[choice], "Semantic choice retained")
			check(chapter.phase == "aftermath" and chapter.targets[&"exit"].can_interact(), "Every choice reaches exit")
			chapter._request_leave_chapter()
			chapter.leave_confirmation.hide()
			chapter._cancel_leave_chapter()
			check(not chapter.is_input_locked() and chapter.player.input_enabled, "Cancel leave restores locks")
			await interact(&"exit")
			await create_timer(1.0).timeout
			check(chapter.transitioning, "Exit starts completion fade")
			chapter.free()
			await frames()
	var epilogue: Node = load("res://scenes/chapters/epilogue.tscn").instantiate()
	epilogue.persistence_enabled = false
	root.add_child(epilogue)
	check(epilogue.lines.size() >= 5, "Epilogue contains memories and open questions")
	epilogue.index = epilogue.lines.size() - 1
	epilogue.typing = false
	epilogue._advance()
	check(epilogue.credits_visible, "Final question leads to credits")
	epilogue.free()
	check(state.get_state() == before, "Playthrough tests preserve existing progress")
	print("LATE CHAPTER PLAYTHROUGHS: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(1 if failures else 0)
