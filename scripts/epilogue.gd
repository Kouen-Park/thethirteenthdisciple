extends Control

var lines := [
	["에필로그", "너는 지켜보았다. 배신을, 도망을, 침묵을, 그리고 다시 돌아온 사랑을."],
	["에필로그", "그날의 열두 제자 중 하나가 아니었어도, 너는 이미 그 자리에 있었다."],
	["에필로그", "두려워하지 말라. 내가 항상 너와 함께 있으리라."],
	["", "너는 오늘, 그 말을 믿고 한 걸음을 내디딜 수 있는가."]
]
var index := 0
var visible_count := 0.0
var typing := false

func _ready() -> void:
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu/chapter_select.tscn"))
	$Panel/Box/Advance.pressed.connect(_advance)
	_show_line()

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
