extends Control

@onready var background: TextureRect = $Background
@onready var center: VBoxContainer = $Center
@onready var settings_layer: Control = $SettingsLayer
@onready var settings_panel: PanelContainer = $SettingsLayer/SettingsPanel
@onready var volume_slider: HSlider = $SettingsLayer/SettingsPanel/Box/VolumeSlider
@onready var volume_value: Label = $SettingsLayer/SettingsPanel/Box/VolumeHeader/Value
@onready var fade_rect: ColorRect = $FadeLayer/Fade

var transitioning := false

func _ready() -> void:
	$Center/StartButton.pressed.connect(_open_chapters)
	$Center/SettingsButton.pressed.connect(_open_settings)
	$SettingsLayer/SettingsPanel/Box/TextSpeed.item_selected.connect(_set_text_speed)
	$SettingsLayer/SettingsPanel/Box/VolumeSlider.value_changed.connect(_set_master_volume)
	$SettingsLayer/SettingsPanel/Box/CloseButton.pressed.connect(_close_settings)
	$SettingsLayer/SettingsPanel/Box/ResetButton.pressed.connect(_reset_progress)
	$SettingsLayer/Dim.gui_input.connect(_on_settings_dim_input)
	settings_layer.hide()
	_sync_settings_controls()
	_play_intro()

func _sync_settings_controls() -> void:
	var speed_index := 1
	if GameState.text_speed <= 18.0:
		speed_index = 0
	elif GameState.text_speed >= 40.0:
		speed_index = 2
	$SettingsLayer/SettingsPanel/Box/TextSpeed.select(speed_index)
	volume_slider.set_value_no_signal(GameState.master_volume * 100.0)
	_update_volume_label(GameState.master_volume * 100.0)

func _play_intro() -> void:
	transitioning = true
	fade_rect.color.a = 1.0
	center.modulate.a = 0.0
	center.position.y += 24.0
	background.pivot_offset = background.size * 0.5
	background.scale = Vector2(1.055, 1.055)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.75).set_trans(Tween.TRANS_SINE)
	tween.tween_property(center, "modulate:a", 1.0, 0.85).set_delay(0.18)
	tween.tween_property(center, "position:y", center.position.y - 24.0, 0.95).set_delay(0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(background, "scale", Vector2.ONE, 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.95).timeout
	transitioning = false

func _open_chapters() -> void:
	if transitioning:
		return
	transitioning = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	tween.tween_property(center, "modulate:a", 0.0, 0.35)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn")

func _open_settings() -> void:
	if transitioning or settings_layer.visible:
		return
	settings_layer.show()
	settings_panel.pivot_offset = settings_panel.size * 0.5
	settings_panel.scale = Vector2(0.94, 0.94)
	settings_panel.modulate.a = 0.0
	$SettingsLayer/Dim.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property($SettingsLayer/Dim, "modulate:a", 1.0, 0.22)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.28)
	tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_settings() -> void:
	if not settings_layer.visible:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property($SettingsLayer/Dim, "modulate:a", 0.0, 0.18)
	tween.tween_property(settings_panel, "modulate:a", 0.0, 0.18)
	tween.tween_property(settings_panel, "scale", Vector2(0.96, 0.96), 0.18)
	await tween.finished
	settings_layer.hide()

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

func _update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)

func _reset_progress() -> void:
	GameState.reset_progress()
	$SettingsLayer/SettingsPanel/Box/ResetButton.text = "진행도를 초기화했습니다"
	await get_tree().create_timer(1.4).timeout
	$SettingsLayer/SettingsPanel/Box/ResetButton.text = "진행도 초기화"
