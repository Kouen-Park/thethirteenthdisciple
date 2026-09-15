class_name PalmDragInteraction
extends Control

signal progress_changed(placed_count: int, required_count: int)
signal completed

@export_range(1, 3) var required_count := 3

var _leaves: Array[Dictionary] = []
var _dragging_index := -1
var _drag_offset := Vector2.ZERO
var _drop_rect := Rect2()
var _initialized := false
var _is_complete := false
var _last_layout_size := Vector2.ZERO
var active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_layout_interaction)
	_layout_interaction()

func configure(interaction: Dictionary) -> void:
	required_count = clampi(int(interaction.get("required", 3)), 1, 3)
	reset_interaction()

func reset_interaction() -> void:
	_initialized = false
	_is_complete = false
	active = true
	_dragging_index = -1
	_layout_interaction()
	progress_changed.emit(0, required_count)

func _layout_interaction() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_drop_rect = Rect2(size.x * 0.12, size.y * 0.61, size.x * 0.76, minf(126.0, size.y * 0.24))
	var size_changed := not size.is_equal_approx(_last_layout_size)
	if not _initialized:
		_leaves.clear()
		for index in required_count:
			_leaves.append({"position": Vector2.ZERO, "home": Vector2.ZERO, "placed": false})
		_initialized = true
	if size_changed:
		var start_y := size.y * 0.29
		for index in _leaves.size():
			if _leaves[index].placed:
				continue
			var position := Vector2(size.x * (float(index + 1) / float(required_count + 1)), start_y + (index % 2) * 26.0)
			_leaves[index].position = position
			_leaves[index].home = position
		_last_layout_size = size
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if _is_complete:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		_update_drag(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag(event.position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging_index >= 0:
		_update_drag(event.position)
		accept_event()

func _begin_drag(pointer_position: Vector2) -> void:
	_dragging_index = _pick_leaf(pointer_position)
	if _dragging_index < 0:
		return
	_drag_offset = _leaves[_dragging_index].position - pointer_position
	queue_redraw()

func _update_drag(pointer_position: Vector2) -> void:
	if _dragging_index < 0:
		return
	_leaves[_dragging_index].position = pointer_position + _drag_offset
	queue_redraw()

func _end_drag(pointer_position: Vector2) -> void:
	if _dragging_index < 0:
		return
	var leaf := _leaves[_dragging_index]
	leaf.position = pointer_position + _drag_offset
	if _drop_rect.grow(28.0).has_point(leaf.position):
		leaf.placed = true
		var next_slot := _placed_count()
		leaf.position = Vector2(
			_drop_rect.position.x + _drop_rect.size.x * (float(next_slot) / float(required_count + 1)),
			_drop_rect.get_center().y + (next_slot % 2) * 18.0 - 9.0
		)
	else:
		leaf.position = leaf.home
	_leaves[_dragging_index] = leaf
	_dragging_index = -1
	var count := _placed_count()
	progress_changed.emit(count, required_count)
	queue_redraw()
	if count >= required_count:
		_is_complete = true
		active = false
		await get_tree().create_timer(0.45, false).timeout
		completed.emit()

## Keyboard-accessible and testable equivalent of dragging a leaf into the road.
func place_leaf(index: int) -> bool:
	if _is_complete or index < 0 or index >= _leaves.size() or _leaves[index].placed:
		return false
	var leaf := _leaves[index]
	leaf.placed = true
	var next_slot := _placed_count()
	leaf.position = Vector2(
		_drop_rect.position.x + _drop_rect.size.x * (float(next_slot) / float(required_count + 1)),
		_drop_rect.get_center().y + (next_slot % 2) * 18.0 - 9.0
	)
	_leaves[index] = leaf
	var count := _placed_count()
	progress_changed.emit(count, required_count)
	queue_redraw()
	if count >= required_count:
		_is_complete = true
		active = false
		await get_tree().create_timer(0.45, false).timeout
		completed.emit()
	return true

func _pick_leaf(pointer_position: Vector2) -> int:
	for index in range(_leaves.size() - 1, -1, -1):
		if _leaves[index].placed:
			continue
		if pointer_position.distance_to(_leaves[index].position) <= 58.0:
			return index
	return -1

func _placed_count() -> int:
	var count := 0
	for leaf in _leaves:
		if leaf.placed:
			count += 1
	return count

func _draw() -> void:
	var glow := Color("#fff1b8")
	draw_rect(_drop_rect, Color(0.95, 0.72, 0.28, 0.15), true)
	draw_rect(_drop_rect, Color(glow, 0.8), false, 3.0)
	for index in _leaves.size():
		_draw_leaf(_leaves[index].position, index == _dragging_index, _leaves[index].placed)

func _draw_leaf(center: Vector2, selected: bool, placed: bool) -> void:
	var angle := -0.28 if not placed else -0.08
	var direction := Vector2(1.0, -0.42).rotated(angle).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var stem_start := center - direction * 48.0
	var stem_end := center + direction * 48.0
	if selected:
		draw_circle(center, 62.0, Color(1.0, 0.88, 0.42, 0.24))
	draw_line(stem_start, stem_end, Color("#4f421d"), 8.0, false)
	for segment in 7:
		var amount := float(segment + 1) / 8.0
		var stem_point := stem_start.lerp(stem_end, amount)
		var length := 31.0 - absf(0.5 - amount) * 20.0
		var half_width := 8.0
		var leaf_color := Color("#9eaa43") if segment % 2 == 0 else Color("#748b32")
		var left_leaf := PackedVector2Array([
			stem_point,
			stem_point + normal * length - direction * half_width,
			stem_point + normal * (length + 4.0),
			stem_point + direction * half_width
		])
		var right_leaf := PackedVector2Array([
			stem_point,
			stem_point - normal * length - direction * half_width,
			stem_point - normal * (length + 4.0),
			stem_point + direction * half_width
		])
		draw_colored_polygon(left_leaf, leaf_color)
		draw_colored_polygon(right_leaf, leaf_color.darkened(0.15))
