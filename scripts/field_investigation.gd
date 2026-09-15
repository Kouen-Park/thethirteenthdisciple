class_name FieldInvestigation
extends Node2D

signal completed(result: Dictionary)
var active := false
var steps: Array = []
var done: Dictionary = {}
var stations: Dictionary = {}
var disabled_targets: Dictionary = {}
var repeatable_targets: Dictionary = {}
var actor: Node2D
var objective: Label
var carrying := ""
var carried_visual: Node2D
var rotations: Dictionary = {}
var focused_action := ""
var work := 0.0
var normal_speed := 150.0
var feedback_seconds := 0.0

func start(number: int, player_node: Node2D, hud: Label, existing: Array) -> void:
	if active: return
	actor = player_node
	normal_speed = actor.speed
	objective = hud
	steps = _get_steps(number)
	active = true
	for target in existing:
		if not target is InteractableComponent:
			continue
		var is_revisitable_witness: bool = number in [2, 3] and (
			target.has_meta("display_name")
			or target.interaction_id in [&"merchant_jonah", &"miriam", &"temple_guard"]
		)
		if is_revisitable_witness:
			repeatable_targets[target] = target.one_shot
			target.one_shot = false
			target.monitorable = true
		else:
			disabled_targets[target] = target.interaction_enabled
			target.interaction_enabled = false
	for step in steps:
		var target := InteractableComponent.new()
		target.interaction_id = StringName("field_" + step.id)
		target.position = step.pos
		target.prompt_text = step.label
		target.dim_on_use = false
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 30
		shape.shape = circle
		target.add_child(shape)
		var prop := Node2D.new()
		prop.name = "Prop"
		prop.draw.connect(_draw_prop.bind(prop, step))
		target.add_child(prop)
		var caption := Label.new()
		caption.name = "Caption"
		caption.position = Vector2(-105, 17)
		caption.size.x = 210
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.text = step.label
		caption.add_theme_font_size_override("font_size", roundi(14 * get_node("/root/GameState").text_scale))
		caption.add_theme_color_override("font_color", Color("e7bd72"))
		caption.add_theme_color_override("font_shadow_color", Color("211c28"))
		caption.add_theme_constant_override("shadow_offset_y", 2)
		target.add_child(caption)
		add_child(target)
		target.interacted.connect(func(_id, _data): use(step.id))
		stations[step.id] = target
	var introductions := {
		1: "환영의 길 만들기 · 먼저 발자국의 방향을 살피세요. E 조사/운반 · J 기록",
		2: "성전 뜰 정돈하기 · 통로를 비우고, 동전과 깔개를 알맞은 자리에 옮기세요.",
		3: "체포 행렬의 길 찾기 · 기름 자국을 읽고, 등불을 옮겨 빛의 방향을 바꾸세요.",
		4: "재판 현장 조사 · 군중 뒤편에서 시작해 총독의 질문과 실제 판결을 확인하세요.",
		5: "곁에 남은 사람들 돕기 · 통로를 비우고, 그늘에 물과 쉴 자리를 마련하세요.",
		6: "빈 무덤 조사 · 장사 지점의 기록에서 시작해 무덤의 흔적과 증언을 대조하세요."
	}
	_hint(introductions[number])
	queue_redraw()

func use(id: String) -> bool:
	if not active or not stations.has(id) or not actor.input_enabled: return false
	if actor.global_position.distance_to(stations[id].global_position) > 90: return false
	var step := _step(id)
	if done.has(id):
		_hint(step.result)
		return false
	for required in step.get("requires", []):
		if not done.has(required):
			_hint(step.hint)
			return false
	match step.kind:
		"pickup":
			if not carrying.is_empty():
				_hint("먼저 들고 있는 물건을 알맞은 자리에 놓아야 합니다.")
				return false
			carrying = step.get("item", id)
			carried_visual = stations[id].get_node("Prop")
			carried_visual.reparent(actor)
			carried_visual.position = Vector2(18, -30)
			stations[id].interaction_enabled = false
		"place":
			if carrying != step.item:
				_hint(step.hint)
				return false
			carrying = ""
			carried_visual.reparent(stations[id])
			carried_visual.position = Vector2.ZERO
			carried_visual = null
		"rotate":
			rotations[id] = (int(rotations.get(id, 0)) + 1) % 4
			stations[id].get_node("Prop").queue_redraw()
			if rotations[id] != step.get("direction", 2):
				_hint("등불 방향이 바뀌었습니다. 빛과 흔적이 이어지는지 살펴보세요. E로 다시 회전")
				return false
		"push":
			focused_action = id
			work = float(rotations.get(id + "_work", 0))
			_hint("물건 곁에서 E를 누른 채 D / →로 천천히 미세요. 놓으면 멈춥니다.")
			return false
	_mark_done(id)
	return true

func _physics_process(delta: float) -> void:
	if not active: return
	actor.speed = normal_speed
	for station in stations.values():
		station.get_node("Caption").visible = actor.global_position.distance_to(station.global_position) < 170
	feedback_seconds = maxf(0, feedback_seconds - delta)
	if not focused_action.is_empty():
		var target: Node2D = stations[focused_action]
		if actor.input_enabled and actor.global_position.distance_to(target.global_position) < 95 and Input.is_action_pressed("interact") and Input.is_action_pressed("move_right"):
			actor.speed = 45.0
			var amount := minf(delta * 45, 90 - work)
			work += amount
			rotations[focused_action + "_work"] = work
			target.position.x += amount
			if work >= 90:
				var id := focused_action
				focused_action = ""
				_mark_done(id)
	if feedback_seconds == 0:
		objective.text = "현장 조사 %d/%d · %s · E 조사/사용 · J 기록" % [done.size(), steps.size(), "손에 든 물건을 놓을 자리 찾기" if not carrying.is_empty() else "흔적과 필요한 도구 찾기"]

func _mark_done(id: String) -> void:
	done[id] = true
	var step := _step(id)
	_hint(step.result)
	stations[id].prompt_text = "다시 확인 · " + step.label
	if stations[id].has_node("Prop"):
		stations[id].get_node("Prop").queue_redraw()
	else:
		queue_redraw()
	var host := get_parent()
	var persists: bool = host.persistence_enabled if "persistence_enabled" in host else true
	if persists:
		var chapter: StringName = host.chapter_id
		get_node("/root/StoryState").record_observation(chapter, StringName("field_" + id), {"title": step.label, "description": step.result, "data": {"kind": "창작 현장 행동"}})
		get_node("/root/GameState").save_progress()
	queue_redraw()
	if _is_complete():
		active = false
		actor.speed = normal_speed
		_restore_world_targets()
		for station in stations.values():
			station.interaction_enabled = false
			station.get_node("Caption").hide()
		focused_action = ""
		completed.emit({"completed": true, "actions": done.keys(), "count": done.size(), "mode": "world_investigation"})

func _step(id: String) -> Dictionary:
	for step in steps:
		if step.id == id: return step
	return {}

func _hint(text: String) -> void:
	objective.text = text
	feedback_seconds = 6.0

func _draw() -> void:
	for step in steps:
		if done.has(step.id) and step.kind == "inspect":
			draw_arc(step.pos, 22, 0, TAU, 20, Color(0.85, 0.71, 0.45, 0.45), 2)

func _draw_prop(prop: Node2D, step: Dictionary) -> void:
	var ink := Color("332838")
	var gold := Color("d3aa70")
	var type: String = step.get("art", step.kind)
	match type:
		"lamp", "rotate":
			prop.draw_circle(Vector2(0, -7), 10, ink)
			prop.draw_circle(Vector2(0, -10), 6, gold)
			var angle: float = float(rotations.get(step.id, 0)) * PI * 0.5
			prop.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(155, -34).rotated(angle), Vector2(155, 34).rotated(angle)]), Color(0.94, 0.76, 0.4, 0.23))
		"wood", "push":
			prop.draw_rect(Rect2(-28, -15, 56, 15), ink)
			prop.draw_rect(Rect2(-25, -13, 50, 8), Color("946944"))
			for x in [-18, 18]: prop.draw_line(Vector2(x, -4), Vector2(x + 7, 10), ink, 5)
		"linen":
			if not done.has(step.id):
				prop.draw_arc(Vector2.ZERO, 18, 0, TAU, 20, gold, 2)
			else:
				for i in 3: prop.draw_rect(Rect2(-28, -8 + i * 5, 30, 3), Color("d8d2ba"))
				prop.draw_rect(Rect2(16, -9, 12, 10), Color("e7dfc9"))
		"cloth":
			prop.draw_colored_polygon(PackedVector2Array([Vector2(-21, -6), Vector2(16, -12), Vector2(26, 9), Vector2(-16, 14)]), Color("c9bda0"))
			prop.draw_line(Vector2(-10, -5), Vector2(1, 10), gold, 2)
		"branch":
			prop.draw_line(Vector2(-18, 8), Vector2(22, -13), Color("a68c58"), 3)
			for i in 5:
				prop.draw_line(Vector2(-12 + i * 7, 5 - i * 3), Vector2(-19 + i * 7, -8 - i * 3), Color("7a914e"), 5)
		"bowl", "jar":
			prop.draw_circle(Vector2(0, -8), 14, ink)
			prop.draw_circle(Vector2(0, -9), 11, Color("a86f46"))
			prop.draw_arc(Vector2(0, -12), 8, 0, PI, 12, Color("85a6ac"), 4)
		"coin":
			for i in 4:
				prop.draw_circle(Vector2(i * 8 - 12, (i % 2) * 8 - 4), 5, gold)
		"inspect":
			for i in 5: prop.draw_circle(Vector2(i * 8 - 20, (i % 2) * 9 - 7), 3, Color("9d8367"))
		_:
			prop.draw_arc(Vector2.ZERO, 20, 0, TAU, 20, Color(0.84, 0.71, 0.48, 0.65), 2)
			prop.draw_line(Vector2(-9, 0), Vector2(9, 0), gold, 2)

func _exit_tree() -> void:
	if is_instance_valid(actor): actor.speed = normal_speed
	_restore_world_targets()

func _restore_world_targets() -> void:
	for target in disabled_targets:
		if is_instance_valid(target): target.interaction_enabled = disabled_targets[target]
	for target in repeatable_targets:
		if is_instance_valid(target): target.one_shot = repeatable_targets[target]
	disabled_targets.clear()
	repeatable_targets.clear()

func _get_steps(number: int) -> Array:
	return preload("res://scripts/field_investigation_data.gd").for_chapter(number)

func _is_complete() -> bool:
	return done.size() == steps.size()
