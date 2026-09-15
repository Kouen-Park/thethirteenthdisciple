class_name ChapterOneEncounter
extends Node

signal finished

# TextureRect positions are top-left coordinates. These points put the donkey's
# feet on the painted road centre, beginning partly off-screen on the right.
const JESUS_START := Vector2(1980.0, 230.0)
const JESUS_ROAD_1 := Vector2(1840.0, 235.0)
const JESUS_ROAD_2 := Vector2(1690.0, 265.0)
const JESUS_ROAD_3 := Vector2(1540.0, 315.0)
const JESUS_ROAD_4 := Vector2(1390.0, 375.0)
const JESUS_JOIN := Vector2(1240.0, 425.0)
const JESUS_STOP := Vector2(1070.0, 455.0)
const MEETING_POINT := Vector2(1010.0, 575.0)
const MEETING_ROUTE_Y := 590.0

var controller: Node
var player: CharacterBody2D
var jesus: TextureRect
var camera: Camera2D
var crowd: Node
var temple_entrance: Area2D
var scanner: Node
var prompt: Label
var objective: Label
var chapter_audio: Node
var speech_bubbles: Node
var running := false
var sequence_tween: Tween

func setup(host: Node) -> void:
	controller = host
	player = host.get_node("CrowdPlayer")
	jesus = host.get_node("CharacterLayer/JesusDonkey")
	camera = host.get_node("WorldCamera")
	crowd = host.get_node("AmbientCrowd")
	temple_entrance = host.get_node("TempleEntrance")
	scanner = host.get_node("CrowdPlayer/InteractionScanner")
	prompt = host.get_node("WorldHUD/InteractionPrompt")
	objective = host.get_node("WorldHUD/Objective")
	chapter_audio = host.get_node("ChapterAudio")
	speech_bubbles = host.get_node("SpeechBubbleController")

func play() -> void:
	if running:
		return
	running = true
	player.set_input_enabled(false)
	scanner.set_input_enabled(false)
	prompt.hide()
	objective.text = "길가의 사람들이 오른쪽 샛길을 바라보며 물러섭니다."
	chapter_audio.hush(2.0)
	_kill_tween()
	sequence_tween = create_tween().set_parallel(true).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sequence_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	crowd.add_parting_tracks(sequence_tween)
	await sequence_tween.finished
	if _aborted():
		return

	jesus.position = JESUS_START
	jesus.scale = Vector2.ONE
	jesus.modulate.a = 1.0
	await camera.focus_on(jesus, Vector2(-140.0, -8.0), 0.85)
	if _aborted():
		return
	sequence_tween = create_tween()
	sequence_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	sequence_tween.tween_property(jesus, "position", JESUS_ROAD_1, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence_tween.tween_property(jesus, "position", JESUS_ROAD_2, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence_tween.tween_property(jesus, "position", JESUS_ROAD_3, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence_tween.tween_property(jesus, "position", JESUS_ROAD_4, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence_tween.tween_property(jesus, "position", JESUS_JOIN, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence_tween.tween_property(jesus, "position", JESUS_STOP, 1.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await sequence_tween.finished
	if _aborted():
		return

	await _approach_for_conversation()
	if _aborted():
		return
	await _show_line(player, "저 사람이… 사람들이 기다리던 사람인가?", &"protagonist")
	await _show_line(player, "나귀를 타고 들어오시는구나. 사람들이 옷과 가지를 펴는 이유를 이제 알겠다.", &"protagonist")


	await _show_line(player, "아직은 모르겠습니다. 하지만 오늘 본 것을 소문이라고만 부를 수는 없습니다.", &"protagonist")
	await _jesus_enters_first()
	if _aborted():
		return
	running = false
	finished.emit()

func cancel() -> void:
	running = false
	_kill_tween()

func _approach_for_conversation() -> void:
	objective.text = "큰 길에 멈춘 예수님에게 다가갑니다."
	# Move onto the clear lower lane first, then approach vertically. Unlike the
	# previous position tween this route respects every StaticBody2D collision.
	var route: Array[Vector2] = [
		Vector2(roundf(player.global_position.x), MEETING_ROUTE_Y),
		Vector2(MEETING_POINT.x, MEETING_ROUTE_Y),
		MEETING_POINT
	]
	await player.walk_cinematic_path(route)
	player.face_toward(jesus.global_position + jesus.size * Vector2(0.5, 0.85))
	await camera.return_to_player(0.5)
	objective.text = "SPACE  대사 진행"

func _jesus_enters_first() -> void:
	objective.text = "예수님이 먼저 성문 안으로 향합니다."
	var foot_pivot := Vector2(jesus.size.x * 0.5, jesus.size.y)
	jesus.pivot_offset = foot_pivot
	var approach: Vector2 = temple_entrance.get_node("Approach").global_position - foot_pivot
	var inside: Vector2 = temple_entrance.get_node("Inside").global_position - foot_pivot - Vector2(0, 12)
	_kill_tween()
	sequence_tween = create_tween()
	sequence_tween.tween_property(jesus, "position", approach, 1.9).set_trans(Tween.TRANS_SINE)
	sequence_tween.tween_property(jesus, "position", inside, 1.3)
	sequence_tween.parallel().tween_property(jesus, "scale", Vector2(0.55, 0.55), 1.3)
	sequence_tween.parallel().tween_property(jesus, "modulate:a", 0.0, 0.6).set_delay(0.7)
	await sequence_tween.finished
	jesus.hide()

func _show_line(speaker: CanvasItem, text: String, style: StringName) -> void:
	speech_bubbles.show_bubble(speaker, text, style)
	await speech_bubbles.bubble_closed

func _kill_tween() -> void:
	if sequence_tween and sequence_tween.is_valid():
		sequence_tween.kill()

func _aborted() -> bool:
	return not running or not is_instance_valid(controller) or bool(controller.transitioning)

func get_entrance_foot_route() -> PackedVector2Array:
	var foot_offset := jesus.size * Vector2(0.5, 1.0) if is_instance_valid(jesus) else Vector2(60.0, 110.0)
	return PackedVector2Array([
		JESUS_START + foot_offset,
		JESUS_ROAD_1 + foot_offset,
		JESUS_ROAD_2 + foot_offset,
		JESUS_ROAD_3 + foot_offset,
		JESUS_ROAD_4 + foot_offset,
		JESUS_JOIN + foot_offset,
		JESUS_STOP + foot_offset
	])
