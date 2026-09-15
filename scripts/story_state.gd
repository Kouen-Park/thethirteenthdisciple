extends Node

signal changed(key: StringName, value: Variant)

const SCHEMA_VERSION := 3

var chapters: Dictionary = {}

func _chapter_state(chapter_id: StringName) -> Dictionary:
	var key := String(chapter_id)
	if not chapters.has(key):
		chapters[key] = {"observed": {}, "choices": {}, "puzzles": {}, "checkpoints": {}, "completed": false}
	elif not chapters[key].has("puzzles"):
		chapters[key]["puzzles"] = {}
	if not chapters[key].has("checkpoints"):
		chapters[key]["checkpoints"] = {}
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

func get_choice(chapter_id: StringName, choice_id: StringName, default_value: Variant = null) -> Variant:
	return chapters.get(String(chapter_id), {}).get("choices", {}).get(String(choice_id), default_value)

func complete_chapter(chapter_id: StringName) -> void:
	_chapter_state(chapter_id)["completed"] = true
	changed.emit(&"completed", chapter_id)

func record_puzzle(chapter_id: StringName, puzzle_id: StringName, result: Dictionary) -> void:
	_chapter_state(chapter_id)["puzzles"][String(puzzle_id)] = result.duplicate(true)
	changed.emit(&"puzzle", puzzle_id)

func set_checkpoint(chapter_id: StringName, checkpoint_id: StringName, value: Dictionary) -> void:
	_chapter_state(chapter_id)["checkpoints"][String(checkpoint_id)] = value.duplicate(true)

func get_checkpoint(chapter_id: StringName, checkpoint_id: StringName) -> Dictionary:
	return _chapter_state(chapter_id)["checkpoints"].get(String(checkpoint_id), {}).duplicate(true)

func clear_checkpoint(chapter_id: StringName, checkpoint_id: StringName) -> void:
	_chapter_state(chapter_id)["checkpoints"].erase(String(checkpoint_id))

func get_chapter_summary(chapter_id: StringName) -> Dictionary:
	return chapters.get(String(chapter_id), {"observed": {}, "choices": {}, "puzzles": {}, "checkpoints": {}, "completed": false}).duplicate(true)

func get_epilogue_memories(limit := 3) -> Array[Dictionary]:
	var memories: Array[Dictionary] = []
	for chapter_key in chapters.keys():
		var state: Dictionary = chapters[chapter_key]
		for observation_id in state.get("observed", {}).keys():
			memories.append({"chapter": chapter_key, "kind": &"observation", "id": observation_id})
		for choice_id in state.get("choices", {}).keys():
			memories.append({"chapter": chapter_key, "kind": &"choice", "id": choice_id, "value": state["choices"][choice_id]})
	if memories.size() > limit:
		memories = memories.slice(memories.size() - limit)
	return memories

func get_state() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "chapters": chapters.duplicate(true)}

func load_state(value: Dictionary) -> void:
	chapters = value.get("chapters", {}).duplicate(true)
	_migrate_state(int(value.get("schema_version", 1)))

func _migrate_state(_from_version: int) -> void:
	for chapter_key in chapters.keys():
		var state: Dictionary = chapters[chapter_key]
		if not state.has("observed"): state["observed"] = {}
		if not state.has("choices"): state["choices"] = {}
		if not state.has("puzzles"): state["puzzles"] = {}
		if not state.has("checkpoints"): state["checkpoints"] = {}
		# Preserve saves made by the earlier classification prototype.
		if state["puzzles"].has("evidence_sort") and not state["puzzles"].has("witness_replay"):
			state["puzzles"]["witness_replay"] = state["puzzles"]["evidence_sort"].duplicate(true)
		if state["puzzles"].has("evidence_reconstruction") and not state["puzzles"].has("witness_replay"):
			state["puzzles"]["witness_replay"] = state["puzzles"]["evidence_reconstruction"].duplicate(true)
		if not state.has("completed"): state["completed"] = false

func reset_story() -> void:
	chapters.clear()
