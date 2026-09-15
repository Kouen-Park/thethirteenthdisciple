class_name DialogueController
extends Node

## 데이터 기반 대화를 표시하고, 타이프라이터·선택지·입력 잠금을 관리하는 컴포넌트입니다.
## ChapterScene은 이 컴포넌트를 직접 제어하지 않고 signal만 구독하는 것을 권장합니다.

signal line_started(line: Dictionary, index: int)
signal line_finished(line: Dictionary, index: int)
signal choice_requested(line: Dictionary, choices: Array)
signal choice_selected(line: Dictionary, choice_index: int, response: Dictionary)
signal sequence_finished

@export var text_speed: float = 28.0
@export var auto_advance_empty_lines: bool = true

var _speaker_label: Label
var _dialogue_label: Label
var _advance_button: Button
var _choice_buttons: Array[Button] = []

var _lines: Array[Dictionary] = []
var _line_index: int = -1
var _current_line: Dictionary = {}
var _is_typing: bool = false
var _is_waiting_for_choice: bool = false
var _is_showing_response: bool = false
var _full_text: String = ""
var _visible_character_count: float = 0.0
var _next_blip_character: int = 1
var _started: bool = false

func setup(
	speaker_label: Label,
	dialogue_label: Label,
	advance_button: Button,
	choice_a: Button,
	choice_b: Button,
	choice_c: Button = null
) -> void:
	_speaker_label = speaker_label
	_dialogue_label = dialogue_label
	_advance_button = advance_button
	_choice_buttons = [choice_a, choice_b]
	if choice_c:
		_choice_buttons.append(choice_c)

	if not _advance_button.pressed.is_connected(advance):
		_advance_button.pressed.connect(advance)
	for index in _choice_buttons.size():
		var button := _choice_buttons[index]
		if not button.pressed.is_connected(_on_choice_pressed.bind(index)):
			button.pressed.connect(_on_choice_pressed.bind(index))

func start(lines: Array) -> void:
	_lines.clear()
	for item in lines:
		if item is Dictionary:
			_lines.append(item as Dictionary)
	_line_index = -1
	_started = true
	_show_next_line()

func stop() -> void:
	_started = false
	_is_typing = false
	_is_waiting_for_choice = false
	_is_showing_response = false
	_hide_choices()

func advance() -> void:
	if not _started:
		return
	if _is_typing:
		_finish_typing()
		return
	if _is_waiting_for_choice:
		return
	_show_next_line()

func set_text_speed(value: float) -> void:
	text_speed = maxf(value, 1.0)

func is_busy() -> bool:
	return _is_typing or _is_waiting_for_choice

func get_current_line() -> Dictionary:
	return _current_line.duplicate(true)

func _process(delta: float) -> void:
	if not _is_typing:
		return
	_visible_character_count += text_speed * delta
	if _dialogue_label == null:
		return
	_dialogue_label.visible_characters = mini(int(_visible_character_count), _full_text.length())
	if _visible_character_count >= _full_text.length():
		_finish_typing()

func _show_next_line() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		_started = false
		sequence_finished.emit()
		return

	_current_line = _lines[_line_index]
	_is_showing_response = false
	_is_waiting_for_choice = false
	_hide_choices()
	_show_line_text(_current_line)
	line_started.emit(_current_line, _line_index)

func _show_line_text(line: Dictionary) -> void:
	if _speaker_label:
		_speaker_label.text = str(line.get("speaker", ""))
	_start_typewriter(str(line.get("text", "")))

func _start_typewriter(text: String) -> void:
	_full_text = text
	_visible_character_count = 0.0
	_next_blip_character = 1
	_is_typing = not text.is_empty()
	if _dialogue_label:
		_dialogue_label.text = text
		_dialogue_label.visible_characters = 0 if _is_typing else -1
	if _advance_button:
		_advance_button.text = "···" if _is_typing else "계속  ›"
	if not _is_typing:
		_finish_typing()

func _finish_typing() -> void:
	if not _is_typing and _full_text.is_empty() == false and _dialogue_label and _dialogue_label.visible_characters == -1:
		return
	_is_typing = false
	if _dialogue_label:
		_dialogue_label.visible_characters = -1
	if _advance_button:
		_advance_button.text = "계속  ›"

	if _is_showing_response:
		line_finished.emit(_current_line, _line_index)
		return

	var choices: Array = _current_line.get("choices", [])
	if choices.size() >= 2:
		_is_waiting_for_choice = true
		if _advance_button:
			_advance_button.hide()
		for index in mini(choices.size(), _choice_buttons.size()):
			_choice_buttons[index].text = str(choices[index])
			_choice_buttons[index].show()
		choice_requested.emit(_current_line, choices)
	else:
		line_finished.emit(_current_line, _line_index)
		if auto_advance_empty_lines and _full_text.is_empty():
			advance()

func _on_choice_pressed(choice_index: int) -> void:
	if not _is_waiting_for_choice or choice_index >= _choice_buttons.size():
		return
	var responses: Array = _current_line.get("responses", [])
	if choice_index >= responses.size() or not responses[choice_index] is Dictionary:
		push_warning("Dialogue response is missing for choice index %d" % choice_index)
		return

	_is_waiting_for_choice = false
	_is_showing_response = true
	_hide_choices()
	var response := responses[choice_index] as Dictionary
	choice_selected.emit(_current_line, choice_index, response)
	_show_line_text(response)

func _hide_choices() -> void:
	for button in _choice_buttons:
		if button:
			button.hide()
	if _advance_button:
		_advance_button.show()
