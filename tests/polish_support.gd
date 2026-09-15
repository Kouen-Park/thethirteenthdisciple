extends RefCounted

static func interlude(host: Node) -> Node:
	for child in host.get_children():
		if child is CanvasLayer and "ready_to_advance" in child and child.has_method("_advance"):
			return child
	return null

static func advance_interlude(host: Node) -> void:
	var scene := interlude(host)
	if is_instance_valid(scene) and scene.ready_to_advance: scene._advance()

static func reach_dialogue(host: Node) -> bool:
	for i in 240:
		advance_interlude(host)
		if is_instance_valid(host.speech_bubbles._active_bubble): return true
		await host.get_tree().physics_frame
	return false

static func reach_exploration(host: Node, actor: Node) -> bool:
	for i in 300:
		advance_interlude(host)
		if is_instance_valid(host.speech_bubbles._active_bubble): host.speech_bubbles.close_bubble()
		await host.get_tree().physics_frame
		if actor.input_enabled: return true
	return false

static func finish_field(field: Node, player: Node) -> bool:
	var tree: SceneTree = player.get_tree()
	if field.has_method("_route_known"):
		return await finish_spatial(field, player)
	if field.has_method("_all_links"):
		return await finish_evidence(field, player)
	for step in field.steps:
		var target: Node2D = field.stations[step.id]
		player.global_position = target.global_position + Vector2(-25, 20)
		for i in 5: await tree.physics_frame
		field.use(step.id)
		if step.kind == "rotate": field.use(step.id)
		if step.kind == "push":
			Input.action_press("interact")
			Input.action_press("move_right")
			for i in 145: await tree.physics_frame
			Input.action_release("interact")
			Input.action_release("move_right")
		if not field.done.has(step.id): return false
	return not field.active

static func finish_evidence(field: Node, player: Node) -> bool:
	for link: Dictionary in field.config.links:
		await spatial_use(field, player, link.first)
		await spatial_use(field, player, link.second)
	if not field._all_links():
		return false
	player.global_position = field.config.destination + Vector2(-85, 0)
	for i in 5: await player.get_tree().physics_frame
	Input.action_press("move_right")
	for i in 50: await player.get_tree().physics_frame
	Input.action_release("move_right")
	for i in 5: await player.get_tree().physics_frame
	return not field.active

static func spatial_use(field: Node, player: Node, id: String) -> void:
	player.global_position = field.stations[id].global_position + Vector2(0, 25)
	for i in 5: await player.get_tree().physics_frame
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
	for i in 2: await player.get_tree().physics_frame
	event = InputEventAction.new()
	event.action = &"interact"
	event.pressed = false
	Input.parse_input_event(event)
	for i in 3: await player.get_tree().physics_frame

static func finish_spatial(field: Node, player: Node) -> bool:
	if field.chapter_number == 2:
		# Independent coin branch first; push uses real player physics.
		await spatial_use(field, player, "coin_lot")
		await spatial_use(field, player, "return_coins")
		player.global_position = field.crate.global_position + Vector2(-70, 8)
		for i in 5: await player.get_tree().physics_frame
		Input.action_press("interact")
		Input.action_press("move_right")
		for i in 230: await player.get_tree().physics_frame
		Input.action_release("interact")
		Input.action_release("move_right")
		for i in 5: await player.get_tree().physics_frame
		if not field.passage_open: return false
		await spatial_use(field, player, "mat")
		await spatial_use(field, player, "prayer_space")
	else:
		await spatial_use(field, player, "working_lamp")
		await spatial_use(field, player, "lamp_rest")
		await spatial_use(field, player, "crowd_path")
		await spatial_use(field, player, "lamp_rest")
		await spatial_use(field, player, "lamp_rest")
		await spatial_use(field, player, "side_path")
		await spatial_use(field, player, "torch_watch")
		player.global_position = Vector2(1750, 610)
		Input.action_press("move_right")
		for i in 45: await player.get_tree().physics_frame
		Input.action_release("move_right")
	return not field.active
