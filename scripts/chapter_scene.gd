extends Control

const Story = preload("res://story_data.gd")

@export_range(0, 5) var chapter_index := 0
@export_file("*.tscn") var finish_scene_path := "res://scenes/menu/chapter_select.tscn"

var line_index := 0
var waiting_for_choice := false
var is_typing := false
var full_text := ""
var visible_character_count := 0.0
var active_interaction: Dictionary = {}
var interaction_step := 0

func _ready() -> void:
	$Header/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn"))
	$DialoguePanel/Box/Advance.pressed.connect(_advance)
	$DialoguePanel/Box/ChoiceA.pressed.connect(_choose.bind(0))
	$DialoguePanel/Box/ChoiceB.pressed.connect(_choose.bind(1))
	$InteractionPanel/Box/Action.pressed.connect(_complete_interaction_step)
	var chapter: Dictionary = Story.CHAPTERS[chapter_index]
	$SceneArt.set_palette(chapter.palette)
	$SceneArt.set_chapter(chapter_index)
	$Header/Title.text = chapter.title
	$Header/Place.text = chapter.place
	_show_line()

func _process(delta: float) -> void:
	if not is_typing:
		return
	visible_character_count += GameState.text_speed * delta
	$DialoguePanel/Box/Dialogue.visible_characters = int(visible_character_count)
	if visible_character_count >= full_text.length():
		_finish_typewriter()

func _show_line() -> void:
	var line: Dictionary = Story.CHAPTERS[chapter_index].lines[line_index]
	active_interaction = line.get("interaction", {})
	interaction_step = 0
	waiting_for_choice = line.has("choices")
	$DialoguePanel.show()
	$DialoguePanel/Box/Speaker.text = line.speaker
	$DialoguePanel/Box/ChoiceA.hide()
	$DialoguePanel/Box/ChoiceB.hide()
	if waiting_for_choice:
		$DialoguePanel/Box/ChoiceA.text = line.choices[0]
		$DialoguePanel/Box/ChoiceB.text = line.choices[1]
	_start_typewriter(line.text)

func _start_typewriter(text: String) -> void:
	full_text = text
	visible_character_count = 0.0
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
	var line: Dictionary = Story.CHAPTERS[chapter_index].lines[line_index]
	waiting_for_choice = false
	$DialoguePanel/Box/ChoiceA.hide()
	$DialoguePanel/Box/ChoiceB.hide()
	var response: Dictionary = line.responses[choice_index]
	$DialoguePanel/Box/Speaker.text = response.speaker
	_start_typewriter(response.text)

func _begin_interaction() -> void:
	$DialoguePanel.hide()
	$InteractionPanel.show()
	$InteractionPanel/Box/Title.text = active_interaction.title
	_update_interaction_prompt()

func _update_interaction_prompt() -> void:
	var steps: Array = active_interaction.steps
	$InteractionPanel/Box/Hint.text = "천천히 눌러 진행하세요."
	$InteractionPanel/Box/Action.text = "%d / %d · %s" % [interaction_step + 1, steps.size(), steps[interaction_step]]

func _complete_interaction_step() -> void:
	interaction_step += 1
	var steps: Array = active_interaction.steps
	if interaction_step < steps.size():
		_update_interaction_prompt()
		return
	$InteractionPanel.hide()
	$DialoguePanel.show()
	active_interaction = {}
	line_index += 1
	if line_index < Story.CHAPTERS[chapter_index].lines.size():
		_show_line()
	else:
		_finish_chapter()

func _finish_chapter() -> void:
	GameState.unlock_through(chapter_index + 2)
	get_tree().change_scene_to_file(finish_scene_path)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_advance()
