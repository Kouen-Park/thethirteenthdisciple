extends SceneTree
const Support = preload("res://tests/polish_support.gd")
var current_chapter: Node

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if is_instance_valid(current_chapter): Support.advance_interlude(current_chapter)

func close_lines(bubbles: SpeechBubbleController, count: int) -> void:
	for i in count:
		var guard := 0
		while bubbles.get_child_count() == 0 and guard < 120:
			await frames(1)
			guard += 1
		check(bubbles.get_child_count() > 0, "Expected dialogue line %d/%d to open" % [i + 1, count])
		bubbles.close_bubble()
		await frames(2)

func interact_and_close(target: InteractableComponent, bubbles: SpeechBubbleController, line_count: int) -> void:
	check(target.can_interact(), "%s must be interactable on the planned route" % target.name)
	target.interact()
	await close_lines(bubbles, line_count)
	await frames(2)

func _run() -> void:
	var story_state := root.get_node("StoryState")
	var saved_story: Dictionary = story_state.get_state()
	var packed := load("res://scenes/chapters/chapter_02_temple.tscn") as PackedScene
	var chapter: Node = packed.instantiate()
	current_chapter = chapter
	chapter.set("persistence_enabled", false)
	root.add_child(chapter)
	var bubbles := chapter.get_node("SpeechBubbleController") as SpeechBubbleController
	var director := chapter.get_node("ChapterDirector") as ChapterDirector

	await frames(55)
	await close_lines(bubbles, 2)
	var player := chapter.get_node("Player") as CrowdPlayerController
	check(player.input_enabled, "Chapter 2 opening must return control to the player")
	var guard := chapter.get_node("TempleGuard") as InteractableComponent
	var guard_visual := guard.get_node("Visual") as Sprite2D
	var guard_height := guard_visual.texture.get_height() * guard_visual.scale.y
	check(guard_height <= 69.0, "Temple guard must be normalized before interaction focus")
	guard.set_focused(true)
	await frames(14)
	check(guard_visual.texture.get_height() * guard_visual.scale.y < 76.0, "Temple guard focus must use the normalized baseline instead of source scale")
	guard.set_focused(false)
	await frames(14)
	check(is_equal_approx(guard_visual.texture.get_height() * guard_visual.scale.y, guard_height), "Temple guard must return to its normalized height after focus")
	var chapter_audio := chapter.get_node("ChapterAudio") as ChapterTwoAudio
	for interaction_id in [&"scattered_coins", &"empty_table", &"prayer_corner"]:
		chapter_audio.investigate(interaction_id)
		check(chapter_audio.investigation.stream.resource_path.begins_with("res://assets/audio/chapter02/"), "Every investigation effect must use a dedicated Chapter 2 asset")

	var coins := chapter.get_node("ScatteredCoins") as InteractableComponent
	check(chapter.get("coin_puzzle") is CoinGatherPuzzle, "Coins must use their own gathering interaction")
	check(chapter.get("table_puzzle") is TableShiftPuzzle, "The overturned table must use its own pushing interaction")
	check(chapter.get("prayer_puzzle") is PrayerClothPuzzle, "The prayer place must use its own unfolding interaction")
	coins.interact()
	await close_lines(bubbles, 3)
	check(player.input_enabled, "Observation restores walking without a modal puzzle")
	await interact_and_close(chapter.get_node("MerchantJonah"), bubbles, 4)
	await interact_and_close(chapter.get_node("Miriam"), bubbles, 4)
	check(director.current_beat == &"investigation", "Both witnesses plus one clue must not unlock reflection")
	var table := chapter.get_node("EmptyTable") as InteractableComponent
	table.interact()
	await close_lines(bubbles, 3)
	check(director.current_beat == &"reflection", "Two clues and both required witnesses must unlock reflection")
	var temple_exit := chapter.get_node("TempleExit") as InteractableComponent
	check(temple_exit.can_interact(), "Temple exit must activate for reflection")
	check(chapter.get_node("TempleGuard").can_interact(), "Guard must remain optional when reflection unlocks")
	check(chapter.get_node("PrayerCorner").can_interact(), "Third clue must remain optional when reflection unlocks")
	var prayer := chapter.get_node("PrayerCorner") as InteractableComponent
	prayer.interact()
	await close_lines(bubbles, 3)
	await close_lines(bubbles, 1)
	check(director.current_beat == &"reflection", "Optional care tasks must not skip the reflection")

	temple_exit.interact()
	await frames(2)
	var field: Node = chapter.field_investigation
	check(chapter.get_node("MerchantJonah").can_interact(), "Witness stays available during restoration")
	chapter.get_node("MerchantJonah").interact()
	await close_lines(bubbles, 4)
	chapter._open_reflection()
	check(chapter.field_investigation == field and director.current_beat == &"reflection", "Repeated witness and exit preserve investigation")
	check(await Support.finish_field(chapter.field_investigation, player), "Physical restoration finishes before reflection")
	temple_exit.interact()
	await frames(2)
	var choice_panel := chapter.get_node("UILayer/ChoicePanel") as PanelContainer
	check(choice_panel.visible, "Exit must open the three-way reflection choice")
	var uncertain_button := chapter.get_node("UILayer/ChoicePanel/Box/Uncertain") as Button
	uncertain_button.pressed.emit()
	await close_lines(bubbles, 1)
	check(director.current_beat == &"aftermath", "Choosing a perspective must unlock the final exit")
	check(story_state.get_choice(&"chapter_02", &"temple_judgment") == &"uncertain", "Actual choice button must record temple_judgment")

	temple_exit.interact()
	await frames(95)
	check(director.current_beat == &"complete", "Walking through the inner exit must complete Chapter 2")
	check(player.global_position.is_equal_approx(chapter.get_node("ExitInside").global_position), "Exit cinematic must reach the inner marker")
	check(player.modulate.a < 0.05, "Exit cinematic must fade the player before completion")

	story_state.load_state(saved_story)
	chapter.free()
	print("Chapter 2 playthrough tests: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
