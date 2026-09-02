class_name InteractionController
extends Node

## 모든 챕터 상호작용을 동일한 start/reset/completed 흐름으로 관리합니다.
## 실제 입력은 child_interaction이 담당하고, 이 컨트롤러는 진행 상태와 화면 연결만 담당합니다.

signal started(data: Dictionary)
signal progress_changed(current: int, total: int)
signal selection_made(option_id: StringName, description: String)
signal completed(data: Dictionary)
signal cancelled

@export var auto_hide_on_complete: bool = true

var _action_button: Button
var _hint_label: Label
var _child_interaction: Node
var _data: Dictionary = {}
var _steps: Array = []
var _step_index: int = 0
var _running: bool = false
var _child_completed_callable: Callable
var _child_progress_callable: Callable
var _child_selected_callable: Callable

func setup(action_button: Button, hint_label: Label) -> void:
	_action_button = action_button
	_hint_label = hint_label
	if _action_button and not _action_button.pressed.is_connected(_on_action_pressed):
		_action_button.pressed.connect(_on_action_pressed)

func start(data: Dictionary, child_interaction: Node = null) -> void:
	reset()
	_data = data.duplicate(true)
	_child_interaction = child_interaction
	_steps = _data.get("steps", []) as Array
	_step_index = 0
	_running = true

	if _child_interaction:
		_connect_child_interaction(_child_interaction)
		if _child_interaction.has_method("configure"):
			_child_interaction.configure(_data)
		if _child_interaction.has_method("show"):
			_child_interaction.show()
		if _action_button:
			_action_button.hide()
	else:
		if _action_button:
			_action_button.show()
		_update_button_step()

	started.emit(_data)
	progress_changed.emit(0, _get_total_progress())

func reset() -> void:
	_disconnect_child_interaction()
	_running = false
	_step_index = 0
	_steps.clear()
	_data.clear()
	_child_interaction = null
	if _action_button:
		_action_button.show()

func cancel() -> void:
	if not _running:
		return
	reset()
	cancelled.emit()

func is_running() -> bool:
	return _running

func get_progress() -> Dictionary:
	return {
		"current": _step_index,
		"total": _get_total_progress(),
		"data": _data.duplicate(true)
	}

func _on_action_pressed() -> void:
	if not _running or _child_interaction:
		return

	if _steps.is_empty():
		_complete()
		return

	_step_index += 1
	progress_changed.emit(_step_index, _steps.size())
	if _step_index >= _steps.size():
		_complete()
	else:
		_update_button_step()

func _update_button_step() -> void:
	if not _action_button:
		return
	if _steps.is_empty():
		_action_button.text = "완료"
		if _hint_label:
			_hint_label.text = str(_data.get("instruction", "천천히 눌러 진행하세요."))
		return

	_action_button.text = "%d / %d · %s" % [
		_step_index + 1,
		_steps.size(),
		str(_steps[_step_index])
	]
	if _hint_label:
		_hint_label.text = str(_data.get("instruction", "천천히 눌러 진행하세요."))

func _connect_child_interaction(interaction: Node) -> void:
	if interaction.has_signal("completed"):
		_child_completed_callable = Callable(self, "_on_child_completed")
		if not interaction.is_connected("completed", _child_completed_callable):
			interaction.connect("completed", _child_completed_callable)
	if interaction.has_signal("progress_changed"):
		_child_progress_callable = Callable(self, "_on_child_progress_changed")
		if not interaction.is_connected("progress_changed", _child_progress_callable):
			interaction.connect("progress_changed", _child_progress_callable)
	if interaction.has_signal("selected"):
		_child_selected_callable = Callable(self, "_on_child_selected")
		if not interaction.is_connected("selected", _child_selected_callable):
			interaction.connect("selected", _child_selected_callable)

func _disconnect_child_interaction() -> void:
	if not is_instance_valid(_child_interaction):
		return
	if _child_completed_callable.is_valid() and _child_interaction.is_connected("completed", _child_completed_callable):
		_child_interaction.disconnect("completed", _child_completed_callable)
	if _child_progress_callable.is_valid() and _child_interaction.is_connected("progress_changed", _child_progress_callable):
		_child_interaction.disconnect("progress_changed", _child_progress_callable)
	if _child_selected_callable.is_valid() and _child_interaction.is_connected("selected", _child_selected_callable):
		_child_interaction.disconnect("selected", _child_selected_callable)
	_child_completed_callable = Callable()
	_child_progress_callable = Callable()
	_child_selected_callable = Callable()

func _on_child_progress_changed(current: int, total: int) -> void:
	if not _running:
		return
	progress_changed.emit(current, total)
	if _hint_label:
		_hint_label.text = "%s  %d / %d" % [
			str(_data.get("instruction", "진행하세요.")),
			current,
			total
		]

func _on_child_selected(option_id: StringName, description: String) -> void:
	if _running:
		selection_made.emit(option_id, description)

func _on_child_completed() -> void:
	if not _running:
		return
	_complete()

func _get_total_progress() -> int:
	if _child_interaction and _data.has("required"):
		return int(_data.get("required", 1))
	return _steps.size()

func _complete() -> void:
	if not _running:
		return
	_running = false
	_disconnect_child_interaction()
	if auto_hide_on_complete and is_instance_valid(_child_interaction) and _child_interaction.has_method("hide"):
		_child_interaction.hide()
	completed.emit(_data.duplicate(true))
