extends GutTest
## Testes da persistência do conhecimento (save em JSON com versão).


func _sample() -> Knowledge:
	var knowledge := Knowledge.new()
	knowledge.discovered_aspects.append_array([&"fire", &"water"])
	knowledge.scanned_targets.append_array([&"candle", &"water_jug"])
	knowledge.research_points = 2
	knowledge.studied_pages.append(&"fire_comprehension")
	return knowledge


func test_round_trip_keeps_everything() -> void:
	var loaded := SaveGame.from_json(SaveGame.to_json(_sample()))
	assert_not_null(loaded)
	assert_eq(loaded.discovered_aspects, [&"fire", &"water"] as Array[StringName])
	assert_eq(loaded.scanned_targets, [&"candle", &"water_jug"] as Array[StringName])
	assert_eq(loaded.research_points, 2)
	assert_eq(loaded.studied_pages, [&"fire_comprehension"] as Array[StringName])


func test_save_is_readable_json_with_version() -> void:
	var text := SaveGame.to_json(_sample())
	var data: Dictionary = JSON.parse_string(text)
	assert_eq(int(data["format_version"]), SaveGame.FORMAT_VERSION)
	assert_string_contains(text, "\"discovered_aspects\"")
	assert_string_contains(text, "\n")


func test_invalid_text_is_rejected() -> void:
	assert_null(SaveGame.from_json("isto não é json"))
	assert_null(SaveGame.from_json("[1, 2, 3]"))


func test_newer_version_is_rejected() -> void:
	assert_null(SaveGame.from_dict({"format_version": SaveGame.FORMAT_VERSION + 1, "knowledge": {}}))


func test_missing_or_wrong_fields_become_defaults() -> void:
	var loaded := SaveGame.from_dict({"format_version": 1, "knowledge": {
		"discovered_aspects": ["fire", 42, "fire"], "research_points": -5}})
	assert_not_null(loaded)
	assert_eq(loaded.discovered_aspects, [&"fire"] as Array[StringName])
	assert_eq(loaded.research_points, 0)
	assert_eq(loaded.studied_pages.size(), 0)
