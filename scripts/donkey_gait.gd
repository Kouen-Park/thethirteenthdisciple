extends TextureRect

var phase := 0.0
var previous_position := Vector2.ZERO
var gait_material: ShaderMaterial
var is_walking := false
var has_walked := false

func _ready() -> void:
	gait_material = ShaderMaterial.new()
	gait_material.shader = preload("res://assets/art/pixel/donkey_walk.gdshader")
	gait_material.set_shader_parameter("gait_texture", texture)
	material = gait_material
	previous_position = global_position

func _process(delta: float) -> void:
	var distance := global_position.distance_to(previous_position)
	previous_position = global_position
	is_walking = visible and modulate.a > 0.01 and distance > 0.01 and distance < 80.0
	if is_walking:
		has_walked = true
		phase = fmod(phase + delta * 9.0, TAU)
	else:
		phase = 0.0
	gait_material.set_shader_parameter("walking", 1.0 if is_walking else 0.0)
	gait_material.set_shader_parameter("gait_phase", phase)
