class_name JourneyPauseMenu
extends CanvasLayer

const ThemeStyle = preload("res://scripts/ui_theme.gd")
var can_open: Callable
var active := false
var button: Button
var overlay: Control
var panel: PanelContainer
var resume_button: Button
var speed_option: OptionButton
var _sliders: Dictionary = {}
var _focus_before: Control
var _settings: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_settings = get_node("/root/GameState")
	button = Button.new()
	button.text = "P  잠시 멈춤"
	button.tooltip_text = "대사와 움직임을 멈추고 음량·대사 속도를 바꿉니다."
	ThemeStyle.apply_button(button)
	button.position = Vector2(128, 26)
	button.size = Vector2(148, 36)
	button.pressed.connect(open_menu)
	add_child(button)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.06, 0.10, 0.83)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeStyle.panel_style(Color("211c28"), Color("be915b")))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	var title := Label.new()
	title.text = "잠시, 숨을 고르며"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", ThemeStyle.PARCHMENT)
	box.add_child(title)
	var description := Label.new()
	description.text = "대사와 움직임이 멈췄습니다. 같은 자리에서 이어갑니다."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", ThemeStyle.MUTED)
	box.add_child(description)
	_add_slider(box, "전체 음량", "master_volume", "set_master_volume")
	_add_slider(box, "환경음", "ambience_volume", "set_ambience_volume")
	_add_slider(box, "효과음", "sfx_volume", "set_sfx_volume")
	var speed_row := HBoxContainer.new()
	box.add_child(speed_row)
	var speed_label := Label.new()
	speed_label.text = "대사 속도"
	speed_label.add_theme_color_override("font_color", ThemeStyle.PARCHMENT)
	speed_label.custom_minimum_size.x = 136
	speed_row.add_child(speed_label)
	speed_option = OptionButton.new()
	for item in ["천천히", "보통", "빠르게"]: speed_option.add_item(item)
	ThemeStyle.apply_button(speed_option)
	speed_option.custom_minimum_size.y = 40
	speed_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_option.item_selected.connect(func(index: int): _settings.set_text_speed([18.0, 28.0, 42.0][index]))
	speed_row.add_child(speed_option)
	var keys := Label.new()
	keys.text = "WASD / 방향키  이동     E  조사\nSPACE  대사 진행     J  기록 수첩"
	keys.add_theme_color_override("font_color", ThemeStyle.MUTED)
	keys.add_theme_font_size_override("font_size", 15)
	box.add_child(keys)
	resume_button = Button.new()
	resume_button.text = "이 자리에서 계속   ·   P / Esc"
	resume_button.custom_minimum_size.y = 46
	ThemeStyle.apply_button(resume_button, true)
	resume_button.pressed.connect(close_menu)
	box.add_child(resume_button)
	for control in panel.find_children("*", "Control", true, false):
		if control is Label or control is Button:
			control.add_theme_font_size_override("font_size", roundi(control.get_theme_font_size("font_size") * _settings.text_scale))
	var controls: Array[Control] = [resume_button, _sliders.master_volume.slider, _sliders.ambience_volume.slider, _sliders.sfx_volume.slider, speed_option]
	for i in controls.size():
		controls[i].focus_next = controls[i].get_path_to(controls[(i + 1) % controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[posmod(i - 1, controls.size())])
		controls[i].focus_neighbor_bottom = controls[i].focus_next
		controls[i].focus_neighbor_top = controls[i].focus_previous
	overlay.hide()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")

func _add_slider(box: VBoxContainer, caption: String, property: String, setter: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 32
	box.add_child(row)
	var label := Label.new()
	label.text = caption
	label.add_theme_color_override("font_color", ThemeStyle.PARCHMENT)
	label.custom_minimum_size.x = 136
	row.add_child(label)
	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.max_value = 100
	slider.step = 1
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 52
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", ThemeStyle.BRASS_LIGHT)
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float):
		_settings.call(setter, value / 100.0)
		value_label.text = "%d%%" % roundi(value))
	_sliders[property] = {"slider": slider, "value": value_label}

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	panel.custom_minimum_size.x = minf(580, view.x - 48)

func _process(_delta: float) -> void:
	button.disabled = active or (can_open.is_valid() and not can_open.call())
	button.visible = not button.disabled

func open_menu() -> void:
	if active or get_tree().paused or (can_open.is_valid() and not can_open.call()): return
	_focus_before = get_viewport().gui_get_focus_owner()
	for property in _sliders:
		var value: float = _settings.get(property) * 100.0
		_sliders[property].slider.set_value_no_signal(value)
		_sliders[property].value.text = "%d%%" % roundi(value)
	speed_option.select(0 if _settings.text_speed <= 18.0 else (2 if _settings.text_speed >= 40.0 else 1))
	active = true
	overlay.show()
	_layout()
	get_tree().paused = true
	resume_button.grab_focus()

func close_menu() -> void:
	if not active: return
	active = false
	overlay.hide()
	get_tree().paused = false
	resume_button.release_focus()
	if is_instance_valid(_focus_before) and _focus_before != button and _focus_before.is_visible_in_tree():
		_focus_before.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	var pause_key: bool = event is InputEventKey and event.pressed and (event.physical_keycode == KEY_P or event.keycode == KEY_P)
	if pause_key or (active and event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		if active: close_menu()
		else: open_menu()
	elif active and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if active: get_tree().paused = false
