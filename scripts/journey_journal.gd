class_name JourneyJournal
extends CanvasLayer

signal opened
signal closed
const ThemeStyle = preload("res://scripts/ui_theme.gd")
const Story = preload("res://story_data.gd")
var can_open: Callable
var current_chapter := 1
var active := false
var button: Button
var overlay: Control
var panel: PanelContainer
var chapter_picker: OptionButton
var entries: VBoxContainer
var scroll: ScrollContainer
var close_button: Button
var status: Label
var _status_seconds := 0.0

func _ready() -> void:
	layer = 45
	button = Button.new()
	button.text = "J  기록 수첩"
	button.tooltip_text = "지금까지 살펴본 흔적과 내가 했던 선택을 다시 읽습니다."
	ThemeStyle.apply_button(button)
	add_child(button)
	button.pressed.connect(open_journal)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", ThemeStyle.PARCHMENT)
	status.add_theme_color_override("font_shadow_color", Color("211c28"))
	status.add_theme_constant_override("shadow_offset_y", 2)
	add_child(status)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.06, 0.10, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeStyle.panel_style(Color("211c28"), Color("8e6c4c")))
	overlay.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var title := Label.new()
	title.text = "길 위의 기록"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", ThemeStyle.PARCHMENT)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "내가 살펴본 것과 들은 말, 그리고 내가 했던 선택.  ·  PgUp / PgDn 스크롤"
	subtitle.add_theme_color_override("font_color", ThemeStyle.MUTED)
	box.add_child(subtitle)
	chapter_picker = OptionButton.new()
	chapter_picker.custom_minimum_size.y = 42
	ThemeStyle.apply_button(chapter_picker)
	chapter_picker.item_selected.connect(func(_index): _show_chapter(chapter_picker.get_selected_id()))
	box.add_child(chapter_picker)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 16)
	scroll.add_child(entries)
	close_button = Button.new()
	close_button.text = "길로 돌아가기   ·   J / Esc"
	close_button.custom_minimum_size.y = 44
	ThemeStyle.apply_button(close_button, true)
	close_button.pressed.connect(close_journal)
	box.add_child(close_button)
	chapter_picker.focus_next = chapter_picker.get_path_to(close_button)
	chapter_picker.focus_previous = chapter_picker.get_path_to(close_button)
	close_button.focus_next = close_button.get_path_to(chapter_picker)
	close_button.focus_previous = close_button.get_path_to(chapter_picker)
	overlay.hide()
	get_node("/root/StoryState").changed.connect(_on_record_changed)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	button.position = Vector2(view.x - 170, 26)
	button.size = Vector2(146, 36)
	status.position = Vector2(view.x - 300, 69)
	status.size.x = 276
	panel.position = Vector2(maxf(24, (view.x - 800) * 0.5), 40)
	panel.size = Vector2(minf(800, view.x - 48), view.y - 80)

func _process(delta: float) -> void:
	button.disabled = active or (can_open.is_valid() and not can_open.call())
	if _status_seconds > 0:
		_status_seconds = maxf(0, _status_seconds - delta)
		status.modulate.a = minf(1, _status_seconds)

func _on_record_changed(kind: StringName, _value: Variant) -> void:
	if kind not in [&"observation", &"choice", &"puzzle"]: return
	status.text = "수첩에 기록했습니다"
	status.modulate.a = 1
	_status_seconds = 3.0

func open_journal() -> void:
	if active or (can_open.is_valid() and not can_open.call()): return
	active = true
	opened.emit()
	chapter_picker.clear()
	for number in range(1, 7):
		var state: Dictionary = get_node("/root/StoryState").get_chapter_summary(StringName("chapter_%02d" % number))
		if number == current_chapter or not state.observed.is_empty() or not state.choices.is_empty():
			chapter_picker.add_item(Story.CHAPTERS[number - 1].title, number)
	chapter_picker.select(chapter_picker.get_item_index(current_chapter))
	_show_chapter(current_chapter)
	overlay.show()
	close_button.grab_focus()

func close_journal() -> void:
	if not active: return
	active = false
	overlay.hide()
	close_button.release_focus()
	closed.emit()

func _show_chapter(number: int) -> void:
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()
	scroll.scroll_vertical = 0
	var state: Dictionary = get_node("/root/StoryState").get_chapter_summary(StringName("chapter_%02d" % number))
	var context: Dictionary = BiblicalContext.CHAPTERS[number]
	_add_entry(context.title + " · " + context.reference, context.text)
	_add_entry("이야기와 창작의 범위", BiblicalContext.FICTION)
	var rows := observation_rows(state)
	if rows.is_empty(): _add_entry("아직 비어 있는 페이지", "주변의 사람과 흔적을 살펴보면 이곳에 남습니다.")
	for row in rows: _add_entry(row.title, row.text)
	for choice in state.choices.values():
		var label := choice_label(number, choice)
		if not label.is_empty(): _add_entry("내가 했던 선택", label)

static func observation_rows(state: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for value in state.get("observed", {}).values():
		if not value is Dictionary: continue
		var description := str(value.get("description", ""))
		var details: Dictionary = value.get("data", {}) if value.get("data", {}) is Dictionary else {}
		var lines: Array[String] = []
		if not description.is_empty(): lines.append(description)
		for line in details.get("lines", []):
			if line is String and not line in lines: lines.append(line)
		for line in details.get("dialogue", []):
			if line is Dictionary and line.has("text") and not str(line.text) in lines: lines.append(str(line.text))
		description = "\n".join(lines)
		if description.is_empty(): continue
		rows.append({"title": str(value.get("title", "남겨진 흔적과 증언")), "text": description})
	return rows

static func choice_label(number: int, choice: Variant) -> String:
	if number == 2:
		return {"order": "무너진 질서가 마음에 남았다.", "prayer": "다시 드러난 기도 자리가 마음에 남았다.", "uncertain": "두 이야기를 더 생각해 보기로 했다."}.get(str(choice), "")
	for line in Story.CHAPTERS[number - 1].lines:
		var ids: Array = line.get("choice_ids", [])
		for i in ids.size():
			if str(ids[i]) == str(choice): return line.choices[i]
	return ""

func _add_entry(title: String, text: String) -> void:
	var heading := Label.new()
	heading.text = title
	heading.add_theme_color_override("font_color", Color("e7bd72"))
	heading.add_theme_font_size_override("font_size", roundi(16 * get_node("/root/GameState").text_scale))
	entries.add_child(heading)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("f1dfad"))
	body.add_theme_font_size_override("font_size", roundi(18 * get_node("/root/GameState").text_scale))
	entries.add_child(body)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	var journal_key: bool = event is InputEventKey and event.pressed and (event.physical_keycode == KEY_J or event.keycode == KEY_J)
	if active and (journal_key or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close_journal()
	elif journal_key:
		get_viewport().set_input_as_handled()
		open_journal()
	elif active and event is InputEventKey and event.pressed and event.physical_keycode in [KEY_PAGEUP, KEY_PAGEDOWN]:
		get_viewport().set_input_as_handled()
		scroll.scroll_vertical += -320 if event.physical_keycode == KEY_PAGEUP else 320
	elif active and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
