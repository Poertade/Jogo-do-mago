extends GutTest
## Testes do carregamento e da verificação do conteúdo de data/.


func test_real_content_loads_without_errors() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors, PackedStringArray(), "Erros no conteúdo de data/")
	assert_not_null(db.player)
	assert_not_null(db.settings_defaults)
	assert_gt(db.presets.size(), 0)
	assert_has(db.rooms, &"test_room")
	assert_has(db.rooms, &"school")
	assert_eq(db.aspects.size(), 6, "Seis aspectos primais")
	assert_eq(db.scannables.size(), 6, "Seis objetos escaneáveis na escola")
	assert_has(db.pages, &"fire_comprehension")
	assert_not_null(db.research_rules)


func test_school_values_match_the_specification() -> void:
	var db := ContentDB.new()
	db.load_all()
	var expected := {&"candle": {&"fire": 3}, &"water_jug": {&"water": 2}, &"soil_pot": {&"earth": 2},
		&"feather": {&"air": 1}, &"ledger": {&"order": 2}, &"old_bone": {&"entropy": 2}}
	for id in expected:
		assert_eq(db.scannables[id].aspects, expected[id], "Aspectos de %s" % id)
	assert_eq(db.research_rules.scan_duration, 1.5)
	assert_eq(db.research_rules.points_per_new_aspect, 1)
	assert_eq(db.pages[&"fire_comprehension"].cost, 3)
	assert_almost_eq(db.pages[&"fire_comprehension"].effects[0].value, 1.2, 0.0001)
	# Varinha, Focus de Fogo e jogador (seção 6)
	assert_eq(db.player.max_health, 100)
	assert_eq(db.player.starting_wand.capacity[&"fire"], 30)
	var focus := db.player.starting_focus
	assert_eq(focus.cost[&"fire"], 5)
	assert_eq(focus.damage, 15.0)
	assert_eq(focus.charge_time, 0.6)
	assert_eq(focus.cooldown, 0.4)
	assert_eq(focus.element, &"fire")
	# Inimigo (seção 6)
	var beadle := db.enemies[&"bone_beadle"]
	assert_eq(beadle.max_health, 40.0)
	assert_eq(beadle.damage, 10.0)
	assert_eq(beadle.weaknesses[&"fire"], 1.5)
	assert_false(beadle.aspects.is_empty(), "O inimigo pode ser escaneado")
	assert_eq(db.find_scannable(&"bone_beadle"), beadle)
	assert_has(db.rooms, &"stone_chamber")


func test_enemy_cannot_reuse_object_id() -> void:
	var db := ContentDB.new()
	var object := ScannableData.new()
	object.id = &"same"
	db.add_scannable(object)
	var enemy := EnemyData.new()
	enemy.id = &"same"
	db.add_enemy(enemy)
	assert_string_contains("\n".join(db.errors), "'same'")


func _aspect(id: StringName, kind: String, parents: Array[StringName]) -> AspectData:
	var aspect := AspectData.new()
	aspect.id = id
	aspect.kind = kind
	aspect.parents = parents
	return aspect


func test_compound_aspect_needs_two_existing_parents() -> void:
	var db := ContentDB.new()
	db.add_aspect(_aspect(&"fire", "primal", []))
	db.add_aspect(_aspect(&"air", "primal", []))
	db.add_aspect(_aspect(&"light", "compound", [&"fire", &"air"]))
	db.add_aspect(_aspect(&"broken", "compound", [&"fire", &"nothing"]))
	db.add_aspect(_aspect(&"lonely", "compound", [&"fire"]))
	db.validate()
	var text := "\n".join(db.errors)
	assert_false("'light'" in text, "Composto válido não deveria dar erro")
	assert_string_contains(text, "'nothing'")
	assert_string_contains(text, "'lonely'")


func test_scannable_with_unknown_aspect_is_reported() -> void:
	var db := ContentDB.new()
	var target := ScannableData.new()
	target.id = &"mystery"
	var aspects: Dictionary[StringName, int] = {&"unknown": 1}
	target.aspects = aspects
	db.add_scannable(target)
	db.validate()
	assert_string_contains("\n".join(db.errors), "'unknown'")


func _room(id: StringName, scene_path: String) -> RoomData:
	var room := RoomData.new()
	room.id = id
	room.scene_path = scene_path
	return room


func test_duplicate_room_id_is_reported() -> void:
	var db := ContentDB.new()
	db.add_room(_room(&"sala", "res://scenes/rooms/test_room.tscn"))
	db.add_room(_room(&"sala", "res://scenes/rooms/test_room.tscn"))
	assert_eq(db.errors.size(), 1)
	assert_string_contains(db.errors[0], "repetido")


func test_missing_room_scene_is_reported() -> void:
	var db := ContentDB.new()
	db.add_room(_room(&"perdida", "res://scenes/rooms/nao_existe.tscn"))
	db.validate()
	var found := false
	for message in db.errors:
		if "perdida" in message and "cena" in message:
			found = true
	assert_true(found, "Deveria avisar da cena inexistente")


func test_missing_default_preset_is_reported() -> void:
	var db := ContentDB.new()
	db.load_all()
	db.errors.clear()
	db.settings_defaults = db.settings_defaults.duplicate()
	db.settings_defaults.default_preset_id = &"nao_existe"
	db.validate()
	var found := false
	for message in db.errors:
		if "nao_existe" in message:
			found = true
	assert_true(found, "Deveria avisar do filtro padrão inexistente")
