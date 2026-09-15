extends Camera2D

enum FollowMode { PLAYER, CINEMATIC }

@export var target_path: NodePath
@export var world_rect := Rect2(0, 0, 1280, 720)
@export var follow_speed := 4.0
@export var horizontal_deadzone := 24.0
@export var look_ahead_distance := 54.0
var smooth_center := Vector2.ZERO
var target: Node2D
var follow_mode := FollowMode.PLAYER
var cinematic_subject: CanvasItem
var cinematic_offset := Vector2.ZERO
var transition_tween: Tween
var transitioning_focus := false

func _ready() -> void:
	target = get_node_or_null(target_path)
	limit_smoothed = true
	position_smoothing_enabled = false # Smooth a float accumulator, then quantize once.
	limit_left = int(world_rect.position.x)
	limit_top = int(world_rect.position.y)
	limit_right = int(world_rect.end.x)
	limit_bottom = int(world_rect.end.y)
	# Begin on the player-facing edge of wide worlds instead of panning in from
	# the full world's midpoint during the opening dialogue.
	smooth_center = bounded_center(target.global_position, get_viewport_rect().size) if is_instance_valid(target) else world_rect.get_center()
	global_position = smooth_center.round()

func bounded_center(point: Vector2, view_size: Vector2) -> Vector2:
	var half := view_size * 0.5 / zoom
	var minimum := world_rect.position + half
	var maximum := world_rect.end - half
	return Vector2(
		clampf(point.x, minimum.x, maximum.x) if maximum.x >= minimum.x else world_rect.get_center().x,
		clampf(point.y, minimum.y, maximum.y) if maximum.y >= minimum.y else world_rect.get_center().y
	)

func _process(delta: float) -> void:
	if not enabled or transitioning_focus:
		return
	var focus_point := _current_focus_point()
	var desired := bounded_center(focus_point, get_viewport_rect().size)
	smooth_center = smooth_center.lerp(desired, 1.0 - exp(-follow_speed * delta))
	global_position = smooth_center.round()

func focus_on(subject: CanvasItem, framing_offset := Vector2.ZERO, duration := 0.8) -> void:
	if not is_instance_valid(subject):
		return
	_kill_transition()
	follow_mode = FollowMode.CINEMATIC
	cinematic_subject = subject
	cinematic_offset = framing_offset
	await _transition_to(_subject_world_position(subject) + cinematic_offset, duration)

func return_to_player(duration := 0.55) -> void:
	_kill_transition()
	follow_mode = FollowMode.PLAYER
	cinematic_subject = null
	cinematic_offset = Vector2.ZERO
	if is_instance_valid(target):
		await _transition_to(target.global_position, duration)

func is_focusing(subject: CanvasItem = null) -> bool:
	if follow_mode != FollowMode.CINEMATIC or not is_instance_valid(cinematic_subject):
		return false
	return subject == null or cinematic_subject == subject

func _current_focus_point() -> Vector2:
	if follow_mode == FollowMode.CINEMATIC and is_instance_valid(cinematic_subject):
		return _subject_world_position(cinematic_subject) + cinematic_offset
	if is_instance_valid(target):
		var point := target.global_position
		if "velocity" in target:
			var target_velocity: Vector2 = target.velocity
			if absf(target_velocity.x) > 1.0:
				point.x += signf(target_velocity.x) * look_ahead_distance
		if absf(point.x - smooth_center.x) < horizontal_deadzone:
			point.x = smooth_center.x
		return point
	return smooth_center

func _subject_world_position(subject: CanvasItem) -> Vector2:
	if subject is Control:
		return (subject as Control).get_global_rect().get_center()
	if subject is Node2D:
		return (subject as Node2D).global_position
	return Vector2.ZERO

func _transition_to(world_point: Vector2, duration: float) -> void:
	var destination := bounded_center(world_point, get_viewport_rect().size)
	if duration <= 0.0:
		_set_transition_position(destination)
		return
	transitioning_focus = true
	transition_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	transition_tween.tween_method(_set_transition_position, smooth_center, destination, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished
	transitioning_focus = false

func _set_transition_position(value: Vector2) -> void:
	smooth_center = value
	global_position = value.round()

func _kill_transition() -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
	transitioning_focus = false
