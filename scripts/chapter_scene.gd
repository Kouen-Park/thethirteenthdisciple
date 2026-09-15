extends Control

const Story = preload("res://story_data.gd")
const DiscipleTheme = preload("res://scripts/ui_theme.gd")
const CHAPTER_ONE_WORLD_RECT := Rect2(0.0, 0.0, 2048.0, 720.0)
const CHAPTER_ONE_PLAYER_START := Vector2(220.0, 630.0)
const CHAPTER_ONE_JESUS_STOP := Vector2(1070.0, 455.0)
const AUDIO_PATHS := {
	"wind": "res://assets/audio/chapter01/wind_loop.wav",
	"crowd": "res://assets/audio/chapter01/crowd_loop.wav",
	"footsteps": "res://assets/audio/chapter01/footsteps_loop.wav",
	"dialogue": "res://assets/audio/chapter01/dialogue_blip.wav",
	"leaf": "res://assets/audio/chapter01/leaf_place.wav",
	"transition": "res://assets/audio/chapter01/transition_whoosh.wav"
}

@export var persistence_enabled := true
@export_range(0, 5) var chapter_index := 0
@export_file("*.tscn") var finish_scene_path := "res://scenes/menu/chapter_select.tscn"

@onready var background_layer: Sprite2D = $BackgroundLayer
@onready var scene_art: Control = $SceneArt
@onready var character_layer: Control = $CharacterLayer
@onready var crowd_group: TextureRect = $CharacterLayer/CrowdGroup
@onready var jesus_donkey: TextureRect = $CharacterLayer/JesusDonkey
@onready var player_disciple: TextureRect = $CharacterLayer/PlayerDisciple
@onready var crowd_player: CharacterBody2D = $CrowdPlayer
@onready var dialogue_panel: PanelContainer = $UILayer/DialoguePanel
@onready var interaction_panel: PanelContainer = $UILayer/InteractionPanel
@onready var palm_drag: PalmDragInteraction = $UILayer/InteractionPanel/Box/PalmDrag
@onready var observation: Node = $UILayer/InteractionPanel/Box/Observation
@onready var fade_rect: ColorRect = $FadeLayer/Fade
@onready var dialogue_controller: Node = $DialogueController
@onready var interaction_controller: Node = $InteractionController
@onready var speech_bubbles: Node = $SpeechBubbleController
@onready var chapter_director: Node = $ChapterDirector
@onready var interaction_scanner: Node = $CrowdPlayer/InteractionScanner
@onready var interaction_prompt: Label = $WorldHUD/InteractionPrompt
@onready var objective_label: Label = $WorldHUD/Objective
@onready var chapter_one_encounter: ChapterOneEncounter = $ChapterOneEncounter

var journal: JourneyJournal
var pause_menu: JourneyPauseMenu
var transitioning := false
var crowd_target_position := Vector2.ZERO
var jesus_target_position := Vector2.ZERO
var world_sequence_active := false
var chapter_id: StringName
var investigation_unlocked := false
var entrance_tween: Tween
var leave_confirmation: ConfirmationDialog
var _resume_movement := false
var _resume_interaction := false
var entering_temple := false
var trail_puzzle: PalmDragInteraction
var trail_puzzle_complete := false
var field_investigation: FieldInvestigation
var story_puzzle: NarrativePuzzle
var _pending_puzzle_line: Dictionary = {}

func _ready() -> void:
	DiscipleTheme.apply_chapter(self)
	$UILayer/Header/BackButton.pressed.connect(_request_leave_chapter)
	leave_confirmation = ConfirmationDialog.new()
	leave_confirmation.title = "장면 선택으로 돌아갈까요?"
	leave_confirmation.dialog_text = "관찰 기록은 유지됩니다.\n다시 들어오면 이 장의 처음부터 시작합니다."
	leave_confirmation.ok_button_text = "장면 선택으로"
	leave_confirmation.cancel_button_text = "계속 플레이"
	add_child(leave_confirmation)
	leave_confirmation.confirmed.connect(_leave_chapter)
	leave_confirmation.canceled.connect(_cancel_leave_chapter)
	dialogue_controller.setup($UILayer/DialoguePanel/Box/Speaker, $UILayer/DialoguePanel/Box/Dialogue, $UILayer/DialoguePanel/Box/Advance, $UILayer/DialoguePanel/Box/ChoiceA, $UILayer/DialoguePanel/Box/ChoiceB, $UILayer/DialoguePanel/Box/ChoiceC)
	dialogue_controller.set_text_speed(GameState.text_speed)
	dialogue_controller.line_started.connect(_on_line_started)
	dialogue_controller.line_finished.connect(_on_line_finished)
	dialogue_controller.sequence_finished.connect(_finish_chapter)
	dialogue_controller.choice_selected.connect(_on_choice_selected)
	interaction_controller.setup($UILayer/InteractionPanel/Box/Action, $UILayer/InteractionPanel/Box/Hint)
	interaction_controller.progress_changed.connect(_on_interaction_progress)
	interaction_controller.selection_made.connect(_on_observation_selected)
	interaction_controller.completed.connect(_on_interaction_completed)
	interaction_scanner.interaction_requested.connect(_on_player_interaction_requested)
	interaction_scanner.target_changed.connect(_on_interaction_target_changed)
	chapter_director.interaction_recorded.connect(_on_interaction_recorded)
	chapter_director.beat_changed.connect(_on_beat_changed)
	chapter_director.chapter_completed.connect(_on_director_chapter_completed)
	chapter_one_encounter.setup(self)
	chapter_one_encounter.finished.connect(_on_chapter_one_encounter_finished)
	_configure_trail_puzzle()
	_configure_story_puzzle()
	chapter_id = StringName("chapter_%02d" % (chapter_index + 1))
	chapter_director.chapter_id = chapter_id
	if chapter_index == 0:
		_fade_chapter_header()
		_connect_world_interactables()
	chapter_director.begin_chapter(Story.get_definition(chapter_index + 1))

	var chapter: Dictionary = Story.CHAPTERS[chapter_index]
	scene_art.set_palette(chapter.palette)
	scene_art.set_chapter(chapter_index)
	$UILayer/Header/Title.text = chapter.title
	$UILayer/Header/Place.text = chapter.place
	_configure_chapter_layers()
	_load_audio()
	DiscipleTheme.apply_world_hud(objective_label, interaction_prompt, GameState.text_scale)
	journal = preload("res://scripts/journey_journal.gd").new()
	journal.current_chapter = chapter_index + 1
	journal.can_open = func(): return not transitioning and not entering_temple and crowd_player.input_enabled and interaction_scanner.input_enabled and not leave_confirmation.visible
	journal.opened.connect(func():
		crowd_player.set_input_enabled(false)
		interaction_scanner.set_input_enabled(false))
	journal.closed.connect(func():
		crowd_player.set_input_enabled(true)
		interaction_scanner.set_input_enabled(true))
	add_child(journal)
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	pause_menu.can_open = func(): return not transitioning and not entering_temple and not leave_confirmation.visible and not journal.active
	add_child(pause_menu)
	dialogue_panel.hide()
	call_deferred("_begin_opening_sequence", chapter)

func _begin_opening_sequence(chapter: Dictionary) -> void:
	crowd_player.set_input_enabled(false)
	interaction_scanner.set_input_enabled(false)
	await _fade_in()
	if chapter_index == 0:
		interaction_scanner.set_input_enabled(false)
		$Audio/Crowd.play()
		objective_label.text = "SPACE  대사 진행"
		await BibleInterlude.present(self, BiblicalContext.CHAPTERS[1])
		for line: String in Story.CHAPTER_ONE_OPENING:
			await _show_world_line(crowd_player, line, &"protagonist")
		_update_world_objective()
		crowd_player.set_input_enabled(true)
		interaction_scanner.set_input_enabled(true)
	else:
		crowd_player.set_input_enabled(true)
		dialogue_controller.start(chapter.lines)

func _fade_chapter_header() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property($UILayer/Header/Title, "modulate:a", 0.0, 0.6).set_delay(2.5)
	tween.tween_property($UILayer/Header/Place, "modulate:a", 0.0, 0.6).set_delay(2.5)
	tween.tween_property($UILayer/HeaderShade, "modulate:a", 0.18, 0.6).set_delay(2.5)

func _configure_chapter_layers() -> void:
	var is_chapter_one := chapter_index == 0
	background_layer.visible = is_chapter_one
	scene_art.visible = not is_chapter_one
	character_layer.visible = is_chapter_one
	# 제1장 플레이어 화면에서는 구형 합성 캐릭터를 끄고 새 주인공만 표시한다.
	crowd_group.visible = false
	jesus_donkey.visible = is_chapter_one
	player_disciple.visible = false
	crowd_player.visible = is_chapter_one
	crowd_player.z_index = 12
	if is_chapter_one:
		$WorldCamera.world_rect = CHAPTER_ONE_WORLD_RECT
		crowd_player.movement_bounds = Rect2(54.0, 318.0, 1940.0, 362.0)
		crowd_player.set_meta("head_offset", Vector2(0, -88))
		for npc in [$MerchantJonah, $Miriam]:
			npc.set_meta("head_offset", Vector2(0, -70))
		for target in [$PalmLeafInteractable, $DiscardedCloakInteractable, $FootprintsInteractable]:
			target.interaction_enabled = false
		crowd_player.global_position = CHAPTER_ONE_PLAYER_START
		crowd_target_position = crowd_group.position
		jesus_target_position = CHAPTER_ONE_JESUS_STOP
		crowd_group.pivot_offset = crowd_group.size * 0.5
		jesus_donkey.pivot_offset = jesus_donkey.size * 0.5
		player_disciple.pivot_offset = player_disciple.size * 0.5
		crowd_group.modulate = Color(1.0, 0.92, 0.76, 0.0)
		crowd_group.position = crowd_target_position + Vector2(-44.0, 8.0)
		crowd_group.scale = Vector2(0.94, 0.94)
		jesus_donkey.modulate = Color(1.0, 0.94, 0.82, 0.0)
		jesus_donkey.position = jesus_target_position + Vector2(58.0, 6.0)
		jesus_donkey.scale = Vector2(0.92, 0.92)
		player_disciple.modulate.a = 0.62
		player_disciple.position.x += 12.0
	else:
		interaction_panel.hide()
	for target in _world_interactables():
		target.process_mode = Node.PROCESS_MODE_INHERIT if is_chapter_one else Node.PROCESS_MODE_DISABLED
		target.visible = is_chapter_one
	$AmbientCrowd.visible = is_chapter_one
	$AmbientCrowd.process_mode = Node.PROCESS_MODE_INHERIT if is_chapter_one else Node.PROCESS_MODE_DISABLED
	$WorldCamera.enabled = is_chapter_one
	$WorldBounds.process_mode = Node.PROCESS_MODE_INHERIT if is_chapter_one else Node.PROCESS_MODE_DISABLED
	$WorldHUD.visible = is_chapter_one
	dialogue_panel.hide()
	interaction_panel.hide()

func _connect_world_interactables() -> void:
	for target in _world_interactables():
		target.one_shot = not String(target.interaction_id).begins_with("crowd_")
		if not target.interacted.is_connected(_on_world_interacted):
			target.interacted.connect(_on_world_interacted)

func _on_world_interacted(interaction_id: StringName, data: Dictionary) -> void:
	if interaction_id == &"temple_entrance":
		_enter_temple()
		return
	interaction_scanner.set_input_enabled(false)
	crowd_player.set_input_enabled(false)
	$ChapterAudio.investigate(interaction_id)
	objective_label.text = "SPACE  대사 진행"
	var speaker := _world_speaker_for(interaction_id)
	var optional_witness := String(interaction_id).begins_with("crowd_")
	var style: StringName = &"witness" if optional_witness or interaction_id in [&"merchant_jonah", &"miriam"] else &"protagonist"
	if optional_witness:
		await _show_world_line(crowd_player, "당신은 저분을 어떻게 생각하세요?", &"protagonist")
	elif style == &"witness":
		await _show_world_line(crowd_player, "무슨 일인가요? 오늘은 왜 이렇게 사람들이 몰려 있지요?", &"protagonist")
	await _show_world_line(speaker, str(data.get("description", "")), style)
	# Record only after the final line closes, so the encounter cannot replace it.
	chapter_director.record_interaction(interaction_id, data)
	if not investigation_unlocked and chapter_director.has_observed(&"merchant_jonah") and chapter_director.has_observed(&"miriam"):
		await _show_world_line(crowd_player, "예수라는 사람을 기다리는 거였구나. 그런데 두 사람의 이야기는 조금 다르다.", &"protagonist")
		await _show_world_line(crowd_player, "길 위에 잎과 옷이 남아 있다. 사람들이 무엇을 했는지 직접 살펴보자.", &"protagonist")
		investigation_unlocked = true
		for target in [$PalmLeafInteractable, $DiscardedCloakInteractable, $FootprintsInteractable]:
			target.interaction_enabled = true
		_update_world_objective()
	if is_instance_valid(field_investigation) and field_investigation.active:
		crowd_player.set_input_enabled(true)
		interaction_scanner.set_input_enabled(true)
		return
	if chapter_director.current_beat != &"encounter":
		_update_world_objective()
		crowd_player.set_input_enabled(true)
		interaction_scanner.set_input_enabled(true)

func _on_interaction_target_changed(target: Node) -> void:
	if target and target.has_method("get_prompt_text"):
		interaction_prompt.text = "E  %s" % target.get_prompt_text()
		interaction_prompt.show()
	else:
		interaction_prompt.hide()

func _on_interaction_recorded(interaction_id: StringName, data: Dictionary) -> void:
	if not persistence_enabled: return
	StoryState.record_observation(chapter_id, interaction_id, data)
	GameState.save_progress()
	_update_world_objective()

func _world_interactables() -> Array[Node]:
	var result: Array[Node] = [$PalmLeafInteractable, $DiscardedCloakInteractable, $FootprintsInteractable, $MerchantJonah, $Miriam, $TempleEntrance]
	result.append_array($AmbientCrowd.conversations())
	return result

func _world_speaker_for(interaction_id: StringName) -> CanvasItem:
	for conversation in $AmbientCrowd.conversations():
		if conversation.interaction_id == interaction_id:
			return conversation.get_parent()
	match interaction_id:
		&"merchant_jonah": return $MerchantJonah
		&"miriam": return $Miriam
		_: return crowd_player

func _update_world_objective() -> void:
	if chapter_director.current_beat == &"aftermath":
		objective_label.text = "주민들의 생각 듣기 (선택) · 준비되면 위쪽 성문으로 이동해 E · 성전으로"
		return
	var observed: Dictionary = chapter_director.get_state()["observed"]
	var trace_count := 0
	for interaction_id in [&"palm_leaf", &"discarded_cloak", &"footprints"]:
		trace_count += int(bool(observed.get(interaction_id, false)))
	var rumor_count := int(bool(observed.get(&"merchant_jonah", false))) + int(bool(observed.get(&"miriam", false)))
	if not investigation_unlocked:
		objective_label.text = "무슨 일인지 요나와 미리암에게 물어보세요. · 소문 %d/2 · E 대화" % rumor_count
	else:
		objective_label.text = "길 위에 남은 흔적을 살펴보세요. · 흔적 %d/3 · E 조사" % trace_count

func _on_beat_changed(beat_id: StringName) -> void:
	if chapter_index == 0 and beat_id == &"encounter" and not world_sequence_active:
		world_sequence_active = true
		_open_trail_puzzle()

func _configure_trail_puzzle() -> void:
	trail_puzzle = palm_drag
	trail_puzzle.completed.connect(_on_trail_puzzle_completed)

func _open_trail_puzzle() -> void:
	interaction_panel.hide()
	field_investigation = FieldInvestigation.new()
	add_child(field_investigation)
	field_investigation.completed.connect(func(_result): _on_trail_puzzle_completed())
	field_investigation.start(1, crowd_player, objective_label, _world_interactables())
	crowd_player.set_input_enabled(true)
	interaction_scanner.set_input_enabled(true)

func _on_trail_puzzle_completed() -> void:
	trail_puzzle_complete = true
	interaction_panel.hide()
	if persistence_enabled:
		StoryState.record_puzzle(chapter_id, &"welcome_path", {"action": &"laid_palm_branches", "count": 2, "completed": true, "mode": "world_investigation"})
		GameState.save_progress()
	chapter_one_encounter.call_deferred("play")

func _on_chapter_one_encounter_finished() -> void:
	chapter_director.finish_encounter()
	$AmbientCrowd.unlock_conversations()
	$TempleEntrance.interaction_enabled = true
	_update_world_objective()
	crowd_player.set_input_enabled(true)
	interaction_scanner.set_input_enabled(true)

func _enter_temple() -> void:
	if transitioning or entering_temple or chapter_director.current_beat != &"aftermath":
		return
	entering_temple = true
	$TempleEntrance.interaction_enabled = false
	interaction_scanner.set_input_enabled(false)
	crowd_player.set_input_enabled(false)
	$UILayer/Header/BackButton.disabled = true
	objective_label.text = "성문을 지나 성전으로 향합니다…"
	# The entrance interaction authorizes crossing the otherwise solid gate boundary.
	crowd_player.collision_mask = 0
	crowd_player.set_cinematic_walk(Vector2.UP)
	entrance_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	entrance_tween.tween_property(crowd_player, "position", $TempleEntrance/Approach.global_position, 0.55)
	entrance_tween.tween_property(crowd_player, "position", $TempleEntrance/Inside.global_position, 1.1)
	entrance_tween.parallel().tween_property(crowd_player, "modulate:a", 0.0, 0.4).set_delay(0.7)
	await entrance_tween.finished
	crowd_player.set_cinematic_walk(Vector2.ZERO)
	chapter_director.complete_chapter()

func _show_world_line(speaker: CanvasItem, text: String, style: StringName) -> void:
	speech_bubbles.show_bubble(speaker, text, style)
	await speech_bubbles.bubble_closed

func _on_line_started(line: Dictionary, _index: int) -> void:
	dialogue_panel.hide()
	interaction_panel.hide()
	_apply_line_event(String(line.get("event", "")))
	_apply_line_sound(String(line.get("sound", "")))
	var speaker_node := _speaker_node(String(line.get("speaker", "")))
	if speaker_node:
		speech_bubbles.show_bubble(speaker_node, String(line.get("text", "")), _speaker_style(String(line.get("speaker", ""))))

func _on_line_finished(line: Dictionary, _index: int) -> void:
	var puzzle_data: Dictionary = line.get("puzzle", {})
	if not puzzle_data.is_empty():
		_open_story_puzzle(puzzle_data)
		return
	var interaction_data: Dictionary = line.get("interaction", {})
	if interaction_data.is_empty():
		return
	dialogue_panel.hide()
	interaction_panel.show()
	$UILayer/InteractionPanel/Box/Title.text = str(interaction_data.get("title", "손으로 참여하기"))
	interaction_controller.start(interaction_data, _resolve_interaction(interaction_data))

func _speaker_node(speaker: String) -> CanvasItem:
	if speaker == "나":
		return crowd_player
	if speaker == "예수":
		return jesus_donkey
	if speaker == "상인 요나" or speaker == "미리암" or speaker == "행인":
		return crowd_group
	return player_disciple

func _speaker_style(speaker: String) -> StringName:
	if speaker == "예수":
		return &"jesus"
	if speaker == "나":
		return &"protagonist"
	return &"witness"

func _resolve_interaction(data: Dictionary) -> Node:
	var interaction_type := String(data.get("type", "button_steps"))
	if interaction_type == "palm_drag":
		return palm_drag
	if interaction_type == "observation":
		return observation
	return null

func _on_choice_selected(line: Dictionary, choice_index: int, _response: Dictionary) -> void:
	var choice_ids: Array = line.get("choice_ids", [])
	var value: Variant = StringName(choice_ids[choice_index]) if choice_index < choice_ids.size() else choice_index
	StoryState.record_choice(chapter_id, &"chapter_choice", value)
	GameState.save_progress()

func _configure_story_puzzle() -> void:
	story_puzzle = NarrativePuzzle.new()
	$UILayer.add_child(story_puzzle)
	story_puzzle.completed.connect(_on_story_puzzle_completed)

func _open_story_puzzle(data: Dictionary) -> void:
	_pending_puzzle_line = data
	crowd_player.set_input_enabled(false)
	interaction_scanner.set_input_enabled(false)
	dialogue_panel.hide()
	story_puzzle.configure(StringName(data.get("id", "chapter_puzzle")), str(data.get("title", "흔적을 잇기")), data.get("steps", []))

func _on_story_puzzle_completed(result: Dictionary) -> void:
	StoryState.record_puzzle(chapter_id, StringName(_pending_puzzle_line.get("id", "chapter_puzzle")), result)
	GameState.save_progress()
	_pending_puzzle_line.clear()
	dialogue_panel.show()
	dialogue_controller.advance()

func _on_player_interaction_requested(target: Node) -> void:
	if target and target.has_method("interact"):
		target.interact()

func _on_observation_selected(option_id: StringName, description: String) -> void:
	# 조사 선택을 비트·감정 상태에 기록합니다. 이전에는 이 함수가 포커스만 처리했습니다.
	chapter_director.record_interaction(option_id, {
		"description": description,
		"chapter_index": chapter_index
	})
	if chapter_index != 0:
		return
	match option_id:
		&"palm_leaf":
			_create_observation_focus(crowd_player)
		&"discarded_cloak":
			_create_observation_focus(character_layer)
		&"footprints":
			_create_observation_focus(background_layer)

func _create_observation_focus(target: CanvasItem) -> void:
	var focus_tween := create_tween().set_parallel(true)
	focus_tween.tween_property(target, "scale", Vector2(1.04, 1.04), 0.45).set_trans(Tween.TRANS_SINE)
	focus_tween.tween_property(target, "modulate", Color(1.0, 0.94, 0.72, 1.0), 0.45).set_trans(Tween.TRANS_SINE)

func _on_interaction_progress(current: int, _total: int) -> void:
	if current > 0 and chapter_index == 0:
		$Audio/SFX.stop()
		$Audio/SFX.play()

func _on_interaction_completed(_data: Dictionary) -> void:
	interaction_panel.hide()
	dialogue_panel.show()
	dialogue_controller.advance()

func _apply_line_event(event_name: String) -> void:
	if chapter_index != 0 or event_name.is_empty():
		return
	match event_name:
		"intro_whisper":
			background_layer.modulate = Color(0.86, 0.77, 0.58, 1.0)
			crowd_group.modulate.a = 0.0
			jesus_donkey.modulate.a = 0.0
			var intro_tween := create_tween()
			intro_tween.tween_property(background_layer, "modulate", Color.WHITE, 1.4).set_trans(Tween.TRANS_SINE)
		"distant_witness":
			var witness_tween := create_tween().set_parallel(true)
			witness_tween.tween_property(crowd_group, "modulate:a", 0.18, 1.0)
			witness_tween.tween_property(crowd_group, "position", crowd_target_position + Vector2(-24.0, 4.0), 1.2).set_trans(Tween.TRANS_SINE)
		"establish_scene":
			background_layer.modulate = Color.WHITE
			var establish_tween := create_tween().set_parallel(true)
			establish_tween.tween_property(crowd_group, "modulate:a", 0.82, 1.15).set_delay(0.25)
			establish_tween.tween_property(crowd_group, "position", crowd_target_position, 1.35).set_delay(0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			establish_tween.tween_property(crowd_group, "scale", Vector2.ONE, 1.35).set_delay(0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"reveal_characters":
			var reveal_tween := create_tween().set_parallel(true)
			reveal_tween.tween_property(jesus_donkey, "modulate:a", 1.0, 0.95)
			reveal_tween.tween_property(jesus_donkey, "position", jesus_target_position, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			reveal_tween.tween_property(jesus_donkey, "scale", Vector2.ONE, 1.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			reveal_tween.tween_property(crowd_group, "modulate:a", 1.0, 0.75)
			reveal_tween.tween_property(player_disciple, "modulate:a", 1.0, 0.8)
			reveal_tween.tween_property(player_disciple, "position:x", player_disciple.position.x - 12.0, 0.8).set_trans(Tween.TRANS_SINE)
		"focus_jesus":
			var focus_tween := create_tween().set_parallel(true)
			focus_tween.tween_property(background_layer, "modulate", Color(0.92, 0.88, 0.82, 1.0), 0.7).set_trans(Tween.TRANS_SINE)
			focus_tween.tween_property(jesus_donkey, "scale", Vector2(1.045, 1.045), 0.7).set_trans(Tween.TRANS_SINE)
			focus_tween.tween_property(crowd_group, "modulate:a", 0.68, 0.7)
		"path_opens":
			var path_tween := create_tween().set_parallel(true)
			path_tween.tween_property(crowd_group, "position", crowd_target_position + Vector2(-22.0, 0.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			path_tween.tween_property(crowd_group, "modulate:a", 0.78, 1.1).set_trans(Tween.TRANS_SINE)
			path_tween.tween_property(player_disciple, "position:x", player_disciple.position.x - 6.0, 0.7).set_delay(0.25).set_trans(Tween.TRANS_SINE)
		"crowd_fade":
			create_tween().tween_property($Audio/Crowd, "volume_db", -28.0, 1.2)
			create_tween().tween_property(crowd_group, "modulate:a", 0.42, 1.0)
		"prepare_exit":
			var exit_tween := create_tween().set_parallel(true)
			exit_tween.tween_property($UILayer/HeaderShade, "color:a", 0.5, 0.8)
			exit_tween.tween_property(character_layer, "modulate:a", 0.72, 0.8)

func _apply_line_sound(sound_name: String) -> void:
	if chapter_index != 0:
		return
	match sound_name:
		"wind_only":
			$Audio/Crowd.stop()
			$Audio/Footsteps.stop()
		"distant_steps":
			$Audio/Footsteps.volume_db = -28.0
			if not $Audio/Footsteps.playing:
				$Audio/Footsteps.play()
		"footsteps":
			$Audio/Footsteps.volume_db = -17.0
			if not $Audio/Footsteps.playing:
				$Audio/Footsteps.play()
		"crowd_swell":
			$Audio/Footsteps.stop()
			if not $Audio/Crowd.playing:
				$Audio/Crowd.play()
			create_tween().tween_property($Audio/Crowd, "volume_db", -11.0, 0.75)
		"crowd_part":
			create_tween().tween_property($Audio/Crowd, "volume_db", -19.0, 0.9)

func _load_audio() -> void:
	if chapter_index != 0:
		return
	_assign_stream($Audio/Wind, "wind", true)
	_assign_stream($Audio/Crowd, "crowd", true)
	_assign_stream($Audio/DialogueBlip, "dialogue", false)
	_assign_stream($Audio/SFX, "leaf", false)
	_assign_stream($Audio/Transition, "transition", false)
	$Audio/Wind.play()
	$Audio/Crowd.stop()
	$Audio/Footsteps.stop()
	$ChapterAudio.setup($Audio, crowd_player, $AmbientCrowd.get_child(1), $AmbientCrowd.get_child(2))
	$CrowdPlayer/AudioListener2D.make_current()

func _assign_stream(player: Node, key: String, should_loop: bool) -> void:
	var stream := load(AUDIO_PATHS[key]).duplicate() as AudioStream
	if stream == null:
		return
	if should_loop and stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream = stream

func _fade_in() -> void:
	transitioning = true
	fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished
	transitioning = false

func _leave_chapter() -> void:
	if transitioning:
		return
	transitioning = true
	dialogue_controller.stop()
	interaction_controller.cancel()
	await _fade_out_audio_and_screen(0.45)
	get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn")

func _request_leave_chapter() -> void:
	if transitioning or entering_temple or leave_confirmation.visible or (is_instance_valid(journal) and journal.active):
		return
	_resume_movement = crowd_player.input_enabled
	_resume_interaction = interaction_scanner.input_enabled
	crowd_player.set_input_enabled(false)
	interaction_scanner.set_input_enabled(false)
	leave_confirmation.popup_centered(Vector2i(460, 180))
	leave_confirmation.get_cancel_button().grab_focus()

func _cancel_leave_chapter() -> void:
	crowd_player.set_input_enabled(_resume_movement)
	interaction_scanner.set_input_enabled(_resume_interaction)
	$UILayer/Header/BackButton.release_focus()

func _finish_chapter() -> void:
	if transitioning:
		return
	transitioning = true
	if chapter_index == 0:
		$Audio/Transition.play()
		await BibleInterlude.present(self, BiblicalContext.TRANSITIONS[1])
	await _fade_out_audio_and_screen(0.85)
	if not persistence_enabled: return
	StoryState.complete_chapter(chapter_id)
	GameState.unlock_through(chapter_index + 2)
	get_tree().change_scene_to_file(GameState.get_next_scene(chapter_index + 2))

func _on_director_chapter_completed(_completed_chapter_id: StringName) -> void:
	_finish_chapter()

func _fade_out_audio_and_screen(duration: float) -> void:
	if chapter_index == 0:
		chapter_one_encounter.cancel()
		$ChapterAudio.prepare_exit()
		if entrance_tween and entrance_tween.is_valid():
			entrance_tween.kill()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	for player in [$Audio/Wind, $Audio/Crowd, $Audio/Footsteps]:
		tween.tween_property(player, "volume_db", -40.0, duration)
	await tween.finished

func _unhandled_key_input(event: InputEvent) -> void:
	if (is_instance_valid(story_puzzle) and story_puzzle.active) or (is_instance_valid(trail_puzzle) and trail_puzzle.active):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_request_leave_chapter()
		return
	if chapter_index == 0:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		dialogue_controller.advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dialogue_controller.advance()
	elif event is InputEventScreenTouch and event.pressed:
		dialogue_controller.advance()
