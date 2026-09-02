class_name InteractionScanner
extends Area2D

signal target_changed(target: Node)
signal interaction_requested(target: Node)

@export var scan_radius: float = 42.0
@export var input_action: StringName = &"interact"

var current_target: Node
var input_enabled := true

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = scan_radius
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _unhandled_input(event: InputEvent) -> void:
	if input_enabled and event.is_action_pressed(input_action) and is_instance_valid(current_target):
		get_viewport().set_input_as_handled()
		interaction_requested.emit(current_target)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("get_interaction_priority") or area.has_method("interact"):
		_refresh_target()

func _on_area_exited(area: Area2D) -> void:
	if area == current_target:
		_refresh_target()

func _refresh_target() -> void:
	var nearest: Node = null
	var nearest_distance := INF
	for area in get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if distance < nearest_distance:
			nearest = area
			nearest_distance = distance
	if nearest != current_target:
		current_target = nearest
		target_changed.emit(current_target)

func clear_target() -> void:
	current_target = null
	target_changed.emit(null)

func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		clear_target()
	else:
		_refresh_target()
