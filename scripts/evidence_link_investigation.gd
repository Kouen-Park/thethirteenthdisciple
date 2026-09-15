extends FieldInvestigation

const Data = preload("res://scripts/evidence_link_data.gd")
var chapter_number := 0
var config: Dictionary
var selected_id := ""
var accepted: Dictionary = {}
var mistakes := 0
var hint_index := 0
var art: Node2D
var goal: InteractableComponent
var hidden_targets: Dictionary = {}

func start(number: int, player_node: Node2D, hud: Label, existing: Array) -> void:
	chapter_number = number
	actor = player_node
	normal_speed = actor.speed
	objective = hud
	config = Data.get_data(number)
	active = true
	_prepare_world_targets(existing)
	art = Node2D.new()
	art.draw.connect(_draw_links)
	add_child(art)
	for source: Dictionary in config.sources:
		var marker := _create_marker(source)
		stations[source.id] = marker
	goal = _create_marker({"id": "destination", "pos": config.destination, "label": config.destination_label, "detail": "", "art": "destination"})
	goal.interaction_enabled = false
	goal.hide()
	_restore_checkpoint()
	_update_goal()
	_hint(config.instruction + "\n성경 사건의 결과는 바뀌지 않으며, 연결 행동은 창작 체험입니다.")

func _prepare_world_targets(existing: Array) -> void:
	for target in existing:
		if not target is InteractableComponent:
			continue
		if target.has_meta("display_name"):
			repeatable_targets[target] = target.one_shot
			target.one_shot = false
			target.monitorable = true
		else:
			disabled_targets[target] = target.interaction_enabled
			target.interaction_enabled = false
			hidden_targets[target] = target.visible
			target.hide()

func _create_marker(source: Dictionary) -> InteractableComponent:
	var marker := InteractableComponent.new()
	marker.interaction_id = StringName("evidence_" + source.id)
	marker.position = source.pos
	marker.prompt_text = source.label
	marker.dim_on_use = false
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 32
	shape.shape = circle
	marker.add_child(shape)
	var visual := Node2D.new()
	visual.name = "EvidenceVisual"
	visual.draw.connect(_draw_marker.bind(visual, source))
	marker.add_child(visual)
	var caption := Label.new()
	caption.name = "Caption"
	caption.position = Vector2(-110, 20)
	caption.size.x = 220
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.text = source.label
	caption.add_theme_font_size_override("font_size", roundi(14 * get_node("/root/GameState").text_scale))
	caption.add_theme_color_override("font_color", Color("e7bd72"))
	caption.add_theme_color_override("font_shadow_color", Color("211c28"))
	caption.add_theme_constant_override("shadow_offset_y", 2)
	marker.add_child(caption)
	add_child(marker)
	marker.interacted.connect(func(_id, _payload): use(source.id))
	marker.focus_changed.connect(func(_focused): art.queue_redraw())
	return marker

func use(id: String) -> bool:
	if not active or not actor.input_enabled or not stations.has(id):
		return false
	var marker: InteractableComponent = stations[id]
	if actor.global_position.distance_to(marker.global_position) > 90:
		return false
	if selected_id.is_empty():
		selected_id = id
		_hint(_source(id).detail + "\n연결할 다른 기록까지 걸어가 E를 누르세요. R 선택 해제")
		_save_checkpoint()
		art.queue_redraw()
		return true
	if selected_id == id:
		selected_id = ""
		_hint("연결 선택을 해제했습니다.")
		_save_checkpoint()
		art.queue_redraw()
		return false
	var link := _find_link(selected_id, id)
	if link.is_empty():
		mistakes += 1
		selected_id = ""
		_hint("두 기록만으로는 같은 사건 관계를 확인할 수 없습니다. 현장에서 각각의 출처를 다시 살펴보세요.")
		_save_checkpoint()
		art.queue_redraw()
		return false
	var key := _pair_key(link.first, link.second)
	accepted[key] = true
	selected_id = ""
	_record_link(link, key)
	_hint(link.result)
	_update_goal()
	art.queue_redraw()
	return true

func _physics_process(delta: float) -> void:
	if not active:
		return
	actor.speed = normal_speed
	feedback_seconds = maxf(0, feedback_seconds - delta)
	for marker in stations.values():
		marker.get_node("Caption").visible = marker.visible and actor.global_position.distance_to(marker.global_position) < 135
	if goal.visible:
		goal.get_node("Caption").visible = actor.global_position.distance_to(goal.global_position) < 170
		if actor.global_position.distance_to(goal.global_position) < 42:
			_finish()
			return
	if feedback_seconds == 0:
		objective.text = "관련된 두 기록을 현장에서 연결하세요. · E 선택 · R 해제 · H 도움 · J 기록"

func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not actor.input_enabled or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey and event.physical_keycode == KEY_R:
		selected_id = ""
		_hint("연결 선택을 해제했습니다.")
		_save_checkpoint()
		art.queue_redraw()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.physical_keycode == KEY_H:
		var hints: Array = config.hints
		_hint(hints[mini(hint_index, hints.size() - 1)])
		hint_index += 1
		get_viewport().set_input_as_handled()

func _all_links() -> bool:
	return accepted.size() == config.links.size()

func _update_goal() -> void:
	goal.visible = _all_links()
	goal.interaction_enabled = false
	if _all_links():
		objective.text = "기록의 관계를 확인했습니다. 표시된 길까지 직접 걸어가세요."

func _finish() -> void:
	if not active:
		return
	active = false
	actor.speed = normal_speed
	for marker in stations.values():
		marker.interaction_enabled = false
		marker.get_node("Caption").hide()
	goal.get_node("Caption").hide()
	_restore_world_targets()
	var host := get_parent()
	if host.persistence_enabled:
		get_node("/root/StoryState").clear_checkpoint(host.chapter_id, &"evidence_link")
		get_node("/root/GameState").save_progress()
	completed.emit({"completed": true, "links": accepted.keys(), "mistakes": mistakes, "mode": "evidence_link"})

func _record_link(link: Dictionary, key: String) -> void:
	var host := get_parent()
	if host.persistence_enabled:
		get_node("/root/StoryState").record_observation(host.chapter_id, StringName("evidence_link_" + key), {
			"title": "연결한 기록 · %s ↔ %s" % [_source(link.first).label, _source(link.second).label],
			"description": link.result,
			"data": {"kind": "성경 본문에 근거한 현장 연결"}
		})
	_save_checkpoint()

func _save_checkpoint() -> void:
	var host := get_parent()
	if not host.persistence_enabled:
		return
	get_node("/root/StoryState").set_checkpoint(host.chapter_id, &"evidence_link", {
		"accepted": accepted.keys(), "selected": selected_id, "mistakes": mistakes
	})
	get_node("/root/GameState").save_progress()

func _restore_checkpoint() -> void:
	var host := get_parent()
	if not host.persistence_enabled:
		return
	var saved: Dictionary = get_node("/root/StoryState").get_checkpoint(host.chapter_id, &"evidence_link")
	for key in saved.get("accepted", []):
		accepted[str(key)] = true
	selected_id = str(saved.get("selected", ""))
	if not stations.has(selected_id):
		selected_id = ""
	mistakes = int(saved.get("mistakes", 0))

func _source(id: String) -> Dictionary:
	for source: Dictionary in config.sources:
		if source.id == id:
			return source
	return {}

func _find_link(first: String, second: String) -> Dictionary:
	var key := _pair_key(first, second)
	for link: Dictionary in config.links:
		if _pair_key(link.first, link.second) == key:
			return link
	return {}

func _pair_key(first: String, second: String) -> String:
	return first + "__" + second if first < second else second + "__" + first

func _draw_links() -> void:
	for link: Dictionary in config.links:
		var key := _pair_key(link.first, link.second)
		if accepted.has(key):
			art.draw_dashed_line(stations[link.first].position, stations[link.second].position, Color("e7bd72"), 4, 10)
	if not selected_id.is_empty() and stations.has(selected_id):
		art.draw_arc(stations[selected_id].position, 31, 0, TAU, 28, Color("fff0a8"), 4)
	if is_instance_valid(goal) and goal.visible:
		art.draw_arc(goal.position, 28, 0, TAU, 24, Color(0.93, 0.75, 0.38, 0.85), 3)

func _draw_marker(canvas: Node2D, source: Dictionary) -> void:
	var gold := Color("d4aa68")
	var ink := Color("3a3032")
	match source.art:
		"question":
			canvas.draw_arc(Vector2.ZERO, 13, -2.6, 0.7, 18, gold, 4)
			canvas.draw_circle(Vector2(0, 19), 3, gold)
		"voices":
			for i in 3: canvas.draw_arc(Vector2(i * 7 - 8, 0), 8 + i * 3, -0.8, 0.8, 12, gold, 3)
		"gate", "stone", "tomb":
			canvas.draw_rect(Rect2(-17, -13, 34, 26), ink)
			canvas.draw_rect(Rect2(-13, -9, 26, 18), gold, false, 3)
		"escort", "person", "soldier":
			canvas.draw_circle(Vector2(0, -11), 7, gold)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-9, -3), Vector2(9, -3), Vector2(14, 17), Vector2(-14, 17)]), ink)
		"trail":
			for i in 4: canvas.draw_line(Vector2(i * 9 - 19, -12 + i * 6), Vector2(i * 9 - 12, -7 + i * 6), gold, 4)
		"cloth", "linen":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-18, -8), Vector2(12, -13), Vector2(20, 10), Vector2(-13, 14)]), Color("c9bda0"))
		"record":
			canvas.draw_rect(Rect2(-18, -13, 36, 26), Color("d0bd91"))
			for y in [-6, 1, 8]: canvas.draw_line(Vector2(-12, y), Vector2(11, y), ink, 2)
		"destination":
			canvas.draw_line(Vector2(-20, 0), Vector2(20, 0), gold, 4)
			canvas.draw_line(Vector2(10, -10), Vector2(20, 0), gold, 4)
			canvas.draw_line(Vector2(10, 10), Vector2(20, 0), gold, 4)
		_:
			canvas.draw_circle(Vector2.ZERO, 14, gold)

func _exit_tree() -> void:
	if is_instance_valid(actor):
		actor.speed = normal_speed
	_restore_world_targets()

func _restore_world_targets() -> void:
	super._restore_world_targets()
	for target in hidden_targets:
		if is_instance_valid(target):
			target.visible = hidden_targets[target]
	hidden_targets.clear()
