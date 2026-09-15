extends Control

const DiscipleTheme = preload("res://scripts/ui_theme.gd")

@onready var background: TextureRect = $Background
@onready var center: VBoxContainer = $Center
@onready var settings_layer: Control = $SettingsLayer
@onready var settings_panel: PanelContainer = $SettingsLayer/SettingsPanel
@onready var volume_slider: HSlider = $SettingsLayer/SettingsPanel/Box/VolumeSlider
@onready var volume_value: Label = $SettingsLayer/SettingsPanel/Box/VolumeHeader/Value
@onready var fade_rect: ColorRect = $FadeLayer/Fade

var transitioning := false
var settings_closing := false
var settings_tween: Tween
var reset_confirmation: ConfirmationDialog
var ambience_slider: HSlider
var sfx_slider: HSlider
var text_scale_option: OptionButton
var emphasis_option: OptionButton
var window_option: OptionButton

func _ready() -> void:
	DiscipleTheme.apply_menu(self)
	_build_extended_settings()
	$Center/StartButton.pressed.connect(_continue_story)
	$Center/JourneyButton.pressed.connect(_open_chapters)
	$Center/SettingsButton.pressed.connect(_open_settings)
	$SettingsLayer/SettingsPanel/Box/TextSpeed.item_selected.connect(_set_text_speed)
	$SettingsLayer/SettingsPanel/Box/VolumeSlider.value_changed.connect(_set_master_volume)
	$SettingsLayer/SettingsPanel/Box/CloseButton.pressed.connect(_close_settings)
	$SettingsLayer/SettingsPanel/Box/ResetButton.pressed.connect(_confirm_reset)
	$SettingsLayer/Dim.gui_input.connect(_on_settings_dim_input)
	settings_layer.hide()
	_sync_settings_controls()
	_refresh_start_label()
	reset_confirmation = ConfirmationDialog.new()
	reset_confirmation.title = "진행도를 초기화할까요?"
	reset_confirmation.dialog_text = "관찰 기록과 완료한 장면이 모두 지워집니다.\n화면·글자·음량 설정은 유지됩니다."
	reset_confirmation.ok_button_text = "초기화"
	reset_confirmation.cancel_button_text = "취소"
	add_child(reset_confirmation)
	reset_confirmation.confirmed.connect(_reset_progress)
	reset_confirmation.canceled.connect(func(): $SettingsLayer/SettingsPanel/Box/ResetButton.grab_focus())
	$SettingsLayer/SettingsPanel/Box/TextSpeed.tooltip_text = "월드 말풍선의 글자가 나타나는 속도입니다."
	$Center/StartButton.tooltip_text = "현재 장의 처음부터 이어갑니다. 관찰 기록은 유지됩니다."
	$Center/StartButton.grab_focus()
	_play_intro()

func _refresh_start_label() -> void:
	var has_progress := not StoryState.chapters.is_empty() or GameState.current_chapter > 1
	$Center/StartButton.text = "이야기 계속  ›" if has_progress else "이야기 시작  ›"
	$Center/JourneyHint.text = "현재 장의 처음부터 이어집니다." if has_progress else "WASD 이동 · E 대화/조사 · SPACE 대사 진행"

func _sync_settings_controls() -> void:
	var speed_index := 1
	if GameState.text_speed <= 18.0:
		speed_index = 0
	elif GameState.text_speed >= 40.0:
		speed_index = 2
	$SettingsLayer/SettingsPanel/Box/TextSpeed.select(speed_index)
	volume_slider.set_value_no_signal(GameState.master_volume * 100.0)
	_update_volume_label(GameState.master_volume * 100.0)
	ambience_slider.set_value_no_signal(GameState.ambience_volume * 100.0)
	sfx_slider.set_value_no_signal(GameState.sfx_volume * 100.0)
	text_scale_option.select(0 if GameState.text_scale < 0.95 else (2 if GameState.text_scale > 1.1 else 1))
	emphasis_option.select(0 if GameState.interaction_emphasis < 0.9 else (2 if GameState.interaction_emphasis > 1.1 else 1))
	window_option.select(1 if GameState.window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN else 0)

func _play_intro() -> void:
	transitioning = true
	fade_rect.color.a = 1.0
	center.modulate.a = 0.0
	center.grow_vertical = Control.GROW_DIRECTION_END
	center.grow_horizontal = Control.GROW_DIRECTION_END
	center.position = Vector2(72, 72)
	background.pivot_offset = background.size * 0.5
	background.scale = Vector2.ONE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.75).set_trans(Tween.TRANS_SINE)
	tween.tween_property(center, "modulate:a", 1.0, 0.85).set_delay(0.18)
	await get_tree().create_timer(0.95).timeout
	transitioning = false

func _continue_story() -> void:
	_transition_to(GameState.get_continue_scene())

func _open_chapters() -> void:
	_transition_to("res://scenes/menu/chapter_select.tscn")

func _transition_to(scene_path: String) -> void:
	if transitioning or settings_layer.visible:
		return
	transitioning = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	tween.tween_property(center, "modulate:a", 0.0, 0.35)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)

func _open_settings() -> void:
	if transitioning or settings_layer.visible:
		return
	settings_closing = false
	settings_layer.show()
	for child in center.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_NONE
			child.disabled = true
	$SettingsLayer/SettingsPanel/Box/TextSpeed.grab_focus()
	var controls: Array[Control] = [$SettingsLayer/SettingsPanel/Box/TextSpeed, volume_slider, ambience_slider, sfx_slider, text_scale_option, emphasis_option, window_option, $SettingsLayer/SettingsPanel/Box/ResetButton, $SettingsLayer/SettingsPanel/Box/CloseButton]
	for i in controls.size():
		controls[i].focus_next = controls[i].get_path_to(controls[(i + 1) % controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[posmod(i - 1, controls.size())])
	settings_panel.pivot_offset = settings_panel.size * 0.5
	settings_panel.scale = Vector2(0.94, 0.94)
	settings_panel.modulate.a = 0.0
	$SettingsLayer/Dim.modulate.a = 0.0
	settings_tween = create_tween().set_parallel(true)
	var tween := settings_tween
	tween.tween_property($SettingsLayer/Dim, "modulate:a", 1.0, 0.22)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.28)
	tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_settings() -> void:
	if not settings_layer.visible or settings_closing or reset_confirmation.visible:
		return
	settings_closing = true
	if settings_tween and settings_tween.is_valid(): settings_tween.kill()
	var tween := create_tween().set_parallel(true)
	tween.tween_property($SettingsLayer/Dim, "modulate:a", 0.0, 0.18)
	tween.tween_property(settings_panel, "modulate:a", 0.0, 0.18)
	tween.tween_property(settings_panel, "scale", Vector2(0.96, 0.96), 0.18)
	await tween.finished
	settings_layer.hide()
	settings_closing = false
	for child in center.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_ALL
			child.disabled = false
	$Center/SettingsButton.grab_focus()

func _on_settings_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_settings()
	elif event is InputEventScreenTouch and event.pressed:
		_close_settings()

func _set_text_speed(index: int) -> void:
	GameState.set_text_speed([18.0, 28.0, 42.0][index])

func _set_master_volume(value: float) -> void:
	GameState.set_master_volume(value / 100.0)
	_update_volume_label(value)

func _build_extended_settings() -> void:
	var box := $SettingsLayer/SettingsPanel/Box as VBoxContainer
	var reset_button := $SettingsLayer/SettingsPanel/Box/ResetButton
	ambience_slider = _add_setting_slider(box, reset_button, "환경음", GameState.ambience_volume * 100.0, GameState.set_ambience_volume)
	sfx_slider = _add_setting_slider(box, reset_button, "효과음", GameState.sfx_volume * 100.0, GameState.set_sfx_volume)
	text_scale_option = _add_setting_option(box, reset_button, "글자 크기", ["작게", "보통", "크게"])
	text_scale_option.item_selected.connect(func(index: int): GameState.set_text_scale([0.9, 1.0, 1.2][index]))
	emphasis_option = _add_setting_option(box, reset_button, "상호작용 강조", ["약하게", "보통", "강하게"])
	emphasis_option.item_selected.connect(func(index: int): GameState.set_interaction_emphasis([0.8, 1.0, 1.3][index]))
	window_option = _add_setting_option(box, reset_button, "화면 모드", ["창 모드", "전체 화면"])
	window_option.item_selected.connect(func(index: int): GameState.set_window_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if index == 1 else DisplayServer.WINDOW_MODE_WINDOWED))

func _add_setting_slider(box: VBoxContainer, before: Control, label_text: String, initial: float, setter: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 31
	box.add_child(row)
	box.move_child(row, before.get_index())
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	row.add_child(label)
	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = initial
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 42
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", DiscipleTheme.BRASS_LIGHT)
	value_label.text = "%d%%" % roundi(initial)
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float):
		setter.call(value / 100.0)
		value_label.text = "%d%%" % roundi(value))
	return slider

func _add_setting_option(box: VBoxContainer, before: Control, label_text: String, items: Array[String]) -> OptionButton:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 33
	box.add_child(row)
	box.move_child(row, before.get_index())
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 180
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in items:
		option.add_item(item)
	row.add_child(option)
	DiscipleTheme.apply_button(option)
	return option

func _update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)

func _reset_progress() -> void:
	GameState.reset_progress()
	_refresh_start_label()
	$SettingsLayer/SettingsPanel/Box/ResetButton.grab_focus()
	$SettingsLayer/SettingsPanel/Box/ResetButton.text = "진행도를 초기화했습니다"
	await get_tree().create_timer(1.4).timeout
	$SettingsLayer/SettingsPanel/Box/ResetButton.text = "진행도 초기화"

func _confirm_reset() -> void:
	reset_confirmation.popup_centered(Vector2i(460, 180))
	reset_confirmation.get_cancel_button().grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_layer.visible:
		get_viewport().set_input_as_handled()
		_close_settings()
