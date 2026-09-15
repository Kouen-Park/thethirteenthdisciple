class_name PrayerClothPuzzle
extends Control

const PuzzleTheme = preload("res://scripts/ui_theme.gd")

signal progress_changed(current: int, total: int)
signal completed(result: Dictionary)

const CORNER_COUNT := 4

var active := false
var _opened: Array[bool] = [false, false, false, false]
var _corners: Array[Button] = []
var _cloth: ColorRect
var _status: Label

func _ready() -> void:
	_build_interface()
	hide()

func start() -> void:
	active = true
	_opened = [false, false, false, false]
	_cloth.position = Vector2(315, 35)
	_cloth.size = Vector2(210, 66)
	for corner in _corners:
		corner.show()
		corner.disabled = false
		corner.modulate = Color.WHITE
		corner.position = corner.get_meta("rest_position")
	_status.text = "접힌 천의 네 귀퉁이를 펼쳐 머물 자리를 만드세요."
	show()
	PuzzleTheme.trap_button_focus(_corners)
	_corners[0].grab_focus()
	progress_changed.emit(0, CORNER_COUNT)

func unfold_corner(index: int) -> bool:
	if not active or index < 0 or index >= CORNER_COUNT or _opened[index]:
		return false
	_opened[index] = true
	var corner := _corners[index]
	corner.disabled = true
	PuzzleTheme.trap_button_focus(_corners)
	for next in _corners:
		if not next.disabled:
			next.grab_focus()
			break
	var targets := [Vector2(228, 12), Vector2(556, 12), Vector2(228, 113), Vector2(556, 113)]
	var tween := create_tween().set_parallel(true)
	tween.tween_property(corner, "position", targets[index], 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_cloth, "position", Vector2(255, 18), 0.22)
	tween.tween_property(_cloth, "size", Vector2(330, 112), 0.22)
	var count := _opened.count(true)
	_status.text = "소음에 가려졌던 자리가 다시 드러납니다. · %d/%d" % [count, CORNER_COUNT]
	progress_changed.emit(count, CORNER_COUNT)
	if count >= CORNER_COUNT:
		active = false
		await tween.finished
		hide()
		completed.emit({"action": &"opened_prayer_cloth", "corners": count, "completed": true})
	return true

func unfold_all() -> void:
	for index in CORNER_COUNT:
		if active:
			unfold_corner(index)

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-430, -300)
	panel.size = Vector2(860, 260)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "드러난 기도 자리"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var explanation := Label.new()
	explanation.text = "새 자리를 만드는 것이 아니라, 접혀 있던 천을 펼쳐 다시 머물 수 있게 합니다."
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(explanation)
	var surface := Control.new()
	surface.custom_minimum_size = Vector2(0, 140)
	box.add_child(surface)
	_cloth = ColorRect.new()
	_cloth.position = Vector2(315, 35)
	_cloth.size = Vector2(210, 66)
	_cloth.color = Color(0.62, 0.46, 0.25, 0.72)
	surface.add_child(_cloth)
	var starts := [Vector2(300, 20), Vector2(510, 20), Vector2(300, 82), Vector2(510, 82)]
	for index in CORNER_COUNT:
		var corner := Button.new()
		corner.position = starts[index]
		corner.size = Vector2(52, 52)
		corner.text = str(index + 1)
		corner.tooltip_text = "접힌 천 귀퉁이 펼치기"
		corner.pressed.connect(unfold_corner.bind(index))
		surface.add_child(corner)
		corner.set_meta("rest_position", corner.position)
		_corners.append(corner)
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
