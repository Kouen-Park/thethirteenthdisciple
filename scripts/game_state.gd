extends Node

const SAVE_PATH := "user://thirteenth_disciple_progress.cfg"

var unlocked_chapter := 1 # 1~6은 본편, 7은 에필로그
var text_speed := 28.0

func _ready() -> void:
	load_progress()

func is_unlocked(chapter_number: int) -> bool:
	return chapter_number <= unlocked_chapter

func unlock_through(chapter_number: int) -> void:
	unlocked_chapter = max(unlocked_chapter, chapter_number)
	save_progress()

func set_text_speed(value: float) -> void:
	text_speed = value
	save_progress()

func reset_progress() -> void:
	unlocked_chapter = 1
	save_progress()

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	unlocked_chapter = int(config.get_value("progress", "unlocked_chapter", 1))
	text_speed = float(config.get_value("settings", "text_speed", 28.0))

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_chapter", unlocked_chapter)
	config.set_value("settings", "text_speed", text_speed)
	config.save(SAVE_PATH)
