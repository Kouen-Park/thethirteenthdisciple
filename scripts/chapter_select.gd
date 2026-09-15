extends Control

const DiscipleTheme = preload("res://scripts/ui_theme.gd")
const Story = preload("res://story_data.gd")

var preview_title: Label
var preview_place: Label
var preview_status: Label
var entering := false

func _ready() -> void:
	DiscipleTheme.apply_chapter_select(self)
	_layout_menu()
	$BackButton.pressed.connect(_go_back)
	for chapter_number in 6:
		var button: Button = get_node("Chapters/Chapter%d" % (chapter_number + 1))
		button.disabled = not GameState.is_unlocked(chapter_number + 1)
		button.text = "%s   ·   %s" % [Story.CHAPTERS[chapter_number].title, _chapter_status(chapter_number)]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.mouse_entered.connect(_preview.bind(chapter_number))
		button.focus_entered.connect(_preview.bind(chapter_number))
		button.pressed.connect(_open_chapter.bind(chapter_number))
	$Chapters/Epilogue.visible = true
	$Chapters/Epilogue.disabled = not GameState.is_unlocked(7)
	$Chapters/Epilogue.text = "에필로그   ·   " + _chapter_status(6)
	$Chapters/Epilogue.alignment = HORIZONTAL_ALIGNMENT_LEFT
	$Chapters/Epilogue.focus_entered.connect(_preview.bind(6))
	$Chapters/Epilogue.mouse_entered.connect(_preview.bind(6))
	$Chapters/Epilogue.pressed.connect(_open_chapter.bind(6))
	_preview(clampi(GameState.current_chapter - 1, 0, 6))
	var focus_target: Control = $Chapters/Epilogue if GameState.current_chapter == 7 else get_node("Chapters/Chapter%d" % clampi(GameState.current_chapter, 1, 6))
	if focus_target.disabled: focus_target = $Chapters/Chapter1
	focus_target.grab_focus()

func _open_chapter(index: int) -> void:
	if entering or not GameState.is_unlocked(index + 1):
		return
	entering = true
	get_tree().change_scene_to_file(GameState.get_next_scene(index + 1))

func _chapter_status(index: int) -> String:
	var id := "chapter_%02d" % (index + 1)
	if not GameState.is_available(index + 1):
		return "제작 중"
	if bool(StoryState.chapters.get(id, {}).get("completed", false)):
		return "완료 · 다시 보기"
	if not GameState.is_unlocked(index + 1):
		return "잠김"
	return "진행 가능"

func _layout_menu() -> void:
	$Card.hide()
	_rect($Title, Rect2(72, 52, 620, 48))
	$Title.text = "장면 선택"
	$Title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	$Title.add_theme_font_size_override("font_size", 32)
	_rect($Chapters, Rect2(72, 155, 610, 440))
	_rect($BackButton, Rect2(72, 628, 240, 48))
	var help := Label.new()
	help.text = "열린 장면은 처음부터 재방문할 수 있습니다."
	help.add_theme_font_size_override("font_size", 16)
	add_child(help)
	_rect(help, Rect2(72, 108, 610, 30))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DiscipleTheme.panel_style(Color(0.08, 0.12, 0.13, 0.91), DiscipleTheme.MUTED))
	add_child(panel)
	_rect(panel, Rect2(740, 330, 450, 244))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	preview_title = Label.new()
	preview_title.add_theme_font_size_override("font_size", 22)
	preview_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(preview_title)
	preview_place = Label.new()
	preview_place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_place.add_theme_font_size_override("font_size", 17)
	box.add_child(preview_place)
	preview_status = Label.new()
	preview_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_status.add_theme_font_size_override("font_size", 15)
	box.add_child(preview_status)

func _preview(index: int) -> void:
	preview_title.text = Story.CHAPTERS[index].title
	preview_place.text = Story.CHAPTERS[index].place
	if not GameState.is_unlocked(index + 1):
		preview_status.text = "앞선 장을 완료하면 열립니다."
	elif index == 0:
		preview_status.text = "소문을 묻고, 흔적을 살펴보고, 군중 속에서 한 사람을 마주합니다."
	elif index == 1:
		preview_status.text = "소란이 지나간 성전 시장에서 흔적과 서로 다른 증언을 살펴봅니다."
	else:
		preview_status.text = [
			"", "", "같은 우물가의 낮과 밤을 걸으며, 등불과 발자국이 이어지는 길을 찾습니다.",
			"재판장 밖에서 질문이 외침으로 바뀌는 과정을 듣고, 내 목소리를 정합니다.",
			"언덕 아래의 작은 흔적을 살펴보고, 지금 손이 닿는 일을 선택합니다.",
			"열린 무덤과 엇갈리는 증언 앞에서, 본 것과 들은 것을 구분합니다.",
			"지나온 길과 내가 했던 선택을 돌아봅니다. 마지막에는 질문이 남습니다."
		][index]

func _rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size

func _go_back() -> void:
	if not entering:
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()
