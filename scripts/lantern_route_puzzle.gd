class_name LanternRoutePuzzle
extends NarrativePuzzle

## The oil lines stay fixed. Rotate the three lantern beams to follow those lines.
const RouteTheme = preload("res://scripts/ui_theme.gd")
const DIRECTIONS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
const TARGETS := [0, 3, 0]
const CLUES := ["broken_lantern", "drag_marks", "abandoned_sandal"]
const NAMES := ["쓰러진 등불", "담을 따라 꺾인 자국", "신발 곁의 발자국"]
var orientations: Array[int] = [1, 2, 1]
var selected := 0
var board: Control
var status: Label
var turn_buttons: Array[Button] = []
var use_saved: Button
var previous_result: Dictionary = {}
var suspended := false

func _ready() -> void:
	puzzle_id = &"lantern_route"
	_build_route_interface()
	hide()

func start(saved_result: Dictionary = {}) -> void:
	previous_result = saved_result
	active = true
	suspended = false
	elapsed = 0.0
	_hint_level = 0
	use_saved.visible = bool(saved_result.get("completed", false))
	status.text = "기름 자국은 그대로 두고, 등불을 돌려 그 방향을 비춰 보세요."
	show()
	turn_buttons[selected].grab_focus()
	_refresh()
	started.emit(puzzle_id)

func rotate_lantern(index: int, amount := 1) -> void:
	if not active or suspended or index < 0 or index >= 3:
		return
	selected = index
	orientations[index] = posmod(orientations[index] + amount, 4)
	attempts += 1
	elapsed = 0.0
	_hint_level = 0
	_refresh()

func confirm_route() -> bool:
	if not active or suspended:
		return false
	for index in 3:
		if orientations[index] != TARGETS[index]:
			selected = index
			status.text = "빛이 흔적에서 벗어났다. 바닥의 가느다란 기름 줄을 다시 보자."
			turn_buttons[index].grab_focus()
			board.queue_redraw()
			return false
	_finish(false)
	return true

func _finish(reused: bool) -> void:
	active = false
	hide()
	completed.emit({"puzzle_id": puzzle_id, "completed": true, "orientations": TARGETS.duplicate(), "attempts": attempts, "reused": reused})

func _reuse_saved() -> void:
	if active and not suspended and bool(previous_result.get("completed", false)):
		orientations.assign(TARGETS)
		_finish(true)

func cancel_puzzle() -> void:
	if not active:
		return
	active = false
	hide()
	canceled.emit()

func _process(delta: float) -> void:
	if not active or suspended:
		return
	elapsed += delta
	if elapsed >= VISUAL_HINT_SECONDS and _hint_level < 2:
		_hint_level = 2
		status.text = "밝아진 기름 줄 끝으로 등불을 돌려 보자."
		hint_requested.emit(2, status.text)
		board.queue_redraw()
	elif elapsed >= FIRST_HINT_SECONDS and _hint_level < 1:
		_hint_level = 1
		status.text = "등불 옆의 자국은 오른쪽, 담에서는 위쪽, 신발 뒤에서는 다시 오른쪽이다."
		hint_requested.emit(1, status.text)

func _unhandled_key_input(event: InputEvent) -> void:
	if not active or suspended or (event is InputEventKey and event.echo):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancel_puzzle()

func _refresh() -> void:
	var count := 0
	for i in 3:
		count += int(orientations[i] == TARGETS[i])
		turn_buttons[i].text = "%d · 등불 돌리기" % (i + 1)
	board.queue_redraw()
	progress_changed.emit(count, 3)

func _draw_board() -> void:
	var centers := [Vector2(150, 102), Vector2(430, 102), Vector2(710, 102)]
	for i in 3:
		var center: Vector2 = centers[i]
		board.draw_rect(Rect2(center - Vector2(118, 84), Vector2(236, 158)), Color("302943"))
		# The ground evidence never rotates with the player's beam.
		var trace: Vector2 = DIRECTIONS[TARGETS[i]]
		var evidence_color := Color("e7bd72") if _hint_level >= 2 else Color("aa8560")
		board.draw_line(center - trace * 42, center + trace * 68, evidence_color, 3)
		board.draw_line(center + trace * 68, center + trace * 52 + trace.orthogonal() * 7, evidence_color, 3)
		board.draw_line(center + trace * 68, center + trace * 52 - trace.orthogonal() * 7, evidence_color, 3)
		var beam: Vector2 = DIRECTIONS[orientations[i]]
		var beam_color := Color(1.0, 0.80, 0.43, 0.28)
		board.draw_colored_polygon(PackedVector2Array([center, center + beam * 72 + beam.orthogonal() * 22, center + beam * 72 - beam.orthogonal() * 22]), beam_color)
		board.draw_circle(center, 9, Color("e7bd72"))
		board.draw_circle(center, 4, Color("5c3828"))
		if i == selected:
			board.draw_rect(Rect2(center - Vector2(118, 84), Vector2(236, 158)), Color("e7bd72"), false, 2)
		if i < 2:
			board.draw_line(center + Vector2(123, 0), center + Vector2(153, 0), Color("8e6c4c"), 2)

func _build_route_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-460, -366)
	panel.size = Vector2(920, 342)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.085, 0.14, 0.97)
	style.border_color = Color("8e6c4c")
	style.set_border_width_all(2)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Label.new()
	title.text = "어둠에 남은 길"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	board = Control.new()
	board.custom_minimum_size = Vector2(860, 182)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(board)
	board.draw.connect(_draw_board)
	for i in 3:
		var caption := Label.new()
		caption.position = Vector2(32 + i * 280, 20)
		caption.size = Vector2(236, 28)
		caption.text = NAMES[i]
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 14)
		board.add_child(caption)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	for i in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(264, 40)
		RouteTheme.apply_button(button)
		button.pressed.connect(rotate_lantern.bind(i, 1))
		button.focus_entered.connect(func(): selected = i; board.queue_redraw())
		row.add_child(button)
		turn_buttons.append(button)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("e7bd72"))
	box.add_child(status)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	for item in [["길 확인하기", confirm_route], ["주변을 더 살펴보기 · Esc", cancel_puzzle], ["이전 관찰로 길 잇기", _reuse_saved]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size = Vector2(220, 38)
		RouteTheme.apply_button(button)
		button.pressed.connect(item[1])
		actions.add_child(button)
		use_saved = button
