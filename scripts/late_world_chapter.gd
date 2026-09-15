extends WorldChapterBase

const Story = preload("res://story_data.gd")
const Data = preload("res://scripts/late_chapter_data.gd")
const NightAudio = preload("res://scripts/chapter_03_audio.gd")
@onready var choice_panel: PanelContainer = $UILayer/ChoicePanel
var targets: Dictionary = {}
var config: Dictionary
var observed: Dictionary = {}
var phase := "explore"
var puzzle: Node
var puzzle_data: Dictionary
var choice_data: Dictionary
var chapter_audio: Node
var chosen_action: StringName
var departure_tween: Tween

func _ready() -> void:
	setup_world_chapter()
	config = Data.get_data(chapter_number)
	player.movement_bounds = Rect2(64, 410, 1920, 250)
	player.position = Vector2(170, 580)
	player.set_meta("head_offset", Vector2(0, -78))
	player.get_node("AudioListener2D").make_current()
	player.reparent($Actors)
	player.z_index = 0
	_normalize_player()
	$Background.texture = load("res://assets/art/late_chapters/" + config.background + ".png")
	for entry in config.targets:
		var target := _create_target(entry[0], entry[1], entry[2], entry[3], 68 if not entry[3].is_empty() else 0)
		target.prompt_text = entry[4]
		target.description = entry[5][0]
		target.interaction_data = {"lines": entry[5]}
		if entry[2].is_empty(): _add_waypoint(entry[0], entry[4])
	_create_target(&"reflection", Vector2(1730, 590), "").prompt_text = config.puzzle_label
	_add_waypoint(&"reflection", config.puzzle_label)
	_create_target(&"exit", Vector2(1940, 490), "").prompt_text = config.exit
	_add_waypoint(&"exit", config.exit)
	for line in Story.CHAPTERS[chapter_number - 1].lines:
		if line.has("puzzle"): puzzle_data = line.puzzle
		if line.has("choice_ids"): choice_data = line
	choice_panel.hide()
	$UILayer/ChoicePanel/Box/Question.text = config.question
	var buttons := [$UILayer/ChoicePanel/Box/Order, $UILayer/ChoicePanel/Box/Prayer, $UILayer/ChoicePanel/Box/Uncertain]
	for i in 3:
		buttons[i].text = choice_data.choices[i]
		DiscipleTheme.apply_button(buttons[i])
		buttons[i].pressed.connect(_choose_action.bind(i))
	$UILayer/Header/Title.text = Story.CHAPTERS[chapter_number - 1].title
	$UILayer/Header/Place.text = config.place
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	_configure_audio()
	leave_confirmation.dialog_text = "관찰과 연결 기록은 저장됩니다.\n다시 들어오면 마지막 확인 단계에서 이어집니다."
	chapter_audio.market.volume_db = -28 if chapter_number == 4 else -38
	chapter_audio.prayer.volume_db = -25
	_restore_progress()
	_update_phase()
	acquire_input_lock(&"opening")
	call_deferred("_opening")

func _opening() -> void:
	await fade_in()
	await BibleInterlude.present(self, BiblicalContext.CHAPTERS[chapter_number])
	fade_chapter_header()
	await show_world_line(player, config.opening, &"protagonist")
	var previous: StringName = StoryState.get_choice(StringName("chapter_%02d" % (chapter_number - 1)), &"chapter_choice", StringName())
	var echoes := {
		&"helped_runner": "어젯밤 일으켜 준 청년의 손이 아직 기억난다. 이곳에서도 누군가는 두려워하고 있다.",
		&"stayed_back": "어젯밤처럼 가장자리에서 본다. 멀리 서 있다고 모든 말이 분명해지는 것은 아니다.",
		&"followed_sound": "발소리를 따라왔지만, 여기서는 어느 목소리를 따라야 할지 모르겠다.",
		&"protected_family": "재판장 담을 따라 아이와 주민을 도왔던 길이 떠오른다. 이곳에서도 곁에 남은 사람을 살핀다.",
		&"recorded_verdict": "재판장에서 확인한 판결이 이 언덕에서 집행되고 있다. 보았다고 기록할 일과 추측을 구분해야 한다.",
		&"prayed_at_edge": "재판장 가장자리에서 바라보며 기도했던 길의 끝에 왔다. 이번에는 눈을 돌리지 않으려 한다.",
		&"offered_water": "길가에 놓았던 그릇을 누가 들었는지는 모른다. 오늘도 모르는 일 앞에 서 있다.",
		&"stood_beside": "언덕 아래 함께 섰던 침묵을 기억한다. 오늘은 떨리는 말을 들어 보려 한다.",
		&"kept_watching": "끝까지 보았다고 모든 것을 아는 것은 아니었다. 새벽의 소문도 직접 확인하고 싶다."
	}
	if echoes.has(previous): await show_world_line(player, echoes[previous], &"protagonist")
	release_input_lock(&"opening")

func _update_phase() -> void:
	var count := 0
	for id in config.required:
		if observed.has(id): count += 1
	if phase == "explore" and count == config.required.size(): phase = "puzzle"
	targets[&"reflection"].interaction_enabled = phase in ["puzzle", "choice"]
	targets[&"reflection"].visible = phase in ["puzzle", "choice"]
	targets[&"exit"].interaction_enabled = phase == "aftermath"
	targets[&"exit"].visible = phase == "aftermath"
	match phase:
		"explore":
			var remaining: Array[String] = []
			for id in config.required:
				if not observed.has(id): remaining.append(targets[id].prompt_text)
			objective_label.text = "아직 살펴볼 것 · " + " / ".join(remaining.slice(0, 2))
			if remaining.size() > 2: objective_label.text += " 외 %d곳" % (remaining.size() - 2)
		"puzzle": objective_label.text = "오른쪽 길목에서 E · " + config.puzzle_label
		"choice":
			objective_label.text = "오른쪽 길목에서 E · 내가 취할 행동 선택"
			targets[&"reflection"].prompt_text = "내가 취할 행동 선택"
		"aftermath": objective_label.text = "준비되면 오른쪽 길에서 E · " + config.exit

func _on_world_interacted(id: StringName, data: Dictionary) -> void:
	if is_input_locked() or transitioning: return
	if id == &"exit":
		finish_world_chapter()
		return
	if id == &"reflection":
		if phase == "puzzle": _open_puzzle()
		elif phase == "choice": _open_choice()
		return
	acquire_input_lock(&"interaction")
	var target: InteractableComponent = targets[id]
	var speaker: CanvasItem = target if target.has_meta("display_name") and id not in [&"traveler", &"jonah"] else player
	var style: StringName = &"witness" if speaker == target else &"protagonist"
	chapter_audio.investigate(&"waiting_cloth" if id in [&"empty_bowl", &"fallen_cloth"] else &"drag_marks")
	for i in target.interaction_data.lines.size():
		var is_self: bool = id in [&"passerby", &"silent_witness"] and i == 1
		await show_world_line(player if is_self else speaker, target.interaction_data.lines[i], &"protagonist" if is_self else style)
	observed[id] = true
	record_observation(id, data)
	_update_phase()
	release_input_lock(&"interaction")

func _open_puzzle() -> void:
	begin_field_investigation(chapter_number, targets.values(), _puzzle_completed)

func _puzzle_completed(result: Dictionary) -> void:
	if persistence_enabled:
		StoryState.record_puzzle(chapter_id, puzzle_data.id, result)
		GameState.save_progress()
	phase = "choice"
	_update_phase()

func _open_choice() -> void:
	acquire_input_lock(&"choice")
	choice_panel.show()
	call_deferred("_layout_ui")
	DiscipleTheme.trap_button_focus([$UILayer/ChoicePanel/Box/Order, $UILayer/ChoicePanel/Box/Prayer, $UILayer/ChoicePanel/Box/Uncertain])
	$UILayer/ChoicePanel/Box/Order.grab_focus()

func _choose_action(index: int) -> void:
	if not choice_panel.visible or phase != "choice" or index < 0 or index >= choice_data.choice_ids.size(): return
	choice_panel.hide()
	chosen_action = choice_data.choice_ids[index]
	acquire_input_lock(&"aftermath")
	release_input_lock(&"choice")
	if persistence_enabled:
		StoryState.record_choice(chapter_id, &"chapter_choice", chosen_action)
		GameState.save_progress()
	# The action changes the player's place and care, never the historical event.
	var destination := player.position
	if chapter_number == 4:
		destination = [Vector2(1250, 580), Vector2(1510, 585), Vector2(1780, 640)][index]
	elif chapter_number == 5:
		destination = [Vector2(470, 450), Vector2(1500, 500), Vector2(1720, 580)][index]
	if destination != player.position:
		await player.walk_cinematic_path([Vector2(player.position.x, 650), Vector2(destination.x, 650), destination])
	await _show_action_result()
	await show_world_line(player, choice_data.responses[index].text, &"protagonist")
	if chapter_number == 4:
		await BibleInterlude.present(self, BiblicalContext.PROCESSION)
	if chapter_number == 5:
		await BibleInterlude.present(self, BiblicalContext.DEATH)
	if chapter_number in [4, 5]:
		await _depart_witnesses()
		if chapter_number == 5:
			await create_tween().tween_property($Background, "modulate", Color(0.70, 0.65, 0.79), 1.5).finished
	await show_world_line(player, config.after, &"protagonist")
	if chapter_number == 5:
		await BibleInterlude.present(self, BiblicalContext.BURIAL)
	phase = "aftermath"
	_update_phase()
	release_input_lock(&"aftermath")

func _request_leave_chapter() -> void:
	if is_input_locked(): return
	super._request_leave_chapter()

func _cancel_leave_chapter() -> void:
	release_input_lock(&"leave")
	$UILayer/Header/BackButton.release_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"): return
	get_viewport().set_input_as_handled()
	if choice_panel.visible:
		choice_panel.hide()
		release_input_lock(&"choice")
	else:
		_request_leave_chapter()
func _normalize_player() -> void:
	player.normalize_visible_height(68)

func _restore_progress() -> void:
	if not persistence_enabled:
		return
	var state: Dictionary = StoryState.get_chapter_summary(chapter_id)
	var saved_observed: Dictionary = state.get("observed", {})
	for id in config.required:
		if saved_observed.has(String(id)):
			observed[id] = true
	var saved_choice: StringName = StoryState.get_choice(chapter_id, &"chapter_choice", StringName())
	if not saved_choice.is_empty():
		chosen_action = saved_choice
		phase = "aftermath"
	elif state.get("puzzles", {}).has(String(puzzle_data.id)):
		phase = "choice"

func _show_action_result() -> void:
	match chosen_action:
		&"protected_family":
			await show_world_line(targets[&"mother"], "고마워요. 아이와 함께 담을 따라 나갈 수 있겠어요.", &"witness")
		&"recorded_verdict":
			objective_label.text = "기록 · 바라바는 석방되고 예수님은 십자가형에 넘겨졌다."
		&"prayed_at_edge":
			chapter_audio.prayer.volume_db = -14
		&"offered_water":
			targets[&"empty_bowl"].position = Vector2(460, 440)
			targets[&"empty_bowl"].modulate = Color.WHITE
			_add_bowl_visual(targets[&"empty_bowl"])
		&"stood_beside":
			await show_world_line(targets[&"silent_witness"], "…곁에 있어 주셔서 고마워요.", &"witness")
		&"trusted_testimony", &"needed_proof", &"remained_open":
			objective_label.text = "마리아의 증언을 들고 제자들이 있는 곳으로 향한다."

func _add_bowl_visual(target: Node2D) -> void:
	if target.has_node("BowlVisual"):
		return
	var bowl := Polygon2D.new()
	bowl.name = "BowlVisual"
	bowl.polygon = PackedVector2Array([Vector2(-18, -8), Vector2(18, -8), Vector2(11, 4), Vector2(-11, 4)])
	bowl.color = Color("b99a72")
	bowl.position.y = -5
	target.add_child(bowl)


func _create_target(id: StringName, pos: Vector2, texture_path: String, display_name := "", height := 0) -> InteractableComponent:
	var target := InteractableComponent.new()
	target.name = String(id).to_pascal_case()
	target.interaction_id = id
	target.position = pos
	target.dim_on_use = display_name.is_empty()
	if not display_name.is_empty():
		target.set_meta("display_name", display_name)
		target.set_meta("head_offset", Vector2(0, -76))
	if not texture_path.is_empty():
		var visual := Sprite2D.new()
		visual.name = "Visual"
		var texture: Texture2D = load(texture_path)
		if height > 0:
			var source := texture.get_image()
			source = source.get_region(source.get_used_rect())
			source.resize(maxi(1, roundi(float(source.get_width()) / source.get_height() * height)), height, Image.INTERPOLATE_NEAREST)
			texture = ImageTexture.create_from_image(source)
		visual.texture = texture
		visual.position = Vector2(0, -texture.get_height() * 0.5)
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		target.add_child(visual)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = 38.0
	collision.shape = shape
	target.add_child(collision)
	if height > 0:
		var body := StaticBody2D.new()
		body.name = "Body"
		var footprint := CollisionShape2D.new()
		var feet := RectangleShape2D.new()
		feet.size = Vector2(22, 12)
		footprint.shape = feet
		footprint.position.y = -6
		body.add_child(footprint)
		target.add_child(body)
		target.visibility_changed.connect(func(): body.collision_layer = 1 if target.is_visible_in_tree() else 0)
	$Actors.add_child(target)
	target.interacted.connect(_on_world_interacted)
	targets[id] = target
	return target


func _add_waypoint(id: StringName, caption: String) -> void:
	var marker := Node2D.new()
	marker.name = "Waypoint"
	var ring := Line2D.new()
	ring.points = PackedVector2Array([Vector2(-18, 0), Vector2(0, -7), Vector2(18, 0), Vector2(0, 7), Vector2(-18, 0)])
	ring.width = 2
	ring.default_color = Color(0.91, 0.74, 0.44, 0.6)
	marker.add_child(ring)
	var label := Label.new()
	label.position = Vector2(-120, 14)
	label.size.x = 240
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("e7bd72"))
	label.add_theme_color_override("font_shadow_color", Color("211c28"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	marker.add_child(label)
	targets[id].add_child(marker)


func _configure_audio() -> void:
	var audio := Node2D.new()
	audio.name = "Audio"
	add_child(audio)
	for settings in [["Market", "res://assets/audio/chapter01/crowd_loop.wav"], ["Prayer", "res://assets/audio/chapter01/wind_loop.wav"]]:
		var output := AudioStreamPlayer2D.new()
		output.name = settings[0]
		var stream := load(settings[1]).duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		output.stream = stream
		audio.add_child(output)
	chapter_audio = NightAudio.new()
	chapter_audio.name = "ChapterAudio"
	add_child(chapter_audio)
	chapter_audio.setup(audio, player)
	for output in audio.get_children():
		if output.name in ["Market", "Prayer"]: output.play()


func _layout_ui() -> void:
	var size := get_viewport_rect().size
	$FadeLayer/Fade.size = size
	$UILayer/Header.size.x = size.x
	$UILayer/Header/Title.size.x = size.x
	$UILayer/Header/Place.size.x = size.x
	$UILayer/HeaderShade.size.x = size.x
	choice_panel.size = Vector2(850, 0)
	var panel_height := maxf(268.0, choice_panel.get_combined_minimum_size().y)
	choice_panel.size.y = panel_height
	choice_panel.position = Vector2((size.x - 850) * 0.5, size.y - panel_height - 24)
	interaction_prompt.position = Vector2((size.x - 660) * 0.5, size.y - 56)
	interaction_prompt.size.x = 660
	_layout_reflection()

func _depart_witnesses() -> void:
	departure_tween = create_tween().set_parallel(true)
	departure_tween.tween_property(chapter_audio.market, "volume_db", -50.0, 3.0)
	var sequence := 0
	for id in targets:
		var actor: InteractableComponent = targets[id]
		if not actor.has_meta("display_name"): continue
		if chapter_number == 5 and id == &"silent_witness": continue
		actor.interaction_enabled = false
		if actor.has_node("Body"): actor.get_node("Body").collision_layer = 0
		# Let the person beside the player stay a moment longer.
		var delay := sequence * 0.28
		if chapter_number == 5 and id == &"silent_witness": delay += 0.7
		var direction := -1.0 if chapter_number == 5 else 1.0
		departure_tween.tween_property(actor, "position:x", actor.position.x + direction * 110, 2.1).set_delay(delay)
		departure_tween.tween_property(actor, "modulate:a", 0.0, 1.0).set_delay(delay + 1.1)
		sequence += 1
	await departure_tween.finished
