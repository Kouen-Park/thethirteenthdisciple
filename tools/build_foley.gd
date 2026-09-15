extends SceneTree

# Deterministic synthesized foley, no external recordings or runtime synthesis cost.
func _initialize() -> void:
	for kind in ["step", "palm", "cloth", "soil"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 731 + kind.hash()
		var duration := 0.22 if kind == "step" else 0.65
		var rate := 22050
		var count := int(duration * rate)
		var bytes := PackedByteArray()
		bytes.resize(count * 2)
		var low := 0.0
		var previous := 0.0
		for i in count:
			var t := float(i) / rate
			var noise := rng.randf_range(-1.0, 1.0)
			low = lerpf(low, noise, 0.07 if kind == "cloth" else 0.25)
			var envelope := sin(PI * float(i) / count)
			var sample := 0.0
			match kind:
				"step":
					sample = (low * 0.7 + sin(TAU * 95.0 * t) * 0.25) * exp(-t * 24.0) * minf(t * 500.0, 1.0)
				"palm":
					sample = (noise - previous) * envelope * (0.06 + 0.15 * pow(absf(sin(t * 38.0)), 6.0))
				"cloth":
					sample = low * envelope * (0.55 + 0.3 * sin(t * 13.0))
				"soil":
					sample = (low * 0.65 + noise * 0.16) * envelope * (0.3 + 0.5 * absf(sin(t * 29.0)))
			previous = noise
			bytes.encode_s16(i * 2, int(clampf(sample, -0.9, 0.9) * 32767.0))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.data = bytes
		var error := stream.save_to_wav("res://assets/audio/chapter01/foley_%s.wav" % kind)
		if error != OK:
			quit(1)
			return
	print("Four foley samples generated")
	quit()
