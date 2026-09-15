extends SceneTree
var failures := 0
var chapter: Node
var before: Dictionary
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func frames(count := 2) -> void:
	for i in count:
		await physics_frame
		if is_instance_valid(chapter):
			for child in chapter.get_children():
				if child is BibleInterlude: child._advance()
func settle() -> void:
	for i in 1200:
		if is_instance_valid(chapter.speech_bubbles._active_bubble): chapter.speech_bubbles.close_bubble()
		await frames()
		if not chapter.is_input_locked(): return
	check(false, "Dialogue/interlude did not release input")
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
func solve_field(field: FieldInvestigation) -> void:
	if field.has_method("_route_known") or field.has_method("_all_links"):
		check(await preload("res://tests/polish_support.gd").finish_field(field, chapter.player), "Spatial world goals complete")
		await settle()
		return
	check(field.active and chapter.player.input_enabled, "Investigation must allow walking")
	var last: Dictionary = field.steps.back()
	chapter.player.position = field.stations[last.id].position + Vector2(0, 20)
	await frames(4)
	check(not field.use(last.id) and field.done.is_empty(), "Cannot skip prerequisite evidence")
	for step in field.steps:
		print("FIELD ", step.id)
		var target: Node2D = field.stations[step.id]
		chapter.player.position = target.global_position + Vector2(-25, 20)
		await frames(5)
		check(chapter.interaction_scanner.current_target == target, "Scanner reaches " + step.id)
		await press(&"interact")
		if step.kind == "rotate":
			check(not field.done.has(step.id), "First lamp direction is not the solution")
			await press(&"interact")
		if step.kind == "push":
			var origin: Vector2 = target.position
			Input.action_press("interact")
			Input.action_press("move_right")
			await frames(35)
			Input.action_release("interact")
			Input.action_release("move_right")
			var partial: Vector2 = target.position
			await frames(10)
			check(target.position == partial and partial.x > origin.x, "Releasing push preserves partial world movement")
			Input.action_press("interact")
			Input.action_press("move_right")
			await frames(140)
			Input.action_release("interact")
			Input.action_release("move_right")
		check(field.done.has(step.id), "World action completes " + step.id)
		if step.kind == "pickup": check(field.carried_visual.get_parent() == chapter.player, "Carried object follows player")
		if step.kind == "place": check(field.carrying.is_empty(), "Place clears hands")
	check(not field.active and field.done.size() == field.steps.size(), "All field actions complete")
	await settle()
func _run() -> void:
	before = root.get_node("StoryState").get_state().duplicate(true)
	for number in range(2, 7):
		print("TEST CHAPTER ", number)
		chapter = load(StoryData.get_scene_path(number)).instantiate()
		chapter.persistence_enabled = false
		root.add_child(chapter)
		await settle()
		print("OPENED")
		check(chapter.player.sprite.hframes == 4, "Player uses four frame walk in every chapter")
		if number >= 4:
			for id in chapter.config.required:
				var target: InteractableComponent = chapter.targets[id]
				chapter.player.position = target.get_interaction_anchor() + Vector2(0, 28)
				await frames(5)
				await press(&"interact")
				await settle()
			check(chapter.phase == "puzzle", "All observations unlock field investigation")
			chapter._open_puzzle()
		else:
			# Run the reusable mechanic in the real scene, including collisions and camera.
			chapter.begin_field_investigation(number, chapter.targets.values() if number == 3 else chapter._world_interactables(), func(_result): pass)
		await solve_field(chapter.field_investigation)
		if number >= 4:
			check(chapter.phase == "choice", "Physical investigation unlocks reflection")
			chapter._open_choice()
			chapter._choose_action(1)
			await settle()
			check(chapter.phase == "aftermath" and chapter.targets[&"exit"].can_interact(), "Reflection and biblical aftermath unlock exit")
		chapter.free()
		await frames()
	check(root.get_node("StoryState").get_state() == before, "Tests preserve player story state")
	print("BIBLICAL REVISION: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(1 if failures else 0)
