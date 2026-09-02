extends Control

var lines := []
var index := 0
var visible_count := 0.0
var typing := false

func _ready() -> void:
	lines = _build_lines()
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn"))
	$Panel/Box/Advance.pressed.connect(_advance)
	_show_line()

func _build_lines() -> Array:
	var chapter_one: Dictionary = StoryState.chapters.get("chapter_01", {})
	var observed: Dictionary = chapter_one.get("observed", {})
	var memory := "당신은 군중 속에서 사람들의 목소리와 남겨진 흔적을 보았습니다."
	if observed.has("palm_leaf") and observed.has("discarded_cloak") and observed.has("footprints"):
		memory = "당신은 종려잎과 버려진 겉옷, 성문으로 향한 발자국을 보았습니다."
	return [
		["회상", memory],
		["질문", "당신은 그를 보았습니까?"],
		["질문", "당신이라면, 그날 군중 속에서 어디에 서 있었을까요?"],
		["", "제자라는 이름은 답이 아니라, 이제 당신에게 남은 질문입니다."]
	]

func _process(delta: float) -> void:
	if not typing: return
	visible_count += GameState.text_speed * delta
	$Panel/Box/Text.visible_characters = int(visible_count)
	if visible_count >= lines[index][1].length():
		typing = false
		$Panel/Box/Text.visible_characters = -1
		$Panel/Box/Advance.text = "계속  ›" if index < lines.size() - 1 else "챕터 선택으로  ›"

func _show_line() -> void:
	$Panel/Box/Speaker.text = lines[index][0]
	$Panel/Box/Text.text = lines[index][1]
	$Panel/Box/Text.visible_characters = 0
	visible_count = 0.0
	typing = true
	$Panel/Box/Advance.text = "···"

func _advance() -> void:
	if typing:
		visible_count = lines[index][1].length()
		return
	index += 1
	if index < lines.size():
		_show_line()
	else:
		get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn")
