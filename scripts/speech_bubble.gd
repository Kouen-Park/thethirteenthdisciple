class_name SpeechBubble
extends PanelContainer

signal dismissed

@export var padding := Vector2(8.0, 5.0)
@export var max_width := 350.0
@export var characters_per_second := 34.0

@onready var text_label: Label = $Margin/Text

var _full_text := ""
var _typing := false
var _elapsed := 0.0
var tail_anchor := Vector2.ZERO

func set_tail_anchor(value: Vector2) -> void:
	tail_anchor = value
	queue_redraw()

func _draw() -> void:
	if tail_anchor.y < size.y:
		return
	var x := clampf(tail_anchor.x, 14.0, size.x - 14.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 8, size.y - 1), Vector2(x + 8, size.y - 1), Vector2(x, size.y + 9)]), Color("#3e2b25"))
	draw_colored_polygon(PackedVector2Array([Vector2(x - 5, size.y - 2), Vector2(x + 5, size.y - 2), Vector2(x, size.y + 5)]), Color("#f6e5bc"))

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
	_update_hint()
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
	_update_hint()

func _update_hint() -> void:
	$Margin/AdvanceHint.text = "SPACE  전체 표시" if _typing else "SPACE  다음"

func set_speaker_name(value: String) -> void:
	$Margin/Speaker.text = value

func apply_text_scale(value: float) -> void:
	var scale_value := clampf(value, 0.85, 1.3)
	$Margin/Speaker.add_theme_font_size_override("font_size", roundi(14.0 * scale_value))
	$Margin/Text.add_theme_font_size_override("font_size", roundi(18.0 * scale_value))
	$Margin/AdvanceHint.add_theme_font_size_override("font_size", roundi(12.0 * scale_value))

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_SPACE or event.keycode == KEY_SPACE):
		get_viewport().set_input_as_handled()
		if _typing:
			_typing = false
			text_label.visible_characters = -1
			_update_hint()
		else:
			hide()
			dismissed.emit()
