class_name BibleInterlude
extends CanvasLayer

const DiscipleTheme = preload("res://scripts/ui_theme.gd")
const CutsceneCast := {
	"jesus": preload("res://assets/art/cutscene_cast/jesus.png"),
	"peter": preload("res://assets/art/cutscene_cast/peter.png"),
	"judas": preload("res://assets/art/cutscene_cast/judas.png"),
	"disciple": preload("res://assets/art/cutscene_cast/disciple.png"),
	"priest": preload("res://assets/art/cutscene_cast/priest.png"),
	"pilate": preload("res://assets/art/cutscene_cast/pilate.png"),
	"barabbas": preload("res://assets/art/cutscene_cast/barabbas.png"),
	"merchant": preload("res://assets/art/cutscene_cast/merchant.png"),
	"male_pilgrim": preload("res://assets/art/cutscene_cast/male_pilgrim.png"),
	"female_pilgrim": preload("res://assets/art/cutscene_cast/female_pilgrim.png"),
	"tomb_messenger": preload("res://assets/art/cutscene_cast/tomb_messenger.png"),
	"escort_soldier": preload("res://assets/art/cutscene_cast/escort_soldier.png"),
	"jesus_donkey": preload("res://assets/art/pixel/jesus_donkey_chibi.png"),
	"servant": preload("res://assets/art/biblical_cast/servant.png"),
	"simon": preload("res://assets/art/biblical_cast/simon.png"),
	"mary": preload("res://assets/art/biblical_cast/mary.png"),
	"salome": preload("res://assets/art/biblical_cast/salome.png"),
	"joseph": preload("res://assets/art/biblical_cast/joseph.png"),
}
signal advanced

var panel: Control
var art: Node2D
var fade: ColorRect
var caption_label: Label
var progress_label: Label
var next_button: Button
var scene_kind := ""
var scenery: Texture2D
var shots: Array = []
var shot_index := 0
var shot_elapsed := 0.0
# Kept as a public clock for pause-state compatibility with the former interlude.
var elapsed := 0.0
var ready_to_advance := false

static func present(host: Node, data: Dictionary) -> void:
	var sequence := BibleInterlude.new()
	host.add_child(sequence)
	sequence.build(data)
	await sequence.advanced
	sequence.queue_free()

func build(data: Dictionary) -> void:
	layer = 52
	scene_kind = str(data.get("scene", ""))
	shots = BiblicalContext.cutscene_shots(data)
	_load_scenery()
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var backdrop := ColorRect.new()
	backdrop.color = Color("10131c")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(backdrop)
	art = Node2D.new()
	art.draw.connect(_draw_cutscene)
	panel.add_child(art)
	fade = ColorRect.new()
	fade.color = Color(0.04, 0.035, 0.055, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(fade)
	_build_header(str(data.get("title", "")))
	_build_caption_panel()
	_show_shot(0)

func _text_scale() -> float:
	var state := get_node_or_null("/root/GameState")
	return minf(float(state.get("text_scale")), 1.15) if state else 1.0

func _load_scenery() -> void:
	var settings := {
		"entry": "res://assets/art/pixel/chapter01_jerusalem_gate_world_2048.png",
		"temple": "res://assets/art/chapter02/temple_market.png",
		"supper": "res://assets/art/chapter03/courtyard.png",
		"arrest": "res://assets/art/chapter03/courtyard.png",
		"trial": "res://assets/art/late_chapters/trial.png",
		"procession": "res://assets/art/late_chapters/golgotha.png",
		"cross": "res://assets/art/late_chapters/golgotha.png",
		"burial": "res://assets/art/late_chapters/tomb.png",
		"tomb": "res://assets/art/late_chapters/tomb.png"
	}
	if settings.has(scene_kind):
		scenery = load(settings[scene_kind])

func _build_header(title: String) -> void:
	var header := ColorRect.new()
	header.color = Color(0.035, 0.025, 0.025, 0.66)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 92
	panel.add_child(header)
	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(44, 20)
	title_label.size = Vector2(1050, 38)
	title_label.add_theme_font_size_override("font_size", roundi(26 * _text_scale()))
	title_label.add_theme_color_override("font_color", Color("f2d18c"))
	title_label.add_theme_color_override("font_shadow_color", Color("24150f"))
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title_label)
	var marker := Label.new()
	marker.text = "성경 배경 컷신"
	marker.position = Vector2(46, 57)
	marker.add_theme_font_size_override("font_size", 14)
	marker.add_theme_color_override("font_color", Color("c9b493"))
	header.add_child(marker)

func _build_caption_panel() -> void:
	var box := PanelContainer.new()
	box.name = "CaptionPanel"
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -172
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.035, 0.045, 0.92)
	style.border_width_top = 2
	style.border_color = Color(0.82, 0.61, 0.31, 0.85)
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 20
	style.content_margin_bottom = 18
	box.add_theme_stylebox_override("panel", style)
	panel.add_child(box)
	var columns := VBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	box.add_child(columns)
	caption_label = Label.new()
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_label.add_theme_font_size_override("font_size", roundi(22 * _text_scale()))
	caption_label.add_theme_color_override("font_color", Color("f4e8d3"))
	caption_label.custom_minimum_size.y = 58
	columns.add_child(caption_label)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 16)
	columns.add_child(controls)
	progress_label = Label.new()
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.add_theme_font_size_override("font_size", 15)
	progress_label.add_theme_color_override("font_color", Color("c9ad7c"))
	controls.add_child(progress_label)
	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(280, 42)
	DiscipleTheme.apply_button(next_button)
	next_button.pressed.connect(_advance)
	controls.add_child(next_button)

func _show_shot(index: int) -> void:
	shot_index = index
	shot_elapsed = 0.0
	elapsed = 0.0
	ready_to_advance = false
	caption_label.text = str(shots[shot_index][1])
	progress_label.text = "%d / %d" % [shot_index + 1, shots.size()]
	next_button.text = "길을 이어가기 · Space / Enter" if shot_index == shots.size() - 1 else "다음 장면 · Space / Enter"
	fade.color.a = 1.0
	art.queue_redraw()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.38).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.32, false).timeout
	ready_to_advance = true
	next_button.grab_focus()

func _advance() -> void:
	if not ready_to_advance:
		return
	if shot_index < shots.size() - 1:
		_show_shot(shot_index + 1)
		return
	ready_to_advance = false
	advanced.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_ENTER]:
		get_viewport().set_input_as_handled()
		_advance()

func _process(delta: float) -> void:
	shot_elapsed += delta
	elapsed = shot_elapsed
	if is_instance_valid(art):
		var view := get_viewport().get_visible_rect().size
		art.scale = Vector2(view.x / 1280.0, view.y / 720.0)
		art.queue_redraw()

func _stage() -> String:
	return str(shots[shot_index][0]) if not shots.is_empty() else ""

func _person(at: Vector2, tint: Color, role := "", facing := 1.0) -> void:
	var sway := sin(shot_elapsed * 2.2 + at.x * 0.01) * 1.5
	art.draw_circle(at + Vector2(0, -66 + sway), 13, tint.lightened(0.12))
	art.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-15 * facing, -50 + sway), at + Vector2(15 * facing, -50 + sway),
		at + Vector2(24 * facing, 0), at + Vector2(-22 * facing, 0)
	]), tint)
	if role == "torch":
		art.draw_line(at + Vector2(20 * facing, -30), at + Vector2(29 * facing, -89), Color("6f4a31"), 6)
		art.draw_circle(at + Vector2(29 * facing, -96), 10 + sin(shot_elapsed * 7) * 2, Color("f0a64d"))
	elif role == "bound":
		art.draw_line(at + Vector2(-18, -35), at + Vector2(18, -35), Color("8c6947"), 5)
	elif role == "staff":
		art.draw_line(at + Vector2(18, -45), at + Vector2(18, 5), Color("745238"), 6)

func _cast_person(role: String, at: Vector2, size_scale := 1.75) -> void:
	var texture: Texture2D = CutsceneCast.get(role)
	if not texture:
		return
	var bob := sin(shot_elapsed * 2.2 + at.x * 0.01) * 1.5
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * size_scale
	art.draw_set_transform(at + Vector2(0, -2), 0.0, Vector2(1.0, 0.28))
	art.draw_circle(Vector2.ZERO, draw_size.x * 0.31, Color(0.05, 0.04, 0.04, 0.22))
	art.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	art.draw_texture_rect(texture, Rect2(at.x - draw_size.x * 0.5, at.y - draw_size.y + bob, draw_size.x, draw_size.y), false)

func _draw_cutscene() -> void:
	if scenery:
		art.draw_texture_rect(scenery, Rect2(0, 0, 1280, 720), false, _scenery_tint())
	else:
		art.draw_rect(Rect2(0, 0, 1280, 720), Color("292936"))
	art.draw_rect(Rect2(0, 430, 1280, 290), Color(0.06, 0.045, 0.05, 0.14))
	var stage := _stage()
	match stage:
		"pilgrims", "return_city", "leave_city": _draw_walking_group(stage != "leave_city")
		"entry": _draw_entry()
		"bethany": _draw_walking_group(false)
		"temple_look": _draw_temple_look()
		"temple_clear": _draw_temple_clear()
		"leaders", "plot": _draw_plot()
		"judas": _draw_judas()
		"supper": _draw_supper()
		"prayer": _draw_prayer()
		"betrayal": _draw_betrayal()
		"arrest", "high_priest", "to_pilate", "mock", "procession": _draw_escort(stage)
		"denial": _draw_denial()
		"release": _draw_release()
		"simon": _draw_simon()
		"crosses", "darkness", "death", "witnesses": _draw_cross(stage)
		"joseph": _draw_joseph()
		"burial", "women_watch", "seal_tomb": _draw_burial(stage)
		"spices": _draw_women_walking()
		"message": _draw_tomb_message()
		"open_tomb": _draw_open_tomb()
		"mary_meets": _draw_mary_meets()
		"mary_reports": _draw_mary_reports()

func _scenery_tint() -> Color:
	if _stage() in ["bethany", "leave_city", "plot", "judas", "supper", "prayer", "betrayal", "arrest", "high_priest", "denial"]:
		return Color(0.38, 0.40, 0.56)
	if _stage() in ["darkness", "death", "witnesses", "burial", "seal_tomb"]:
		return Color(0.48, 0.45, 0.56)
	return Color(0.78, 0.75, 0.70)

func _draw_walking_group(toward_right: bool) -> void:
	var direction := 1.0 if toward_right else -1.0
	var drift := fmod(shot_elapsed * 42.0, 80.0) * direction
	for i in 6:
		var role := "male_pilgrim" if i % 3 == 0 else ("female_pilgrim" if i % 3 == 1 else "disciple")
		_cast_person(role, Vector2(360 + i * 92 + drift, 535 + (i % 2) * 12), 1.48)

func _draw_entry() -> void:
	for i in 5:
		_cast_person("female_pilgrim" if i % 2 else "male_pilgrim", Vector2(250 + i * 175, 545), 1.4)
		art.draw_colored_polygon(PackedVector2Array([Vector2(235 + i * 175, 565), Vector2(280 + i * 175, 550), Vector2(294 + i * 175, 567)]), Color("607945"))
	var x := 835.0 - minf(shot_elapsed * 48, 95)
	_cast_person("jesus_donkey", Vector2(x, 548), 0.95)

func _draw_temple_look() -> void:
	_cast_person("jesus", Vector2(640, 530), 1.72)
	for i in 5: _cast_person("disciple" if i % 2 else "male_pilgrim", Vector2(390 + i * 125, 548), 1.38)

func _draw_temple_clear() -> void:
	var tilt := minf(shot_elapsed * 0.7, 0.45)
	art.draw_set_transform(Vector2(610, 535), tilt)
	art.draw_rect(Rect2(-100, -18, 200, 28), Color("806044"))
	art.draw_set_transform(Vector2.ZERO, 0)
	for i in 9:
		art.draw_circle(Vector2(570 + i * 19 + sin(float(i)) * 18, 575 + (i % 3) * 10), 5, Color("d5ad55"))
	_cast_person("jesus", Vector2(430, 540), 1.72)
	for i in 3: _cast_person("merchant", Vector2(760 + i * 90 + minf(shot_elapsed * 55, 70), 548), 1.42)

func _draw_plot() -> void:
	for i in 4: _cast_person("priest", Vector2(465 + i * 108, 540), 1.48 if i else 1.66)
	for i in 3: art.draw_line(Vector2(500 + i * 90, 458), Vector2(550 + i * 70, 430), Color(0.78, 0.64, 0.42, 0.45), 2)

func _draw_judas() -> void:
	_cast_person("judas", Vector2(540, 540), 1.72)
	_cast_person("priest", Vector2(720, 540), 1.72)
	art.draw_circle(Vector2(625, 500), 8, Color("c6a357"))

func _draw_supper() -> void:
	art.draw_rect(Rect2(330, 520, 620, 35), Color("76553d"))
	for i in 9:
		var role := "jesus" if i == 4 else ("peter" if i == 2 else ("judas" if i == 7 else "disciple"))
		_cast_person(role, Vector2(370 + i * 68, 510 - (i % 2) * 12), 1.16)
	art.draw_circle(Vector2(600, 514), 10, Color("d9bc7b"))
	art.draw_rect(Rect2(720, 498, 12, 17), Color("b58a52"))

func _draw_prayer() -> void:
	_cast_person("jesus", Vector2(610, 545), 1.72)
	art.draw_line(Vector2(590, 504), Vector2(628, 504), Color("d9c39b"), 4)
	for i in 3: _cast_person("peter" if i == 0 else "disciple", Vector2(820 + i * 82, 545), 1.35)

func _draw_betrayal() -> void:
	_cast_person("jesus", Vector2(570, 545), 1.72)
	_cast_person("judas", Vector2(700, 545), 1.72)
	for i in 4:
		_cast_person("escort_soldier", Vector2(810 + i * 80, 545), 1.45)
		if i in [0, 3]:
			art.draw_line(Vector2(835 + i * 80, 500), Vector2(845 + i * 80, 430), Color("6f4a31"), 6)
			art.draw_circle(Vector2(845 + i * 80, 422), 10 + sin(shot_elapsed * 7) * 2, Color("f0a64d"))

func _draw_escort(stage: String) -> void:
	var drift := minf(shot_elapsed * 55, 105)
	for i in 5:
		_cast_person("jesus" if i == 2 else "escort_soldier", Vector2(405 + i * 105 + drift, 545 + (i % 2) * 6), 1.58)
		if i == 2: art.draw_line(Vector2(585 + drift, 500), Vector2(645 + drift, 500), Color("8c6947"), 5)
	if stage in ["mock", "procession"]:
		art.draw_line(Vector2(570 + drift, 480), Vector2(700 + drift, 420), Color("694b38"), 15)

func _draw_denial() -> void:
	for x in [580, 605, 630]: art.draw_circle(Vector2(x, 542), 10, Color("6f6257"))
	var flame := 8.0 + sin(shot_elapsed * 7.0) * 3.0
	art.draw_colored_polygon(PackedVector2Array([
		Vector2(605, 540), Vector2(587, 518), Vector2(604, 525 - flame),
		Vector2(614, 495 - flame), Vector2(625, 526), Vector2(620, 540)
	]), Color("df8238"))
	art.draw_colored_polygon(PackedVector2Array([Vector2(603, 538), Vector2(600, 521), Vector2(611, 509), Vector2(616, 538)]), Color("f4c45f"))
	_cast_person("peter", Vector2(475, 545), 1.7)
	_cast_person("servant", Vector2(750, 545), 1.7)
	art.draw_colored_polygon(PackedVector2Array([Vector2(830, 548), Vector2(848, 530), Vector2(863, 552)]), Color("7a4d37"))

func _draw_release() -> void:
	art.draw_rect(Rect2(250, 430, 150, 115), Color(0.10, 0.09, 0.12, 0.55))
	for x in [270, 305, 340, 375]: art.draw_line(Vector2(x, 430), Vector2(x, 545), Color("77624d"), 5)
	_cast_person("barabbas", Vector2(465 - minf(shot_elapsed * 45, 75), 545), 1.7)
	_cast_person("jesus", Vector2(780, 545), 1.7)
	art.draw_line(Vector2(750, 500), Vector2(810, 500), Color("8c6947"), 5)
	for i in 2: _cast_person("escort_soldier", Vector2(900 + i * 95, 545), 1.48)
	_cast_person("pilate", Vector2(300, 530), 1.48)

func _draw_simon() -> void:
	_cast_person("jesus", Vector2(545, 545), 1.65)
	_cast_person("simon", Vector2(700, 545), 1.72)
	art.draw_line(Vector2(485, 475), Vector2(760, 390), Color("694b38"), 17)
	for x in [395, 840]: _person(Vector2(x, 565), Color("202630"), "staff")

func _draw_cross(stage: String) -> void:
	if stage in ["darkness", "death", "witnesses"]:
		art.draw_rect(Rect2(0, 0, 1280, 720), Color(0.015, 0.02, 0.055, 0.48 + minf(0.22, shot_elapsed * 0.04)))
	for x in [420, 640, 860]:
		var height := 255.0 if x == 640 else 205.0
		art.draw_rect(Rect2(x - 8, 535 - height, 16, height), Color("3d2a24"))
		art.draw_rect(Rect2(x - 70, 355 if x == 640 else 395, 140, 14), Color("3d2a24"))
	if stage == "witnesses":
		_cast_person("escort_soldier", Vector2(300, 540), 1.42)
		_cast_person("mary", Vector2(390, 540), 1.55)
		_cast_person("salome", Vector2(470, 540), 1.55)
		_cast_person("female_pilgrim", Vector2(550, 540), 1.48)

func _draw_joseph() -> void:
	_cast_person("joseph", Vector2(520, 540), 1.72)
	art.draw_colored_polygon(PackedVector2Array([Vector2(610, 520), Vector2(760, 520), Vector2(790, 565), Vector2(580, 565)]), Color("c7b99c"))

func _draw_burial(stage: String) -> void:
	# The painted background already contains the rock-cut entrance and its round
	# stone. Keep that readable and animate the burial action in front of it.
	var carry := minf(shot_elapsed * 34.0, 54.0) if stage == "burial" else 54.0
	_cast_person("joseph", Vector2(655 + carry, 535), 1.66)
	art.draw_line(Vector2(720 + carry, 505), Vector2(900 + carry, 505), Color("594536"), 8)
	art.draw_colored_polygon(PackedVector2Array([
		Vector2(735 + carry, 477), Vector2(875 + carry, 477),
		Vector2(900 + carry, 505), Vector2(715 + carry, 505)
	]), Color("d6c8aa"))
	if stage == "seal_tomb":
		for i in 5:
			var dust := fmod(shot_elapsed * 24.0 + i * 19.0, 62.0)
			art.draw_circle(Vector2(1035 + i * 15, 394 - dust * 0.3), 4 + i % 2, Color(0.72, 0.60, 0.43, 0.28))
	if stage == "women_watch":
		_cast_person("mary", Vector2(470, 535), 1.66)
		_cast_person("salome", Vector2(550, 535), 1.66)

func _draw_women_walking() -> void:
	var drift := minf(shot_elapsed * 42, 75)
	_cast_person("mary", Vector2(330 + drift, 535), 1.66)
	_cast_person("salome", Vector2(430 + drift, 535), 1.66)
	art.draw_circle(Vector2(370 + drift, 555), 9, Color("c59b58"))

func _draw_tomb_message() -> void:
	_cast_person("mary", Vector2(560, 535), 1.66)
	_cast_person("salome", Vector2(650, 535), 1.66)
	_cast_person("tomb_messenger", Vector2(900, 515), 1.88)

func _draw_open_tomb() -> void:
	var glow := 0.12 + sin(shot_elapsed * 2.2) * 0.025
	art.draw_colored_polygon(PackedVector2Array([
		Vector2(980, 270), Vector2(510, 520), Vector2(760, 520)
	]), Color(0.98, 0.82, 0.50, glow))
	_cast_person("mary", Vector2(650, 535), 1.66)
	_cast_person("salome", Vector2(740, 535), 1.66)

func _draw_mary_meets() -> void:
	_cast_person("mary", Vector2(500, 535), 1.76)
	_cast_person("jesus", Vector2(740, 535), 1.76)
	art.draw_line(Vector2(535, 505), Vector2(705, 495), Color(0.91, 0.77, 0.51, 0.35), 3)

func _draw_mary_reports() -> void:
	var drift := minf(shot_elapsed * 55, 90)
	_cast_person("mary", Vector2(420 + drift, 535), 1.72)
	for i in 4: _cast_person("peter" if i == 0 else "disciple", Vector2(760 + i * 82, 540), 1.46)
