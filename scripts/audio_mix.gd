extends Node

const AMBIENCE_BUS := &"Ambience"
const SFX_BUS := &"SFX"
const UI_BUS := &"UI"
const DIALOGUE_BUS := &"Dialogue"
const DUCK_DB := -5.0

var _dialogue_depth := 0
var _ambience_base_db := 0.0
var _duck_tween: Tween

func _ready() -> void:
	_ensure_required_buses()
	_ambience_base_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(AMBIENCE_BUS))

func set_bus_linear(bus_name: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var linear := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.001)))
	if bus_name == AMBIENCE_BUS:
		_ambience_base_db = linear_to_db(maxf(linear, 0.001))
		_tween_ambience(_ambience_base_db + (DUCK_DB if _dialogue_depth > 0 else 0.0), 0.12)

func begin_dialogue() -> void:
	_dialogue_depth += 1
	if _dialogue_depth == 1:
		_tween_ambience(_ambience_base_db + DUCK_DB, 0.12)

func end_dialogue() -> void:
	_dialogue_depth = maxi(0, _dialogue_depth - 1)
	if _dialogue_depth == 0:
		_tween_ambience(_ambience_base_db, 0.42)

func reset_dialogue_duck() -> void:
	_dialogue_depth = 0
	_tween_ambience(_ambience_base_db, 0.1)

func _tween_ambience(target_db: float, duration: float) -> void:
	var index := AudioServer.get_bus_index(AMBIENCE_BUS)
	if index < 0:
		return
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_duck_tween.tween_method(func(value: float): AudioServer.set_bus_volume_db(index, value), AudioServer.get_bus_volume_db(index), target_db, duration).set_trans(Tween.TRANS_SINE)

func _ensure_required_buses() -> void:
	for bus_name in [AMBIENCE_BUS, SFX_BUS, UI_BUS, DIALOGUE_BUS]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")
