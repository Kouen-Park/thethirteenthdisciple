extends SceneTree

const Support = preload("res://tests/polish_support.gd")
const OUTPUT := "res://output/npc_audit"

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	print("NPC AUDIT CAPTURE START")
	await _capture_chapter_two()
	await _capture_chapter_three()
	print("NPC AUDIT CAPTURE COMPLETE")
	quit()

func _capture_chapter_two() -> void:
	var chapter: Node = load("res://scenes/chapters/chapter_02_temple.tscn").instantiate()
	chapter.persistence_enabled = false
	root.add_child(chapter)
	await Support.reach_exploration(chapter, chapter.player)
	chapter.get_node("FadeLayer/Fade").color.a = 0
	chapter.player.global_position = Vector2(1540, 590)
	chapter.world_camera.smooth_center = Vector2(1408, 360)
	chapter.world_camera.global_position = Vector2(1408, 360)
	await create_timer(0.8).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUTPUT + "/chapter02-temple-guard.png")
	chapter.free()
	await process_frame

func _capture_chapter_three() -> void:
	var chapter: Node = load("res://scenes/chapters/chapter_03_garden.tscn").instantiate()
	chapter.persistence_enabled = false
	root.add_child(chapter)
	await Support.reach_exploration(chapter, chapter.player)
	chapter.get_node("FadeLayer/Fade").color.a = 0
	chapter.player.global_position = Vector2(1510, 585)
	await create_timer(1.0).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUTPUT + "/chapter03-pilgrim.png")
	chapter.apply_night_state()
	chapter.director.current_beat = &"night_rumors"
	chapter._on_beat_changed(&"night_rumors")
	chapter.player.global_position = Vector2(1570, 585)
	await create_timer(0.8).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUTPUT + "/chapter03-runner-relative.png")
	chapter.free()
