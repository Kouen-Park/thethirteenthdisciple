extends SceneTree

const TARGET_SIZE := Vector2i(2048, 720)
const PALETTE_SIZE := 64
const TARGETS := [
	{"source": "res://assets/art/pixel/source/chapter01_jerusalem_gate_world_2048.png", "output": "res://assets/art/pixel/chapter01_jerusalem_gate_world_2048.png"},
	{"source": "res://assets/art/chapter02/source/temple_market.png", "output": "res://assets/art/chapter02/temple_market.png"},
	{"source": "res://assets/art/chapter03/source/courtyard.png", "output": "res://assets/art/chapter03/courtyard.png"},
	{"source": "res://assets/art/late_chapters/source/trial.png", "output": "res://assets/art/late_chapters/trial.png"},
	{"source": "res://assets/art/late_chapters/source/golgotha.png", "output": "res://assets/art/late_chapters/golgotha.png"},
	{"source": "res://assets/art/late_chapters/source/tomb.png", "output": "res://assets/art/late_chapters/tomb.png"},
	{"source": "res://assets/art/late_chapters/source/dawn.png", "output": "res://assets/art/late_chapters/dawn.png"},
]

func _initialize() -> void:
	for target: Dictionary in TARGETS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(target.source))
		if image == null or image.is_empty():
			push_error("Cannot load generated background: %s" % target.source)
			quit(1)
			return
		image.resize(TARGET_SIZE.x, TARGET_SIZE.y, Image.INTERPOLATE_NEAREST)
		image.convert(Image.FORMAT_RGB8)
		_quantize(image, PALETTE_SIZE)
		if image.save_png(ProjectSettings.globalize_path(target.output)) != OK:
			push_error("Cannot save processed background: %s" % target.output)
			quit(1)
			return
		print("Processed %s -> %s" % [target.source, target.output])
	quit(0)

func _quantize(image: Image, palette_size: int) -> void:
	var histogram: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var key := _color_key(color)
			histogram[key] = int(histogram.get(key, 0)) + 1
	var buckets: Array = [histogram.keys()]
	while buckets.size() < palette_size:
		var split_at := _largest_bucket_index(buckets, histogram)
		if split_at < 0:
			break
		var parts := _split_bucket(buckets[split_at], histogram)
		buckets.remove_at(split_at)
		buckets.append(parts[0])
		buckets.append(parts[1])
	var palette: Array[Color] = []
	for bucket: Array in buckets:
		palette.append(_average_color(bucket, histogram))
	var lookup: Dictionary = {}
	for key: int in histogram:
		lookup[key] = _nearest_palette_color(_key_color(key), palette)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, lookup[_color_key(image.get_pixel(x, y))])

func _color_key(color: Color) -> int:
	return (int(color.r * 255.0) >> 3) | ((int(color.g * 255.0) >> 3) << 5) | ((int(color.b * 255.0) >> 3) << 10)

func _component(key: int, channel: int) -> int:
	return (key >> (channel * 5)) & 31

func _key_color(key: int) -> Color:
	return Color(float(_component(key, 0)) / 31.0, float(_component(key, 1)) / 31.0, float(_component(key, 2)) / 31.0)

func _bucket_stats(bucket: Array, histogram: Dictionary) -> Dictionary:
	var minimum := [31, 31, 31]
	var maximum := [0, 0, 0]
	var total := 0
	for key: int in bucket:
		total += int(histogram[key])
		for channel in 3:
			var value := _component(key, channel)
			minimum[channel] = mini(minimum[channel], value)
			maximum[channel] = maxi(maximum[channel], value)
	var ranges := [maximum[0] - minimum[0], maximum[1] - minimum[1], maximum[2] - minimum[2]]
	var channel := 0
	if ranges[1] > ranges[channel]: channel = 1
	if ranges[2] > ranges[channel]: channel = 2
	return {"channel": channel, "range": ranges[channel], "total": total}

func _largest_bucket_index(buckets: Array, histogram: Dictionary) -> int:
	var best := -1
	var best_score := -1
	for index in buckets.size():
		var bucket: Array = buckets[index]
		if bucket.size() < 2:
			continue
		var stats := _bucket_stats(bucket, histogram)
		var score: int = int(stats.range) * int(stats.total)
		if score > best_score:
			best_score = score
			best = index
	return best

func _split_bucket(bucket: Array, histogram: Dictionary) -> Array:
	var stats := _bucket_stats(bucket, histogram)
	var channel: int = stats.channel
	var sorted := bucket.duplicate()
	sorted.sort_custom(func(a: int, b: int) -> bool: return _component(a, channel) < _component(b, channel))
	var halfway: int = int(stats.total) / 2
	var accumulated := 0
	var split_index := 1
	for index in sorted.size() - 1:
		accumulated += int(histogram[sorted[index]])
		if accumulated >= halfway:
			split_index = index + 1
			break
	return [sorted.slice(0, split_index), sorted.slice(split_index)]

func _average_color(bucket: Array, histogram: Dictionary) -> Color:
	var sum := Vector3.ZERO
	var total := 0
	for key: int in bucket:
		var count: int = histogram[key]
		var color := _key_color(key)
		sum += Vector3(color.r, color.g, color.b) * count
		total += count
	return Color(sum.x / total, sum.y / total, sum.z / total)

func _nearest_palette_color(color: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate: Color in palette:
		var delta := Vector3(color.r - candidate.r, color.g - candidate.g, color.b - candidate.b)
		var distance: float = delta.length_squared()
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best
