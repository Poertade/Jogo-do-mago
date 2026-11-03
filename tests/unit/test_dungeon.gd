extends GutTest
## Testes da Dungeon de mapa fixo: o que o jogador muda no mapa (DungeonProgress), o que ele
## guarda na escola (Stash), os achados de uma incursão (RunState) e o mapa de verdade
## (âncoras, salas, chaves e passagens).

const MAP_PATH := "res://scenes/dungeon/dungeon.tscn"


func test_progress_remembers_passages_keys_anchors_and_bosses() -> void:
	var world := DungeonProgress.new()
	watch_signals(world)
	assert_true(world.open(&"dorm_gate"))
	assert_false(world.open(&"dorm_gate"), "Abrir de novo não muda nada")
	assert_true(world.is_open(&"dorm_gate"))
	assert_true(world.take_key(&"crypt_key"))
	assert_true(world.has_key(&"crypt_key"))
	assert_true(world.attune(&"spring"))
	assert_true(world.is_attuned(&"spring"))
	assert_true(world.defeat(&"archivist"))
	assert_true(world.is_defeated(&"archivist"))
	assert_false(world.open(&""), "Identificador vazio é ignorado")
	assert_signal_emit_count(world, "changed", 4)


func test_stash_spends_all_or_nothing() -> void:
	var stash := Stash.new()
	stash.add({&"silver": 15, &"glass": 2})
	assert_eq(stash.count(&"silver"), 15)
	assert_eq(stash.missing({&"silver": 20, &"glass": 1}), {&"silver": 5})
	assert_false(stash.spend({&"silver": 20, &"glass": 1}))
	assert_eq(stash.count(&"glass"), 2, "Nada é gasto quando falta algo")
	assert_true(stash.spend({&"silver": 10, &"glass": 2}))
	assert_eq(stash.count(&"silver"), 5)
	assert_eq(stash.count(&"glass"), 0)


func test_stash_jars_respect_the_belt() -> void:
	var stash := Stash.new()
	assert_eq(stash.jars, 0, "O jogador começa sem potes")
	assert_true(stash.add_jar(2))
	assert_true(stash.add_jar(2))
	assert_false(stash.add_jar(2), "O cinto só leva 2")
	assert_eq(stash.jars, 2)


func test_found_items_are_lost_on_death() -> void:
	var run := _run(2)
	run.start_dungeon(42)
	assert_true(run.in_dungeon())
	run.find(&"silver", 7)
	run.find(&"silver", 3)
	run.find(&"glass", 0)
	assert_eq(run.found, {&"silver": 10} as Dictionary[StringName, int])
	run.jars.store(&"fire", 6)
	run.carry_book(BookData.new())
	run.reset()
	assert_false(run.in_dungeon())
	assert_true(run.found.is_empty(), "Morrer perde o que foi achado")
	assert_eq(run.jars.jars.size(), 2, "Os potes continuam com o jogador")
	assert_eq(run.jars.total(&"fire"), 0, "Só o Vis dos potes se perde")
	assert_eq(run.carried_books.size(), 0, "Livros não lidos se perdem")


func test_found_items_go_to_the_stash_when_taken_home() -> void:
	var run := _run(0)
	var stash := Stash.new()
	run.find(&"silver", 12)
	stash.add(run.take_found())
	assert_eq(stash.count(&"silver"), 12)
	assert_true(run.found.is_empty())


func test_belt_grows_with_new_jars() -> void:
	var run := _run(0)
	assert_eq(run.jars.store(&"fire", 5), 0, "Sem potes, nada é guardado")
	run.jars.set_count(1)
	assert_eq(run.jars.store(&"fire", 5), 5)
	run.jars.set_count(3)
	assert_eq(run.jars.jars.size(), 3)
	assert_eq(run.jars.total(&"fire"), 5, "Potes novos não mexem no Vis dos antigos")


func test_world_and_stash_survive_the_save() -> void:
	var world := DungeonProgress.new()
	world.open(&"dorm_gate")
	world.take_key(&"crypt_key")
	world.attune(&"spring")
	world.defeat(&"archivist")
	var stash := Stash.new()
	stash.add({&"silver": 9, &"glass": 4})
	stash.add_jar(4)
	var data := SaveGame.parse(SaveGame.to_json(Knowledge.new(), world, stash))
	assert_eq(int(data["format_version"]), 6)
	var loaded_world := SaveGame.world_from_dict(data)
	assert_eq(loaded_world.open_passages, [&"dorm_gate"] as Array[StringName])
	assert_eq(loaded_world.keys, [&"crypt_key"] as Array[StringName])
	assert_eq(loaded_world.anchors, [&"spring"] as Array[StringName])
	assert_eq(loaded_world.defeated, [&"archivist"] as Array[StringName])
	var loaded_stash := SaveGame.stash_from_dict(data)
	assert_eq(loaded_stash.count(&"silver"), 9)
	assert_eq(loaded_stash.count(&"glass"), 4)
	assert_eq(loaded_stash.jars, 1)


func test_old_save_starts_without_jars_or_map() -> void:
	var data := {"format_version": 5, "knowledge": {"discovered_aspects": ["fire"]}}
	assert_not_null(SaveGame.from_dict(data))
	assert_eq(SaveGame.stash_from_dict(data).jars, 0)
	assert_true(SaveGame.world_from_dict(data).open_passages.is_empty())


func test_real_rules_and_map() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	assert_eq(db.player.starting_vis.is_empty(), false)
	assert_true(ResourceLoader.exists(db.dungeon_rules.map_scene))
	assert_gt(db.dungeon_rules.anchors.size(), 1, "Mais de uma âncora: o portal leva a lugares diferentes")


## O mapa tem cada âncora das regras, cada sala da Dungeon, uma chave para cada porta
## trancada e identificadores de passagem sem repetição.
func test_map_has_every_anchor_room_and_key() -> void:
	var db := ContentDB.new()
	db.load_all()
	var map := _map_text()
	for anchor_id in db.dungeon_rules.anchors:
		assert_string_contains(map, 'anchor_id = &"%s"' % anchor_id, "Âncora '%s' fora do mapa" % anchor_id)
	for room: RoomData in db.rooms.values():
		if room.zone != &"":
			assert_string_contains(map, '"%s"' % room.scene_path, "Sala '%s' fora do mapa" % room.id)
	var keys := _values(map, "key_id")
	for key_id in _values(map, "needs_key"):
		assert_true(key_id in keys, "A porta que pede '%s' não tem chave no mapa" % key_id)
	var passages := _values(map, "passage_id")
	var seen := {}
	for passage_id in passages:
		assert_false(passage_id in seen, "Passagem repetida: '%s'" % passage_id)
		seen[passage_id] = true
	assert_gt(passages.size(), 2, "O mapa tem atalhos e segredos")


## Toda sala da Dungeon diz qual é (room_id), para o mapa aplicar a atmosfera dela.
func test_room_scenes_know_their_id() -> void:
	var db := ContentDB.new()
	db.load_all()
	for room: RoomData in db.rooms.values():
		if room.zone == &"":
			continue
		var text := FileAccess.get_file_as_string(room.scene_path)
		assert_string_contains(text, 'room_id = &"%s"' % room.id, "Sala '%s' sem room_id na cena" % room.id)


func _map_text() -> String:
	return FileAccess.get_file_as_string(MAP_PATH)


## Valores de uma propriedade StringName na cena (ex.: passage_id = &"x" → "x").
func _values(text: String, property: String) -> Array[String]:
	var result: Array[String] = []
	var regex := RegEx.create_from_string(property + ' = &"([^"]+)"')
	for found in regex.search_all(text):
		result.append(found.get_string(1))
	return result


func _run(jar_count: int) -> RunState:
	var player := PlayerData.new()
	player.max_health = 100
	player.jar_slots = 4
	player.jar_capacity = 10
	var wand := WandData.new()
	wand.aspects = [&"fire"] as Array[StringName]
	wand.capacity = 10
	wand.aspect_capacity = 10
	wand.efficiency = 1.0
	player.starting_wand = wand
	player.starting_focus = FocusData.new()
	return RunState.new(player, jar_count)
