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

func _ready() -> void:
	layer = 20
	set_process(false)

func show_bubble(speaker: CanvasItem, text: String, style: StringName = &"default") -> void:
	close_bubble()
	_speaker = speaker
	if bubble_scene:
		_active_bubble = bubble_scene.instantiate() as SpeechBubble
	else:
		_active_bubble = SpeechBubble.new()
	add_child(_active_bubble)
	_active_bubble.set_meta("style", style)
	_active_bubble.dismissed.connect(close_bubble)
	_active_bubble.show_text(text)
	set_process(true)
	await get_tree().process_frame
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
	if above.y < screen_margin.y:
		var right := point + side_offset
		var left := point - Vector2(bubble_size.x + side_offset.x, -side_offset.y)
		position = right if right.x + bubble_size.x <= viewport_size.x - screen_margin.x else left

	position.x = clampf(position.x, screen_margin.x, maxf(screen_margin.x, viewport_size.x - bubble_size.x - screen_margin.x))
	position.y = clampf(position.y, screen_margin.y, maxf(screen_margin.y, viewport_size.y - bubble_size.y - screen_margin.y))
	_active_bubble.position = position

func _get_head_anchor() -> Vector2:
	if _speaker is Control:
		var rect := (_speaker as Control).get_global_rect()
		return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + minf(24.0, rect.size.y * 0.16))
	return _speaker.get_global_transform_with_canvas().origin + actor_head_offset

func close_bubble() -> void:
	set_process(false)
	_speaker = null
	if is_instance_valid(_active_bubble):
		_active_bubble.queue_free()
	_active_bubble = null
	bubble_closed.emit()
