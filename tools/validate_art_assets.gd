extends SceneTree

const BACKGROUNDS := [
	"res://assets/art/pixel/chapter01_jerusalem_gate_world_2048.png",
	"res://assets/art/chapter02/temple_market.png",
	"res://assets/art/chapter03/courtyard.png",
	"res://assets/art/late_chapters/trial.png",
	"res://assets/art/late_chapters/golgotha.png",
	"res://assets/art/late_chapters/tomb.png",
	"res://assets/art/late_chapters/dawn.png",
]
const REQUIRED_SIZE := Vector2i(2048, 720)
const MAX_COLORS := 64

const ALPHA_AUDIT := [
	"res://assets/art/player_walk/down.png",
	"res://assets/art/player_walk/down_left.png",
	"res://assets/art/player_walk/down_right.png",
	"res://assets/art/player_walk/left.png",
	"res://assets/art/player_walk/right.png",
	"res://assets/art/player_walk/up.png",
	"res://assets/art/player_walk/up_left.png",
	"res://assets/art/player_walk/up_right.png",
	"res://assets/art/pixel/npcs/merchant_jonah.png",
	"res://assets/art/pixel/npcs/miriam.png",
	"res://assets/art/biblical_cast/mary.png",
	"res://assets/art/pixel/npcs/frightened_runner.png",
	"res://assets/art/chapter03/closed_door.png",
]

func _initialize() -> void:
	var failed := false
	for path: String in BACKGROUNDS:
		failed = not _validate_background(path) or failed
	for path: String in ALPHA_AUDIT:
		failed = not _audit_sprite_alpha(path) or failed
	if failed:
		push_error("Art asset validation failed.")
		quit(1)
		return
	print("Art asset validation: PASS")
	quit(0)

func _load_image(path: String) -> Image:
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		push_error("Missing art asset: %s" % path)
		return null
	var image := Image.load_from_file(absolute)
	if image == null or image.is_empty():
		push_error("Unreadable art asset: %s" % path)
		return null
	return image

func _validate_background(path: String) -> bool:
	var image := _load_image(path)
	if image == null:
		return false
	var valid := true
	if image.get_size() != REQUIRED_SIZE:
		push_error("Background must be 2048x720: %s is %s" % [path, image.get_size()])
		valid = false
	if image.get_format() != Image.FORMAT_RGB8:
		push_error("Background must be solid RGB8: %s uses format %s" % [path, image.get_format()])
		valid = false
	var colors: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			colors[image.get_pixel(x, y).to_rgba32()] = true
			if colors.size() > MAX_COLORS:
				push_error("Background exceeds %d colors: %s" % [MAX_COLORS, path])
				return false
	print("Background OK: %s (%d colors)" % [path, colors.size()])
	return valid

func _audit_sprite_alpha(path: String) -> bool:
	var image := _load_image(path)
	if image == null:
		return false
	var partial_alpha := 0
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				partial_alpha += 1
	print("Alpha audit: %s (%d partial-alpha pixels)" % [path, partial_alpha])
	return true
