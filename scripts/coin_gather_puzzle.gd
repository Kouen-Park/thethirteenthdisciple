class_name CoinGatherPuzzle
extends Control

const PuzzleTheme = preload("res://scripts/ui_theme.gd")

signal progress_changed(current: int, total: int)
signal completed(result: Dictionary)

const COIN_COUNT := 6

var active := false
var _collected := 0
var _coins: Array[Button] = []
var _status: Label
var _cloth: PanelContainer

func _ready() -> void:
	_build_interface()
	hide()

func start() -> void:
	active = true
	_collected = 0
	for coin in _coins:
		coin.show()
		coin.disabled = false
		coin.modulate = Color.WHITE
		coin.position = coin.get_meta("rest_position")
	_status.text = "흩어진 동전을 눌러 천 위에 모으세요. · 0/%d" % COIN_COUNT
	show()
	PuzzleTheme.trap_button_focus(_coins)
	_coins[0].grab_focus()
	progress_changed.emit(0, COIN_COUNT)

func collect_coin(index: int) -> bool:
	if not active or index < 0 or index >= _coins.size() or _coins[index].disabled:
		return false
	var coin := _coins[index]
	coin.disabled = true
	PuzzleTheme.trap_button_focus(_coins)
	for next in _coins:
		if not next.disabled:
			next.grab_focus()
			break
	_collected += 1
	var target := _cloth.global_position + _cloth.size * 0.5 - coin.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(coin, "global_position", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(coin, "modulate:a", 0.0, 0.22)
	_status.text = "동전을 상 위로 되돌리지 않고 한곳에 모읍니다. · %d/%d" % [_collected, COIN_COUNT]
	progress_changed.emit(_collected, COIN_COUNT)
	if _collected >= COIN_COUNT:
		active = false
		await tween.finished
		hide()
		completed.emit({"action": &"gathered_coins_aside", "count": _collected, "completed": true})
	return true

func collect_all() -> void:
	for index in _coins.size():
		if active:
			collect_coin(index)

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-430, -300)
	panel.size = Vector2(860, 260)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "흩어진 동전"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var explanation := Label.new()
	explanation.text = "거래를 다시 시작시키지 않고, 사람들이 밟지 않도록 옆의 천에 모읍니다."
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(explanation)
	var ground := Control.new()
	ground.custom_minimum_size = Vector2(0, 118)
	box.add_child(ground)
	_cloth = PanelContainer.new()
	_cloth.position = Vector2(655, 26)
	_cloth.size = Vector2(145, 72)
	var cloth_style := StyleBoxFlat.new()
	cloth_style.bg_color = Color(0.38, 0.24, 0.13, 0.9)
	cloth_style.border_color = Color(0.76, 0.58, 0.32, 1.0)
	cloth_style.set_border_width_all(2)
	cloth_style.set_corner_radius_all(10)
	_cloth.add_theme_stylebox_override("panel", cloth_style)
	ground.add_child(_cloth)
	var cloth_label := Label.new()
	cloth_label.text = "천 위에 모으기"
	cloth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cloth_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cloth.add_child(cloth_label)
	var positions := [Vector2(60, 22), Vector2(176, 70), Vector2(284, 30), Vector2(382, 78), Vector2(490, 24), Vector2(572, 74)]
	for index in COIN_COUNT:
		var coin := Button.new()
		coin.position = positions[index]
		coin.size = Vector2(46, 46)
		coin.text = "●"
		coin.tooltip_text = "흙먼지에 반쯤 묻힌 동전"
		coin.add_theme_color_override("font_color", Color("e4b84d"))
		coin.add_theme_font_size_override("font_size", 25)
		coin.pressed.connect(collect_coin.bind(index))
		ground.add_child(coin)
		coin.set_meta("rest_position", coin.position)
		_coins.append(coin)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color("e7c47b"))
	box.add_child(_status)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.065, 0.04, 0.96)
	style.border_color = Color(0.78, 0.57, 0.28, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	return style
