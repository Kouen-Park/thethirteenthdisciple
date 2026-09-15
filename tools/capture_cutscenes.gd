extends SceneTree

const OUTPUT := "res://output/cutscenes"

func _initialize() -> void:
	call_deferred("_capture")

func _shot_index(shots: Array, stage: String) -> int:
	for index in shots.size():
		if str(shots[index][0]) == stage:
			return index
	return 0

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var captures := [
		["01-entry", BiblicalContext.CHAPTERS[1], "entry"],
		["02-temple-clearing", BiblicalContext.CHAPTERS[2], "temple_clear"],
		["03-betrayal", BiblicalContext.NIGHT, "betrayal"],
		["04-to-pilate", BiblicalContext.TRANSITIONS[3], "to_pilate"],
		["05-simon", BiblicalContext.PROCESSION, "simon"],
		["06-death", BiblicalContext.DEATH, "death"],
		["07-burial", BiblicalContext.BURIAL, "burial"],
		["08-open-tomb", BiblicalContext.CHAPTERS[6], "open_tomb"],
		["09-supper", BiblicalContext.NIGHT, "supper"],
		["10-denial", BiblicalContext.TRANSITIONS[3], "denial"],
		["11-release", BiblicalContext.PROCESSION, "release"],
		["12-tomb-message", BiblicalContext.TRANSITIONS[6], "message"],
		["13-mary-meets", BiblicalContext.TRANSITIONS[6], "mary_meets"],
	]
	for item in captures:
		var sequence := BibleInterlude.new()
		root.add_child(sequence)
		sequence.build(item[1])
		await sequence._show_shot(_shot_index(sequence.shots, item[2]))
		await create_timer(0.12).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(OUTPUT + "/" + item[0] + ".png")
		sequence.free()
		await process_frame
	print("CUTSCENE CAPTURES COMPLETE")
	quit()

