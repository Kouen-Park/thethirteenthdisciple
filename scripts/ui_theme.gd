class_name UITheme
extends RefCounted

# THE THIRTEENTH DISCIPLE의 공통 시각 언어.
# 돌벽의 모래색, 오래된 양피지, 황동 장식, 밤의 잉크색을 모든 화면에서 공유합니다.
const INK := Color("#2a211b")
const INK_SOFT := Color("#443327")
const PARCHMENT := Color("#f3d9a0")
const PARCHMENT_SOFT := Color("#e9c783")
const BRASS := Color("#d49a45")
const BRASS_LIGHT := Color("#f4c96b")
const TERRACOTTA := Color("#a85f3c")
const TERRACOTTA_HOVER := Color("#c4774b")
const NIGHT := Color("#1d2730")
const MUTED := Color("#b79d78")

static func panel_style(fill: Color, line: Color, radius := 2, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = line
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(0.05, 0.025, 0.01, 0.24)
	style.shadow_size = 2
	return style

static func button_style(fill: Color, line: Color, radius := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = line
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

static func apply_button(button: Button, primary := false) -> void:
	if button == null:
		return
	var normal_fill := TERRACOTTA if primary else Color(0.16, 0.11, 0.07, 0.94)
	var normal_line := BRASS_LIGHT if primary else Color(0.73, 0.54, 0.30, 0.86)
	button.add_theme_color_override("font_color", PARCHMENT if primary else PARCHMENT_SOFT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", PARCHMENT)
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.49, 0.40, 0.55))
	button.add_theme_stylebox_override("normal", button_style(normal_fill, normal_line))
	button.add_theme_stylebox_override("hover", button_style(TERRACOTTA_HOVER if primary else Color("#5b412d"), BRASS_LIGHT))
	button.add_theme_stylebox_override("pressed", button_style(Color("#744027") if primary else Color("#24170e"), BRASS))
	button.add_theme_stylebox_override("disabled", button_style(Color(0.13, 0.11, 0.09, 0.65), Color(0.35, 0.30, 0.23, 0.45)))

static func apply_menu(root: Control) -> void:
	root.add_theme_color_override("font_color", PARCHMENT)
	apply_button(root.get_node_or_null("Center/StartButton"), true)
	apply_button(root.get_node_or_null("Center/SettingsButton"))
	apply_button(root.get_node_or_null("SettingsLayer/SettingsPanel/Box/ResetButton"))
	apply_button(root.get_node_or_null("SettingsLayer/SettingsPanel/Box/CloseButton"), true)
	var brand := root.get_node_or_null("Center/BrandPanel") as PanelContainer
	if brand:
		brand.add_theme_stylebox_override("panel", panel_style(Color(0.10, 0.065, 0.038, 0.94), Color(0.82, 0.59, 0.29, 0.90), 2, 2))
	var settings := root.get_node_or_null("SettingsLayer/SettingsPanel") as PanelContainer
	if settings:
		settings.add_theme_stylebox_override("panel", panel_style(Color(0.10, 0.065, 0.038, 0.98), BRASS, 2, 2))

static func apply_chapter_select(root: Control) -> void:
	root.add_theme_color_override("font_color", PARCHMENT)
	for index in 6:
		var button := root.get_node_or_null("Chapters/Chapter%d" % (index + 1)) as Button
		apply_button(button, index == 0)
		if button:
			button.custom_minimum_size = Vector2(0, 46)
			button.add_theme_font_size_override("font_size", 15)
	var epilogue := root.get_node_or_null("Chapters/Epilogue") as Button
	apply_button(epilogue)
	if epilogue:
		epilogue.custom_minimum_size = Vector2(0, 46)
		epilogue.add_theme_font_size_override("font_size", 15)
	var back := root.get_node_or_null("BackButton") as Button
	apply_button(back)
	if back:
		back.custom_minimum_size = Vector2(0, 44)
	var card := root.get_node_or_null("Card") as PanelContainer
	if card:
		card.add_theme_stylebox_override("panel", panel_style(Color(0.10, 0.07, 0.045, 0.96), Color(0.78, 0.56, 0.28, 0.86), 2, 2))

static func apply_chapter(root: Control) -> void:
	apply_button(root.get_node_or_null("Header/BackButton"))
	apply_button(root.get_node_or_null("DialoguePanel/Box/Advance"))
	apply_button(root.get_node_or_null("DialoguePanel/Box/ChoiceA"))
	apply_button(root.get_node_or_null("DialoguePanel/Box/ChoiceB"))
	apply_button(root.get_node_or_null("InteractionPanel/Box/Action"), true)
	var dialogue := root.get_node_or_null("DialoguePanel") as PanelContainer
	if dialogue:
		dialogue.add_theme_stylebox_override("panel", panel_style(Color(0.10, 0.07, 0.045, 0.96), Color(0.79, 0.58, 0.30, 0.90), 2, 2))
	var interaction := root.get_node_or_null("InteractionPanel") as PanelContainer
	if interaction:
		interaction.add_theme_stylebox_override("panel", panel_style(Color(0.10, 0.07, 0.045, 0.98), Color(0.86, 0.64, 0.33, 0.92), 2, 2))
	var speaker := root.get_node_or_null("DialoguePanel/Box/Speaker") as Label
	if speaker:
		speaker.add_theme_color_override("font_color", BRASS_LIGHT)
	var dialogue_text := root.get_node_or_null("DialoguePanel/Box/Dialogue") as Label
	if dialogue_text:
		dialogue_text.add_theme_color_override("font_color", PARCHMENT)
