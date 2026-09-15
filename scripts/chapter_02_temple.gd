extends WorldChapterBase

const Story = preload("res://story_data.gd")
const EVIDENCE_IDS: Array[StringName] = [&"scattered_coins", &"empty_table", &"prayer_corner"]
const WITNESS_IDS: Array[StringName] = [&"merchant_jonah", &"miriam"]
const JUDGMENTS := [&"order", &"prayer", &"uncertain"]

@onready var director: ChapterDirector = $ChapterDirector
@onready var chapter_audio: ChapterTwoAudio = $ChapterAudio
@onready var choice_panel: PanelContainer = $UILayer/ChoicePanel
@onready var choice_buttons: Array[Button] = [
	$UILayer/ChoicePanel/Box/Order,
	$UILayer/ChoicePanel/Box/Prayer,
	$UILayer/ChoicePanel/Box/Uncertain
]
@onready var temple_exit: InteractableComponent = $TempleExit

var field_complete := false
var heard_echo := false
var reflection_open := false
var entering_temple := false
var coin_puzzle: CoinGatherPuzzle
var table_puzzle: TableShiftPuzzle
var prayer_puzzle: PrayerClothPuzzle
var _pending_interaction_data: Dictionary = {}

func _ready() -> void:
	chapter_number = 2
	setup_world_chapter()
	$UILayer/Header/Title.text = "제2장 · 성전의 소음"
	$UILayer/Header/Place.text = "예루살렘 성전 바깥 시장"
	world_camera.world_rect = Rect2(0, 0, 2048, 720)
	player.movement_bounds = Rect2(54, 386, 1940, 294)
	player.global_position = Vector2(150, 590)
	player.set_meta("head_offset", Vector2(0, -88))
	$Player/AudioListener2D.make_current()
	director.chapter_id = chapter_id
	director.beat_changed.connect(_on_beat_changed)
	director.interaction_recorded.connect(_on_interaction_recorded)
	director.chapter_completed.connect(_on_chapter_completed)
	register_interactables(_world_interactables())
	_normalize_large_npc($TempleGuard/Visual, 68.0)
	_configure_choices()
	_configure_object_puzzles()
	chapter_audio.setup($Audio, player)
	_start_ambience()
	temple_exit.interaction_enabled = false
	choice_panel.hide()
	director.begin_chapter(Story.get_definition(2))
	set_world_input(false)
	call_deferred("_play_opening")

func _normalize_large_npc(sprite: Sprite2D, visible_height: float) -> void:
	var source := sprite.texture
	if source == null:
		return
	var used_rect := source.get_image().get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = used_rect
	sprite.texture = atlas
	sprite.scale = Vector2.ONE * visible_height / float(used_rect.size.y)
	var interaction := sprite.get_parent() as InteractableComponent
	if interaction:
		interaction.refresh_visual_baseline()

func _configure_choices() -> void:
	for button in choice_buttons:
		DiscipleTheme.apply_button(button)
	for index in choice_buttons.size():
		choice_buttons[index].pressed.connect(_choose_judgment.bind(index))
	choice_buttons[0].focus_neighbor_bottom = choice_buttons[1].get_path()
	choice_buttons[1].focus_neighbor_top = choice_buttons[0].get_path()
	choice_buttons[1].focus_neighbor_bottom = choice_buttons[2].get_path()
	choice_buttons[2].focus_neighbor_top = choice_buttons[1].get_path()

func _start_ambience() -> void:
	for output in [$Audio/Market, $Audio/Prayer]:
		var stream := output.stream.duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		output.stream = stream
		output.play()

func _play_opening() -> void:
	await fade_in()
	await BibleInterlude.present(self, BiblicalContext.CHAPTERS[2])
	fade_chapter_header()
	await show_world_line(player, "다음 날 성전으로 다시 왔다. 예수님이 상들을 뒤엎으셨다는 말을 들었다. 뜰에는 동전과 쓰러진 상이 남아 있다.", &"protagonist")
	await show_world_line(player, get_carryover_line(), &"protagonist")
	_update_objective()
	set_world_input(true)

func get_carryover_line() -> String:
	if StoryState.has_observed(&"chapter_01", &"crowd_porter"):
		return "소란의 대가는 우리 같은 사람이 치른다던 짐꾼의 말이 떠오른다."
	if StoryState.has_observed(&"chapter_01", &"crowd_pilgrim"):
		return "성전에서 무슨 일이 있었는지 먼저 보겠다던 순례자의 말이 떠오른다."
	return "그가 떠난 자리에는 말보다 더 오래 남은 것들이 있다."

func _world_interactables() -> Array[Node]:
	return [
		$ScatteredCoins, $EmptyTable, $PrayerCorner,
		$MerchantJonah, $Miriam, $TempleGuard, $TempleExit
	]

func _on_world_interacted(interaction_id: StringName, data: Dictionary) -> void:
	if interaction_id == &"temple_exit":
		if director.current_beat == &"reflection":
			_open_reflection()
		elif director.current_beat == &"aftermath":
			_enter_temple()
		return
	set_world_input(false)
	chapter_audio.investigate(interaction_id)
	var speaker := _speaker_for(interaction_id)
	var is_witness := interaction_id in [&"merchant_jonah", &"miriam", &"temple_guard"]
	var interaction_details: Dictionary = data.get("data", {})
	var dialogue: Array = interaction_details.get("dialogue", [])
	if dialogue.is_empty():
		if is_witness:
			await show_world_line(player, "무슨 일이 있었는지 보셨습니까?", &"protagonist")
		await show_world_line(speaker, str(data.get("description", "")), &"witness" if is_witness else &"protagonist")
	else:
		for line: Dictionary in dialogue:
			var line_speaker: CanvasItem = player if line.get("speaker", "target") == "player" else speaker
			var line_style: StringName = &"protagonist" if line_speaker == player else &"witness"
			await show_world_line(line_speaker, str(line.get("text", "")), line_style)
	if _start_object_puzzle(interaction_id, data):
		return
	_finish_interaction(interaction_id, data)

func _finish_interaction(interaction_id: StringName, data: Dictionary) -> void:
	director.record_interaction(interaction_id, data)
	if interaction_id == &"prayer_corner" and not heard_echo:
		heard_echo = true
		await show_world_line($EchoAnchor, "…내 집은 기도하는 집이라…", &"witness")
	_update_objective()
	set_world_input(true)

func _start_object_puzzle(_interaction_id: StringName, _data: Dictionary) -> bool:
	return false

func _speaker_for(interaction_id: StringName) -> CanvasItem:
	match interaction_id:
		&"merchant_jonah": return $MerchantJonah
		&"miriam": return $Miriam
		&"temple_guard": return $TempleGuard
		_: return player

func _on_interaction_recorded(interaction_id: StringName, data: Dictionary) -> void:
	record_observation(interaction_id, data)

func _on_beat_changed(beat_id: StringName) -> void:
	if beat_id == &"reflection":
		temple_exit.interaction_enabled = true
		reflection_open = true
	_update_objective()

func _update_objective() -> void:
	if director.current_beat == &"reflection":
		objective_label.text = "오른쪽 성전 안쪽 출구에서, 본 것의 의미를 돌아보세요."
		return
	if director.current_beat == &"aftermath":
		objective_label.text = "선택이 기록되었습니다. 성전 안쪽 출구에서 E · 다음 장"
		return
	var evidence_count := 0
	for interaction_id in EVIDENCE_IDS:
		evidence_count += int(director.has_observed(interaction_id))
	var witness_count := 0
	for interaction_id in WITNESS_IDS:
		witness_count += int(director.has_observed(interaction_id))
	objective_label.text = "현장의 흔적과 상반된 증언을 확인하세요. · 흔적 %d/2 · 증언 %d/2" % [mini(evidence_count, 2), witness_count]

func _open_reflection() -> void:
	if not reflection_open or choice_panel.visible:
		return
	if not field_complete:
		begin_field_investigation(2, _world_interactables(), _field_finished)
		return
	set_world_input(false)
	interaction_prompt.hide()
	choice_panel.show()
	DiscipleTheme.trap_button_focus(choice_buttons)
	choice_buttons[0].grab_focus()

func _configure_object_puzzles() -> void:
	coin_puzzle = CoinGatherPuzzle.new()
	table_puzzle = TableShiftPuzzle.new()
	prayer_puzzle = PrayerClothPuzzle.new()
	for puzzle in [coin_puzzle, table_puzzle, prayer_puzzle]:
		$UILayer.add_child(puzzle)
	coin_puzzle.completed.connect(_on_object_puzzle_completed.bind(&"scattered_coins"))
	table_puzzle.completed.connect(_on_object_puzzle_completed.bind(&"empty_table"))
	prayer_puzzle.completed.connect(_on_object_puzzle_completed.bind(&"prayer_corner"))

func _on_object_puzzle_completed(result: Dictionary, interaction_id: StringName) -> void:
	StoryState.record_puzzle(chapter_id, interaction_id, result)
	if persistence_enabled:
		GameState.save_progress()
	_apply_object_result(interaction_id, result)
	match interaction_id:
		&"scattered_coins":
			await show_world_line(player, "동전은 다시 상 위로 돌아가지 않았다. 발에 밟히지 않도록 한쪽 천 위에 모아 두었다.", &"protagonist")
		&"empty_table":
			await show_world_line(player, "상을 세우지는 않았다. 다만 사람들이 다시 지나갈 통로는 열어 두었다.", &"protagonist")
		&"prayer_corner":
			await show_world_line(player, "새 자리를 만든 것이 아니다. 소음에 가려졌던 자리를 다시 펼쳐 두었을 뿐이다.", &"protagonist")
	_finish_interaction(interaction_id, _pending_interaction_data)

func _apply_object_result(interaction_id: StringName, result: Dictionary) -> void:
	match interaction_id:
		&"scattered_coins":
			$ScatteredCoins/Visual.modulate = Color(0.82, 0.76, 0.62, 0.45)
			$ScatteredCoins/Visual.position.x += 28.0
		&"empty_table":
			var direction := int(result.get("direction", 1))
			$EmptyTable.position.x += direction * 88.0
			$EmptyTable/Visual.rotation += direction * 0.05
		&"prayer_corner":
			$PrayerCorner/Visual.modulate = Color(1.08, 1.03, 0.88, 1.0)
			$PrayerCorner/Visual.scale *= 1.04

func _choose_judgment(index: int) -> void:
	if not choice_panel.visible or index < 0 or index >= JUDGMENTS.size():
		return
	choice_panel.hide()
	record_judgment(JUDGMENTS[index], persistence_enabled)
	director.finish_reflection()
	await show_world_line(player, "나는 그 사람을 보지 못했다. 다만 그가 떠난 뒤, 무엇이 비워지고 무엇이 다시 드러났는지는 보았다.", &"protagonist")
	_update_objective()
	set_world_input(true)

func record_judgment(judgment: StringName, persist := true) -> bool:
	if not judgment in JUDGMENTS:
		return false
	StoryState.record_choice(&"chapter_02", &"temple_judgment", judgment)
	if persist:
		GameState.save_progress()
	return true

func _enter_temple() -> void:
	if entering_temple or transitioning or director.current_beat != &"aftermath":
		return
	entering_temple = true
	temple_exit.interaction_enabled = false
	set_world_input(false)
	$UILayer/Header/BackButton.disabled = true
	objective_label.text = "조용해진 뜰을 지나 오늘의 성전을 떠납니다…"
	player.collision_mask = 0
	player.set_cinematic_walk(Vector2.RIGHT)
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(player, "global_position", $ExitInside.global_position, 1.35).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(player, "modulate:a", 0.0, 0.45).set_delay(0.85)
	await tween.finished
	player.set_cinematic_walk(Vector2.ZERO)
	director.complete_chapter()

func _on_chapter_completed(_completed_chapter_id: StringName) -> void:
	finish_world_chapter()

func _field_finished(result: Dictionary) -> void:
	field_complete = true
	if persistence_enabled:
		StoryState.record_puzzle(chapter_id, &"temple_restoration", result)
		GameState.save_progress()
	objective_label.text = "통로와 기도 자리를 정돈했습니다. 성전 출구에서 E · 돌아보기"
