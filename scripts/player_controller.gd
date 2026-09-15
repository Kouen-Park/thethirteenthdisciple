class_name CrowdPlayerController
extends CharacterBody2D

signal movement_started
signal movement_stopped
signal facing_changed(direction: Vector2)
signal footstep
signal cinematic_destination_reached

@export var speed: float = 150.0
@export var movement_bounds := Rect2(40.0, 120.0, 1200.0, 560.0)
@export var walk_cycle_speed := 10.5
@export var stride_length := 58.0
@export var walk_bob_height := 3.5
@export var walk_sway := 1.2
@export var walk_scale_amount := 0.025

@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Polygon2D = $Shadow

const DIRECTION_TEXTURES := {
	"down": "res://assets/art/player_walk/down.png",
	"down_right": "res://assets/art/player_walk/down_right.png",
	"right": "res://assets/art/player_walk/right.png",
	"up_right": "res://assets/art/player_walk/up_right.png",
	"up": "res://assets/art/player_walk/up.png",
	"up_left": "res://assets/art/player_walk/up_left.png",
	"left": "res://assets/art/player_walk/left.png",
	"down_left": "res://assets/art/player_walk/down_left.png"
}

var input_enabled := true
var cinematic_walking := false
var _last_direction := Vector2.DOWN
var _was_moving := false
var _walk_phase := 0.0
var _distance_this_tick := 0.0
var _previous_world_position := Vector2.ZERO
var _contact_index := 0
var _walk_frame := 0
var _base_sprite_position := Vector2.ZERO
var _base_sprite_scale := Vector2.ONE
var _base_shadow_scale := Vector2.ONE
var _texture_cache: Dictionary = {}
var _cinematic_destination := Vector2.ZERO
var _has_cinematic_destination := false

func _ready() -> void:
	sprite.hframes = 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	floor_stop_on_slope = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_base_sprite_position = sprite.position
	_base_sprite_scale = sprite.scale
	_base_shadow_scale = shadow.scale
	for key in DIRECTION_TEXTURES:
		_texture_cache[key] = load(DIRECTION_TEXTURES[key])
	normalize_visible_height(68)
	_apply_direction(_last_direction)
	_previous_world_position = global_position

func _physics_process(delta: float) -> void:
	_distance_this_tick = global_position.distance_to(_previous_world_position)
	_previous_world_position = global_position
	if not input_enabled:
		if _has_cinematic_destination:
			_move_toward_cinematic_destination(delta)
		else:
			velocity = Vector2.ZERO
			if _was_moving:
				movement_stopped.emit()
			_was_moving = false
			_update_walk_animation(delta, cinematic_walking)
			move_and_slide()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	var before := global_position
	move_and_slide()
	global_position = Vector2(
		clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x),
		clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)
	)
	_distance_this_tick = global_position.distance_to(before)
	_previous_world_position = global_position
	var moving := _distance_this_tick > 0.01
	if moving and not _was_moving:
		movement_started.emit()
	elif not moving and _was_moving:
		movement_stopped.emit()
	_was_moving = moving

	if moving:
		var facing := _eight_direction(direction)
		if facing != _last_direction:
			_last_direction = facing
			_apply_direction(facing)
			facing_changed.emit(facing)
	_update_walk_animation(delta, moving)

func _apply_direction(direction: Vector2) -> void:
	var key := _direction_key(direction)
	if _texture_cache.has(key):
		sprite.texture = _texture_cache[key]
	sprite.flip_h = false

func _update_walk_animation(delta: float, moving: bool) -> void:
	if not moving:
		# Settle to a passing pose without snapping the body's scale or direction.
		sprite.frame = 1 if sprite.hframes > 2 else 0
		sprite.position = sprite.position.lerp(_base_sprite_position, 1.0 - exp(-22.0 * delta))
		sprite.scale = _base_sprite_scale
		shadow.scale = _base_shadow_scale
		return
	# Distance, not elapsed time: wall contact and slow diagonal sliding cannot skate.
	var travel := minf(_distance_this_tick, speed * delta * 1.5)
	_walk_phase = fmod(_walk_phase + travel / stride_length * TAU, TAU)
	var contact := int(floor(_walk_phase / PI))
	if contact != _contact_index and travel > 0.01:
		_contact_index = contact
		footstep.emit()
	_walk_frame = int(floor(_walk_phase / TAU * sprite.hframes)) % sprite.hframes
	sprite.frame = _walk_frame
	# One pixel of rise on passing steps; no rubber-like body scaling or sway.
	var lift := sin(_walk_phase * 2.0)
	sprite.position = _base_sprite_position + Vector2(0, -maxf(0.0, lift) * 0.8)
	sprite.scale = _base_sprite_scale
	shadow.scale = _base_shadow_scale

func normalize_visible_height(height: int) -> void:
	for key in _texture_cache:
		var source: Image = _texture_cache[key].get_image()
		var frame_width := source.get_width() / sprite.hframes
		var regions: Array[Image] = []
		var maximum_height := 1
		for frame in sprite.hframes:
			var single := source.get_region(Rect2i(frame * frame_width, 0, frame_width, source.get_height()))
			single = single.get_region(single.get_used_rect())
			regions.append(single)
			maximum_height = maxi(maximum_height, single.get_height())
		var sheet := Image.create(80 * sprite.hframes, 80, false, Image.FORMAT_RGBA8)
		var ratio := float(height) / maximum_height
		for frame in sprite.hframes:
			var single := regions[frame]
			single.resize(maxi(1, roundi(single.get_width() * ratio)), maxi(1, roundi(single.get_height() * ratio)), Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(single, Rect2i(Vector2i.ZERO, single.get_size()), Vector2i(frame * 80 + (80 - single.get_width()) / 2, 76 - single.get_height()))
		_texture_cache[key] = ImageTexture.create_from_image(sheet)
	sprite.scale = Vector2.ONE
	sprite.position = Vector2(0, -36)
	_base_sprite_scale = Vector2.ONE
	_base_sprite_position = sprite.position
	shadow.position = Vector2(0, -2)
	shadow.scale = Vector2(0.65, 0.5)
	_base_shadow_scale = shadow.scale
	_apply_direction(_last_direction)

func _eight_direction(direction: Vector2) -> Vector2:
	var angle := atan2(direction.y, direction.x)
	var octant := int(round(angle / (PI / 4.0)))
	match posmod(octant, 8):
		0: return Vector2.RIGHT
		1: return Vector2(1, 1)
		2: return Vector2.DOWN
		3: return Vector2(-1, 1)
		4: return Vector2.LEFT
		5: return Vector2(-1, -1)
		6: return Vector2.UP
		_: return Vector2(1, -1)

func _direction_key(direction: Vector2) -> String:
	match direction:
		Vector2.DOWN: return "down"
		Vector2(1, 1): return "down_right"
		Vector2.RIGHT: return "right"
		Vector2(-1, 1): return "down_left"
		Vector2.UP: return "up"
		Vector2(-1, -1): return "up_left"
		Vector2.LEFT: return "left"
		_: return "up_right"

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		if _was_moving:
			movement_stopped.emit()
		_was_moving = false
	else:
		_has_cinematic_destination = false
		cinematic_walking = false

func get_facing_direction() -> Vector2:
	return _last_direction

func set_cinematic_walk(direction: Vector2) -> void:
	cinematic_walking = direction != Vector2.ZERO
	if cinematic_walking:
		_last_direction = _eight_direction(direction)
		_apply_direction(_last_direction)
	else:
		movement_stopped.emit()

func face_toward(world_point: Vector2) -> void:
	var direction := world_point - global_position
	if direction.length_squared() > 0.01:
		_last_direction = _eight_direction(direction.normalized())
		_apply_direction(_last_direction)

## Physics-driven cinematic travel keeps authored routes subject to the same
## walls and NPC bodies as normal WASD movement.
func walk_cinematic_path(points: Array[Vector2]) -> void:
	set_input_enabled(false)
	for destination in points:
		_cinematic_destination = destination
		_has_cinematic_destination = true
		set_cinematic_walk(destination - global_position)
		await cinematic_destination_reached
	set_cinematic_walk(Vector2.ZERO)

func _move_toward_cinematic_destination(delta: float) -> void:
	var offset := _cinematic_destination - global_position
	var maximum_step := speed * delta
	if offset.length() <= maximum_step:
		global_position = _cinematic_destination.round()
		velocity = Vector2.ZERO
		_has_cinematic_destination = false
		_was_moving = false
		_update_walk_animation(delta, false)
		cinematic_destination_reached.emit()
		return
	var direction := offset.normalized()
	velocity = direction * speed
	var before := global_position
	move_and_slide()
	global_position = Vector2(
		clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x),
		clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)
	)
	_distance_this_tick = global_position.distance_to(before)
	_previous_world_position = global_position
	var moving := _distance_this_tick > 0.01
	if moving and not _was_moving:
		movement_started.emit()
	elif not moving and _was_moving:
		movement_stopped.emit()
	_was_moving = moving
	if moving:
		var facing := _eight_direction(direction)
		if facing != _last_direction:
			_last_direction = facing
			_apply_direction(facing)
			facing_changed.emit(facing)
	_update_walk_animation(delta, moving)
