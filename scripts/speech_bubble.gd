class_name SpeechBubble
extends PanelContainer

signal dismissed

@export var padding := Vector2(8.0, 5.0)
@export var max_width := 300.0
@export var characters_per_second := 34.0

@onready var text_label: Label = $Margin/Text

var _full_text := ""
var _typing := false
var _elapsed := 0.0

func _ready() -> void:
	add_theme_constant_override("panel_border_width_left", 2)
	add_theme_constant_override("panel_border_width_top", 2)
	add_theme_constant_override("panel_border_width_right", 2)
	add_theme_constant_override("panel_border_width_bottom", 2)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(max_width, 0.0)
	custom_minimum_size = Vector2(max_width + 20.0, 0.0)
	pivot_offset = size * 0.5

func show_text(value: String) -> void:
	_full_text = value
	text_label.text = value
	text_label.custom_minimum_size = Vector2(max_width, 0.0)
	text_label.visible_characters = 0
	_typing = not value.is_empty()
	_elapsed = 0.0
	show()
	await get_tree().process_frame
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	if not _typing:
		return
	_elapsed += delta * characters_per_second
	text_label.visible_characters = mini(int(_elapsed), _full_text.length())
	if text_label.visible_characters >= _full_text.length():
		_typing = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		if _typing:
			_typing = false
			text_label.visible_characters = -1
		else:
			dismissed.emit()
			hide()
