class_name TableShiftPuzzle
extends Control

signal progress_changed(current: int, total: int)
signal completed(result: Dictionary)

const REQUIRED_PUSHES := 3

var active := false
var _offset_steps := 0
var _table: PanelContainer
var _status: Label

func _ready() -> void:
	_build_interface()
	hide()

func start() -> void:
	active = true
	_offset_steps = 0
	_table.position = Vector2(340, 25)
	_table.rotation = -0.13
	_status.text = "상을 세우지 않고 통로의 왼쪽이나 오른쪽 가장자리로 밀어내세요."
	show()
	progress_changed.emit(0, REQUIRED_PUSHES)

func push(direction: int) -> bool:
	if not active or direction == 0:
		return false
	_offset_steps += signi(direction)
	_offset_steps = clampi(_offset_steps, -REQUIRED_PUSHES, REQUIRED_PUSHES)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_table, "position:x", 340.0 + _offset_steps * 82.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_table, "rotation", -0.13 + _offset_steps * 0.025, 0.18)
	_status.text = "통로가 조금씩 드러납니다. · %d/%d" % [absi(_offset_steps), REQUIRED_PUSHES]
	progress_changed.emit(absi(_offset_steps), REQUIRED_PUSHES)
	if absi(_offset_steps) >= REQUIRED_PUSHES:
		active = false
		await tween.finished
		hide()
		completed.emit({"action": &"shifted_table_aside", "direction": signi(_offset_steps), "completed": true})
	return true

func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not event.pressed or event.echo:
		return
	if event.is_action_pressed("ui_left"):
		push(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		push(1)
		get_viewport().set_input_as_handled()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-430, -286)
	panel.size = Vector2(860, 246)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "막힌 통로"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var explanation := Label.new()
	explanation.text = "뒤집힌 상은 그대로 두되, 기도하러 온 사람이 지나갈 길을 확보합니다."
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(explanation)
	var lane := Control.new()
	lane.custom_minimum_size = Vector2(0, 100)
	box.add_child(lane)
	var marker := ColorRect.new()
	marker.position = Vector2(292, 8)
	marker.size = Vector2(260, 84)
	marker.color = Color(0.86, 0.72, 0.44, 0.11)
	lane.add_child(marker)
	_table = PanelContainer.new()
	_table.position = Vector2(340, 25)
	_table.size = Vector2(170, 48)
	var table_style := StyleBoxFlat.new()
	table_style.bg_color = Color(0.37, 0.20, 0.09, 1.0)
	table_style.border_color = Color(0.69, 0.43, 0.18, 1.0)
	table_style.set_border_width_all(3)
	_table.add_theme_stylebox_override("panel", table_style)
	lane.add_child(_table)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	var left := Button.new()
	left.text = "← 왼쪽으로 밀기"
	left.custom_minimum_size = Vector2(190, 42)
	left.pressed.connect(push.bind(-1))
	buttons.add_child(left)
	var right := Button.new()
	right.text = "오른쪽으로 밀기 →"
	right.custom_minimum_size = Vector2(190, 42)
	right.pressed.connect(push.bind(1))
	buttons.add_child(right)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color("e7c47b"))
	box.add_child(_status)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.065, 0.04, 0.96)
	style.border_color = Color(0.78, 0.57, 0.28, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	return style
