extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_director_accepts_any_interaction_order()
	_test_story_beat_contract()
	_test_chapter_one_world_layout()
	_test_chapter_two_requirements()
	_test_chapter_two_world_layout()
	_test_chapter_definitions_and_puzzle_contract()
	_test_future_chapter_contracts()
	_test_npc_cast_integrity()
	_test_biblical_transitions()
	_test_checkpoint_migration()
	_test_dialogue_input()
	await _test_runtime_visual_baseline_refresh()
	await _test_used_visual_state_persists()
	await _test_future_chapter_runtime()
	await _test_menu_and_speech_settings()
	if failures == 0:
		print("Story system tests: PASS")
		quit(0)
	else:
		push_error("Story system tests: %d failure(s)" % failures)
		quit(1)

func _expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _test_chapter_definitions_and_puzzle_contract() -> void:
	var first := StoryData.get_definition(1)
	var second := StoryData.get_definition(2)
	_expect(first.production_ready and second.production_ready, "Completed chapters must be marked production-ready")
	_expect(first.scene_path == "res://scenes/chapters/chapter_01_entry.tscn", "Chapter definitions must own scene routing")
	_expect(StoryData.CHAPTERS[2].title.contains("발소리"), "Chapter 3 must use the combined waiting-and-arrest canon")
	var puzzle := NarrativePuzzle.new()
	root.add_child(puzzle)
	puzzle.configure(&"test", "구분", [{
		"prompt": "직접 본 것",
		"answer": &"seen",
		"hint": "다시 본다",
		"options": [{"id": &"heard", "label": "들은 것"}, {"id": &"seen", "label": "본 것"}]
	}])
	_expect(not puzzle.submit(&"heard") and puzzle.active, "Narrative puzzles must remain active after a wrong answer")
	_expect(puzzle.submit(&"seen") and not puzzle.active, "Narrative puzzles must complete on grounded evidence")
	puzzle.free()

func _test_future_chapter_contracts() -> void:
	var puzzle_ids: Array[StringName] = [&"lantern_route", &"trial_evidence_links", &"passion_evidence_links", &"resurrection_evidence_links"]
	for chapter_number in range(3, 7):
		var definition := StoryData.get_definition(chapter_number)
		_expect(definition.production_ready, "Only completed world chapters must be available in release exports")
		var packed := load(definition.scene_path) as PackedScene
		_expect(packed != null, "Chapter %d scene must load from its definition" % chapter_number)
		var has_puzzle := false
		var has_choice_ids := false
		for line in StoryData.CHAPTERS[chapter_number - 1].lines:
			if line.get("puzzle", {}).get("id", StringName()) == puzzle_ids[chapter_number - 3]:
				has_puzzle = true
			if line.get("choice_ids", []).size() == 3:
				has_choice_ids = true
		_expect(has_puzzle, "Chapter %d must provide its distinct narrative puzzle" % chapter_number)
		_expect(has_choice_ids, "Chapter %d must store three semantic reflection choices" % chapter_number)

func _test_checkpoint_migration() -> void:
	var state := root.get_node("StoryState")
	var before: Dictionary = state.get_state().duplicate(true)
	state.load_state({"schema_version": 2, "chapters": {"chapter_04": {"observed": {}, "choices": {}, "puzzles": {}, "completed": false}}})
	_expect(state.get_chapter_summary(&"chapter_04").has("checkpoints"), "Older saves must gain checkpoint storage")
	state.set_checkpoint(&"chapter_04", &"evidence_link", {"accepted": ["a__b"]})
	var restored: Dictionary = state.get_checkpoint(&"chapter_04", &"evidence_link")
	restored.accepted.append("changed")
	_expect(state.get_checkpoint(&"chapter_04", &"evidence_link").accepted.size() == 1, "Checkpoint reads must not mutate saved state")
	state.clear_checkpoint(&"chapter_04", &"evidence_link")
	_expect(state.get_checkpoint(&"chapter_04", &"evidence_link").is_empty(), "Completed investigations clear their checkpoint")
	state.load_state(before)

func _test_npc_cast_integrity() -> void:
	_expect(NPCCast.reuse_conflicts().is_empty(), "One NPC image may not represent different people across chapters")
	for entry: Dictionary in NPCCast.ENTRIES:
		_expect(ResourceLoader.exists(entry.path), "NPC asset must exist: " + entry.path)

func _test_biblical_transitions() -> void:
	for chapter_number in [1, 2, 3, 6]:
		var transition: Dictionary = BiblicalContext.TRANSITIONS.get(chapter_number, {})
		_expect(not transition.is_empty(), "Chapter %d must explain the time and place change" % chapter_number)
		_expect(not str(transition.get("reference", "")).is_empty(), "Chapter transition must cite its biblical basis")
	_expect(BiblicalContext.PROCESSION.reference.contains("15:15"), "Chapter 4 must connect the verdict to the procession")
	_expect(BiblicalContext.BURIAL.reference.contains("15:42"), "Chapter 5 must connect the death to the burial")

func _test_menu_and_speech_settings() -> void:
	for bus_name in [&"Master", &"Ambience", &"SFX", &"UI", &"Dialogue"]:
		_expect(AudioServer.get_bus_index(bus_name) >= 0, "Static audio layout must include %s" % bus_name)
	var menu := load("res://scenes/menu/main_menu.tscn").instantiate() as Control
	root.add_child(menu)
	await process_frame
	var confirmation := menu.get("reset_confirmation") as ConfirmationDialog
	_expect(confirmation != null and confirmation.cancel_button_text == "취소", "Reset must offer explicit confirmation and cancellation")
	_expect(menu.get_node("Center/StartButton").has_theme_stylebox_override("focus"), "Menu buttons need visible keyboard focus")
	_expect(menu.get("ambience_slider") != null and menu.get("text_scale_option") != null, "Commercial settings must expose category audio and readable text controls")
	var settings_panel := menu.get_node("SettingsLayer/SettingsPanel") as PanelContainer
	var settings_box := menu.get_node("SettingsLayer/SettingsPanel/Box") as VBoxContainer
	_expect(settings_box.get_combined_minimum_size().y <= settings_panel.size.y, "Expanded settings must fit inside the 720p panel")
	menu.free()
	var chapters := load("res://scenes/menu/chapter_select.tscn").instantiate() as Control
	root.add_child(chapters)
	for i in 6:
		var button := chapters.get_node("Chapters/Chapter%d" % (i + 1)) as Button
		_expect(button.text.contains(StoryData.CHAPTERS[i].title), "Chapter labels must use current story titles")
	chapters.free()
	var controller := SpeechBubbleController.new()
	controller.bubble_scene = load("res://scenes/common/speech_bubble.tscn")
	root.add_child(controller)
	var actor := Node2D.new()
	actor.name = "MerchantJonah"
	root.add_child(actor)
	controller.show_bubble(actor, "말풍선 설정 확인", &"witness")
	var bubble := controller.get_child(0) as SpeechBubble
	_expect(is_equal_approx(bubble.characters_per_second, float(root.get_node("GameState").get("text_speed"))), "World dialogue must respect the saved text speed")
	_expect(bubble.get_node("Margin/Speaker").text == "상인 요나", "World dialogue must identify its speaker")
	controller.close_bubble()
	controller.free()
	actor.free()

func _test_future_chapter_runtime() -> void:
	for chapter_number in range(3, 7):
		var chapter := (load(StoryData.get_scene_path(chapter_number)) as PackedScene).instantiate()
		root.add_child(chapter)
		await process_frame
		if chapter_number == 3:
			_expect(chapter.get("route_puzzle") is NarrativePuzzle, "Chapter 3 retains its narrative bridge puzzle")
		else:
			_expect(chapter.get("puzzle") == null, "Chapter %d must use the in-world evidence system instead of a popup puzzle" % chapter_number)
		chapter.free()

func _test_dialogue_input() -> void:
	var bubble := load("res://scenes/common/speech_bubble.tscn").instantiate() as SpeechBubble
	root.add_child(bubble)
	bubble.show_text("입력 분리 확인")
	var label := bubble.get_node("Margin/Text") as Label
	var interact := InputEventAction.new()
	interact.action = &"interact"
	interact.pressed = true
	root.push_input(interact)
	_expect(label.visible_characters == 0 and bubble.visible, "E must not reveal or dismiss dialogue")
	var advance := InputEventKey.new()
	advance.physical_keycode = KEY_SPACE
	advance.pressed = true
	root.push_input(advance)
	_expect(label.visible_characters == -1 and bubble.visible, "First Space must reveal text")
	advance.echo = true
	root.push_input(advance)
	_expect(bubble.visible, "Held Space must not skip dialogue")
	advance.echo = false
	root.push_input(advance)
	_expect(not bubble.visible, "Second Space must dismiss dialogue")
	bubble.free()
	var target := InteractableComponent.new()
	target.interaction_enabled = false
	_expect(not target.can_interact(), "Locked clues must not be selectable")
	target.interaction_enabled = true
	_expect(target.can_interact(), "Unlocked clues must become selectable")
	target.free()
	var dialogue := DialogueController.new()
	var speaker_label := Label.new()
	var dialogue_label := Label.new()
	var advance_button := Button.new()
	var choice_a := Button.new()
	var choice_b := Button.new()
	var choice_c := Button.new()
	dialogue.setup(speaker_label, dialogue_label, advance_button, choice_a, choice_b, choice_c)
	dialogue.start([{
		"speaker": "나", "text": "세 관점",
		"choices": ["질서", "기도", "유보"],
		"responses": [{"text": "질서"}, {"text": "기도"}, {"text": "유보"}]
	}])
	dialogue.advance()
	_expect(choice_c.visible and choice_c.text == "유보", "Dialogue controller must expose a third keyboard-selectable choice")
	for node in [dialogue, speaker_label, dialogue_label, advance_button, choice_a, choice_b, choice_c]:
		node.free()

func _test_runtime_visual_baseline_refresh() -> void:
	var target := InteractableComponent.new()
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.scale = Vector2(1.05, 1.05)
	target.add_child(visual)
	root.add_child(target)
	await process_frame
	visual.scale = Vector2(0.05, 0.05)
	target.refresh_visual_baseline()
	target.set_focused(true)
	await create_timer(0.22).timeout
	_expect(visual.scale.x < 0.06, "Runtime-normalized NPCs must not return to their source scale when focused")
	target.free()

func _test_used_visual_state_persists() -> void:
	var target := InteractableComponent.new()
	target.one_shot = true
	target.dim_on_use = true
	var visual := Sprite2D.new()
	visual.name = "Visual"
	target.add_child(visual)
	root.add_child(target)
	await process_frame
	target.set_focused(true)
	await create_timer(0.18).timeout
	target.interact()
	await create_timer(0.22).timeout
	_expect(visual.modulate.is_equal_approx(Color(0.78, 0.74, 0.66, 0.82)), "Used evidence must remain dim after its focus tween completes")
	target.free()

func _test_director_accepts_any_interaction_order() -> void:
	var director := ChapterDirector.new()
	var required: Array[StringName] = [&"palm_leaf", &"discarded_cloak", &"footprints", &"merchant_jonah", &"miriam"]
	director.required_interactions = required
	director.begin_chapter()
	director.record_interaction(&"footprints")
	director.record_interaction(&"miriam")
	director.record_interaction(&"palm_leaf")
	director.record_interaction(&"merchant_jonah")
	_expect(director.current_beat == &"approach", "Director advanced before every required clue and rumor was observed")
	director.record_interaction(&"discarded_cloak")
	_expect(director.current_beat == &"encounter", "Director did not enter encounter after all required clues and rumors")
	var count: int = director.get_state()["observed"].size()
	director.record_interaction(&"discarded_cloak")
	_expect(director.get_state()["observed"].size() == count, "One-shot narrative observation was counted twice")
	director.finish_encounter()
	_expect(director.current_beat == &"aftermath", "Jesus conversation must leave exploration open")
	director.record_interaction(&"crowd_elder")
	_expect(director.current_beat == &"aftermath", "Optional opinions must not replay the encounter")
	director.free()

func _test_story_beat_contract() -> void:
	var beats: Array = StoryData.get_beats(&"chapter_01")
	_expect(beats.size() == 4 and beats[3].id == &"aftermath", "Chapter 1 must include post-encounter exploration")
	_expect(beats[1].get("required", []).size() == 5, "Chapter 1 approach beat must require three traces and two witness rumors")
	var chapter_two_beats: Array = StoryData.get_beats(&"chapter_02")
	_expect(chapter_two_beats.size() == 4 and chapter_two_beats[2].id == &"reflection", "Chapter 2 must investigate, reflect, then exit")
	_expect(chapter_two_beats[1].requirements.size() == 2, "Chapter 2 must keep evidence and witness requirements separate")

func _test_chapter_two_requirements() -> void:
	var director := ChapterDirector.new()
	director.requirement_groups = [
		{"ids": [&"scattered_coins", &"empty_table", &"prayer_corner"], "minimum": 2},
		{"ids": [&"merchant_jonah", &"miriam"], "minimum": 2}
	]
	director.requirements_met_beat = &"reflection"
	director.begin_chapter()
	director.record_interaction(&"scattered_coins")
	director.record_interaction(&"merchant_jonah")
	director.record_interaction(&"temple_guard")
	director.record_interaction(&"miriam")
	_expect(director.current_beat == &"investigation", "One clue plus every witness must not unlock Chapter 2 reflection")
	director.record_interaction(&"prayer_corner")
	_expect(director.current_beat == &"reflection", "Any two clues plus Jonah and Miriam must unlock reflection")
	director.finish_reflection()
	_expect(director.current_beat == &"aftermath", "Recording the Chapter 2 judgment must unlock the exit")
	director.free()

func _test_chapter_two_world_layout() -> void:
	var packed := load("res://scenes/chapters/chapter_02_temple.tscn") as PackedScene
	_expect(packed != null, "Chapter 2 temple scene must load")
	var chapter := packed.instantiate()
	var background := chapter.get_node("Background") as Sprite2D
	_expect(background.texture.get_size() == Vector2(2048, 720), "Chapter 2 background must provide the planned 2048x720 world")
	var camera := chapter.get_node("WorldCamera")
	_expect(camera.world_rect == Rect2(0, 0, 2048, 720), "Chapter 2 camera must clamp to the wide world")
	for path in ["ScatteredCoins", "EmptyTable", "PrayerCorner"]:
		var target := chapter.get_node(path) as InteractableComponent
		_expect(target != null and target.get_node("Visual").texture != null, "%s must have readable pixel-art evidence" % path)
		_expect(target.get_node_or_null("Body/CollisionShape2D") != null, "%s must have a physical footprint collision" % path)
	var audio_paths := [
		chapter.get_node("Audio/Market").stream.resource_path,
		chapter.get_node("Audio/Prayer").stream.resource_path
	]
	for audio_path in audio_paths:
		_expect(audio_path.begins_with("res://assets/audio/chapter02/"), "Chapter 2 ambience must not reuse Chapter 1 placeholders")
	_expect(chapter.get_node_or_null("CharacterLayer/JesusDonkey") == null, "Jesus must not appear in the Chapter 2 aftermath")
	_expect(chapter.get_node("UILayer/ChoicePanel/Box").get_child_count() == 4, "Chapter 2 reflection must present exactly three choices below its question")
	var story_state := root.get_node("StoryState")
	var saved_story: Dictionary = story_state.get_state()
	for judgment in [&"order", &"prayer", &"uncertain"]:
		story_state.reset_story()
		_expect(chapter.record_judgment(judgment, false), "Every planned Chapter 2 judgment must be accepted")
		_expect(story_state.get_choice(&"chapter_02", &"temple_judgment") == judgment, "Chapter 2 judgment must use the temple_judgment save key")
	_expect(not chapter.record_judgment(&"unsupported", false), "Unknown Chapter 2 judgments must be rejected")
	story_state.reset_story()
	_expect(chapter.get_carryover_line().contains("말보다 더 오래"), "Chapter 2 needs a neutral carryover when no optional resident was heard")
	story_state.record_observation(&"chapter_01", &"crowd_pilgrim")
	_expect(chapter.get_carryover_line().contains("순례자"), "Chapter 2 must remember the pilgrim when the porter was not heard")
	story_state.record_observation(&"chapter_01", &"crowd_porter")
	_expect(chapter.get_carryover_line().contains("짐꾼"), "Porter memory must take priority when both optional residents were heard")
	story_state.load_state(saved_story)
	chapter.free()

func _test_chapter_one_world_layout() -> void:
	var packed := load("res://scenes/chapters/chapter_01_entry.tscn") as PackedScene
	var chapter := packed.instantiate()
	var background := chapter.get_node("BackgroundLayer") as Sprite2D
	_expect(background != null and background.texture != null, "Chapter 1 must use a world-space Sprite2D background")
	_expect(background.texture.get_size() == Vector2(2048, 720), "Chapter 1 background must match Chapter 2's 2048x720 world")
	_expect(not background.centered and background.position == Vector2.ZERO, "Chapter 1 background must render pixel-for-pixel from the world origin")
	var camera := chapter.get_node("WorldCamera")
	_expect(camera.world_rect == Rect2(0, 0, 2048, 720), "Chapter 1 camera limits must match the full remade world")
	var player := chapter.get_node("CrowdPlayer") as CharacterBody2D
	_expect(player.movement_bounds == Rect2(54, 318, 1940, 362), "Chapter 1 movement bounds must span the wide walkable ground only")
	var interactable_sizes := {
		"PalmLeafInteractable/Visual": Vector2(120, 80),
		"DiscardedCloakInteractable/Visual": Vector2(120, 80),
		"FootprintsInteractable/Visual": Vector2(88, 96)
	}
	for path in interactable_sizes:
		var visual := chapter.get_node(path) as Sprite2D
		_expect(visual != null and visual.texture != null, "%s must have a visible investigation prop" % path)
		_expect(visual.texture.resource_path.ends_with("_ch02_style.png"), "%s must use the shared Chapter 2 object style" % path)
		_expect(visual.texture.get_size() == interactable_sizes[path], "%s must keep its gameplay-sized canvas" % path)
	for path in ["MerchantJonah/Visual", "Miriam/Visual"]:
		var visual := chapter.get_node(path) as Sprite2D
		_expect(visual != null and visual.texture != null, "%s must have a visible NPC" % path)
	var boundary := chapter.get_node("WorldBounds/Top/CollisionPolygon2D") as CollisionPolygon2D
	_expect(boundary != null and boundary.polygon.size() >= 4, "Sky and city wall need a collision boundary")
	var lowest_boundary := 0.0
	for point in boundary.polygon:
		lowest_boundary = maxf(lowest_boundary, point.y)
	_expect(lowest_boundary >= 300.0 and lowest_boundary <= 315.0, "Collision boundary must follow the remade city wall base")
	var jesus := chapter.get_node("CharacterLayer/JesusDonkey") as TextureRect
	_expect(jesus.texture.get_size() == Vector2(150, 138), "Jesus must use the compact chibi sprite")
	_expect(jesus.get_meta("head_anchor_local", Vector2.ZERO) == Vector2(61, 15), "Jesus must define an explicit head anchor for world speech bubbles")
	for path in [
		"MerchantJonah/Body/CollisionShape2D",
		"Miriam/Body/CollisionShape2D",
		"WorldBounds/GateThreshold/CollisionShape2D",
		"WorldBounds/LeftRoadsideProps/CollisionPolygon2D",
		"WorldBounds/RightRoadsideProps/CollisionPolygon2D"
	]:
		_expect(chapter.get_node_or_null(path) != null, "%s must provide physical world collision" % path)
	var player_sprite := chapter.get_node("CrowdPlayer/Sprite") as Sprite2D
	var leaf := chapter.get_node("PalmLeafInteractable") as Node2D
	var cloak := chapter.get_node("DiscardedCloakInteractable") as Node2D
	var footprints := chapter.get_node("FootprintsInteractable") as Node2D
	var jonah := chapter.get_node("MerchantJonah") as Node2D
	var miriam := chapter.get_node("Miriam") as Node2D
	_expect(absf(leaf.position.x - jonah.position.x) >= 100.0, "Palm leaf must remain visually separate from Jonah")
	_expect(jonah.position.x < leaf.position.x and leaf.position.x < cloak.position.x and cloak.position.x < footprints.position.x and footprints.position.x < miriam.position.x, "Required NPCs and clues must form a readable left-to-right exploration route")
	_expect(chapter.get_node("TempleEntrance").position == Vector2(1024, 314), "Temple entrance interaction must align with the painted gate")
	_expect(miriam.position == Vector2(1740, 590), "Miriam must stand clear of Jesus's right-road entrance")
	_expect(jonah.get_interaction_anchor() == jonah.get_node("CollisionShape2D").global_position, "NPC targeting must use the actual conversation shape center")
	for npc_path in ["MerchantJonah/Visual", "Miriam/Visual"]:
		var npc := chapter.get_node(npc_path) as Sprite2D
		_expect(absf(npc.texture.get_height() * npc.scale.y - 67.2) < 1.0, "NPC height must match the player's visible height")
	_expect(is_equal_approx(player_sprite.scale.x, 0.075), "Player visual scale should use the smaller chibi presentation")
	chapter.free()
