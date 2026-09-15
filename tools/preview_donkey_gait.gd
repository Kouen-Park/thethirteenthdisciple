extends SceneTree

func _initialize() -> void:
	call_deferred("_preview")

func _preview() -> void:
	root.size = Vector2i(960, 320)
	for i in 3:
		var sprite := TextureRect.new()
		sprite.texture = load("res://assets/art/pixel/jesus_donkey_chibi.png")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(i * 320, 10)
		sprite.scale = Vector2(2, 2)
		var material := ShaderMaterial.new()
		material.shader = load("res://assets/art/pixel/donkey_walk.gdshader")
		material.set_shader_parameter("gait_texture", sprite.texture)
		material.set_shader_parameter("walking", 0.0 if i == 0 else 1.0)
		material.set_shader_parameter("gait_phase", PI * (0.5 if i == 1 else 1.5))
		sprite.material = material
		root.add_child(sprite)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/disciple-donkey-poses.png")
	quit()
