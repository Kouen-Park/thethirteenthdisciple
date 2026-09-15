class_name ChapterTwoAudio
extends Node

const FOLEY_ROOT := "res://assets/audio/chapter01/kenney/"
const STEP_PATHS := [
	FOLEY_ROOT + "rpg/footstep00.ogg", FOLEY_ROOT + "rpg/footstep01.ogg",
	FOLEY_ROOT + "rpg/footstep02.ogg", FOLEY_ROOT + "rpg/footstep03.ogg",
	FOLEY_ROOT + "rpg/footstep04.ogg"
]
const INVESTIGATION := {
	&"scattered_coins": {"path": "res://assets/audio/chapter02/coins_clatter.wav", "pitch": 1.0, "db": -15.0},
	&"empty_table": {"path": "res://assets/audio/chapter02/table_wood.wav", "pitch": 1.0, "db": -14.0},
	&"prayer_corner": {"path": "res://assets/audio/chapter02/prayer_cloth.wav", "pitch": 1.0, "db": -17.0}
}

var market: AudioStreamPlayer2D
var prayer: AudioStreamPlayer2D
var player: CrowdPlayerController
var footsteps: Array[AudioStreamPlayer] = []
var step_streams: Array[AudioStream] = []
var investigation: AudioStreamPlayer
var rng := RandomNumberGenerator.new()
var last_step := -1
var slot := 0
var fading := false

func setup(audio_root: Node, actor: CrowdPlayerController) -> void:
	player = actor
	market = audio_root.get_node("Market")
	prayer = audio_root.get_node("Prayer")
	for bus_name in ["Ambience", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	market.bus = "Ambience"
	market.max_distance = 1050.0
	market.attenuation = 1.15
	market.panning_strength = 0.55
	prayer.bus = "Ambience"
	prayer.max_distance = 820.0
	prayer.attenuation = 1.35
	prayer.panning_strength = 0.4
	for path in STEP_PATHS:
		step_streams.append(load(path) as AudioStream)
	for i in 2:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		voice.volume_db = -19.0
		add_child(voice)
		footsteps.append(voice)
	investigation = AudioStreamPlayer.new()
	investigation.bus = "SFX"
	add_child(investigation)
	player.footstep.connect(play_step)
	player.movement_stopped.connect(stop_steps)

func play_step() -> void:
	if fading:
		return
	var voice := footsteps[slot % footsteps.size()]
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

func investigate(interaction_id: StringName) -> void:
	if fading or not INVESTIGATION.has(interaction_id):
		return
	var settings: Dictionary = INVESTIGATION[interaction_id]
	investigation.stream = load(settings.path)
	investigation.pitch_scale = settings.pitch
	investigation.volume_db = settings.db
	investigation.play()

func prepare_exit() -> void:
	fading = true
	stop_steps()
	if investigation:
		investigation.stop()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(market, "volume_db", -40.0, 0.7)
	tween.tween_property(prayer, "volume_db", -40.0, 0.7)
