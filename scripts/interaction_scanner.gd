class_name InteractionScanner
extends Area2D

signal target_changed(target: Node)
signal interaction_requested(target: Node)

@export var scan_radius: float = 42.0
@export var input_action: StringName = &"interact"
@export var focus_slack := 8.0

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
	if event is InputEventKey and event.echo:
		return
	if input_enabled and event.is_action_pressed(input_action) and is_instance_valid(current_target):
		get_viewport().set_input_as_handled()
		if not current_target.is_visible_in_tree() or (current_target.has_method("can_interact") and not current_target.can_interact()):
			_refresh_target()
			return
		interaction_requested.emit(current_target)

func _physics_process(_delta: float) -> void:
	if input_enabled:
		_refresh_target()

func _on_area_entered(area: Area2D) -> void:
	if not input_enabled:
		return
	if area.has_method("get_interaction_priority") or area.has_method("interact"):
		call_deferred("_refresh_target")

func _on_area_exited(area: Area2D) -> void:
	if not input_enabled:
		return
	if area == current_target:
		_refresh_target()

func _refresh_target() -> void:
	var nearest: Node = null
	var nearest_score := INF
	for area in get_overlapping_areas():
		if not area.has_method("interact") or not area.is_visible_in_tree():
			continue
		if area.has_method("can_interact") and not area.can_interact():
			continue
		var anchor: Vector2 = area.get_interaction_anchor() if area.has_method("get_interaction_anchor") else area.global_position
		# A small preference for the current target prevents flicker between nearby
		# people and clues. Unread evidence wins otherwise similar candidates.
		var score := global_position.distance_to(anchor)
		if area.has_method("get_interaction_priority"): score -= area.get_interaction_priority()
		if area == current_target: score -= focus_slack
		if score < nearest_score:
			nearest = area
			nearest_score = score
	if nearest != current_target:
		if is_instance_valid(current_target) and current_target.has_method("set_focused"):
			current_target.set_focused(false)
		current_target = nearest
		if is_instance_valid(current_target) and current_target.has_method("set_focused"):
			current_target.set_focused(true)
		target_changed.emit(current_target)

func clear_target() -> void:
	if is_instance_valid(current_target) and current_target.has_method("set_focused"):
		current_target.set_focused(false)
	current_target = null
	target_changed.emit(null)

func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		clear_target()
	else:
		_refresh_target()
