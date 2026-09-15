extends Node

const FOLEY_ROOT := "res://assets/audio/chapter01/kenney/"
const STEP_PATHS := [
	FOLEY_ROOT + "rpg/footstep00.ogg", FOLEY_ROOT + "rpg/footstep01.ogg",
	FOLEY_ROOT + "rpg/footstep02.ogg", FOLEY_ROOT + "rpg/footstep03.ogg",
	FOLEY_ROOT + "rpg/footstep04.ogg"
]
# Grass foley stands in for foliage and loose ground; these are not palm recordings.
const INVESTIGATION := {
	&"palm_leaf": {"path": FOLEY_ROOT + "impact/footstep_grass_000.ogg", "pitch": 0.88, "db": -16.0},
	&"discarded_cloak": {"path": FOLEY_ROOT + "rpg/cloth2.ogg", "pitch": 0.96, "db": -15.0},
	&"footprints": {"path": FOLEY_ROOT + "impact/footstep_grass_003.ogg", "pitch": 0.76, "db": -19.0}
}
var crowd: AudioStreamPlayer2D
var player: CharacterBody2D
var left_group: Node2D
var right_group: Node2D
var footsteps: Array[AudioStreamPlayer] = []
var investigation: AudioStreamPlayer
var streams: Dictionary = {}
var step_streams: Array[AudioStream] = []
var rng := RandomNumberGenerator.new()
var last_step := -1
var hush_tween: Tween
var slot := 0
var fading := false

func setup(audio: Node, actor: CharacterBody2D, left: Node2D, right: Node2D) -> void:
	var has_limiter := false
	for i in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) is AudioEffectLimiter:
			has_limiter = true
	if not has_limiter:
		AudioServer.add_bus_effect(0, AudioEffectLimiter.new())
	for bus_name in ["Ambience", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	for output in audio.get_children():
		if output is AudioStreamPlayer or output is AudioStreamPlayer2D:
			output.bus = "Ambience" if output.name in [&"Wind", &"Crowd"] else "SFX"
	# Keep the old transition accent below material sounds, not a dramatic whoosh.
	audio.get_node("Transition").volume_db = -25.0
	audio.get_node("DialogueBlip").bus = "UI"
	player = actor
	left_group = left
	right_group = right
	crowd = audio.get_node("Crowd")
	crowd.max_distance = 720.0
	crowd.attenuation = 1.3
	crowd.panning_strength = 0.6
	crowd.volume_db = -12.0
	for path in STEP_PATHS:
		step_streams.append(load(path) as AudioStream)
	for i in 2:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		voice.stream = step_streams[i]
		voice.volume_db = -19.0
		add_child(voice)
		footsteps.append(voice)
	investigation = AudioStreamPlayer.new()
	investigation.bus = "SFX"
	investigation.volume_db = -9.0
	add_child(investigation)
	for id in INVESTIGATION:
		streams[id] = load(INVESTIGATION[id].path)
	player.footstep.connect(play_step)
	player.movement_stopped.connect(stop_steps)
	_update_position()

func _process(_delta: float) -> void:
	if is_instance_valid(crowd):
		_update_position()

func _update_position() -> void:
	crowd.global_position = (left_group.global_position + right_group.global_position) * 0.5

func play_step() -> void:
	if fading:
		return
	var voice := footsteps[slot % footsteps.size()]
	# Pick any take except the previous one, using a bounded, reusable voice pool.
	var next_step := rng.randi_range(0, step_streams.size() - (2 if last_step >= 0 else 1))
	if last_step >= 0 and next_step >= last_step:
		next_step += 1
	last_step = next_step
	voice.stream = step_streams[next_step]
	voice.pitch_scale = rng.randf_range(0.97, 1.03)
	voice.volume_db = rng.randf_range(-20.0, -18.0)
	voice.play()
	slot += 1

func stop_steps() -> void:
	for voice in footsteps:
		voice.stop()

func investigate(id: StringName) -> void:
	if not fading and streams.has(id):
		investigation.stream = streams[id]
		investigation.pitch_scale = INVESTIGATION[id].pitch
		investigation.volume_db = INVESTIGATION[id].db
		investigation.play()

func hush(duration := 1.8) -> void:
	if hush_tween and hush_tween.is_valid():
		hush_tween.kill()
	hush_tween = create_tween()
	hush_tween.tween_property(crowd, "volume_db", -36.0, duration).set_trans(Tween.TRANS_SINE)

func prepare_exit() -> void:
	fading = true
	stop_steps()
	if investigation:
		investigation.stop()
	if hush_tween and hush_tween.is_valid():
		hush_tween.kill()
