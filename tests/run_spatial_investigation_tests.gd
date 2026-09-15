extends SceneTree
const Spatial = preload("res://scripts/spatial_investigation.gd")
var failures := 0
var host: Node2D
var player: CrowdPlayerController
var field: FieldInvestigation
var emitted := 0
class Host extends Node2D:
	var persistence_enabled := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(n := 3) -> void:
	for i in n: await physics_frame
func setup(number: int) -> void:
	host = Host.new()
	root.add_child(host)
	player = load("res://scenes/common/crowd_player.tscn").instantiate()
	host.add_child(player)
	player.get_node("InteractionScanner").interaction_requested.connect(func(target): target.interact())
	player.movement_bounds = Rect2(40, 400, 1950, 290)
	var label := Label.new()
	host.add_child(label)
	field = Spatial.new()
	host.add_child(field)
	field.completed.connect(func(_result): emitted += 1)
	field.start(number, player, label, [])
	await frames()
func hold(keys: Array, n: int) -> void:
	for key in keys: Input.action_press(key)
	await frames(n)
	for key in keys: Input.action_release(key)
	await frames()
func use_at(id: String) -> void:
	player.position = field.stations[id].position + Vector2(0, 25)
	await frames()
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventAction.new()
	event.action = &"interact"
	event.pressed = false
	Input.parse_input_event(event)
	await frames()
func run() -> void:
	await setup(2)
	check(not field._passage_is_open(), "Crate really blocks doorway")
	player.position = Vector2(1020, 628)
	await hold(["move_right"], 80)
	check(player.position.x < 1062, "Walking cannot cross crate")
	player.position = Vector2(1000, 628)
	var before: Vector2 = field.crate.position
	await hold(["interact", "move_left"], 15)
	check(field.crate.position == before, "Remote/opposite direction cannot push")
	player.position = Vector2(1030, 628)
	await hold(["interact", "move_right"], 70)
	check(field.crate.position.x > 1130, "Contact input moves physical crate")
	var partial: Vector2 = field.crate.position
	await hold([], 10)
	check(field.crate.position == partial and player.speed == 150, "Release stops push and restores speed")
	player.input_enabled = false
	await hold(["interact", "move_right"], 10)
	check(field.crate.position == partial, "Input lock stops push")
	player.input_enabled = true
	paused = true
	await create_timer(0.1, true).timeout
	check(field.crate.position == partial and player.speed == 150, "Tree pause freezes crate and restores speed")
	paused = false
	await hold(["interact", "move_right"], 130)
	check(field._passage_is_open(), "Sweep confirms actual passage after pushing")
	# Walk through opening and around the displaced crate, without teleporting across it.
	await hold(["move_down"], 22)
	await hold(["move_right"], 90)
	check(player.position.x > 1300, "Player can traverse opened space")
	player.position = field.crate.position + Vector2(70, 8)
	await hold(["interact", "move_left"], 30)
	check(field.crate.position.x < 1265, "Crate can be pushed back from opposite side")
	await use_at("coin_lot")
	field.return_item()
	check(field.carrying.is_empty() and not field.done.has("coin_lot"), "Return restores source pickup")
	await use_at("coin_lot")
	await use_at("return_coins")
	# Reopen if the reverse move closed the approach.
	player.position = field.crate.position + Vector2(-70, 8)
	await hold(["interact", "move_right"], 100)
	await use_at("mat")
	await use_at("prayer_space")
	check(not field.active and emitted == 1, "World goals complete once without optional inspections")
	for station in field.stations.values(): check(not station.get_node("Caption").visible, "Completion removes captions")
	host.free()
	await frames()
	await setup(3)
	await use_at("side_path")
	check(not field.done.has("side_path"), "Dark clue cannot be inspected")
	await use_at("working_lamp")
	await use_at("lamp_rest")
	await frames()
	check(field.is_lit(field.stations.crowd_path.global_position), "East beam reveals east clue")
	check(not field.is_lit(field.stations.side_path.global_position), "Outside cone stays hidden")
	await use_at("crowd_path")
	await use_at("lamp_rest")
	await use_at("lamp_rest")
	check(field.is_lit(field.stations.side_path.global_position), "Rotated beam reveals north clue")
	check(field.done.has("crowd_path"), "Turning light preserves discovered record")
	await use_at("side_path")
	# Insert an actual wall into the ray path and check the displayed polygon as well.
	field._block(Rect2(1310, 500, 40, 20))
	await frames()
	check(not field.is_lit(field.stations.side_path.global_position), "Wall occludes light and clue")
	await use_at("wrong_road")
	check(field.active, "Wrong path permits return without completing")
	await use_at("torch_watch")
	player.position = Vector2(1740, 610)
	await hold(["move_right"], 42)
	check(not field.active and emitted == 2, "Walking to supported destination completes route once")
	await frames(20)
	check(emitted == 2, "Completion cannot repeat")
	host.free()
	print("SPATIAL INVESTIGATION: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(1 if failures else 0)
