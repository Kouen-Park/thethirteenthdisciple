extends Control

const DiscipleTheme = preload("res://scripts/ui_theme.gd")

const CHAPTER_PATHS := [
	"res://scenes/chapters/chapter_01_entry.tscn", "res://scenes/chapters/chapter_02_supper.tscn",
	"res://scenes/chapters/chapter_03_garden.tscn", "res://scenes/chapters/chapter_04_trial.tscn",
	"res://scenes/chapters/chapter_05_golgotha.tscn", "res://scenes/chapters/chapter_06_resurrection.tscn"
]

func _ready() -> void:
	DiscipleTheme.apply_chapter_select(self)
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn"))
	for chapter_number in 6:
		var button: Button = get_node("Chapters/Chapter%d" % (chapter_number + 1))
		button.disabled = not GameState.is_unlocked(chapter_number + 1)
		button.pressed.connect(_open_chapter.bind(chapter_number))
	$Chapters/Epilogue.visible = GameState.is_unlocked(7)
	$Chapters/Epilogue.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/chapters/epilogue.tscn"))

func _open_chapter(index: int) -> void:
	get_tree().change_scene_to_file(CHAPTER_PATHS[index])
