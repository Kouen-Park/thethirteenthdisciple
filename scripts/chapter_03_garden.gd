extends WorldChapterBase

const Story = preload("res://story_data.gd")
const Data = preload("res://scripts/chapter_03_data.gd")
const RoutePuzzle = preload("res://scripts/lantern_route_puzzle.gd")
const NightAudio = preload("res://scripts/chapter_03_audio.gd")
const DAY_IDS: Array[StringName] = [&"waiting_well", &"waiting_cloth", &"miriam_day", &"jonah_day", &"waiting_traveler"]
const NIGHT_IDS: Array[StringName] = [&"broken_lantern", &"drag_marks", &"abandoned_sandal", &"miriam_night", &"jonah_night", &"closed_door", &"frightened_runner", &"guard_relative"]

@onready var director: ChapterDirector = $ChapterDirector
@onready var choice_panel: PanelContainer = $UILayer/ChoicePanel
var targets: Dictionary = {}
var route_puzzle: LanternRoutePuzzle
var chapter_audio: Node
var time_material: ShaderMaterial
var night := false
var chosen_action: StringName
var route_line: Line2D
var _time_tween: Tween
var _return_focus: Control
var _time_amount := 0.0

func _ready() -> void:
	chapter_number = 3
	setup_world_chapter()
	player.movement_bounds = Rect2(64, 410, 1920, 250)
	player.position = Vector2(170, 570)
	player.set_meta("head_offset", Vector2(0, -78))
	player.get_node("AudioListener2D").make_current()
	player.reparent($Actors)
	player.z_index = 0
	_normalize_player()
	$Background.texture = load(Data.ART + "courtyard.png")
	time_material = ShaderMaterial.new()
	time_material.shader = load(Data.ART + "time_of_day.gdshader")
	time_material.set_shader_parameter("night", 0.0)
	$Background.material = time_material
	_create_world()
	_configure_audio()
	_configure_interface()
	director.use_definition_flow = true
	director.beat_changed.connect(_on_beat_changed)
	director.interaction_recorded.connect(record_observation)
	director.chapter_completed.connect(func(_id): finish_world_chapter())
	director.begin_chapter(Story.get_definition(3))
	acquire_input_lock(&"opening")
	call_deferred("_opening")

func _normalize_player() -> void:
	player.normalize_visible_height(68)


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

func _create_world() -> void:
	_create_target(&"waiting_well", Vector2(420, 496), Data.ART + "well.png")
	_create_target(&"waiting_cloth", Vector2(690, 530), Data.ART + "waiting_cloth.png")
	_create_target(&"miriam_day", Vector2(550, 535), "res://assets/art/pixel/npcs/miriam.png", "미리암", 68)
	_create_target(&"jonah_day", Vector2(1120, 510), "res://assets/art/pixel/npcs/merchant_jonah.png", "상인 요나", 70)
	_create_target(&"waiting_traveler", Vector2(1350, 600), "res://assets/art/pixel/npcs/well_pilgrim.png", "갈릴리에서 온 순례자", 68)
	_create_target(&"broken_lantern", Vector2(995, 548), Data.ART + "broken_lantern.png")
	_create_target(&"drag_marks", Vector2(1320, 492), Data.ART + "drag_marks.png")
	_create_target(&"abandoned_sandal", Vector2(1630, 550), Data.ART + "abandoned_sandal.png")
	_create_target(&"miriam_night", Vector2(620, 510), "res://assets/art/pixel/npcs/miriam.png", "미리암", 68)
	_create_target(&"jonah_night", Vector2(1160, 600), "res://assets/art/pixel/npcs/merchant_jonah.png", "상인 요나", 70)
	_create_target(&"closed_door", Vector2(811, 355), Data.ART + "closed_door.png", "문 안의 목소리")
	# The door art sits on the architectural opening; its reachable anchor is below the sill.
	targets[&"closed_door"].get_node("CollisionShape2D").position.y = 72.0
	_create_target(&"frightened_runner", Vector2(1740, 610), "res://assets/art/pixel/npcs/frightened_runner.png", "도망쳐 온 청년", 68)
	_create_target(&"guard_relative", Vector2(1510, 445), "res://assets/art/pixel/npcs/guard_relative.png", "성전 경비의 친척", 68)
	_create_target(&"wait_until_night", Vector2(420, 570), "").prompt_text = "우물가에서 저녁까지 기다리기"
	_create_target(&"route_start", Vector2(1450, 610), "").prompt_text = "기름 자국과 현장에서 등불로 길 조사하기"
	_create_target(&"court_road", Vector2(1930, 460), "").prompt_text = "재판장 쪽 길 확인하기"
	_add_waypoint(&"wait_until_night", "기다리던 자리")
	_add_waypoint(&"route_start", "흔적이 이어지는 길목")
	_add_waypoint(&"court_road", "재판장으로 →")
	for id in Data.DAY:
		targets[id].prompt_text = Data.DAY[id][0]
		targets[id].description = Data.DAY[id][1]
		targets[id].interaction_data = {"period": "day", "lines": Data.DAY[id].slice(1)}
	for id in Data.NIGHT:
		targets[id].prompt_text = Data.NIGHT[id][0]
		targets[id].description = Data.NIGHT[id][1]
		targets[id].interaction_data = {"period": "night", "lines": Data.NIGHT[id].slice(1)}
	for id in targets:
		targets[id].interaction_enabled = false
	for id in NIGHT_IDS:
		targets[id].hide()
	# Solid footprint only: the surrounding courtyard stays traversable.
	_add_body(targets[&"waiting_well"], Vector2(122, 34), Vector2(0, -18))
	route_line = Line2D.new()
	route_line.z_index = -1
	route_line.width = 3.0
	route_line.default_color = Color(0.91, 0.74, 0.44, 0.45)
	route_line.points = PackedVector2Array([Vector2(995, 551), Vector2(1280, 551), Vector2(1320, 498), Vector2(1630, 553), Vector2(1910, 468)])
	route_line.hide()
	$Actors.add_child(route_line)

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

func _add_body(parent: Node, dimensions: Vector2, offset: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions
	shape.shape = rectangle
	shape.position = offset
	body.add_child(shape)
	parent.add_child(body)

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

func _configure_interface() -> void:
	choice_panel.hide()
	var buttons := [$UILayer/ChoicePanel/Box/Order, $UILayer/ChoicePanel/Box/Prayer, $UILayer/ChoicePanel/Box/Uncertain]
	for i in buttons.size():
		DiscipleTheme.apply_button(buttons[i])
		buttons[i].pressed.connect(_choose_action.bind(i))
	route_puzzle = RoutePuzzle.new()
	$UILayer.add_child(route_puzzle)
	route_puzzle.completed.connect(_on_route_completed)
	route_puzzle.canceled.connect(_on_route_canceled)
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()

func _layout_ui() -> void:
	var size := get_viewport_rect().size
	$FadeLayer/Fade.size = size
	$UILayer/Header.size.x = size.x
	$UILayer/Header/Title.size.x = size.x
	$UILayer/Header/Place.size.x = size.x
	$UILayer/HeaderShade.size.x = size.x
	choice_panel.position = Vector2((size.x - 850) * 0.5, size.y - 292)
	choice_panel.size = Vector2(850, 268)
	interaction_prompt.position = Vector2((size.x - 660) * 0.5, size.y - 56)
	interaction_prompt.size.x = 660
	_layout_reflection()

func _opening() -> void:
	await fade_in()
	await BibleInterlude.present(self, BiblicalContext.CHAPTERS[3])
	fade_chapter_header()
	await show_world_line(player, "성전에서 며칠이 지났다. 유월절 음식을 준비하는 사람들이 우물을 오간다. 저녁에는 예수님도 제자들과 식사하신다고 한다.", &"protagonist")
	await show_world_line(player, Data.carryover(StringName(StoryState.get_choice(&"chapter_02", &"temple_judgment", &"uncertain"))), &"protagonist")
	director.finish_defined_beat(&"intro_dismissed")
	release_input_lock(&"opening")

func _on_beat_changed(beat: StringName) -> void:
	for id in targets:
		var target: InteractableComponent = targets[id]
		if id in DAY_IDS:
			target.interaction_enabled = not night and beat in [&"day_waiting", &"dusk"]
		elif id in NIGHT_IDS:
			target.interaction_enabled = night and beat in [&"night_rumors", &"route", &"reflection", &"aftermath"]
		targets[&"wait_until_night"].interaction_enabled = beat == &"dusk"
		targets[&"route_start"].interaction_enabled = beat == &"route"
		targets[&"court_road"].interaction_enabled = beat in [&"reflection", &"aftermath"]
	for id in [&"wait_until_night", &"route_start", &"court_road"]:
		targets[id].get_node("Waypoint").visible = targets[id].interaction_enabled
	match beat:
		&"day_waiting": objective_label.text = "우물과 남겨진 물건을 살펴보고, 미리암에게 말을 걸어 보세요."
		&"dusk":
			objective_label.text = "그분은 아직 오지 않았습니다. 우물 앞에서 E · 저녁까지 기다리기"
			_set_time(0.32, 2.5)
		&"night_rumors": objective_label.text = "낮과 달라진 길의 세 흔적을 살피고, 미리암이나 요나에게 물어보세요."
		&"route": objective_label.text = "흔적이 꺾이는 길목에서 E · 현장에서 등불로 길 조사하기"
		&"reflection": objective_label.text = "오른쪽 재판장 길에서, 어떻게 움직일지 결정하세요."
		&"aftermath": objective_label.text = "길의 방향을 확인했습니다. 오른쪽 재판장 길에서 E · 다음 장"
		&"complete": objective_label.text = "발소리가 이어지는 재판장으로…"

func _on_world_interacted(id: StringName, data: Dictionary) -> void:
	if is_input_locked() or transitioning:
		return
	match id:
		&"wait_until_night":
			_wait_for_night()
			return
		&"route_start":
			_open_route()
			return
		&"court_road":
			if director.current_beat == &"reflection": _open_choice()
			elif director.current_beat == &"aftermath": _exit_to_court()
			return
	acquire_input_lock(&"interaction")
	chapter_audio.investigate(id)
	var lines: Array = Data.NIGHT.get(id, []) if night else Data.DAY.get(id, [])
	var target: InteractableComponent = targets[id]
	var witness := target.has_meta("display_name")
	for i in range(1, lines.size()):
		var speaker: CanvasItem = target if witness and i != 2 else player
		# Door's second line is the hidden resident, rather than the protagonist.
		if id == &"closed_door": speaker = target if i == 2 else player
		await show_world_line(speaker, str(lines[i]), &"witness" if speaker != player else &"protagonist")
	director.record_interaction(id, data)
	release_input_lock(&"interaction")

func _set_time(amount: float, duration: float) -> void:
	if _time_tween and _time_tween.is_valid(): _time_tween.kill()
	_time_tween = create_tween()
	_time_tween.tween_method(func(value: float):
		_time_amount = value
		time_material.set_shader_parameter("night", value), _time_amount, amount, duration)

func _wait_for_night() -> void:
	if director.current_beat != &"dusk": return
	acquire_input_lock(&"time_change")
	var waiting_line := "그릇을 치우지 않고 기다려 보기로 했다. 누군가 늦게라도 돌아올지 모르니까."
	if director.has_observed(&"waiting_traveler"):
		waiting_line = "먼 길을 온 여행자가 잠시 쉬어 갔다. 다음 사람도 마실 수 있도록 물을 남겨 두자."
	await show_world_line(player, waiting_line, &"protagonist")
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tween.finished
	await BibleInterlude.present(self, BiblicalContext.NIGHT)
	apply_night_state()
	await get_tree().create_timer(0.65, false).timeout
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
	await tween.finished
	await show_world_line(player, "문 닫히는 소리에 고개를 들었다. 기다리던 목소리 대신, 감람산 쪽에서 급한 발소리가 내려온다.", &"protagonist")
	director.finish_defined_beat(&"wait_until_night")
	release_input_lock(&"time_change")

func apply_night_state() -> void:
	night = true
	if _time_tween and _time_tween.is_valid(): _time_tween.kill()
	time_material.set_shader_parameter("night", 1.0)
	_time_amount = 1.0
	for id in DAY_IDS:
		if id not in [&"waiting_well", &"waiting_cloth"]: targets[id].hide()
		targets[id].interaction_enabled = false
	for id in NIGHT_IDS: targets[id].show()
	$Actors.modulate = Color(0.78, 0.79, 0.94)
	$UILayer/Header/Place.text = "같은 우물가 · 체포의 밤"
	chapter_audio.set_night()

func _open_route() -> void:
	if director.current_beat != &"route": return
	begin_field_investigation(3, targets.values(), _on_route_completed)

func _on_route_canceled() -> void:
	release_input_lock(&"puzzle")
	objective_label.text = "주변을 더 살펴볼 수 있습니다. 같은 길목에서 E · 방향 잇기 재개"

func _on_route_completed(result: Dictionary) -> void:
	acquire_input_lock(&"puzzle")
	if persistence_enabled:
		StoryState.record_puzzle(chapter_id, &"lantern_route", result)
		GameState.save_progress()
	route_line.show()
	await show_world_line(player, "기름 자국은 담을 따라 꺾여 재판장 쪽으로 이어진다. 예수님을 붙잡아 간 행렬이 지나간 길이다. 곁에서 보지 못한 일은 함부로 덧붙이지 말자.", &"protagonist")
	director.finish_defined_beat(&"route_connected")
	release_input_lock(&"puzzle")

func _open_choice() -> void:
	acquire_input_lock(&"choice")
	choice_panel.show()
	# Hidden containers can retain an early minimum height before text has wrapped.
	call_deferred("_layout_ui")
	DiscipleTheme.trap_button_focus([$UILayer/ChoicePanel/Box/Order, $UILayer/ChoicePanel/Box/Prayer, $UILayer/ChoicePanel/Box/Uncertain])
	$UILayer/ChoicePanel/Box/Order.grab_focus()

func _choose_action(index: int) -> void:
	if not choice_panel.visible or is_input_locked(&"leave") or index < 0 or index >= Data.CHOICES.size(): return
	choice_panel.hide()
	chosen_action = Data.CHOICES[index]
	if persistence_enabled:
		StoryState.record_choice(chapter_id, &"chapter_choice", chosen_action)
		GameState.save_progress()
	match chosen_action:
		&"followed_sound":
			await show_world_line(player, "소리를 따라가 보자. 소문이 되기 전에, 내 눈으로 볼 수 있는 데까지.", &"protagonist")
		&"stayed_back":
			await show_world_line(player, "가까이 서지는 못하겠다. 그래도 보이지 않는 곳까지 돌아서지는 말자.", &"protagonist")
			await player.walk_cinematic_path([Vector2(player.position.x, 630)])
		&"helped_runner":
			await player.walk_cinematic_path([Vector2(player.position.x, 650), Vector2(1780, 650)])
			player.face_toward(targets[&"frightened_runner"].position)
			await show_world_line(player, "서두르지 않아도 됩니다. 일어설 수 있겠습니까?", &"protagonist")
			await show_world_line(targets[&"frightened_runner"], "…고마워요. 큰길은 피할게요. 당신도 조심하세요.", &"witness")
			var tween := create_tween()
			tween.tween_property(targets[&"frightened_runner"], "position", Vector2(1540, 650), 1.2)
			tween.parallel().tween_property(targets[&"frightened_runner"], "modulate:a", 0.0, 0.5).set_delay(0.7)
			await tween.finished
			targets[&"frightened_runner"].interaction_enabled = false
	director.finish_defined_beat(&"choice_recorded")
	if chosen_action == &"helped_runner": targets[&"frightened_runner"].interaction_enabled = false
	release_input_lock(&"choice")

func _exit_to_court() -> void:
	if director.current_beat != &"aftermath": return
	acquire_input_lock(&"exit")
	$UILayer/Header/BackButton.disabled = true
	await player.walk_cinematic_path([Vector2(1940, player.position.y), Vector2(1980, 445)])
	director.finish_defined_beat(&"court_road_entered")

func _request_leave_chapter() -> void:
	if journal.active or transitioning or leave_confirmation.visible or is_input_locked(&"exit") or is_input_locked(&"time_change") or is_input_locked(&"opening"):
		return
	_return_focus = get_viewport().gui_get_focus_owner()
	acquire_input_lock(&"leave")
	route_puzzle.suspended = true
	route_puzzle.set_process_unhandled_key_input(false)
	choice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leave_confirmation.popup_centered(Vector2i(460, 180))
	leave_confirmation.get_cancel_button().grab_focus()

func _cancel_leave_chapter() -> void:
	route_puzzle.suspended = false
	route_puzzle.set_process_unhandled_key_input(true)
	release_input_lock(&"leave")
	choice_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree(): _return_focus.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"): return
	get_viewport().set_input_as_handled()
	if route_puzzle.active:
		route_puzzle.cancel_puzzle()
	elif choice_panel.visible:
		choice_panel.hide()
		release_input_lock(&"choice")
	else:
		_request_leave_chapter()
