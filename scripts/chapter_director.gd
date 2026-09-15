class_name ChapterDirector
extends Node

signal beat_changed(beat_id: StringName)
signal interaction_recorded(interaction_id: StringName, data: Dictionary)
signal chapter_completed(chapter_id: StringName)

@export var chapter_id: StringName = &"chapter_01"
@export var required_interactions: Array[StringName] = []
@export var requirement_groups: Array[Dictionary] = []
@export var requirements_met_beat: StringName = &"encounter"

var chapter_state: Dictionary = {
	"observed": {},
	"curiosity": 0,
	"doubt": 0,
	"empathy": 0
}
var current_beat: StringName = &"arrival"
var definition: ChapterDefinition
var use_definition_flow := false

func begin_chapter(chapter_definition: ChapterDefinition = null) -> void:
	definition = chapter_definition
	if definition:
		chapter_id = definition.chapter_id
		_configure_from_definition(definition)
	chapter_state = {
		"observed": {},
		"curiosity": 0,
		"doubt": 0,
		"empathy": 0
	}
	current_beat = &"arrival"
	if use_definition_flow and definition and not definition.beats.is_empty():
		current_beat = StringName(definition.beats[0].id)
	beat_changed.emit(current_beat)

## Multi-stage worlds advance only the currently active definition's conditions.
func finish_defined_beat(completion: StringName) -> bool:
	if not use_definition_flow or not definition:
		return false
	for beat: Dictionary in definition.beats:
		if StringName(beat.id) != current_beat or StringName(beat.get("completion", "")) != completion:
			continue
		var next_beat := StringName(beat.get("next", "complete"))
		if next_beat == &"complete":
			complete_chapter()
		else:
			current_beat = next_beat
			beat_changed.emit(current_beat)
		return true
	return false

func _configure_from_definition(value: ChapterDefinition) -> void:
	required_interactions.clear()
	requirement_groups.clear()
	if value.beats.is_empty():
		return
	for beat in value.beats:
		if beat.has("required"):
			required_interactions.assign(beat.get("required", []))
		if beat.has("requirements"):
			requirement_groups.assign(beat.get("requirements", []))
		var next_beat := StringName(beat.get("next", ""))
		if next_beat in [&"encounter", &"reflection"]:
			requirements_met_beat = next_beat

func record_interaction(interaction_id: StringName, data: Dictionary = {}) -> void:
	if has_observed(interaction_id):
		return
	chapter_state["observed"][interaction_id] = true
	match interaction_id:
		&"palm_leaf", &"footprints":
			chapter_state["curiosity"] += 1
		&"discarded_cloak":
			chapter_state["empathy"] += 1
		&"merchant", &"merchant_jonah", &"gate_guard":
			chapter_state["doubt"] += 1
		&"miriam":
			chapter_state["empathy"] += 1
	interaction_recorded.emit(interaction_id, data)
	_update_beat()

func has_observed(interaction_id: StringName) -> bool:
	return bool(chapter_state["observed"].get(interaction_id, false))

func _update_beat() -> void:
	if use_definition_flow:
		_update_defined_beat()
		return
	if current_beat in [&"encounter", &"reflection", &"aftermath", &"complete"]:
		return
	var required_complete := _requirements_complete()
	if required_complete and current_beat != &"encounter":
		current_beat = requirements_met_beat
		beat_changed.emit(current_beat)
		return
	var observed_count: int = chapter_state["observed"].size()
	if observed_count >= 1 and current_beat == &"arrival":
		current_beat = &"investigation" if not requirement_groups.is_empty() else &"approach"
		beat_changed.emit(current_beat)

func _update_defined_beat() -> void:
	if not definition:
		return
	for beat: Dictionary in definition.beats:
		if StringName(beat.id) != current_beat:
			continue
		var completion := StringName(beat.get("completion", ""))
		if completion not in [&"required_interactions", &"requirement_groups"]:
			return
		required_interactions.assign(beat.get("required", []))
		requirement_groups.assign(beat.get("requirements", []))
		if _requirements_complete():
			finish_defined_beat(completion)
		return

func _requirements_complete() -> bool:
	if not requirement_groups.is_empty():
		for group: Dictionary in requirement_groups:
			var ids: Array = group.get("ids", [])
			var minimum := int(group.get("minimum", ids.size()))
			var count := 0
			for interaction_id in ids:
				count += int(has_observed(StringName(interaction_id)))
			if count < minimum:
				return false
		return true
	if required_interactions.is_empty():
		return false
	for interaction_id in required_interactions:
		if not has_observed(interaction_id):
			return false
	return true

func complete_chapter() -> void:
	if current_beat == &"complete":
		return
	current_beat = &"complete"
	beat_changed.emit(current_beat)
	chapter_completed.emit(chapter_id)

func finish_encounter() -> void:
	if current_beat != &"encounter":
		return
	current_beat = &"aftermath"
	beat_changed.emit(current_beat)

func finish_reflection() -> void:
	if current_beat != &"reflection":
		return
	current_beat = &"aftermath"
	beat_changed.emit(current_beat)

func get_state() -> Dictionary:
	return chapter_state.duplicate(true)
