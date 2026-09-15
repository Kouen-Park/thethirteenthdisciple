class_name WorldChapterBase
extends Node2D

const DiscipleTheme = preload("res://scripts/ui_theme.gd")

@export_range(1, 6) var chapter_number := 1
@export var persistence_enabled := true

@onready var player: CrowdPlayerController = $Player
@onready var world_camera: Camera2D = $WorldCamera
@onready var speech_bubbles: SpeechBubbleController = $SpeechBubbleController
@onready var interaction_scanner: InteractionScanner = $Player/InteractionScanner
@onready var objective_label: Label = $UILayer/Objective
@onready var interaction_prompt: Label = $UILayer/InteractionPrompt
@onready var fade_rect: ColorRect = $FadeLayer/Fade

var field_investigation: FieldInvestigation
var journal: JourneyJournal
var pause_menu: JourneyPauseMenu
var chapter_id: StringName
var transitioning := false
var leave_confirmation: ConfirmationDialog
var _resume_movement := false
var _resume_interaction := false
var _input_locks: Dictionary = {}

func setup_world_chapter() -> void:
	chapter_id = StringName("chapter_%02d" % chapter_number)
	interaction_scanner.interaction_requested.connect(_on_player_interaction_requested)
	interaction_scanner.target_changed.connect(_on_interaction_target_changed)
	$UILayer/Header/BackButton.pressed.connect(_request_leave_chapter)
	DiscipleTheme.apply_button($UILayer/Header/BackButton)
	leave_confirmation = ConfirmationDialog.new()
	leave_confirmation.title = "장면 선택으로 돌아갈까요?"
	leave_confirmation.dialog_text = "관찰 기록은 유지됩니다.\n다시 들어오면 이 장의 처음부터 시작합니다."
	leave_confirmation.ok_button_text = "장면 선택으로"
	leave_confirmation.cancel_button_text = "계속 플레이"
	add_child(leave_confirmation)
	leave_confirmation.confirmed.connect(_leave_chapter)
	leave_confirmation.canceled.connect(_cancel_leave_chapter)
	DiscipleTheme.apply_world_hud(objective_label, interaction_prompt, GameState.text_scale)
	journal = preload("res://scripts/journey_journal.gd").new()
	journal.current_chapter = chapter_number
	journal.can_open = func(): return not transitioning and not is_input_locked() and not leave_confirmation.visible
	journal.opened.connect(func(): acquire_input_lock(&"journal"))
	journal.closed.connect(func(): release_input_lock(&"journal"))
	add_child(journal)
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	pause_menu.can_open = func(): return not transitioning and not leave_confirmation.visible and not journal.active
	add_child(pause_menu)
	var reflection := get_node_or_null("UILayer/ChoicePanel") as PanelContainer
	if reflection:
		for child in reflection.get_node("Box").get_children():
			if child is Button or child is Label:
				child.add_theme_font_size_override("font_size", roundi((16 if child is Button else 20) * GameState.text_scale))
		reflection.visibility_changed.connect(func(): call_deferred("_layout_reflection"))
		get_viewport().size_changed.connect(_layout_reflection)
		call_deferred("_layout_reflection")

func register_interactables(targets: Array[Node]) -> void:
	for target in targets:
		if not target.interacted.is_connected(_on_world_interacted):
			target.interacted.connect(_on_world_interacted)

func set_world_input(enabled: bool) -> void:
	if enabled:
		_input_locks.erase(&"legacy")
	else:
		_input_locks[&"legacy"] = true
	_apply_world_input_state()

func acquire_input_lock(reason: StringName) -> void:
	_input_locks[reason] = true
	_apply_world_input_state()

func release_input_lock(reason: StringName) -> void:
	_input_locks.erase(reason)
	_apply_world_input_state()

func is_input_locked(reason: StringName = StringName()) -> bool:
	return not _input_locks.is_empty() if reason == StringName() else _input_locks.has(reason)

func _apply_world_input_state() -> void:
	var enabled := _input_locks.is_empty()
	player.set_input_enabled(enabled)
	interaction_scanner.set_input_enabled(enabled)
	if not enabled:
		interaction_prompt.hide()

func show_world_line(speaker: CanvasItem, text: String, style: StringName) -> void:
	acquire_input_lock(&"dialogue")
	if speaker is Node2D and speaker != player:
		player.face_toward(speaker.global_position)
	speech_bubbles.show_bubble(speaker, text, style)
	await speech_bubbles.bubble_closed
	release_input_lock(&"dialogue")

func record_observation(interaction_id: StringName, data: Dictionary) -> void:
	if not persistence_enabled:
		return
	StoryState.record_observation(chapter_id, interaction_id, data)
	GameState.save_progress()

func fade_in() -> void:
	transitioning = true
	fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished
	transitioning = false

func fade_chapter_header(delay := 2.5) -> void:
	if not has_node("UILayer/Header"):
		return
	var title := get_node_or_null("UILayer/Header/Title") as CanvasItem
	var place := get_node_or_null("UILayer/Header/Place") as CanvasItem
	var shade := get_node_or_null("UILayer/HeaderShade") as CanvasItem
	var tween := create_tween().set_parallel(true)
	if title:
		tween.tween_property(title, "modulate:a", 0.0, 0.6).set_delay(delay)
	if place:
		tween.tween_property(place, "modulate:a", 0.0, 0.6).set_delay(delay)
	if shade:
		tween.tween_property(shade, "modulate:a", 0.18, 0.6).set_delay(delay)

func finish_world_chapter() -> void:
	if transitioning:
		return
	transitioning = true
	set_world_input(false)
	if BiblicalContext.TRANSITIONS.has(chapter_number):
		await BibleInterlude.present(self, BiblicalContext.TRANSITIONS[chapter_number])
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, 0.85).set_trans(Tween.TRANS_SINE)
	if has_node("ChapterAudio"):
		$ChapterAudio.prepare_exit()
	await tween.finished
	if not persistence_enabled:
		return
	StoryState.complete_chapter(chapter_id)
	GameState.unlock_through(chapter_number + 1)
	get_tree().change_scene_to_file(GameState.get_next_scene(chapter_number + 1))

func _on_player_interaction_requested(target: Node) -> void:
	if target and target.has_method("interact"):
		target.interact()

func _on_interaction_target_changed(target: Node) -> void:
	if target and target.has_method("get_prompt_text"):
		interaction_prompt.text = "E  %s" % target.get_prompt_text()
		interaction_prompt.show()
	else:
		interaction_prompt.hide()

func _on_world_interacted(_interaction_id: StringName, _data: Dictionary) -> void:
	pass

func _request_leave_chapter() -> void:
	if transitioning or leave_confirmation.visible or (is_instance_valid(journal) and journal.active):
		return
	acquire_input_lock(&"leave")
	leave_confirmation.popup_centered(Vector2i(460, 180))
	leave_confirmation.get_cancel_button().grab_focus()

func _cancel_leave_chapter() -> void:
	release_input_lock(&"leave")
	$UILayer/Header/BackButton.release_focus()

func _leave_chapter() -> void:
	if transitioning:
		return
	transitioning = true
	if has_node("ChapterAudio"):
		$ChapterAudio.prepare_exit()
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.45)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_request_leave_chapter()

func _layout_reflection() -> void:
	var reflection := get_node_or_null("UILayer/ChoicePanel") as PanelContainer
	if not reflection: return
	var view := get_viewport_rect().size
	reflection.set_anchors_preset(Control.PRESET_TOP_LEFT)
	reflection.size = Vector2(minf(850, view.x - 48), 0)
	reflection.position = Vector2((view.x - reflection.size.x) * 0.5, view.y - reflection.size.y - 24)

func begin_field_investigation(number: int, targets_to_suspend: Array, on_complete: Callable) -> void:
	if is_instance_valid(field_investigation) and field_investigation.active: return
	if is_instance_valid(field_investigation): return
	if number in [2, 3]:
		field_investigation = preload("res://scripts/spatial_investigation.gd").new()
	elif number in [4, 5, 6]:
		field_investigation = preload("res://scripts/evidence_link_investigation.gd").new()
	else:
		field_investigation = FieldInvestigation.new()
	add_child(field_investigation)
	field_investigation.completed.connect(on_complete)
	field_investigation.start(number, player, objective_label, targets_to_suspend)
