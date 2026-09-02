extends Control

const Story = preload("res://story_data.gd")
const DiscipleTheme = preload("res://scripts/ui_theme.gd")
const AUDIO_PATHS := {
	"wind": "res://assets/audio/chapter01/wind_loop.wav",
	"crowd": "res://assets/audio/chapter01/crowd_loop.wav",
	"footsteps": "res://assets/audio/chapter01/footsteps_loop.wav",
	"dialogue": "res://assets/audio/chapter01/dialogue_blip.wav",
	"leaf": "res://assets/audio/chapter01/leaf_place.wav",
	"transition": "res://assets/audio/chapter01/transition_whoosh.wav"
}

@export_range(0, 5) var chapter_index := 0
@export_file("*.tscn") var finish_scene_path := "res://scenes/menu/chapter_select.tscn"

@onready var background_layer: TextureRect = $BackgroundLayer
@onready var scene_art: Control = $SceneArt
@onready var character_layer: Control = $CharacterLayer
@onready var crowd_group: TextureRect = $CharacterLayer/CrowdGroup
@onready var jesus_donkey: TextureRect = $CharacterLayer/JesusDonkey
@onready var player_disciple: TextureRect = $CharacterLayer/PlayerDisciple
@onready var crowd_player: CharacterBody2D = $CrowdPlayer
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var interaction_panel: PanelContainer = $InteractionPanel
@onready var palm_drag: PalmDragInteraction = $InteractionPanel/Box/PalmDrag
@onready var observation: Node = $InteractionPanel/Box/Observation
@onready var fade_rect: ColorRect = $FadeLayer/Fade
@onready var dialogue_controller: Node = $DialogueController
@onready var interaction_controller: Node = $InteractionController
@onready var speech_bubbles: Node = $SpeechBubbleController
@onready var chapter_director: Node = $ChapterDirector
@onready var interaction_scanner: Node = $CrowdPlayer/InteractionScanner
@onready var interaction_prompt: Label = $WorldHUD/InteractionPrompt
@onready var objective_label: Label = $WorldHUD/Objective

var transitioning := false
var crowd_target_position := Vector2.ZERO
var jesus_target_position := Vector2.ZERO
var world_sequence_active := false
var chapter_id: StringName

func _ready() -> void:
	DiscipleTheme.apply_chapter(self)
	$Header/BackButton.pressed.connect(_leave_chapter)
	dialogue_controller.setup($DialoguePanel/Box/Speaker, $DialoguePanel/Box/Dialogue, $DialoguePanel/Box/Advance, $DialoguePanel/Box/ChoiceA, $DialoguePanel/Box/ChoiceB)
	dialogue_controller.set_text_speed(GameState.text_speed)
	dialogue_controller.line_started.connect(_on_line_started)
	dialogue_controller.line_finished.connect(_on_line_finished)
	dialogue_controller.sequence_finished.connect(_finish_chapter)
	dialogue_controller.choice_selected.connect(_on_choice_selected)
	interaction_controller.setup($InteractionPanel/Box/Action, $InteractionPanel/Box/Hint)
	interaction_controller.progress_changed.connect(_on_interaction_progress)
	interaction_controller.selection_made.connect(_on_observation_selected)
	interaction_controller.completed.connect(_on_interaction_completed)
	interaction_scanner.interaction_requested.connect(_on_player_interaction_requested)
	interaction_scanner.target_changed.connect(_on_interaction_target_changed)
	chapter_director.interaction_recorded.connect(_on_interaction_recorded)
	chapter_director.beat_changed.connect(_on_beat_changed)
	chapter_director.chapter_completed.connect(_on_director_chapter_completed)
	chapter_id = StringName("chapter_%02d" % (chapter_index + 1))
	chapter_director.chapter_id = chapter_id
	if chapter_index == 0:
		var required: Array[StringName] = [&"palm_leaf", &"discarded_cloak", &"footprints"]
		chapter_director.required_interactions = required
		_connect_world_interactables()
	chapter_director.begin_chapter()

	var chapter: Dictionary = Story.CHAPTERS[chapter_index]
	scene_art.set_palette(chapter.palette)
	scene_art.set_chapter(chapter_index)
	$Header/Title.text = chapter.title
	$Header/Place.text = chapter.place
	_configure_chapter_layers()
	_load_audio()
	dialogue_panel.hide()
	call_deferred("_begin_opening_sequence", chapter)

func _begin_opening_sequence(chapter: Dictionary) -> void:
	crowd_player.set_input_enabled(false)
	await _fade_in()
	if chapter_index == 0:
		interaction_scanner.set_input_enabled(false)
		await _show_world_line(crowd_player, "오늘은 일찍 돌아가야 한다. 시장은 벌써 너무 시끄럽다.", &"protagonist")
		objective_label.text = "주변에 남은 세 가지 흔적을 찾아 E키로 조사하세요."
		crowd_player.set_input_enabled(true)
		interaction_scanner.set_input_enabled(true)
	else:
		crowd_player.set_input_enabled(true)
		dialogue_controller.start(chapter.lines)

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
		crowd_player.global_position = Vector2(640.0, 520.0)
		crowd_target_position = crowd_group.position
		jesus_target_position = jesus_donkey.position
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
	for target in [$PalmLeafInteractable, $DiscardedCloakInteractable, $FootprintsInteractable]:
		target.process_mode = Node.PROCESS_MODE_INHERIT if is_chapter_one else Node.PROCESS_MODE_DISABLED
		target.visible = is_chapter_one
	$WorldBounds.process_mode = Node.PROCESS_MODE_INHERIT if is_chapter_one else Node.PROCESS_MODE_DISABLED
	$WorldHUD.visible = is_chapter_one
	dialogue_panel.hide()
	interaction_panel.hide()

func _connect_world_interactables() -> void:
	for target in [$PalmLeafInteractable, $DiscardedCloakInteractable, $FootprintsInteractable]:
		target.one_shot = true
		if not target.interacted.is_connected(_on_world_interacted):
			target.interacted.connect(_on_world_interacted)

func _on_world_interacted(interaction_id: StringName, data: Dictionary) -> void:
	interaction_scanner.set_input_enabled(false)
	crowd_player.set_input_enabled(false)
	chapter_director.record_interaction(interaction_id, data)
	await _show_world_line(crowd_player, str(data.get("description", "")), &"protagonist")
	if chapter_director.current_beat != &"encounter":
		crowd_player.set_input_enabled(true)
		interaction_scanner.set_input_enabled(true)

func _on_interaction_target_changed(target: Node) -> void:
	if target and target.has_method("get_prompt_text"):
		interaction_prompt.text = "E  %s" % target.get_prompt_text()
		interaction_prompt.show()
	else:
		interaction_prompt.hide()

func _on_interaction_recorded(interaction_id: StringName, data: Dictionary) -> void:
	StoryState.record_observation(chapter_id, interaction_id, data)
	GameState.save_progress()
	var count: int = chapter_director.get_state()["observed"].size()
	objective_label.text = "흔적 조사 %d / 3" % count

func _on_beat_changed(beat_id: StringName) -> void:
	if chapter_index == 0 and beat_id == &"encounter" and not world_sequence_active:
		world_sequence_active = true
		call_deferred("_play_chapter_one_encounter")

func _play_chapter_one_encounter() -> void:
	interaction_prompt.hide()
	objective_label.text = "사람들이 길 양옆으로 물러서기 시작합니다."
	_apply_line_event("path_opens")
	_apply_line_sound("crowd_part")
	await get_tree().create_timer(0.8).timeout
	_apply_line_event("reveal_characters")
	await _show_world_line(crowd_player, "저 사람이… 사람들이 기다리던 사람인가?", &"protagonist")
	await _show_world_line(jesus_donkey, "당신도 이 길에 멈추어 섰군요.", &"jesus")
	await _show_world_line(crowd_player, "사람들은 당신을 왜 기다리고 있습니까?", &"protagonist")
	await _show_world_line(jesus_donkey, "사람마다 기다리는 것이 다르지요. 당신은 무엇을 보았습니까?", &"jesus")
	await _show_world_line(crowd_player, "아직은 모르겠습니다. 하지만 오늘 본 것을 소문이라고만 부를 수는 없습니다.", &"protagonist")
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
	var interaction_data: Dictionary = line.get("interaction", {})
	if interaction_data.is_empty():
		return
	dialogue_panel.hide()
	interaction_panel.show()
	$InteractionPanel/Box/Title.text = str(interaction_data.get("title", "손으로 참여하기"))
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

func _on_choice_selected(_line: Dictionary, _choice_index: int, _response: Dictionary) -> void:
	StoryState.record_choice(chapter_id, StringName("chapter_choice"), _choice_index)
	GameState.save_progress()

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
			background_layer.pivot_offset = background_layer.size * 0.5
			var focus_tween := create_tween().set_parallel(true)
			focus_tween.tween_property(background_layer, "scale", Vector2(1.025, 1.025), 1.5).set_trans(Tween.TRANS_SINE)
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
			exit_tween.tween_property($HeaderShade, "color:a", 0.5, 0.8)
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
	_assign_stream($Audio/Footsteps, "footsteps", true)
	_assign_stream($Audio/DialogueBlip, "dialogue", false)
	_assign_stream($Audio/SFX, "leaf", false)
	_assign_stream($Audio/Transition, "transition", false)
	$Audio/Wind.play()
	$Audio/Crowd.stop()
	$Audio/Footsteps.stop()

func _assign_stream(player: AudioStreamPlayer, key: String, should_loop: bool) -> void:
	var stream := load(AUDIO_PATHS[key]) as AudioStream
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

func _finish_chapter() -> void:
	if transitioning:
		return
	transitioning = true
	if chapter_index == 0:
		$Audio/Transition.play()
	await _fade_out_audio_and_screen(0.85)
	StoryState.complete_chapter(chapter_id)
	GameState.unlock_through(chapter_index + 2)
	get_tree().change_scene_to_file(GameState.get_next_scene(chapter_index + 2))

func _on_director_chapter_completed(_completed_chapter_id: StringName) -> void:
	_finish_chapter()

func _fade_out_audio_and_screen(duration: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	for player in [$Audio/Wind, $Audio/Crowd, $Audio/Footsteps]:
		tween.tween_property(player, "volume_db", -40.0, duration)
	await tween.finished

func _unhandled_key_input(event: InputEvent) -> void:
	if chapter_index == 0:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		dialogue_controller.advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dialogue_controller.advance()
	elif event is InputEventScreenTouch and event.pressed:
		dialogue_controller.advance()
