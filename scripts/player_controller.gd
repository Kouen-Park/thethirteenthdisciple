class_name CrowdPlayerController
extends CharacterBody2D

signal movement_started
signal movement_stopped
signal facing_changed(direction: Vector2)

@export var speed: float = 150.0
@export var movement_bounds := Rect2(40.0, 120.0, 1200.0, 560.0)
@export var walk_cycle_speed := 8.5
@export var walk_bob_height := 3.5
@export var walk_sway := 1.2
@export var walk_scale_amount := 0.025

@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Polygon2D = $Shadow

const DIRECTION_TEXTURES := {
	"down": "res://assets/art/pixel/small_walk_down_game.png",
	"down_right": "res://assets/art/pixel/small_walk_down_right_game.png",
	"right": "res://assets/art/pixel/small_walk_right_game.png",
	"up_right": "res://assets/art/pixel/small_walk_up_right_game.png",
	"up": "res://assets/art/pixel/small_walk_up_game.png",
	"down_left": "res://assets/art/pixel/small_walk_down_right_left_game.png",
	"left": "res://assets/art/pixel/small_walk_right_left_game.png",
	"up_left": "res://assets/art/pixel/small_walk_up_right_left_game.png"
}

var input_enabled := true
var _last_direction := Vector2.DOWN
var _was_moving := false
var _walk_phase := 0.0
var _walk_frame := 0
var _base_sprite_position := Vector2.ZERO
var _base_sprite_scale := Vector2.ONE
var _base_shadow_scale := Vector2.ONE
var _texture_cache: Dictionary = {}

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	floor_stop_on_slope = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_base_sprite_position = sprite.position
	_base_sprite_scale = sprite.scale
	_base_shadow_scale = shadow.scale
	for key in DIRECTION_TEXTURES:
		_texture_cache[key] = load(DIRECTION_TEXTURES[key])
	_apply_direction(_last_direction)

func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = Vector2.ZERO
		_update_walk_animation(delta, false)
		move_and_slide()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	var moving := direction.length_squared() > 0.01
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
		_walk_phase = 0.0
		_walk_frame = 0
		sprite.frame = 0
		sprite.position = _base_sprite_position
		sprite.scale = _base_sprite_scale
		shadow.scale = _base_shadow_scale
		return
	_walk_phase = fmod(_walk_phase + delta * walk_cycle_speed, TAU)
	_walk_frame = int(floor(_walk_phase / PI)) % 2
	sprite.frame = _walk_frame
	# 발 기준점은 걷는 동안 고정합니다. 실제 보폭은 2프레임 시트가 담당합니다.
	sprite.position = _base_sprite_position
	sprite.scale = _base_sprite_scale
	shadow.scale = _base_shadow_scale

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

func get_facing_direction() -> Vector2:
	return _last_direction
