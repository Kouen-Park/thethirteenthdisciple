extends Control

func _ready() -> void:
	$Center/StartButton.pressed.connect(_open_chapters)
	$Center/SettingsButton.pressed.connect(_open_settings)
	$SettingsPanel/Box/TextSpeed.item_selected.connect(_set_text_speed)
	$SettingsPanel/Box/CloseButton.pressed.connect(func(): $SettingsPanel.hide())
	$SettingsPanel/Box/ResetButton.pressed.connect(_reset_progress)
	$SettingsPanel.hide()
	var speed_index := 1
	if GameState.text_speed <= 18.0: speed_index = 0
	elif GameState.text_speed >= 40.0: speed_index = 2
	$SettingsPanel/Box/TextSpeed.select(speed_index)

func _open_chapters() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn")

func _open_settings() -> void:
	$SettingsPanel.show()

func _set_text_speed(index: int) -> void:
	GameState.set_text_speed([18.0, 28.0, 42.0][index])

func _reset_progress() -> void:
	GameState.reset_progress()
	$SettingsPanel/Box/ResetButton.text = "진행도를 초기화했습니다"
