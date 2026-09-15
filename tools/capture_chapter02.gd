extends SceneTree
const Support = preload("res://tests/polish_support.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var chapter: Node = load("res://scenes/chapters/chapter_02_temple.tscn").instantiate()
	root.add_child(chapter)
	chapter.persistence_enabled = false
	await Support.reach_exploration(chapter, chapter.player)
	chapter.get_node("FadeLayer/Fade").hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/disciple-chapter02.png")
	chapter.set_world_input(false)
	chapter.get_node("Player").global_position = Vector2(1540, 590)
	chapter.get_node("WorldCamera").smooth_center = Vector2(1408, 360)
	chapter.get_node("WorldCamera").global_position = Vector2(1408, 360)
	chapter.get_node("TempleGuard").set_focused(true)
	await create_timer(0.22).timeout
	chapter.get_node("UILayer/ChoicePanel").show()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/disciple-chapter02-right.png")
	chapter.free()
	quit()

