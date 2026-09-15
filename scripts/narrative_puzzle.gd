class_name NarrativePuzzle
extends Control

signal started(puzzle_id: StringName)
signal progress_changed(current: int, total: int)
signal hint_requested(level: int, text: String)
signal completed(result: Dictionary)
signal canceled

const PuzzleTheme = preload("res://scripts/ui_theme.gd")

const FIRST_HINT_SECONDS := 45.0
const VISUAL_HINT_SECONDS := 90.0

var puzzle_id: StringName
var steps: Array[Dictionary] = []
var current_step := 0
var attempts := 0
var elapsed := 0.0
var active := false
var _hint_level := 0

var _title_label: Label
var _prompt_label: Label
var _hint_label: Label
var _buttons: Array[Button] = []
var _panel: PanelContainer
var _step_label: Label
var _hint_button: Button
var _cancel_button: Button
var _text_scale := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var settings := get_node_or_null("/root/GameState")
	if settings: _text_scale = settings.text_scale
	_build_interface()
	get_viewport().size_changed.connect(_layout_panel)
	call_deferred("_layout_panel")
	hide()

func configure(id: StringName, title: String, puzzle_steps: Array[Dictionary]) -> void:
	puzzle_id = id
	steps = puzzle_steps.duplicate(true)
	_title_label.text = title
	current_step = 0
	attempts = 0
	elapsed = 0.0
	_hint_level = 0
	active = not steps.is_empty()
	if not active:
		return
	show()
	_show_step()
	started.emit(puzzle_id)
	progress_changed.emit(0, steps.size())

func submit(answer: StringName) -> bool:
	if not active or current_step >= steps.size():
		return false
	var step: Dictionary = steps[current_step]
	if answer != StringName(step.get("answer", "")):
		attempts += 1
		_show_hint(1, str(step.get("hint", "한 번 더 관찰해 보자.")))
		return false
	current_step += 1
	elapsed = 0.0
	_hint_level = 0
	_hint_label.text = ""
	progress_changed.emit(current_step, steps.size())
	if current_step >= steps.size():
		active = false
		hide()
		completed.emit({"puzzle_id": puzzle_id, "attempts": attempts, "completed": true})
	else:
		_show_step()
	return true

func resume_puzzle() -> void:
	if steps.is_empty() or current_step >= steps.size(): return
	active = true
	show()
	_show_step()

func request_hint() -> void:
	if not active or current_step >= steps.size(): return
	var step: Dictionary = steps[current_step]
	_show_hint(1, str(step.get("hint", "남겨진 흔적을 다시 살펴보자.")))

func cancel_puzzle() -> void:
	if not active:
		return
	active = false
	hide()
	canceled.emit()

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var step: Dictionary = steps[current_step]
	if elapsed >= VISUAL_HINT_SECONDS and _hint_level < 2:
		_show_hint(2, str(step.get("visual_hint", step.get("hint", "관찰한 흔적을 다시 살펴보자."))))
		_highlight_answer(StringName(step.get("answer", "")))
	elif elapsed >= FIRST_HINT_SECONDS and _hint_level < 1:
		_show_hint(1, str(step.get("hint", "관찰한 흔적을 다시 살펴보자.")))

func _show_hint(level: int, value: String) -> void:
	_hint_level = maxi(_hint_level, level)
	_hint_label.text = value
	hint_requested.emit(level, value)

func _show_step() -> void:
	var step: Dictionary = steps[current_step]
	_step_label.text = "%d / %d   ·   흔적 되짚기" % [current_step + 1, steps.size()]
	_prompt_label.text = str(step.get("prompt", "무엇을 먼저 살펴볼까?"))
	for button in _buttons:
		button.hide()
		button.disabled = false
		button.modulate = Color.WHITE
	var options: Array = step.get("options", [])
	for index in mini(options.size(), _buttons.size()):
		var option: Dictionary = options[index]
		var button := _buttons[index]
		button.text = str(option.get("label", option.get("id", "")))
		button.set_meta("answer_id", StringName(option.get("id", "")))
		button.show()
	PuzzleTheme.trap_button_focus(_buttons + [_hint_button, _cancel_button])
	if not _buttons.is_empty():
		_buttons[0].grab_focus()
	call_deferred("_layout_panel")

func _highlight_answer(answer: StringName) -> void:
	for button in _buttons:
		if button.visible and StringName(button.get_meta("answer_id", "")) == answer:
			button.modulate = Color(1.18, 1.05, 0.66, 1.0)

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.015, 0.48)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	_panel = panel
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-430, -300)
	panel.size = Vector2(860, 260)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.065, 0.04, 0.96)
	style.border_color = Color(0.78, 0.57, 0.28, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_step_label = Label.new()
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_label.add_theme_color_override("font_color", Color("be915b"))
	_step_label.add_theme_font_size_override("font_size", 14)
	box.add_child(_step_label)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", roundi(20 * _text_scale))
	box.add_child(_title_label)
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.add_theme_font_size_override("font_size", roundi(18 * _text_scale))
	box.add_child(_prompt_label)
	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 10)
	box.add_child(choices)
	for index in 4:
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 54)
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", roundi(16 * _text_scale))
		PuzzleTheme.apply_button(button)
		button.pressed.connect(_on_button_pressed.bind(button))
		choices.add_child(button)
		_buttons.append(button)
	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_color_override("font_color", Color("e7c47b"))
	_hint_label.custom_minimum_size.y = 28
	_hint_label.add_theme_font_size_override("font_size", roundi(15 * _text_scale))
	box.add_child(_hint_label)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	box.add_child(footer)
	_hint_button = Button.new()
	_hint_button.text = "단서 다시 보기"
	_hint_button.pressed.connect(request_hint)
	footer.add_child(_hint_button)
	_cancel_button = Button.new()
	_cancel_button.text = "돌아가서 살펴보기 · Esc"
	_cancel_button.pressed.connect(cancel_puzzle)
	footer.add_child(_cancel_button)
	for button in [_hint_button, _cancel_button]:
		button.custom_minimum_size.y = 36
		PuzzleTheme.apply_button(button)

func _on_button_pressed(button: Button) -> void:
	submit(StringName(button.get_meta("answer_id", "")))

func _layout_panel() -> void:
	if not is_instance_valid(_panel): return
	var view := get_viewport_rect().size
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.size = Vector2(minf(960, view.x - 48), 0)
	_panel.position = Vector2((view.x - _panel.size.x) * 0.5, maxf(160, view.y - _panel.size.y - 24))
