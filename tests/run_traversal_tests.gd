extends SceneTree

const Story = preload("res://story_data.gd")
const Support = preload("res://tests/polish_support.gd")
var failures := 0
var interactions := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func frames(count := 3) -> void:
	for i in count: await physics_frame

func _run() -> void:
	await _scanner_checks()
	var state: Node = root.get_node("StoryState")
	var before: Dictionary = state.get_state()
	# Keep the same simulation step while running the physical sweep faster.
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = 4.0
	for number in range(1, 2 if "chapter1" in OS.get_cmdline_user_args() else 7):
		var chapter: Node = load(Story.get_scene_path(number)).instantiate()
		chapter.persistence_enabled = false
		root.add_child(chapter)
		await create_timer(1.0).timeout
		var player: CharacterBody2D = chapter.crowd_player if number == 1 else chapter.player
		await Support.reach_exploration(chapter, player)
		check(player.input_enabled, "Chapter %d opens exploration before movement QA" % number)
		var bounds: Rect2 = player.movement_bounds
		player.global_position = Vector2(bounds.position.x + 24, bounds.end.y - 10)
		await frames()
		if number == 1:
			chapter._open_trail_puzzle()
		else:
			chapter.begin_field_investigation(number, chapter.targets.values() if number >= 3 else chapter._world_interactables(), func(_result): pass)
		await frames()
		if number == 2:
			var field: Node = chapter.field_investigation
			check(not field._passage_is_open(), "Temple passage starts physically blocked")
			player.global_position = field.crate.global_position + Vector2(-70, 8)
			await frames()
			Input.action_press("interact")
			Input.action_press("move_right")
			await frames(230)
			Input.action_release("interact")
			Input.action_release("move_right")
			await frames()
			check(field._passage_is_open(), "Physical pushing opens temple traversal")
			player.global_position = Vector2(bounds.position.x + 24, bounds.end.y - 10)
			await frames()
		var route := _check_reachable_clues(chapter, player, number)
		var crossed := await _walk_route(player, route)
		# Roadside architecture occupies the extreme lower-right corner in chapter 1.
		check(crossed and not route.is_empty() and player.global_position.x >= bounds.position.x + bounds.size.x * 0.9, "Chapter %d can be crossed with normal movement around obstacles (x=%.0f)" % [number, player.global_position.x])
		check(player.global_position.y >= bounds.position.y and player.global_position.y <= bounds.end.y, "Movement stays in the authored world bounds")
		chapter.free()
		await frames()
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await create_timer(0.15).timeout
	check(state.get_state() == before, "Traversal validation does not alter story records")
	print("TRAVERSAL TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(1 if failures else 0)

func _check_reachable_clues(chapter: Node, player: CharacterBody2D, number: int) -> PackedVector2Array:
	var bounds: Rect2 = player.movement_bounds
	var feet: CollisionShape2D = player.get_node("CollisionShape2D")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = feet.shape
	query.margin = 4.0
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, floori(bounds.size.x / 16) + 1, floori(bounds.size.y / 16) + 1)
	grid.cell_size = Vector2(16, 16)
	grid.offset = bounds.position
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var point := Vector2i(x, y)
			query.transform = Transform2D(0, grid.get_point_position(point) + feet.position)
			grid.set_point_solid(point, not player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty())
	var reachable: Dictionary = {}
	var start: Vector2i = Vector2i(((player.global_position - bounds.position) / 16).round())
	var queue: Array[Vector2i] = [start]
	reachable[start] = true
	var cursor := 0
	while cursor < queue.size():
		var current := queue[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + direction
			if grid.region.has_point(next) and not reachable.has(next) and not grid.is_point_solid(next):
				reachable[next] = true
				queue.append(next)
	for target in chapter.find_children("*", "Area2D", true, false):
		if not target is InteractableComponent: continue
		var anchor: Vector2 = target.get_interaction_anchor()
		var found := false
		for point in reachable:
			if grid.get_point_position(point).distance_to(anchor) <= 68.0:
				found = true
				break
		check(found, "Chapter %d has a collision-free approach to %s" % [number, target.interaction_id])
	var end := start
	var distance := INF
	for point in reachable:
		var gap: float = grid.get_point_position(point).distance_squared_to(bounds.end - Vector2(16, 16))
		if gap < distance:
			distance = gap
			end = point
	return grid.get_point_path(start, end)

func _walk_route(player: CharacterBody2D, route: PackedVector2Array) -> bool:
	for point in route:
		var reached := false
		for i in 90:
			var offset := point - player.global_position
			for action in ["move_left", "move_right", "move_up", "move_down"]: Input.action_release(action)
			if offset.length() <= 3.0:
				reached = true
				break
			if absf(offset.x) > 2.0: Input.action_press("move_right" if offset.x > 0 else "move_left")
			if absf(offset.y) > 2.0: Input.action_press("move_down" if offset.y > 0 else "move_up")
			await physics_frame
		if not reached:
			print("Blocked travel: ", player.global_position, " -> ", point, " input=", player.input_enabled)
			for i in player.get_slide_collision_count(): print("Contact: ", player.get_slide_collision(i).get_collider().get_path())
			for action in ["move_left", "move_right", "move_up", "move_down"]: Input.action_release(action)
			return false
	for action in ["move_left", "move_right", "move_up", "move_down"]: Input.action_release(action)
	return true

func _scanner_checks() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var scanner := InteractionScanner.new()
	scanner.position = Vector2(300, 500)
	world.add_child(scanner)
	scanner.interaction_requested.connect(func(_target): interactions += 1)
	var targets: Array[InteractableComponent] = []
	for x in [280, 326]:
		var target := InteractableComponent.new()
		target.position = Vector2(x, 500)
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 30
		collision.shape = circle
		target.add_child(collision)
		world.add_child(target)
		targets.append(target)
	await frames()
	check(scanner.current_target == targets[0], "Scanner initially picks the nearest clue")
	scanner.position.x = 304
	await frames()
	check(scanner.current_target == targets[0], "A small movement between nearby clues does not flicker focus")
	scanner.position.x = 318
	await frames()
	check(scanner.current_target == targets[1], "Moving clearly closer selects the other clue")
	targets[1].hide()
	await frames()
	check(scanner.current_target == targets[0], "Hidden clues cannot retain interaction focus")
	targets[0].interaction_enabled = false
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	check(interactions == 0, "E does not activate a target disabled after the last scan")
	world.free()
	await frames()
