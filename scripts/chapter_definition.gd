class_name ChapterDefinition
extends Resource

@export var chapter_id: StringName
@export_range(1, 7) var chapter_number := 1
@export var title := ""
@export var place := ""
@export_file("*.tscn") var scene_path := ""
@export_file("*.tscn") var next_scene_path := ""
@export var beats: Array[Dictionary] = []
@export var optional_interactions: Array[StringName] = []
@export var reflection_choices: Array[StringName] = []
@export var production_ready := false

static func from_dictionary(data: Dictionary) -> ChapterDefinition:
	var definition := ChapterDefinition.new()
	definition.chapter_id = StringName(data.get("id", ""))
	definition.chapter_number = int(data.get("number", 1))
	definition.title = str(data.get("title", ""))
	definition.place = str(data.get("place", ""))
	definition.scene_path = str(data.get("scene_path", ""))
	definition.next_scene_path = str(data.get("next_scene_path", ""))
	definition.beats.assign(data.get("beats", []))
	definition.optional_interactions.assign(data.get("optional_interactions", []))
	definition.reflection_choices.assign(data.get("reflection_choices", []))
	definition.production_ready = bool(data.get("production_ready", false))
	return definition
