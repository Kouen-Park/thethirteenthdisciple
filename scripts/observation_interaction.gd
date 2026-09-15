class_name ObservationInteraction
extends Control

## 여러 관찰 지점 중 하나를 선택하게 하는 내러티브 상호작용입니다.
## options 형식: [{"id": "crowd", "label": "군중의 얼굴", "description": "..."}]

signal progress_changed(current: int, total: int)
signal selected(option_id: StringName, description: String)
signal completed

var _options: Array[Dictionary] = []
var _selected_index := -1
var _is_complete := false
var _option_rects: Array[Rect2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_layout_options)
	_layout_options()

func configure(data: Dictionary) -> void:
	_options.clear()
	for raw_option in data.get("options", []):
		if raw_option is Dictionary:
			_options.append(raw_option as Dictionary)
	_selected_index = -1
	_is_complete = false
	_layout_options()
	progress_changed.emit(0, _options.size())

func reset_interaction() -> void:
	_selected_index = -1
	_is_complete = false
	_layout_options()
	progress_changed.emit(0, _options.size())

func _layout_options() -> void:
	_option_rects.clear()
	if _options.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		queue_redraw()
		return
	var margin := 18.0
	var gap := 12.0
	var card_height := minf(96.0, (size.y - margin * 2.0 - gap * (_options.size() - 1)) / _options.size())
	for index in _options.size():
		_option_rects.append(Rect2(margin, margin + index * (card_height + gap), size.x - margin * 2.0, card_height))
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if _is_complete:
		return
	var pointer_position := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		pointer_position = event.position
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_position = event.position
		pressed = event.pressed
	if pressed:
		_select_at(pointer_position)
		accept_event()

func _select_at(pointer_position: Vector2) -> void:
	for index in _option_rects.size():
		if _option_rects[index].has_point(pointer_position):
			_select(index)
			return

func _select(index: int) -> void:
	if index < 0 or index >= _options.size() or _is_complete:
		return
	_selected_index = index
	_is_complete = true
	var option := _options[index]
	var option_id := StringName(str(option.get("id", "unknown")))
	var description := str(option.get("description", ""))
	selected.emit(option_id, description)
	progress_changed.emit(1, _options.size())
	queue_redraw()
	await get_tree().create_timer(0.35, false).timeout
	completed.emit()

func _draw() -> void:
	for index in _option_rects.size():
		var rect := _option_rects[index]
		var is_selected := index == _selected_index
		var fill := Color("#8f5b27") if is_selected else Color(0.12, 0.08, 0.05, 0.94)
		var border := Color("#ffe19a") if is_selected else Color(0.72, 0.52, 0.28, 0.9)
		draw_style_box(_make_box(fill, border, 10.0), rect)
		var label := str(_options[index].get("label", "살펴보기"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, rect.size.y * 0.56), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36.0, 18, Color("#fff3d0"))
	if _options.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(16.0, 32.0), "관찰할 대상이 없습니다.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#fff3d0"))

func _make_box(fill: Color, border: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(radius))
	return box
