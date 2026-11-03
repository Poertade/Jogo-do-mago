extends GutTest
## Testes da persistência do conhecimento (save em JSON com versão).


func _sample() -> Knowledge:
	var knowledge := Knowledge.new()
	knowledge.discovered_aspects.append_array([&"fire", &"water", &"life"])
	knowledge.aspect_points = {&"fire": 4, &"life": 1} as Dictionary[StringName, int]
	knowledge.scanned_targets.append_array([&"candle", &"water_jug"])
	knowledge.studied_pages.append(&"fire_comprehension")
	return knowledge


func test_round_trip_keeps_everything() -> void:
	var loaded := SaveGame.from_json(SaveGame.to_json(_sample()))
	assert_not_null(loaded)
	assert_eq(loaded.discovered_aspects, [&"fire", &"water", &"life"] as Array[StringName])
	assert_eq(loaded.points(&"fire"), 4)
	assert_eq(loaded.points(&"life"), 1)
	assert_eq(loaded.points(&"water"), 0)
	assert_eq(loaded.scanned_targets, [&"candle", &"water_jug"] as Array[StringName])
	assert_eq(loaded.studied_pages, [&"fire_comprehension"] as Array[StringName])


func test_save_is_readable_json_with_version() -> void:
	var text := SaveGame.to_json(_sample())
	var data: Dictionary = JSON.parse_string(text)
	assert_eq(int(data["format_version"]), SaveGame.FORMAT_VERSION)
	assert_string_contains(text, "\"aspect_points\"")
	assert_string_contains(text, "\n")


func test_invalid_text_is_rejected() -> void:
	assert_null(SaveGame.from_json("isto não é json"))
	assert_null(SaveGame.from_json("[1, 2, 3]"))


func test_newer_version_is_rejected() -> void:
	assert_null(SaveGame.from_dict({"format_version": SaveGame.FORMAT_VERSION + 1, "knowledge": {}}))


func test_version_1_is_migrated() -> void:
	var loaded := SaveGame.from_dict({"format_version": 1, "knowledge": {
		"discovered_aspects": ["fire", "water"], "scanned_targets": ["candle"],
		"research_points": 3, "studied_pages": ["fire_comprehension"]}})
	assert_not_null(loaded)
	assert_eq(loaded.discovered_aspects, [&"fire", &"water"] as Array[StringName])
	assert_eq(loaded.studied_pages, [&"fire_comprehension"] as Array[StringName])
	assert_eq(loaded.scanned_targets.size(), 0, "Objetos voltam a render pontos por aspecto")
	assert_eq(loaded.aspect_points.size(), 0, "O total antigo não tem como ser dividido")


func test_missing_or_wrong_fields_become_defaults() -> void:
	var loaded := SaveGame.from_dict({"format_version": 2, "knowledge": {
		"discovered_aspects": ["fire", 42, "fire"], "aspect_points": {"fire": -5, "water": "x", "air": 2}}})
	assert_not_null(loaded)
	assert_eq(loaded.discovered_aspects, [&"fire"] as Array[StringName])
	assert_eq(loaded.points(&"fire"), 0)
	assert_eq(loaded.points(&"air"), 2)
	assert_eq(loaded.studied_pages.size(), 0)
