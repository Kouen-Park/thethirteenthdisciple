extends Node

signal text_speed_changed(value: float)

const Story = preload("res://story_data.gd")
const SAVE_PATH := "user://thirteenth_disciple_progress.cfg"

var unlocked_chapter := 1 # 1~6은 본편, 7은 에필로그
var text_speed := 28.0
var master_volume := 0.8
var ambience_volume := 0.8
var sfx_volume := 0.85
var text_scale := 1.0
var interaction_emphasis := 1.0
var window_mode := DisplayServer.WINDOW_MODE_WINDOWED
var current_chapter := 1

func _ready() -> void:
	load_progress()
	_apply_master_volume()
	_apply_category_volumes()
	_apply_window_mode()

func is_unlocked(chapter_number: int) -> bool:
	return chapter_number <= unlocked_chapter and is_available(chapter_number)

func is_available(chapter_number: int) -> bool:
	var index := clampi(chapter_number, 1, Story.PRODUCTION_READY.size()) - 1
	return Story.PRODUCTION_READY[index] or OS.is_debug_build()

func unlock_through(chapter_number: int) -> void:
	unlocked_chapter = max(unlocked_chapter, chapter_number)
	current_chapter = maxi(current_chapter, clampi(chapter_number, 1, 7))
	save_progress()

func get_continue_scene() -> String:
	var target := clampi(current_chapter, 1, Story.SCENE_PATHS.size())
	while target > 1 and not is_available(target):
		target -= 1
	return Story.get_scene_path(target)

func get_next_scene(chapter_number: int) -> String:
	if not is_available(chapter_number):
		return "res://scenes/menu/chapter_select.tscn"
	return Story.get_scene_path(chapter_number)

func set_text_speed(value: float) -> void:
	text_speed = clampf(value, 18.0, 42.0)
	text_speed_changed.emit(text_speed)
	save_progress()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	save_progress()

func set_ambience_volume(value: float) -> void:
	ambience_volume = clampf(value, 0.0, 1.0)
	var audio_mix := get_node_or_null("/root/AudioMix")
	if audio_mix: audio_mix.set_bus_linear(&"Ambience", ambience_volume)
	save_progress()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	var audio_mix := get_node_or_null("/root/AudioMix")
	if audio_mix: audio_mix.set_bus_linear(&"SFX", sfx_volume)
	save_progress()

func set_text_scale(value: float) -> void:
	text_scale = clampf(value, 0.85, 1.3)
	save_progress()

func set_interaction_emphasis(value: float) -> void:
	interaction_emphasis = clampf(value, 0.75, 1.4)
	save_progress()

func set_window_mode(value: int) -> void:
	window_mode = value if value in [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN] else DisplayServer.WINDOW_MODE_WINDOWED
	_apply_window_mode()
	save_progress()

func _apply_window_mode() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(window_mode)

func _apply_master_volume() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.001)))

func _apply_category_volumes() -> void:
	var audio_mix := get_node_or_null("/root/AudioMix")
	if audio_mix:
		audio_mix.set_bus_linear(&"Ambience", ambience_volume)
		audio_mix.set_bus_linear(&"SFX", sfx_volume)

func reset_progress() -> void:
	unlocked_chapter = 1
	current_chapter = 1
	StoryState.reset_story()
	save_progress()

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	unlocked_chapter = clampi(int(config.get_value("progress", "unlocked_chapter", 1)), 1, Story.SCENE_PATHS.size())
	current_chapter = clampi(int(config.get_value("progress", "current_chapter", unlocked_chapter)), 1, Story.SCENE_PATHS.size())
	text_speed = float(config.get_value("settings", "text_speed", 28.0))
	master_volume = clampf(float(config.get_value("settings", "master_volume", 0.8)), 0.0, 1.0)
	ambience_volume = clampf(float(config.get_value("settings", "ambience_volume", 0.8)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("settings", "sfx_volume", 0.85)), 0.0, 1.0)
	text_scale = clampf(float(config.get_value("settings", "text_scale", 1.0)), 0.85, 1.3)
	interaction_emphasis = clampf(float(config.get_value("settings", "interaction_emphasis", 1.0)), 0.75, 1.4)
	window_mode = int(config.get_value("settings", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED))
	var parsed: Variant = JSON.parse_string(str(config.get_value("story", "state", "{}")))
	if parsed is Dictionary:
		StoryState.load_state(parsed)

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_chapter", unlocked_chapter)
	config.set_value("progress", "current_chapter", current_chapter)
	config.set_value("settings", "text_speed", text_speed)
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("settings", "ambience_volume", ambience_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "text_scale", text_scale)
	config.set_value("settings", "interaction_emphasis", interaction_emphasis)
	config.set_value("settings", "window_mode", window_mode)
	config.set_value("story", "state", JSON.stringify(StoryState.get_state()))
	config.save(SAVE_PATH)
