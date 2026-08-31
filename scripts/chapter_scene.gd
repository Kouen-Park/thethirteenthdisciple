extends Control

const Story = preload("res://story_data.gd")
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
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var interaction_panel: PanelContainer = $InteractionPanel
@onready var palm_drag: PalmDragInteraction = $InteractionPanel/Box/PalmDrag
@onready var interaction_action: Button = $InteractionPanel/Box/Action
@onready var fade_rect: ColorRect = $FadeLayer/Fade

var line_index := 0
var waiting_for_choice := false
var is_typing := false
var full_text := ""
var visible_character_count := 0.0
var active_interaction: Dictionary = {}
var interaction_step := 0
var next_blip_character := 0
var transitioning := false
var crowd_target_position := Vector2.ZERO
var jesus_target_position := Vector2.ZERO

func _ready() -> void:
	$Header/BackButton.pressed.connect(_leave_chapter)
	$DialoguePanel/Box/Advance.pressed.connect(_advance)
	$DialoguePanel/Box/ChoiceA.pressed.connect(_choose.bind(0))
	$DialoguePanel/Box/ChoiceB.pressed.connect(_choose.bind(1))
	interaction_action.pressed.connect(_complete_interaction_step)
	palm_drag.progress_changed.connect(_on_palm_progress_changed)
	palm_drag.completed.connect(_on_palm_completed)

	var chapter: Dictionary = Story.CHAPTERS[chapter_index]
	scene_art.set_palette(chapter.palette)
	scene_art.set_chapter(chapter_index)
	$Header/Title.text = chapter.title
	$Header/Place.text = chapter.place
	_configure_chapter_layers()
	_load_audio()
	_show_line()
	_fade_in()

func _process(delta: float) -> void:
	if not is_typing:
		return
	visible_character_count += GameState.text_speed * delta
	var character_count := mini(int(visible_character_count), full_text.length())
	$DialoguePanel/Box/Dialogue.visible_characters = character_count
	if chapter_index == 0 and character_count >= next_blip_character and character_count < full_text.length():
		if character_count > 0 and not full_text[character_count - 1].strip_edges().is_empty():
			$Audio/DialogueBlip.play()
		next_blip_character = character_count + 4
	if visible_character_count >= full_text.length():
		_finish_typewriter()

func _configure_chapter_layers() -> void:
	var is_chapter_one := chapter_index == 0
	background_layer.visible = is_chapter_one
	scene_art.visible = not is_chapter_one
	character_layer.visible = is_chapter_one
	crowd_group.visible = is_chapter_one
	jesus_donkey.visible = is_chapter_one
	player_disciple.visible = is_chapter_one
	if is_chapter_one:
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

func _show_line() -> void:
	var line: Dictionary = Story.CHAPTERS[chapter_index].lines[line_index]
	active_interaction = line.get("interaction", {})
	interaction_step = 0
	waiting_for_choice = line.has("choices")
	dialogue_panel.show()
	interaction_panel.hide()
	palm_drag.hide()
	$DialoguePanel/Box/Speaker.text = line.speaker
	$DialoguePanel/Box/ChoiceA.hide()
	$DialoguePanel/Box/ChoiceB.hide()
	_apply_line_event(String(line.get("event", "")))
	_apply_line_sound(String(line.get("sound", "")))
	_start_typewriter(line.text)

func _start_typewriter(text: String) -> void:
	full_text = text
	visible_character_count = 0.0
	next_blip_character = 1
	$DialoguePanel/Box/Dialogue.text = text
	$DialoguePanel/Box/Dialogue.visible_characters = 0
	is_typing = not text.is_empty()
	$DialoguePanel/Box/Advance.text = "···"
	$DialoguePanel/Box/Advance.show()
	if not is_typing:
		_finish_typewriter()

func _finish_typewriter() -> void:
	is_typing = false
	$DialoguePanel/Box/Dialogue.visible_characters = -1
	$DialoguePanel/Box/Advance.text = "계속  ›"
	if not active_interaction.is_empty():
		_begin_interaction()
	elif waiting_for_choice:
		$DialoguePanel/Box/Advance.hide()
		$DialoguePanel/Box/ChoiceA.show()
		$DialoguePanel/Box/ChoiceB.show()

func _advance() -> void:
	if transitioning:
		return
	if is_typing:
		_finish_typewriter()
		return
	if waiting_for_choice or not active_interaction.is_empty():
		return
	line_index += 1
	if line_index < Story.CHAPTERS[chapter_index].lines.size():
		_show_line()
	else:
		_finish_chapter()

func _choose(choice_index: int) -> void:
	if transitioning:
		return
	var line: Dictionary = Story.CHAPTERS[chapter_index].lines[line_index]
	waiting_for_choice = false
	$DialoguePanel/Box/ChoiceA.hide()
	$DialoguePanel/Box/ChoiceB.hide()
	var response: Dictionary = line.responses[choice_index]
	$DialoguePanel/Box/Speaker.text = response.speaker
	_start_typewriter(response.text)

func _begin_interaction() -> void:
	dialogue_panel.hide()
	interaction_panel.show()
	$InteractionPanel/Box/Title.text = active_interaction.get("title", "손으로 참여하기")
	var interaction_type := String(active_interaction.get("type", "button_steps"))
	if chapter_index == 0 and interaction_type == "palm_drag":
		interaction_action.hide()
		palm_drag.show()
		palm_drag.configure(active_interaction)
		$InteractionPanel/Box/Hint.text = active_interaction.get("instruction", "종려잎을 길 위로 끌어 놓으세요.")
	else:
		palm_drag.hide()
		interaction_action.show()
		_update_interaction_prompt()

func _update_interaction_prompt() -> void:
	var steps: Array = active_interaction.get("steps", [])
	if steps.is_empty():
		interaction_action.text = "완료"
		$InteractionPanel/Box/Hint.text = "천천히 눌러 진행하세요."
		return
	$InteractionPanel/Box/Hint.text = "천천히 눌러 진행하세요."
	interaction_action.text = "%d / %d · %s" % [interaction_step + 1, steps.size(), steps[interaction_step]]

func _complete_interaction_step() -> void:
	if transitioning:
		return
	var steps: Array = active_interaction.get("steps", [])
	if steps.is_empty():
		_complete_current_interaction()
		return
	interaction_step += 1
	if interaction_step < steps.size():
		_update_interaction_prompt()
		return
	_complete_current_interaction()

func _on_palm_progress_changed(placed_count: int, required_count: int) -> void:
	if placed_count <= 0:
		$InteractionPanel/Box/Hint.text = active_interaction.get("instruction", "종려잎을 길 위로 끌어 놓으세요.")
		return
	$InteractionPanel/Box/Hint.text = "종려잎을 길 위에 놓았습니다.  %d / %d" % [placed_count, required_count]
	$Audio/SFX.stop()
	$Audio/SFX.play()

func _on_palm_completed() -> void:
	_complete_current_interaction()

func _complete_current_interaction() -> void:
	interaction_panel.hide()
	dialogue_panel.show()
	active_interaction = {}
	line_index += 1
	if line_index < Story.CHAPTERS[chapter_index].lines.size():
		_show_line()
	else:
		_finish_chapter()

func _apply_line_event(event_name: String) -> void:
	if chapter_index != 0 or event_name.is_empty():
		return
	match event_name:
		"establish_scene":
			background_layer.modulate = Color.WHITE
			var intro_tween := create_tween().set_parallel(true)
			intro_tween.tween_property(crowd_group, "modulate:a", 0.82, 1.15).set_delay(0.25)
			intro_tween.tween_property(crowd_group, "position", crowd_target_position, 1.35).set_delay(0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			intro_tween.tween_property(crowd_group, "scale", Vector2.ONE, 1.35).set_delay(0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
		"footsteps":
			if not $Audio/Footsteps.playing:
				$Audio/Footsteps.play()
		"crowd_swell":
			$Audio/Footsteps.stop()
			if not $Audio/Crowd.playing:
				$Audio/Crowd.play()
			create_tween().tween_property($Audio/Crowd, "volume_db", -11.0, 0.75)

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
	$Audio/Crowd.play()

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
	await _fade_out_audio_and_screen(0.45)
	get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn")

func _finish_chapter() -> void:
	if transitioning:
		return
	transitioning = true
	if chapter_index == 0:
		$Audio/Transition.play()
	await _fade_out_audio_and_screen(0.85)
	GameState.unlock_through(chapter_index + 2)
	get_tree().change_scene_to_file(finish_scene_path)

func _fade_out_audio_and_screen(duration: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	for player in [$Audio/Wind, $Audio/Crowd, $Audio/Footsteps]:
		tween.tween_property(player, "volume_db", -40.0, duration)
	await tween.finished

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_advance()
