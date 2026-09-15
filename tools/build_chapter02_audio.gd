extends SceneTree

const OUTPUT_ROOT := "res://assets/audio/chapter02/"
const RATE := 22050

func _initialize() -> void:
	var results := [
		_save_one_shot("coins_clatter", 0.72, &"coins"),
		_save_one_shot("table_wood", 0.78, &"wood"),
		_save_one_shot("prayer_cloth", 0.82, &"cloth"),
		_save_ambience("market_aftermath", 8.0, &"market"),
		_save_ambience("prayer_court", 8.0, &"prayer")
	]
	for result in results:
		if result != OK:
			quit(1)
			return
	print("Chapter 2 audio generated")
	quit()

func _save_one_shot(file_name: String, duration: float, kind: StringName) -> Error:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260906 + kind.hash()
	var count := int(duration * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var smooth_noise := 0.0
	var click_times := [0.0, 0.075, 0.16, 0.29, 0.44]
	for i in count:
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		smooth_noise = lerpf(smooth_noise, noise, 0.06 if kind == &"cloth" else 0.22)
		var sample := 0.0
		match kind:
			&"coins":
				for c in click_times.size():
					var local_t: float = t - float(click_times[c])
					if local_t >= 0.0:
						var decay := exp(-local_t * (16.0 + c * 1.7))
						sample += sin(TAU * (1040.0 + c * 185.0) * local_t) * decay * (0.22 - c * 0.018)
			&"wood":
				var attack := minf(t * 700.0, 1.0)
				sample = (sin(TAU * 92.0 * t) * 0.56 + sin(TAU * 173.0 * t) * 0.22 + smooth_noise * 0.2) * exp(-t * 9.0) * attack
				var second_t := t - 0.115
				if second_t >= 0.0:
					sample += sin(TAU * 118.0 * second_t) * exp(-second_t * 14.0) * 0.24
			&"cloth":
				var envelope := pow(sin(PI * t / duration), 1.45)
				sample = (smooth_noise * 0.62 + noise * 0.07) * envelope * (0.7 + 0.3 * sin(TAU * 2.2 * t))
		bytes.encode_s16(i * 2, int(clampf(sample, -0.88, 0.88) * 32767.0))
	return _save_stream(file_name, bytes, false)

func _save_ambience(file_name: String, duration: float, kind: StringName) -> Error:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9042026 + kind.hash()
	var partials: Array[Dictionary] = []
	var partial_count := 24 if kind == &"market" else 16
	for p in partial_count:
		var cycles := rng.randi_range(7, 155 if kind == &"market" else 96)
		partials.append({
			"frequency": float(cycles) / duration,
			"phase": rng.randf_range(0.0, TAU),
			"amplitude": rng.randf_range(0.008, 0.028 if kind == &"market" else 0.018)
		})
	var count := int(duration * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var sample := 0.0
		for partial in partials:
			sample += sin(TAU * partial.frequency * t + partial.phase) * partial.amplitude
		if kind == &"market":
			sample += sin(TAU * 0.375 * t) * sin(TAU * 147.0 * t) * 0.025
		else:
			sample += sin(TAU * 55.0 * t) * 0.022 + sin(TAU * 110.0 * t) * 0.012
		bytes.encode_s16(i * 2, int(clampf(sample, -0.6, 0.6) * 32767.0))
	return _save_stream(file_name, bytes, true)

func _save_stream(file_name: String, bytes: PackedByteArray, looping: bool) -> Error:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = bytes.size() / 2
	return stream.save_to_wav(OUTPUT_ROOT + file_name + ".wav")
