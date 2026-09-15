extends Control

const DiscipleTheme = preload("res://scripts/ui_theme.gd")
@export var persistence_enabled := true
var credits_visible := false
var ambience: AudioStreamPlayer
var lines := []
var index := 0
var visible_count := 0.0
var typing := false
var transitioning := false
var progress_label: Label
var fade: ColorRect
var pause_menu: JourneyPauseMenu

func _ready() -> void:
	lines = _build_lines()
	$Background.texture = load("res://assets/art/late_chapters/dawn.png")
	DiscipleTheme.apply_button($BackButton)
	DiscipleTheme.apply_button($Panel/Box/Advance)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.11, 0.16, 0.93)
	style.border_color = Color("be915b")
	style.set_border_width_all(1)
	style.set_content_margin_all(24)
	$Panel.add_theme_stylebox_override("panel", style)
	$Panel/Box/Text.add_theme_color_override("font_color", Color("f1dfad"))
	$Panel/Box/Speaker.add_theme_color_override("font_color", Color("e7bd72"))
	ambience = AudioStreamPlayer.new()
	var wind := load("res://assets/audio/chapter01/wind_loop.wav").duplicate() as AudioStreamWAV
	wind.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambience.stream = wind
	ambience.bus = "Ambience"
	ambience.volume_db = -28
	add_child(ambience)
	ambience.play()
	$Title.add_theme_color_override("font_color", Color("f1dfad"))
	$Title.add_theme_color_override("font_shadow_color", Color("211c28"))
	$Title.add_theme_constant_override("shadow_offset_x", 2)
	$Title.add_theme_constant_override("shadow_offset_y", 2)
	$Title.add_theme_constant_override("outline_size", 4)
	$Title.add_theme_color_override("font_outline_color", Color("211c28"))
	$Panel/Box/Text.add_theme_font_size_override("font_size", roundi(21 * GameState.text_scale))
	$Panel/Box/Text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Panel/Box/Speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Panel/Box/Advance.alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label = Label.new()
	progress_label.add_theme_color_override("font_color", Color("be915b"))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Panel/Box.add_child(progress_label)
	$Panel/Box.move_child(progress_label, 0)
	fade = ColorRect.new()
	fade.color = Color(0.13, 0.11, 0.16, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	create_tween().tween_property(fade, "color:a", 0.0, 0.8)
	get_viewport().size_changed.connect(_layout_ending)
	call_deferred("_layout_ending")
	$Panel/Box/Advance.grab_focus()
	$BackButton.pressed.connect(_return_to_chapters)
	$Panel/Box/Advance.pressed.connect(_advance)
	_show_line()
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	pause_menu.can_open = func(): return not transitioning
	add_child(pause_menu)

func _build_lines() -> Array:
	var result: Array = [["복음서의 증언", "예수님은 십자가에서 죽으시고 무덤에 묻히셨으며, 부활하셨습니다. 막달라 마리아는 주님을 보았다고 제자들에게 전했습니다. (요한복음 20:18 요약)"]]
	var memories := _curated_memories()
	for memory in memories:
		result.append(["회상", memory])
	result.append(["질문", "당신은 그를 보았습니까?"])
	result.append(["질문", "당신이라면, 그날 군중 속에서 어디에 서 있었을까요?"])
	result.append(["질문", "모두가 외칠 때, 당신은 어떤 목소리를 내고 있었습니까?"])
	result.append(["", "제자라는 이름은 답이 아니라, 이제 당신에게 남은 질문입니다."])
	return result

func _curated_memories() -> Array[String]:
	var candidates: Array[String] = []
	var chapter_one := StoryState.get_chapter_summary(&"chapter_01")
	var observed: Dictionary = chapter_one.get("observed", {})
	if observed.has("palm_leaf") and observed.has("discarded_cloak") and observed.has("footprints"):
		candidates.append("당신은 종려잎과 버려진 겉옷, 성문으로 향한 발자국을 하나의 길로 이었습니다.")
	var temple_choice: StringName = StoryState.get_choice(&"chapter_02", &"temple_judgment", StringName())
	var temple_memories := {&"order": "당신은 성전의 무너진 질서를 걱정했습니다.", &"prayer": "당신은 소음 뒤에서 기도할 자리를 보았습니다.", &"uncertain": "당신은 성전에서 서로 다른 말을 들은 뒤 판단을 미뤘습니다."}
	if temple_memories.has(temple_choice): candidates.append(temple_memories[temple_choice])
	var chapter_three_choice: StringName = StoryState.get_choice(&"chapter_03", &"chapter_choice", StringName())
	var chapter_three_lines := {
		&"followed_sound": "당신은 어둠 속의 발소리를 따라 재판장 쪽으로 걸었습니다.",
		&"stayed_back": "당신은 체포 행렬과 거리를 두면서도 완전히 돌아서지는 않았습니다.",
		&"helped_runner": "당신은 달아나던 사람에게 먼저 손을 내밀었습니다."
	}
	if chapter_three_lines.has(chapter_three_choice): candidates.append(chapter_three_lines[chapter_three_choice])
	var court_choice: StringName = StoryState.get_choice(&"chapter_04", &"chapter_choice", StringName())
	var court_memories := {&"protected_family": "당신은 재판장 담을 따라 아이와 주민이 빠져나갈 길을 도왔습니다.", &"recorded_verdict": "당신은 바라바의 석방과 예수님을 넘긴 판결을 기록했습니다.", &"prayed_at_edge": "당신은 군중 가장자리에서 성 밖으로 가는 행렬을 바라보며 기도했습니다."}
	if court_memories.has(court_choice): candidates.append(court_memories[court_choice])
	var chapter_five_choice: StringName = StoryState.get_choice(&"chapter_05", &"chapter_choice", StringName())
	var chapter_five_lines := {
		&"offered_water": "당신은 누가 마실지 모르는 물그릇을 길가에 두었습니다.",
		&"stood_beside": "당신은 혼자 선 사람의 곁에서 침묵을 나누었습니다.",
		&"kept_watching": "당신은 사람들이 떠난 뒤까지 고개를 돌리지 않았습니다."
	}
	if chapter_five_lines.has(chapter_five_choice): candidates.append(chapter_five_lines[chapter_five_choice])
	var chapter_six_choice: StringName = StoryState.get_choice(&"chapter_06", &"chapter_choice", StringName())
	var chapter_six_lines := {
		&"trusted_testimony": "당신은 자신이 보지 못한 것을 말하는 떨리는 증언을 신뢰했습니다.",
		&"needed_proof": "당신은 빈자리 앞에서도 더 많은 증거가 필요하다고 남았습니다.",
		&"remained_open": "당신은 모른다는 말을 닫힌 결론으로 만들지 않았습니다."
	}
	if chapter_six_lines.has(chapter_six_choice): candidates.append(chapter_six_lines[chapter_six_choice])
	if candidates.is_empty():
		candidates.append("당신은 군중 속에서 사람들의 목소리와 남겨진 흔적을 보았습니다.")
	return candidates

func _process(delta: float) -> void:
	if not typing: return
	visible_count += GameState.text_speed * delta
	$Panel/Box/Text.visible_characters = int(visible_count)
	if visible_count >= lines[index][1].length():
		typing = false
		$Panel/Box/Text.visible_characters = -1
		$Panel/Box/Advance.text = "계속  ›" if index < lines.size() - 1 else "크레딧  ›"

func _show_line() -> void:
	progress_label.text = "%d / %d" % [index + 1, lines.size()]
	$Panel/Box/Speaker.text = lines[index][0]
	$Panel/Box/Text.text = lines[index][1]
	$Panel/Box/Text.visible_characters = 0
	visible_count = 0.0
	typing = true
	$Panel/Box/Advance.text = "···"

func _advance() -> void:
	if transitioning: return
	if credits_visible:
		_return_to_chapters()
		return
	if typing:
		visible_count = lines[index][1].length()
		typing = false
		$Panel/Box/Text.visible_characters = -1
		$Panel/Box/Advance.text = "계속  ›" if index < lines.size() - 1 else "크레딧  ›"
		return
	index += 1
	if index < lines.size():
		_show_line()
	else:
		_show_credits()

func _show_credits() -> void:
	if credits_visible: return
	progress_label.text = "여정의 끝"
	credits_visible = true
	typing = false
	$Title.text = "THE THIRTEENTH DISCIPLE"
	$Panel/Box/Speaker.text = "제작 기록"
	$Panel/Box/Text.visible_characters = -1
	$Panel/Box/Text.add_theme_font_size_override("font_size", roundi(18 * GameState.text_scale))
	$Panel/Box/Text.text = "군중 속에서 멈추어 주셔서 감사합니다.\n\n제작 · Gavin Park   |   엔진 · Godot\n월드 아트 · AI 생성 및 프로젝트 아트디렉션\n폴리 · Kenney (CC0)   |   발소리와 재질음 · Kenney RPG Audio"
	$Panel/Box/Advance.text = "장면 선택으로  ›"
	call_deferred("_layout_ending")
	create_tween().tween_property($Background, "modulate", Color(1.12, 1.08, 1.0), 2.0)
	if persistence_enabled:
		StoryState.complete_chapter(&"chapter_07")
		GameState.save_progress()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_chapters()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_advance()

func _layout_ending() -> void:
	var view := get_viewport_rect().size
	var panel := $Panel as PanelContainer
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(minf(940, view.x - 64), 0)
	panel.position = Vector2((view.x - panel.size.x) * 0.5, view.y - panel.size.y - 40)

func _return_to_chapters() -> void:
	if transitioning: return
	transitioning = true
	$Panel/Box/Advance.disabled = true
	$BackButton.disabled = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fade, "color:a", 1.0, 0.55)
	tween.tween_property(ambience, "volume_db", -50.0, 0.55)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn")
