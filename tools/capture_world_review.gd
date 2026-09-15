extends SceneTree

const Support = preload("res://tests/polish_support.gd")
const CHAPTERS := [
	[1, "res://scenes/chapters/chapter_01_entry.tscn"],
	[2, "res://scenes/chapters/chapter_02_temple.tscn"],
	[3, "res://scenes/chapters/chapter_03_garden.tscn"],
]
const VIEWPOINTS := [
	["left", 170.0],
	["center", 1024.0],
	["right", 1880.0],
]

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://output/world_review")
	for definition: Array in CHAPTERS:
		var chapter: Node = load(definition[1]).instantiate()
		chapter.persistence_enabled = false
		root.add_child(chapter)
		var actor: Node2D = chapter.crowd_player if definition[0] == 1 else chapter.player
		await Support.reach_exploration(chapter, actor)
		if chapter.has_node("FadeLayer/Fade"):
			chapter.get_node("FadeLayer/Fade").color.a = 0.0
		for view: Array in VIEWPOINTS:
			actor.position.x = view[1]
			await create_timer(0.5).timeout
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png(
				"res://output/world_review/chapter-%d-%s.png" % [definition[0], view[0]]
			)
		chapter.free()
		await process_frame
	print("WORLD REVIEW CAPTURES COMPLETE")
	quit()
