class_name InteractableComponent
extends Area2D

signal interacted(interaction_id: StringName, data: Dictionary)
signal focus_changed(is_focused: bool)

@export var interaction_id: StringName
@export var prompt_text := "살펴보기"
@export_multiline var description := ""
@export var one_shot := false
@export var dim_on_use := true
@export var interaction_enabled := true
@export var interaction_data: Dictionary = {}

var _focused := false
var _used := false
var _highlight_tween: Tween
var _visual: Sprite2D
var _visual_rest_position := Vector2.ZERO
var _visual_rest_scale := Vector2.ONE

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	if interaction_id == StringName():
		interaction_id = StringName(name.to_snake_case())
	_visual = get_node_or_null("Visual") as Sprite2D
	if _visual:
		_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		refresh_visual_baseline()

## Call after replacing or resizing a Visual at runtime so focus animation never
## restores the pre-normalized transform.
func refresh_visual_baseline() -> void:
	if not is_instance_valid(_visual):
		_visual = get_node_or_null("Visual") as Sprite2D
	if not _visual:
		return
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()
	_visual_rest_position = _visual.position
	_visual_rest_scale = _visual.scale

func get_interaction_priority() -> int:
	return 0 if not _used else -10

func get_prompt_text() -> String:
	return prompt_text

## The scanner must measure from the shape the player can actually overlap, not
## from an owning NPC's feet. This matters for characters whose talk area is
## intentionally raised toward the torso.
func get_interaction_anchor() -> Vector2:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and not collision.disabled:
		return collision.global_position
	return global_position

func interact() -> void:
	if not can_interact():
		return
	_used = true
	interacted.emit(interaction_id, {
		"id": interaction_id,
		"description": description,
		"title": prompt_text,
		"data": interaction_data
	})
	if one_shot:
		monitorable = false
		if _focused:
			set_focused(false)
		else:
			# A one-shot interaction can complete after the scanner has already
			# cleared focus. Refresh the visual anyway so its used state sticks.
			_animate_highlight(false)

func can_interact() -> bool:
	return interaction_enabled and not (one_shot and _used)

func set_focused(value: bool) -> void:
	if _focused == value:
		return
	_focused = value
	focus_changed.emit(_focused)
	_animate_highlight(_focused)

func _animate_highlight(enabled: bool) -> void:
	if not _visual:
		return
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()
	_highlight_tween = create_tween().set_parallel(true)
	var target_position := _visual_rest_position + (Vector2.UP * 2.0 if enabled and dim_on_use else Vector2.ZERO)
	var emphasis := 1.0
	var settings := get_node_or_null("/root/GameState")
	if settings:
		emphasis = settings.interaction_emphasis
	var target_scale := _visual_rest_scale
	var target_color := Color.WHITE
	if enabled:
		target_color = Color.WHITE.lerp(Color(1.18, 1.08, 0.72, 1.0), minf(emphasis, 1.4))
	elif _used and dim_on_use:
		target_color = Color(0.78, 0.74, 0.66, 0.82)
	_highlight_tween.tween_property(_visual, "position", target_position, 0.16).set_trans(Tween.TRANS_SINE)
	_highlight_tween.tween_property(_visual, "scale", target_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_highlight_tween.tween_property(_visual, "modulate", target_color, 0.16)
