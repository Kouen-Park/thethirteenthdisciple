extends SceneTree

# Deterministic fallback for the image-generation usage limit. This is a pixel
# cleanup pass, not a resize: silhouettes and the gameplay-sized canvases remain
# unchanged while the objects adopt the Chapter 2 palette and hard alpha edges.
const PALETTE := [
	Color("211c28"), Color("302943"), Color("4a4058"), Color("5c3828"),
	Color("8c5732"), Color("8e6c4c"), Color("be915b"), Color("e7bd72"),
	Color("ffd987"), Color("4b4b2d"), Color("687047"), Color("493b65"),
	Color("7a4c35"), Color("b26e3c"), Color("d39759"), Color("f0c57d"),
	Color("6c5c52"), Color("a58a68"), Color("c6a77d"), Color("e2c59b")
]
const LEAF_PALETTE := [
	Color("211c28"), Color("302943"), Color("4b4b2d"), Color("5a6638"),
	Color("687047"), Color("879052"), Color("a6a55a"), Color("c4b86e"),
	Color("e7bd72"), Color("ffd987")
]
const CLOTH_PALETTE := [
	Color("211c28"), Color("302943"), Color("493b65"), Color("5c3828"),
	Color("7a4c35"), Color("8c5732"), Color("b26e3c"), Color("d39759"),
	Color("e7bd72"), Color("f0c57d")
]
const SOIL_PALETTE := [
	Color("211c28"), Color("302943"), Color("4a4058"), Color("5c3828"),
	Color("6c5c52"), Color("8e6c4c"), Color("a58a68"), Color("be915b"),
	Color("e2c59b"), Color("ffd987")
]

const ASSETS := [
	["res://assets/art/pixel/interactables/palm_leaf.png", "res://assets/art/pixel/interactables/palm_leaf_ch02_style.png", LEAF_PALETTE],
	["res://assets/art/pixel/interactables/discarded_cloak.png", "res://assets/art/pixel/interactables/discarded_cloak_ch02_style.png", CLOTH_PALETTE],
	["res://assets/art/pixel/interactables/footprints.png", "res://assets/art/pixel/interactables/footprints_ch02_style.png", SOIL_PALETTE]
]

func _initialize() -> void:
	for spec in ASSETS:
		_restyle(spec[0], spec[1], spec[2])
	quit(0)

func _restyle(source_path: String, output_path: String, palette: Array) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if image == null or image.is_empty():
		push_error("Unable to load %s" % source_path)
		return
	image.convert(Image.FORMAT_RGBA8)
	var source := image.duplicate()
	# Remove translucent colored fringes first, then quantize opaque pixels to the
	# shared sandstone/indigo palette. This keeps transparent edges truly clean.
	for y in image.get_height():
		for x in image.get_width():
			var color: Color = source.get_pixel(x, y)
			if color.a < 0.72:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				image.set_pixel(x, y, Color(_nearest_palette(color, palette), 1.0))
	# Add a single near-black-violet contour only on transparent neighbors. The
	# contour is deliberately one native pixel, matching the art bible.
	var outlined := image.duplicate()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				continue
			var adjacent := false
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var sample: Vector2i = Vector2i(x, y) + offset
				if sample.x >= 0 and sample.x < image.get_width() and sample.y >= 0 and sample.y < image.get_height() and image.get_pixel(sample.x, sample.y).a > 0.0:
					adjacent = true
			if adjacent:
				outlined.set_pixel(x, y, Color(PALETTE[0], 1.0))
	if outlined.save_png(ProjectSettings.globalize_path(output_path)) != OK:
		push_error("Unable to save %s" % output_path)
	else:
		print("Restyled %s" % output_path)

func _nearest_palette(color: Color, palette: Array) -> Color:
	var best: Color = palette[0]
	var distance := INF
	for candidate in palette:
		var current := pow(color.r - candidate.r, 2.0) + pow(color.g - candidate.g, 2.0) + pow(color.b - candidate.b, 2.0)
		if current < distance:
			distance = current
			best = candidate
	return best
