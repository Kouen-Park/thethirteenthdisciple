extends Node

const SAVE_PATH := "user://thirteenth_disciple_progress.cfg"
const CHAPTER_PATHS := [
	"res://scenes/chapters/chapter_01_entry.tscn",
	"res://scenes/chapters/chapter_02_supper.tscn",
	"res://scenes/chapters/chapter_03_garden.tscn",
	"res://scenes/chapters/chapter_04_trial.tscn",
	"res://scenes/chapters/chapter_05_golgotha.tscn",
	"res://scenes/chapters/chapter_06_resurrection.tscn",
	"res://scenes/chapters/epilogue.tscn"
]

var unlocked_chapter := 1 # 1~6은 본편, 7은 에필로그
var text_speed := 28.0
var master_volume := 0.8
var current_chapter := 1

func _ready() -> void:
	load_progress()
	_apply_master_volume()

func is_unlocked(chapter_number: int) -> bool:
	return chapter_number <= unlocked_chapter

func unlock_through(chapter_number: int) -> void:
	unlocked_chapter = max(unlocked_chapter, chapter_number)
	current_chapter = maxi(current_chapter, clampi(chapter_number, 1, 7))
	save_progress()

func get_continue_scene() -> String:
	return CHAPTER_PATHS[clampi(current_chapter, 1, CHAPTER_PATHS.size()) - 1]

func get_next_scene(chapter_number: int) -> String:
	return CHAPTER_PATHS[clampi(chapter_number, 1, CHAPTER_PATHS.size()) - 1]

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
	current_chapter = 1
	StoryState.reset_story()
	save_progress()

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	unlocked_chapter = int(config.get_value("progress", "unlocked_chapter", 1))
	current_chapter = int(config.get_value("progress", "current_chapter", unlocked_chapter))
	text_speed = float(config.get_value("settings", "text_speed", 28.0))
	master_volume = clampf(float(config.get_value("settings", "master_volume", 0.8)), 0.0, 1.0)
	var parsed: Variant = JSON.parse_string(str(config.get_value("story", "state", "{}")))
	if parsed is Dictionary:
		StoryState.load_state(parsed)

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_chapter", unlocked_chapter)
	config.set_value("progress", "current_chapter", current_chapter)
	config.set_value("settings", "text_speed", text_speed)
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("story", "state", JSON.stringify(StoryState.get_state()))
	config.save(SAVE_PATH)
