extends Node

const SAVE_PATH := "user://thirteenth_disciple_progress.cfg"

var unlocked_chapter := 1 # 1~6은 본편, 7은 에필로그
var text_speed := 28.0
var master_volume := 0.8

func _ready() -> void:
	load_progress()
	_apply_master_volume()

func is_unlocked(chapter_number: int) -> bool:
	return chapter_number <= unlocked_chapter

func unlock_through(chapter_number: int) -> void:
	unlocked_chapter = max(unlocked_chapter, chapter_number)
	save_progress()

func set_text_speed(value: float) -> void:
	text_speed = value
	save_progress()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	save_progress()

func _apply_master_volume() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.001)))

func reset_progress() -> void:
	unlocked_chapter = 1
	save_progress()

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	unlocked_chapter = int(config.get_value("progress", "unlocked_chapter", 1))
	text_speed = float(config.get_value("settings", "text_speed", 28.0))
	master_volume = clampf(float(config.get_value("settings", "master_volume", 0.8)), 0.0, 1.0)

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_chapter", unlocked_chapter)
	config.set_value("settings", "text_speed", text_speed)
	config.set_value("settings", "master_volume", master_volume)
	config.save(SAVE_PATH)
