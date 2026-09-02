class_name InteractableComponent
extends Area2D

signal interacted(interaction_id: StringName, data: Dictionary)
signal focus_changed(is_focused: bool)

@export var interaction_id: StringName
@export var prompt_text := "살펴보기"
@export_multiline var description := ""
@export var one_shot := false
@export var interaction_data: Dictionary = {}

var _focused := false
var _used := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	if interaction_id == StringName():
		interaction_id = StringName(name.to_snake_case())

func get_interaction_priority() -> int:
	return 0 if not _used else -10

func get_prompt_text() -> String:
	return prompt_text

func interact() -> void:
	if one_shot and _used:
		return
	_used = true
	interacted.emit(interaction_id, {
		"id": interaction_id,
		"description": description,
		"data": interaction_data
	})
	if one_shot:
		monitorable = false

func set_focused(value: bool) -> void:
	if _focused == value:
		return
	_focused = value
	focus_changed.emit(_focused)
	if has_method("set_highlighted"):
		call("set_highlighted", _focused)
