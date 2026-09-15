extends ChapterTwoAudio

var distant_steps: AudioStreamPlayer2D
var night_tween: Tween
var steps_timer: Timer

func setup(audio_root: Node, actor: CrowdPlayerController) -> void:
	super.setup(audio_root, actor)
	market.position = Vector2(420, 470)
	prayer.position = Vector2(1800, 480)
	market.volume_db = -27.0
	prayer.volume_db = -29.0
	distant_steps = AudioStreamPlayer2D.new()
	distant_steps.position = Vector2(1920, 450)
	distant_steps.stream = load("res://assets/audio/chapter01/footsteps_loop.wav")
	distant_steps.bus = "Ambience"
	distant_steps.volume_db = -26.0
	distant_steps.max_distance = 1600.0
	distant_steps.panning_strength = 0.6
	audio_root.add_child(distant_steps)
	steps_timer = Timer.new()
	steps_timer.one_shot = true
	steps_timer.wait_time = 5.0
	steps_timer.timeout.connect(distant_steps.stop)
	add_child(steps_timer)

func set_night() -> void:
	night_tween = create_tween().set_parallel(true)
	night_tween.tween_property(market, "volume_db", -45.0, 1.8)
	night_tween.tween_property(prayer, "volume_db", -22.0, 1.8)
	distant_steps.play()
	steps_timer.start()

func investigate(interaction_id: StringName) -> void:
	if fading:
		return
	var path := "res://assets/audio/chapter01/kenney/"
	match interaction_id:
		&"waiting_cloth", &"abandoned_sandal": path += "rpg/cloth2.ogg"
		&"broken_lantern": path = "res://assets/audio/chapter02/coins_clatter.wav"
		&"closed_door": path = "res://assets/audio/chapter02/table_wood.wav"
		&"drag_marks", &"waiting_well": path += "rpg/footstep02.ogg"
		_: return
	if ResourceLoader.exists(path):
		investigation.stream = load(path)
		investigation.volume_db = -24.0
		investigation.pitch_scale = 0.86
		investigation.play()

func prepare_exit() -> void:
	if night_tween and night_tween.is_valid(): night_tween.kill()
	if distant_steps: distant_steps.stop()
	super.prepare_exit()
