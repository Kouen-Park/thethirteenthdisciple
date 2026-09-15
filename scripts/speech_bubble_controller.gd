class_name SpeechBubbleController
extends CanvasLayer

signal bubble_opened(speaker: Node, text: String)
signal bubble_closed

@export var bubble_scene: PackedScene
@export var screen_margin := Vector2(16.0, 16.0)
@export var vertical_offset := 10.0
@export var actor_head_offset := Vector2(0.0, -92.0)
@export var side_offset := Vector2(26.0, -18.0)

var _active_bubble: SpeechBubble
var _speaker: CanvasItem
var _owns_dialogue_duck := false

func _ready() -> void:
	layer = 20
	set_process(false)
	var settings := get_node_or_null("/root/GameState")
	if settings: settings.text_speed_changed.connect(_on_text_speed_changed)

func _on_text_speed_changed(value: float) -> void:
	if is_instance_valid(_active_bubble): _active_bubble.characters_per_second = value

func show_bubble(speaker: CanvasItem, text: String, style: StringName = &"default") -> void:
	close_bubble()
	_speaker = speaker
	if bubble_scene:
		_active_bubble = bubble_scene.instantiate() as SpeechBubble
	else:
		_active_bubble = SpeechBubble.new()
	add_child(_active_bubble)
	var settings := get_node_or_null("/root/GameState")
	if settings:
		_active_bubble.characters_per_second = settings.text_speed
		_active_bubble.apply_text_scale(settings.text_scale)
	var speaker_name := "나"
	if style == &"jesus":
		speaker_name = "예수"
	elif speaker.name == &"MerchantJonah":
		speaker_name = "상인 요나"
	elif speaker.name == &"Miriam":
		speaker_name = "미리암"
	elif style == &"witness":
		speaker_name = str(speaker.get_meta("display_name", "행인"))
	_active_bubble.set_speaker_name(speaker_name)
	_active_bubble.set_meta("style", style)
	_active_bubble.dismissed.connect(close_bubble)
	_active_bubble.show_text(text)
	var audio_mix := get_node_or_null("/root/AudioMix")
	if audio_mix:
		audio_mix.begin_dialogue()
		_owns_dialogue_duck = true
	set_process(true)
	await get_tree().process_frame
	if not is_instance_valid(_active_bubble) or not is_instance_valid(_speaker):
		return
	_update_position()
	bubble_opened.emit(speaker, text)

func _process(_delta: float) -> void:
	if is_instance_valid(_speaker) and is_instance_valid(_active_bubble):
		_update_position()

func _update_position() -> void:
	if not is_instance_valid(_speaker) or not is_instance_valid(_active_bubble):
		return
	var point := _get_head_anchor()
	var viewport_size := get_viewport().get_visible_rect().size
	var bubble_size := _active_bubble.size
	var above := point - Vector2(bubble_size.x * 0.5, bubble_size.y + vertical_offset)
	var position := above

	# If there is not enough room above the character, place the bubble beside the head
	# rather than clamping it to the top edge of the screen.
	if above.y < 148.0:
		var right := point + side_offset
		var left := point - Vector2(bubble_size.x + side_offset.x, -side_offset.y)
		position = right if right.x + bubble_size.x <= viewport_size.x - screen_margin.x else left

	position.x = clampf(position.x, screen_margin.x, maxf(screen_margin.x, viewport_size.x - bubble_size.x - screen_margin.x))
	position.y = clampf(position.y, 148.0, maxf(148.0, viewport_size.y - bubble_size.y - screen_margin.y))
	_active_bubble.position = position
	_active_bubble.set_tail_anchor(point - position)

func _get_head_anchor() -> Vector2:
	if _speaker is Control:
		var control := _speaker as Control
		var default_anchor := Vector2(control.size.x * 0.5, minf(24.0, control.size.y * 0.16))
		var local_anchor: Vector2 = control.get_meta("head_anchor_local", default_anchor)
		# The bubble lives in a CanvasLayer. Include the active Camera2D transform
		# so world-space Control actors point to their on-screen head position.
		return control.get_global_transform_with_canvas() * local_anchor
	var head_offset: Vector2 = _speaker.get_meta("head_offset", actor_head_offset)
	return _speaker.get_global_transform_with_canvas().origin + head_offset

func close_bubble() -> void:
	set_process(false)
	_speaker = null
	var had_bubble := is_instance_valid(_active_bubble)
	if had_bubble:
		_active_bubble.hide()
		_active_bubble.set_process_unhandled_input(false)
		_active_bubble.queue_free()
	_active_bubble = null
	if had_bubble:
		var audio_mix := get_node_or_null("/root/AudioMix")
		if audio_mix and _owns_dialogue_duck:
			audio_mix.end_dialogue()
		_owns_dialogue_duck = false
		bubble_closed.emit()

func _exit_tree() -> void:
	# Scene changes can remove a live bubble without its dismissed signal.
	if _owns_dialogue_duck:
		var mix := get_node_or_null("/root/AudioMix")
		if mix: mix.end_dialogue()
		_owns_dialogue_duck = false
