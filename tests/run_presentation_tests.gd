extends SceneTree
const Support = preload("res://tests/polish_support.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func _run() -> void:
	var camera = load("res://scripts/pixel_follow_camera.gd").new()
	check(camera.bounded_center(Vector2.ZERO, Vector2(1280, 720)) == Vector2(640, 360), "One-screen camera must remain within artwork")
	camera.world_rect = Rect2(0, 0, 2048, 1024)
	check(camera.bounded_center(Vector2(2048, 1024), Vector2(1280, 720)) == Vector2(1408, 664), "Expanded-world camera must clamp at edges")
	camera.free()
	var chapter = load("res://scenes/chapters/chapter_01_entry.tscn").instantiate()
	chapter.persistence_enabled = false
	root.add_child(chapter)
	await frames(90)
	var world_camera = chapter.get_node("WorldCamera")
	check(world_camera.world_rect == Rect2(0, 0, 2048, 720), "Chapter 1 must use the same wide camera world as Chapter 2")
	check(world_camera.global_position == Vector2(640, 360), "Wide-world camera must begin at the player's left-side starting view")
	check(await Support.reach_exploration(chapter, chapter.get_node("CrowdPlayer")), "Opening context and dialogue finish")
	var player = chapter.get_node("CrowdPlayer")
	var audio = chapter.get_node("ChapterAudio")
	audio.rng.seed = 20260903
	check(audio.step_streams.size() == 5, "Walking must have five material takes")
	for stream in audio.step_streams + audio.streams.values():
		check(stream is AudioStreamOggVorbis, "Material effects must load the licensed Ogg assets")
		check(stream.get_length() > 0.02 and stream.get_length() < 3.0, "Foley must be a short nonempty one-shot")
		check(not stream.loop, "Material effects must never loop")
	var previous_step: AudioStream
	for i in 20:
		var voice = audio.footsteps[audio.slot % audio.footsteps.size()]
		audio.play_step()
		check(voice.stream != previous_step, "Footstep samples must not repeat consecutively")
		check(voice.pitch_scale >= 0.97 and voice.pitch_scale <= 1.03, "Footstep pitch variation must stay subtle")
		previous_step = voice.stream
	audio.stop_steps()
	audio.slot = 0
	check(player.input_enabled, "Opening must unlock movement")
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(audio.slot > 0, "Movement animation must emit footsteps")
	player.set_input_enabled(false)
	var stopped_count: int = audio.slot
	await frames(30)
	check(audio.slot == stopped_count, "Locked movement must stop footsteps")
	for voice in audio.footsteps:
		check(not voice.playing, "Footstep tails must stop when movement locks")
	player.global_position = Vector2(650, 470)
	player.set_input_enabled(true)
	Input.action_press("move_up")
	await frames(60)
	stopped_count = audio.slot
	await frames(30)
	check(audio.slot == stopped_count, "Pushing against the wall must not emit footsteps")
	Input.action_release("move_up")
	player.set_input_enabled(false)
	check(audio.crowd is AudioStreamPlayer2D and audio.crowd.max_distance > 0, "Crowd must use positional attenuation")
	var previous: AudioStream
	for id in [&"palm_leaf", &"discarded_cloak", &"footprints"]:
		audio.investigate(id)
		check(audio.investigation.stream != previous, "Each clue must use distinct foley")
		previous = audio.investigation.stream
	# Trigger presentation only: no observation/completion writes to the user's save.
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/disciple-crowd-before.png")
	var director = chapter.get_node("ChapterDirector")
	director.current_beat = &"encounter"
	director.beat_changed.emit(&"encounter")
	await frames(2)
	var field: Node = chapter.field_investigation
	check(field != null and field.active, "Welcome path is prepared inside the world")
	check(await Support.finish_field(field, player), "World palms are carried and laid before the encounter")
	await frames(240)
	var jesus = chapter.get_node("CharacterLayer/JesusDonkey")
	check(jesus.position.x > 1600.0, "Jesus must enter from the far-right lane of the expanded world")
	check(jesus.has_walked, "Donkey gait must run while entering")
	check(world_camera.is_focusing(jesus), "Camera must lock onto Jesus during his entrance")
	check(world_camera.global_position.x > 1200.0, "Jesus entrance shot must pan away from the player toward the right road")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/disciple-right-lane.png")
	await frames(720)
	check(jesus.position.is_equal_approx(Vector2(1070, 455)), "Jesus must reach the central main road")
	check(player.position.is_equal_approx(Vector2(1010, 575)), "Player must approach Jesus before dialogue")
	check(player.collision_mask == 1, "Conversation approach must keep physical world collision enabled")
	check(player.get_facing_direction().x > 0.0, "Player must face Jesus during dialogue")
	check(not jesus.is_walking, "Donkey must stand still during dialogue")
	check(not world_camera.is_focusing(), "Camera must return to player follow before the conversation")
	var residents = chapter.get_node("AmbientCrowd").get_children()
	check(residents.size() == 8, "Crowd must contain eight independent residents")
	var textures: Array[String] = []
	for resident in residents:
		check(resident is StaticBody2D and resident.has_node("CollisionShape2D"), "Every resident needs an individual collision body")
		check(resident.position.is_equal_approx(resident.get_meta("parted_position")), "Each resident must finish their own parting route")
		check(resident.position.x < 940.0 or resident.position.x > 1120.0, "Residents must leave the expanded world's central main road open")
		var visual = resident.get_node("Visual")
		check(not visual.region_enabled, "Never cut a group image into halves")
		var path: String = visual.texture.atlas.resource_path
		check(not path in textures, "Every resident needs a unique source image")
		textures.append(path)
		var talk_shape := resident.get_node("Conversation/CollisionShape2D").shape as CircleShape2D
		check(is_equal_approx(talk_shape.radius, 32.0), "Optional witnesses need a forgiving but non-overlapping talk radius")
	var props := [
		chapter.get_node("PalmLeafInteractable"),
		chapter.get_node("DiscardedCloakInteractable"),
		chapter.get_node("FootprintsInteractable")
	]
	var people: Array = [chapter.get_node("MerchantJonah"), chapter.get_node("Miriam")]
	people.append_array(residents)
	for prop in props:
		for person in people:
			check(prop.global_position.distance_to(person.global_position) >= 140.0, "%s must keep visual breathing room from %s" % [prop.name, person.name])
	var route: PackedVector2Array = chapter.get_node("ChapterOneEncounter").get_entrance_foot_route()
	check(route.size() == 7, "Jesus must follow the painted road curve with enough authored waypoints")
	check(route[0].y <= 350.0 and route[1].y <= 355.0 and route[2].y <= 390.0, "The right-road entry must stay above the lower stone wall")
	for person in people:
		for route_index in route.size() - 1:
			check(_distance_to_segment(person.global_position, route[route_index], route[route_index + 1]) >= 96.0, "Jesus entrance route must stay clear of %s" % person.name)
	for npc_path in ["MerchantJonah", "Miriam"]:
		var npc = chapter.get_node(npc_path)
		check(npc.get_interaction_anchor() == npc.get_node("CollisionShape2D").global_position, "%s targeting must use the raised conversation area" % npc_path)
	check(audio.crowd.volume_db <= -35.0, "Crowd must hush during entrance")
	check(not player.input_enabled, "Encounter must keep movement locked")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/disciple-entrance.png")
	# Complete the three encounter lines without writing any user progress.
	for i in 3:
		chapter.get_node("SpeechBubbleController").close_bubble()
		await frames(2)
		if i == 0:
			var bubble_controller = chapter.get_node("SpeechBubbleController")
			var player_bubble := bubble_controller.get_child(0) as SpeechBubble
			var expected_head: Vector2 = player.get_global_transform_with_canvas().origin + player.get_meta("head_offset", Vector2(0, -92))
			check((player_bubble.position + player_bubble.tail_anchor).distance_to(expected_head) < 2.0, "Reflection bubble follows the player's head without inventing Jesus dialogue")
	check(not player.input_enabled, "Player must wait for Jesus to enter first")
	await frames(150)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/disciple-jesus-gate.png")
	await frames(60)
	check(not jesus.visible, "Jesus must leave through the gate after dialogue")
	check(director.current_beat == &"aftermath" and player.input_enabled, "Finishing Jesus dialogue must resume exploration, not change scenes")
	check(chapter.get_node("TempleEntrance").can_interact(), "Exit must unlock after encounter without optional conversations")
	# Suppress persistence and actual scene replacement in this test only.
	director.interaction_recorded.disconnect(chapter._on_interaction_recorded)
	director.chapter_completed.disconnect(chapter._on_director_chapter_completed)
	var optional = residents[0].get_node("Conversation")
	check(optional.can_interact(), "Optional resident must unlock after encounter")
	optional.interact()
	for i in 2:
		await frames(2)
		if i == 1 and "--capture" in OS.get_cmdline_user_args():
			var advance := InputEventKey.new()
			advance.physical_keycode = KEY_SPACE
			advance.pressed = true
			root.push_input(advance)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/disciple-optional-opinion.png")
		chapter.get_node("SpeechBubbleController").close_bubble()
	await frames(2)
	check(director.has_observed(optional.interaction_id) and director.current_beat == &"aftermath", "Optional opinion must record without completing chapter")
	check(optional.can_interact() and player.input_enabled, "Opinion can be heard again and must return movement")
	chapter.get_node("TempleEntrance").interact()
	await frames(85)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/disciple-player-gate.png")
	await frames(25)
	check(director.current_beat == &"complete" and player.position.is_equal_approx(Vector2(1024, 268)), "Player must enter the remade painted doorway, not the wall")
	check(player.get_facing_direction() == Vector2.UP, "Player must face into the gate")
	audio.prepare_exit()
	stopped_count = audio.slot
	audio.play_step()
	audio.investigate(&"palm_leaf")
	check(audio.slot == stopped_count and not audio.investigation.playing, "Scene exit must reject new foley")
	for voice in audio.footsteps:
		check(not voice.playing, "Scene exit must stop pooled footstep voices")
	chapter.free()
	print("Presentation tests: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	if segment.length_squared() <= 0.001:
		return point.distance_to(start)
	var amount := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * amount)
