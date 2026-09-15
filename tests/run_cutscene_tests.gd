extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _labels_below(node: Node) -> Array[String]:
	var result: Array[String] = []
	if node is Label:
		result.append(node.text)
	for child in node.get_children():
		result.append_array(_labels_below(child))
	return result

func _all_interludes() -> Array:
	var entries: Array = []
	for data in BiblicalContext.CHAPTERS.values():
		entries.append(data)
	for data in BiblicalContext.TRANSITIONS.values():
		entries.append(data)
	entries.append_array([
		BiblicalContext.NIGHT,
		BiblicalContext.PROCESSION,
		BiblicalContext.DEATH,
		BiblicalContext.BURIAL,
	])
	return entries

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for data in _all_interludes():
		var shots := BiblicalContext.cutscene_shots(data)
		check(shots.size() >= 2, "%s must be a multi-shot cutscene" % data.title)
		for shot in shots:
			check(shot.size() == 2 and not str(shot[0]).is_empty(), "%s has a drawable stage" % data.title)
			check(not str(shot[1]).is_empty() and str(shot[1]).length() <= 90, "%s uses a short visual caption" % data.title)
	for role in BibleInterlude.CutsceneCast:
		var texture: Texture2D = BibleInterlude.CutsceneCast[role]
		check(texture != null and texture.get_height() > 0, "Cutscene cast role has a usable sprite: " + role)

	var data: Dictionary = BiblicalContext.NIGHT
	var sequence := BibleInterlude.new()
	root.add_child(sequence)
	sequence.build(data)
	await create_timer(0.45).timeout
	check(sequence.ready_to_advance, "First cutscene shot becomes advanceable")
	check(sequence.shot_index == 0, "Cutscene starts on its first shot")
	check(sequence.caption_label.text == BiblicalContext.cutscene_shots(data)[0][1], "Caption matches the visible shot")
	var labels := _labels_below(sequence)
	check(not labels.has(str(data.reference)), "Bible reference stays in the journal instead of the cutscene")
	check(not labels.has(str(data.text)), "Long background text is replaced by visual shots")

	var emitted := [0]
	sequence.advanced.connect(func(): emitted[0] += 1)
	while sequence.shot_index < sequence.shots.size() - 1:
		var previous := sequence.shot_index
		sequence._advance()
		await create_timer(0.45).timeout
		check(sequence.shot_index == previous + 1, "Advance moves to exactly one following shot")
	sequence._advance()
	sequence._advance()
	check(emitted[0] == 1, "Cutscene completion emits exactly once")
	sequence.free()

	print("CUTSCENE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, ")")
	quit(1 if failures else 0)
