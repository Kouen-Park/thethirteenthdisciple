extends FieldInvestigation
## Chapters 2–3 share reversible tools, but complete from world state.
var chapter_number := 0
var crate: CharacterBody2D
var crate_visual: Sprite2D
var lamp_on := false
var lamp_angle := 0.0
var beam_polygon := PackedVector2Array()
var source_id := ""
var hint_index := 0
var passage_open := false
var spatial_art: Node2D
const LAMP := Vector2(1330, 610)
const PASSAGE_X := 1100.0
const BEAM_RANGE := 280.0
const BEAM_HALF_ANGLE := 0.32


func start(number: int, player_node: Node2D, hud: Label, existing: Array) -> void:
	chapter_number = number
	super.start(number, player_node, hud, existing)
	spatial_art = Node2D.new()
	spatial_art.z_index = 0
	spatial_art.draw.connect(_draw_space)
	add_child(spatial_art)
	for station in stations.values():
		station.focus_changed.connect(func(focused: bool):
			if station.has_node("Prop"):
				station.get_node("Prop").modulate = Color(1.25, 1.15, 0.8) if focused and get_node("/root/GameState").interaction_emphasis > 0 else Color.WHITE)
	if number == 2:
		# A visible screen spans the walkable courtyard, leaving one 64px opening.
		# Market debris divides the court, leaving one narrow gap that the crate blocks.
		_block(Rect2(1062, 386, 76, 202), &"market_debris")
		_block(Rect2(1062, 652, 76, 28), &"market_debris")
		crate = CharacterBody2D.new()
		crate.position = stations.table_move.position
		crate.collision_layer = 1
		crate.collision_mask = 1
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(108, 38)
		shape.shape = box
		crate.add_child(shape)
		add_child(crate)
		var original_table := get_parent().get_node_or_null("EmptyTable") as InteractableComponent
		if original_table:
			crate_visual = original_table.get_node_or_null("Visual") as Sprite2D
			if crate_visual:
				crate_visual.reparent(crate)
				crate_visual.position = Vector2(0, -30)
			var old_body := original_table.get_node_or_null("Body") as StaticBody2D
			if old_body:
				old_body.collision_layer = 0
		stations.table_move.get_node("Prop").hide()
	else:
		_block(Rect2(1290, 410, 170, 20), &"stone_wall")
	_hint("주변 공간과 흔적을 살펴보세요. E 사용 · R 물건 돌려놓기 · H 도움 · J 기록\n주변 도구와 조사 행동은 창작입니다.")

func _block(rect: Rect2, visual_kind: StringName = &"plain") -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	body.set_meta("rect", rect)
	body.set_meta("visual_kind", visual_kind)
	add_child(body)

func use(id: String) -> bool:
	if not active or not actor.input_enabled or not stations.has(id): return false
	if actor.global_position.distance_to(stations[id].global_position) > 90: return false
	if chapter_number == 3:
		if id in ["side_path", "crowd_path"] and not is_lit(stations[id].global_position): return false
		if id == "lamp_rest" and lamp_on:
			lamp_angle = wrapf(lamp_angle - PI / 4, -PI, PI)
			_hint("빛이 움직였다. 드러난 흔적을 가까이에서 살펴보자.")
			return true
		if id == "court_direction":
			_hint("큰길이다. 발자국과 멀리 보이는 횃불을 확인한 뒤 직접 걸어가 보자.")
			return false
	if chapter_number == 2:
		if id == "table_move":
			focused_action = id
			_hint("받침 옆에서 E를 누른 채 받침을 향해 걸으세요. 양쪽에서 밀 수 있습니다.")
			return false
		if id == "mat" and (not passage_open or actor.global_position.x < 1140):
			_hint("먼저 받침 뒤 공간으로 들어가야 한다.")
			return false
	var step := _step(id)
	var used := super.use(id)
	if used and step.kind == "pickup":
		source_id = id
	if used and step.kind == "place":
		source_id = ""
		if id == "lamp_rest": lamp_on = true
	return used

func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not actor.input_enabled or not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey and event.physical_keycode == KEY_R:
		return_item()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_H:
		var hints := ["긁힌 자국과 받침 주변의 빈 공간을 살펴보세요.", "받침 옆에 서서 E와 받침을 향하는 이동키를 함께 누르세요.", "받침 뒤로 지나간 다음 깔개를 가져오세요. 동전 정리는 언제든 할 수 있습니다."] if chapter_number == 2 else ["등불과 등불을 놓을 받침을 찾아보세요.", "받침에 놓은 등불은 E로 돌릴 수 있습니다. 빛이 닿은 두 갈래 흔적을 살펴보세요.", "많은 발자국과 멀리 움직이는 횃불을 함께 확인하고 큰길로 걸어가세요."]
		_hint(hints[mini(hint_index, hints.size() - 1)])
		hint_index += 1
		get_viewport().set_input_as_handled()

func return_item() -> void:
	if source_id.is_empty() or not is_instance_valid(carried_visual): return
	carried_visual.reparent(stations[source_id])
	carried_visual.position = Vector2.ZERO
	stations[source_id].interaction_enabled = true
	done.erase(source_id)
	stations[source_id].prompt_text = _step(source_id).label
	carrying = ""
	carried_visual = null
	source_id = ""
	_hint("물건을 원래 자리에 돌려놓았다.")

func _physics_process(delta: float) -> void:
	if not active: return
	actor.speed = normal_speed
	if not actor.input_enabled:
		focused_action = ""
		return
	feedback_seconds = maxf(0, feedback_seconds - delta)
	if chapter_number == 2:
		_push(delta)
		passage_open = _passage_is_open()
		if passage_open and not done.has("table_move"): _mark_done("table_move")
	else:
		_update_beam()
		for id in ["side_path", "crowd_path"]:
			var lit := is_lit(stations[id].global_position)
			stations[id].visible = lit
			stations[id].interaction_enabled = lit
		stations.wrong_road.visible = done.has("side_path")
		stations.wrong_road.interaction_enabled = done.has("side_path")
		if _route_known() and actor.global_position.distance_to(stations.court_direction.global_position) < 38:
			_mark_done("court_direction")
	if not active: return
	for station in stations.values():
		station.get_node("Caption").visible = station.visible and actor.global_position.distance_to(station.global_position) < 125
	if feedback_seconds == 0:
		objective.text = ("동전을 회수용 천에 모으고, 통로 뒤의 깔개를 벽 곁에 펼치세요." if chapter_number == 2 else "등불로 갈림길을 살피고, 발자국과 횃불이 이어지는 길을 찾으세요.") + " · H 도움 · R 물건 반환"
	spatial_art.queue_redraw()

func _push(delta: float) -> void:
	if not Input.is_action_pressed("interact"):
		focused_action = ""
		return
	var direction := Input.get_axis("move_left", "move_right")
	var offset: Vector2 = crate.global_position - (actor.global_position + Vector2(0, -8))
	# Contact on a side, facing into the body; never drag from across a gap.
	if absf(offset.y) > 22 or absf(offset.x) > 72 or absf(offset.x) < 64 or direction * offset.x <= 0: return
	actor.speed = 45
	var motion := Vector2(direction * 45 * delta, 0)
	motion.x = clampf(crate.position.x + motion.x, 1000, 1280) - crate.position.x
	crate.move_and_collide(motion)
	stations.table_move.position = crate.position

func _passage_is_open() -> bool:
	# Sweep the player's actual collision shape through the doorway.
	var collision: CollisionShape2D = actor.get_node("CollisionShape2D")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = Transform2D(0, Vector2(PASSAGE_X - 65, 620))
	query.motion = Vector2(115, 0)
	query.collision_mask = 1
	query.exclude = [actor.get_rid()]
	if not get_world_2d().direct_space_state.intersect_shape(query).is_empty(): return false
	var sweep := get_world_2d().direct_space_state.cast_motion(query)
	return sweep[0] >= 1.0

func _update_beam() -> void:
	beam_polygon = PackedVector2Array([LAMP])
	if not lamp_on: return
	for i in 33:
		var angle := lamp_angle - BEAM_HALF_ANGLE + 2 * BEAM_HALF_ANGLE * i / 32.0
		var end := LAMP + Vector2.from_angle(angle) * BEAM_RANGE
		var query := PhysicsRayQueryParameters2D.create(to_global(LAMP), to_global(end), 1)
		query.exclude = [actor.get_rid()]
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		beam_polygon.append(to_local(hit.position) if not hit.is_empty() else end)

func is_lit(point: Vector2) -> bool:
	return lamp_on and beam_polygon.size() > 2 and Geometry2D.is_point_in_polygon(to_local(point), beam_polygon)

func _route_known() -> bool:
	return done.has("side_path") and done.has("crowd_path") and done.has("torch_watch")

func _is_complete() -> bool:
	if chapter_number == 2: return passage_open and done.has("return_coins") and done.has("prayer_space")
	return _route_known() and done.has("court_direction")

func _draw() -> void:
	pass

func _draw_prop(prop: Node2D, step: Dictionary) -> void:
	if step.id in ["side_path", "crowd_path"]:
		var direction := Vector2.UP if step.id == "side_path" else Vector2.RIGHT
		var across := direction.orthogonal()
		for i in (3 if step.id == "side_path" else 7):
			var point := direction * (i * 8 - 20) + across * (5 if i % 2 else -5)
			prop.draw_line(point, point + direction * 5, Color("c0a780"), 3)
		return
	if step.id == "lamp_rest":
		prop.draw_rect(Rect2(-16, -5, 32, 10), Color("776455"))
		return
	if step.art == "lamp":
		prop.draw_circle(Vector2(0, -5), 8, Color("95683e"))
		prop.draw_circle(Vector2(0, -11), 4, Color("f4c873"))
		return
	super._draw_prop(prop, step)

func _draw_space() -> void:
	for child in get_children():
		if child.has_meta("rect"):
			var rect: Rect2 = child.get_meta("rect")
			var visual_kind: StringName = child.get_meta("visual_kind")
			if visual_kind == &"market_debris":
				if rect.size.y > 60:
					var screen := PackedVector2Array([
						rect.position + Vector2(8, 0), rect.position + Vector2(rect.size.x - 5, 7),
						rect.end - Vector2(8, 0), Vector2(rect.position.x + 4, rect.end.y - 10)])
					spatial_art.draw_colored_polygon(screen, Color("675044"))
					spatial_art.draw_polyline(screen + PackedVector2Array([screen[0]]), Color("342b2a"), 5)
					for y in range(int(rect.position.y) + 24, int(rect.end.y), 30):
						spatial_art.draw_line(Vector2(rect.position.x + 10, y), Vector2(rect.end.x - 9, y + 5), Color("8d7060"), 3)
					spatial_art.draw_line(rect.position + Vector2(10, 4), rect.end - Vector2(8, 3), Color("44352f"), 5)
				else:
					for x in [rect.position.x + 20, rect.end.x - 20]:
						var center := Vector2(x, rect.get_center().y)
						spatial_art.draw_circle(center, 13, Color("6f5037"))
						spatial_art.draw_arc(center, 10, 0, TAU, 12, Color("a98255"), 3)
			elif visual_kind == &"stone_wall":
				spatial_art.draw_rect(rect, Color("655f59"))
				spatial_art.draw_rect(rect.grow(-3), Color("958a7b"), false, 3)
				for x in range(int(rect.position.x) + 8, int(rect.end.x), 30):
					spatial_art.draw_line(Vector2(x, rect.position.y + 2), Vector2(x, rect.end.y - 2), Color("514a46"), 2)
	if chapter_number == 2:
		for y in [604, 636]: spatial_art.draw_line(Vector2(1010, y), Vector2(1300, y), Color("b39a73"), 2)
		if not is_instance_valid(crate_visual):
			var rect := Rect2(crate.position - Vector2(54, 19), Vector2(108, 38))
			spatial_art.draw_rect(rect, Color("4b3529"))
			for y in range(4, 38, 10): spatial_art.draw_rect(Rect2(rect.position + Vector2(3, y), Vector2(102, 7)), Color("9b744d"))
	else:
		if beam_polygon.size() > 2: spatial_art.draw_colored_polygon(beam_polygon, Color(0.96, 0.78, 0.4, 0.25))
		for i in 4:
			spatial_art.draw_line(Vector2(1740 + i * 18, 485), Vector2(1740 + i * 18, 470), Color("5a4131"), 3)
			spatial_art.draw_circle(Vector2(1740 + i * 18, 468), 3, Color("e6ae55"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		focused_action = ""
		if is_instance_valid(actor): actor.speed = normal_speed
