extends Node

signal changed(key: StringName, value: Variant)

var chapters: Dictionary = {}

func _chapter_state(chapter_id: StringName) -> Dictionary:
	var key := String(chapter_id)
	if not chapters.has(key):
		chapters[key] = {"observed": {}, "choices": {}, "completed": false}
	return chapters[key]

func record_observation(chapter_id: StringName, interaction_id: StringName, data: Dictionary = {}) -> void:
	var state := _chapter_state(chapter_id)
	var observed: Dictionary = state["observed"]
	if observed.has(String(interaction_id)):
		return
	observed[String(interaction_id)] = data.duplicate(true)
	changed.emit(&"observation", interaction_id)

func has_observed(chapter_id: StringName, interaction_id: StringName) -> bool:
	return _chapter_state(chapter_id)["observed"].has(String(interaction_id))

func record_choice(chapter_id: StringName, choice_id: StringName, value: Variant) -> void:
	_chapter_state(chapter_id)["choices"][String(choice_id)] = value
	changed.emit(&"choice", choice_id)

func complete_chapter(chapter_id: StringName) -> void:
	_chapter_state(chapter_id)["completed"] = true
	changed.emit(&"completed", chapter_id)

func get_state() -> Dictionary:
	return {"chapters": chapters.duplicate(true)}

func load_state(value: Dictionary) -> void:
	chapters = value.get("chapters", {}).duplicate(true)

func reset_story() -> void:
	chapters.clear()
