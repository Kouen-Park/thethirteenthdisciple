class_name SceneArt
extends Control

var sky_color := Color("#e8bd67")
var ground_color := Color("#b87947")
var accent_color := Color("#fff1b8")
var chapter_index := 0
var elapsed := 0.0

func set_palette(palette: Dictionary) -> void:
	sky_color = palette.sky
	ground_color = palette.ground
	accent_color = palette.accent
	queue_redraw()

func set_chapter(index: int) -> void:
	chapter_index = index
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), sky_color)
	match chapter_index:
		0: _draw_entry()
		1: _draw_temple_aftermath()
		2: _draw_garden()
		3: _draw_trial()
		4: _draw_golgotha()
		_: _draw_tomb()

func _draw_entry() -> void:
	var horizon := size.y * 0.58
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), ground_color)
	var sway := sin(elapsed * 1.4) * 4.0
	_draw_palm(Vector2(size.x * 0.12, horizon + 22), 1.0, sway)
	_draw_palm(Vector2(size.x * 0.92, horizon + 6), 0.78, -sway)
	var wall := Color("#9a6746").lerp(sky_color, 0.25)
	draw_rect(Rect2(size.x * 0.58, horizon - 58, size.x * 0.38, 58), wall)
	for x in range(int(size.x * 0.6), int(size.x * 0.95), 22): draw_rect(Rect2(x, horizon - 66, 11, 10), wall)
	for index in 9:
		var x := size.x * (0.48 + float(index) * 0.042)
		var bob := sin(elapsed * 2.0 + index) * 2.0
		draw_circle(Vector2(x, horizon + 8 + bob), 5, Color("#4a3541"))
		draw_rect(Rect2(x - 5, horizon + 13 + bob, 10, 15), Color("#594050"))
	draw_circle(Vector2(size.x * 0.79, horizon + 50), 27 + sin(elapsed * 2.0) * 2, Color(accent_color, 0.33))
	draw_circle(Vector2(size.x * 0.79, horizon + 39), 6, Color("#49373e"))
	draw_rect(Rect2(size.x * 0.79 - 7, horizon + 45, 14, 25), Color("#efe4cf"))

func _draw_temple_aftermath() -> void:
	draw_rect(Rect2(18, 160, size.x - 36, 340), Color("#201c28"))
	for x in [65.0, size.x - 65.0]:
		var flame := sin(elapsed * 5.0 + x) * 3.0
		draw_rect(Rect2(x - 3, 230, 6, 90), Color("#7d5e42"))
		draw_circle(Vector2(x, 222 + flame), 10, Color("#ffd676"))
	draw_rect(Rect2(55, 365, size.x - 110, 48), Color("#7c513d"))
	for index in 6:
		var x := 82 + index * 47
		var bob := sin(elapsed * 1.5 + index) * 1.5
		draw_circle(Vector2(x, 337 + bob), 7, Color("#4d3740"))
		draw_rect(Rect2(x - 7, 344 + bob, 14, 22), Color("#6c5061"))

func _draw_garden() -> void:
	draw_rect(Rect2(0, size.y * 0.6, size.x, size.y * 0.4), ground_color)
	draw_circle(Vector2(size.x * 0.78, 145), 34, Color("#d9e4eb"))
	for x in [65.0, 155.0, 285.0, 350.0]: _draw_palm(Vector2(x, 530), 0.8, sin(elapsed + x) * 3)
	for index in 13:
		var star := Vector2(20 + (index * 43) % int(size.x - 30), 130 + (index * 61) % 180)
		draw_circle(star, 1 + sin(elapsed * 2 + index) * 0.4, Color("#c6d8e8"))

func _draw_trial() -> void:
	draw_rect(Rect2(0, size.y * 0.55, size.x, size.y * 0.45), ground_color)
	for x in [50.0, size.x - 50.0]:
		draw_rect(Rect2(x - 4, 245, 8, 110), Color("#473a38"))
		draw_circle(Vector2(x, 235 + sin(elapsed * 5 + x) * 3), 14, Color("#ffb354"))
	for index in 11:
		var x := 28 + index * 34
		var bob := sin(elapsed * 2.7 + index) * 2
		draw_circle(Vector2(x, 410 + bob), 6, Color("#44434b"))
		draw_rect(Rect2(x - 6, 416 + bob, 12, 32), Color("#55545b"))

func _draw_golgotha() -> void:
	draw_rect(Rect2(0, size.y * 0.62, size.x, size.y * 0.38), ground_color)
	var wind := sin(elapsed * 0.8) * 4
	for x in [size.x * 0.36, size.x * 0.5, size.x * 0.64]:
		draw_rect(Rect2(x - 3, 235 + wind, 6, 150), Color("#251e25"))
		draw_rect(Rect2(x - 28, 270 + wind, 56, 7), Color("#251e25"))

func _draw_tomb() -> void:
	draw_rect(Rect2(0, size.y * 0.62, size.x, size.y * 0.38), ground_color)
	var glow := 0.15 + (sin(elapsed * 2.0) + 1.0) * 0.05
	draw_circle(Vector2(size.x * 0.5, 350), 92, Color(accent_color, glow))
	draw_circle(Vector2(size.x * 0.5, 360), 62, Color("#4d5863"))
	draw_circle(Vector2(size.x * 0.5, 360), 42, Color("#eff2df"))
	for index in 4:
		var x := 50 + index * 95
		draw_line(Vector2(x, 170 + sin(elapsed + index) * 5), Vector2(x + 24, 157 + sin(elapsed + index) * 5), Color("#f7f3d5"), 2)

func _draw_palm(origin: Vector2, scale_factor: float, sway: float) -> void:
	draw_rect(Rect2(origin.x - 4 * scale_factor, origin.y - 75 * scale_factor, 8 * scale_factor, 76 * scale_factor), Color("#694834"))
	for direction in [-1.0, 1.0]:
		for height in [58.0, 71.0, 82.0]:
			draw_line(Vector2(origin.x, origin.y - height * scale_factor), Vector2(origin.x + direction * 35 * scale_factor + sway, origin.y - (height + 12) * scale_factor), Color("#3c6148"), 7 * scale_factor)
