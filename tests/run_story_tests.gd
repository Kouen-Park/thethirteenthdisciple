extends SceneTree

var failures := 0

func _initialize() -> void:
	_test_director_accepts_any_interaction_order()
	_test_story_beat_contract()
	if failures == 0:
		print("Story system tests: PASS")
		quit(0)
	else:
		push_error("Story system tests: %d failure(s)" % failures)
		quit(1)

func _expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _test_director_accepts_any_interaction_order() -> void:
	var director := ChapterDirector.new()
	var required: Array[StringName] = [&"palm_leaf", &"discarded_cloak", &"footprints"]
	director.required_interactions = required
	director.begin_chapter()
	director.record_interaction(&"footprints")
	director.record_interaction(&"palm_leaf")
	_expect(director.current_beat == &"approach", "Director advanced before every required clue was observed")
	director.record_interaction(&"discarded_cloak")
	_expect(director.current_beat == &"encounter", "Director did not enter encounter after all required clues")
	var count: int = director.get_state()["observed"].size()
	director.record_interaction(&"discarded_cloak")
	_expect(director.get_state()["observed"].size() == count, "One-shot narrative observation was counted twice")
	director.free()

func _test_story_beat_contract() -> void:
	var beats: Array = StoryData.get_beats(&"chapter_01")
	_expect(beats.size() == 3, "Chapter 1 must expose arrival, approach, and encounter beats")
	_expect(beats[1].get("required", []).size() == 3, "Chapter 1 approach beat must require three world interactions")
