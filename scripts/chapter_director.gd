class_name ChapterDirector
extends Node

signal beat_changed(beat_id: StringName)
signal interaction_recorded(interaction_id: StringName, data: Dictionary)
signal chapter_completed(chapter_id: StringName)

@export var chapter_id: StringName = &"chapter_01"
@export var required_interactions: Array[StringName] = []

var chapter_state: Dictionary = {
	"observed": {},
	"curiosity": 0,
	"doubt": 0,
	"empathy": 0
}
var current_beat: StringName = &"arrival"

func begin_chapter() -> void:
	chapter_state = {
		"observed": {},
		"curiosity": 0,
		"doubt": 0,
		"empathy": 0
	}
	current_beat = &"arrival"
	beat_changed.emit(current_beat)

func record_interaction(interaction_id: StringName, data: Dictionary = {}) -> void:
	if has_observed(interaction_id):
		return
	chapter_state["observed"][interaction_id] = true
	match interaction_id:
		&"palm_leaf", &"footprints":
			chapter_state["curiosity"] += 1
		&"discarded_cloak":
			chapter_state["empathy"] += 1
		&"merchant", &"gate_guard":
			chapter_state["doubt"] += 1
	interaction_recorded.emit(interaction_id, data)
	_update_beat()

func has_observed(interaction_id: StringName) -> bool:
	return bool(chapter_state["observed"].get(interaction_id, false))

func _update_beat() -> void:
	var required_complete := not required_interactions.is_empty()
	for interaction_id in required_interactions:
		if not has_observed(interaction_id):
			required_complete = false
			break
	if required_complete and current_beat != &"encounter":
		current_beat = &"encounter"
		beat_changed.emit(current_beat)
		return
	var observed_count: int = chapter_state["observed"].size()
	if observed_count >= 1 and current_beat == &"arrival":
		current_beat = &"approach"
		beat_changed.emit(current_beat)

func complete_chapter() -> void:
	current_beat = &"complete"
	beat_changed.emit(current_beat)
	chapter_completed.emit(chapter_id)

func get_state() -> Dictionary:
	return chapter_state.duplicate(true)
