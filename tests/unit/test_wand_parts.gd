extends GutTest
## Testes do M8 (a varinha que cresce): núcleos e ponteiras, a economia acumulada da eficiência,
## a troca de varinha mantendo o Vis, as peças guardadas na escola (save 7) e o conteúdo real
## (toda peça tem página, todo material dá para achar).

var wand_aspects: Array[StringName] = [&"fire", &"water", &"order"]


func _core(per_aspect: int, total: int) -> WandCoreData:
	var core := WandCoreData.new()
	core.aspect_capacity = per_aspect
	core.capacity = total
	return core


func _cap(efficiency: float) -> WandCapData:
	var cap := WandCapData.new()
	cap.efficiency = efficiency
	return cap


func test_assemble_takes_limits_from_the_core_and_efficiency_from_the_cap() -> void:
	var wand := WandData.assemble(_core(12, 36), _cap(1.25), wand_aspects)
	assert_eq(wand.aspect_capacity, 12)
	assert_eq(wand.capacity, 36)
	assert_eq(wand.efficiency, 1.25)
	assert_eq(wand.aspects, wand_aspects)


func test_efficiency_savings_accumulate() -> void:
	var wand := WandState.new(WandData.assemble(_core(10, 30), _cap(1.25), wand_aspects), {&"fire": 10})
	var cost := {&"fire": 1}
	for i in 5:
		assert_true(wand.pay(cost))
	assert_eq(wand.reserve(&"fire"), 6, "Com eficiência 1,25, cinco disparos de 1 custam 4")
	assert_eq(WandState.new(wand.wand, {&"fire": 10}).casts_available(cost), 12, "10 de Ignis dão 12 disparos")


func test_normal_cap_costs_the_full_price() -> void:
	var wand := WandState.new(WandData.assemble(_core(10, 30), _cap(1.0), wand_aspects), {&"fire": 10})
	assert_eq(wand.casts_available({&"fire": 1}), 10)
	assert_eq(wand.cost_now({&"water": 1, &"order": 1}), {&"water": 1, &"order": 1} as Dictionary[StringName, int])


func test_changing_the_wand_keeps_what_fits() -> void:
	var big := WandData.assemble(_core(15, 45), _cap(1.0), wand_aspects)
	var wand := WandState.new(big, {&"fire": 15, &"water": 15, &"order": 15})
	wand.set_wand(WandData.assemble(_core(10, 30), _cap(1.0), wand_aspects))
	assert_eq(wand.reserve(&"fire"), 10, "O recipiente menor transborda")
	assert_eq(wand.total(), 30)
	wand.set_wand(WandData.assemble(_core(12, 20), _cap(1.0), wand_aspects))
	assert_eq(wand.total(), 20, "A soma não passa do novo limite total")


func test_stash_remembers_parts_and_survives_the_save() -> void:
	var stash := Stash.new()
	stash.add_core(&"bone")
	stash.add_cap(&"brass")
	stash.equip(&"wood", true)
	var data := SaveGame.parse(SaveGame.to_json(Knowledge.new(), DungeonProgress.new(), stash))
	assert_eq(int(data["format_version"]), 7)
	var loaded := SaveGame.stash_from_dict(data)
	assert_eq(loaded.cores, [&"bone"] as Array[StringName])
	assert_eq(loaded.caps, [&"brass"] as Array[StringName])
	assert_eq(loaded.core, &"wood")
	assert_eq(loaded.cap, &"brass")
	var old := SaveGame.stash_from_dict({"format_version": 6, "stash": {"jars": 2}})
	assert_true(old.cores.is_empty() and old.core == &"", "Saves antigos começam com as peças iniciais")


func test_pages_unlock_wand_parts() -> void:
	var db := ContentDB.new()
	db.load_all()
	var page: ResearchPageData = db.pages[&"brass_caps"]
	var modifiers := Modifiers.from_pages([page] as Array[ResearchPageData])
	assert_eq(modifiers.unlocked_parts, [db.caps[&"brass"]] as Array[Resource])


func test_real_parts_grow_and_cost_materials_that_exist_in_the_map() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	assert_eq(db.player.starting_core.id, &"wood")
	assert_eq(db.player.starting_cap.id, &"iron")
	var cores := db.cores.values()
	cores.sort_custom(func(a, b): return a.tier < b.tier)
	for i in range(1, cores.size()):
		assert_gt(cores[i].capacity, cores[i - 1].capacity, "Cada núcleo guarda mais que o anterior")
	var caps := db.caps.values()
	caps.sort_custom(func(a, b): return a.tier < b.tier)
	for i in range(1, caps.size()):
		assert_gt(caps[i].efficiency, caps[i - 1].efficiency, "Cada ponteira gasta menos que a anterior")
	# Onde cada material aparece: achados do mapa, inimigos e o baú.
	var sources := {}
	for room: RoomData in db.rooms.values():
		var text := FileAccess.get_file_as_string(room.scene_path)
		for found in RegEx.create_from_string('kind = &"([a-z_]+)"').search_all(text):
			sources[found.get_string(1)] = true
	for enemy: EnemyData in db.enemies.values():
		if enemy.silver_max > 0:
			sources["silver"] = true
		if enemy.material != &"":
			sources[String(enemy.material)] = true
	for item_id in db.economy.chest_materials:
		sources[String(item_id)] = true
	for part: Resource in cores + caps:
		for item_id in part.cost:
			assert_true(String(item_id) in sources, "%s pede '%s', que não aparece em lugar nenhum" % [part.id, item_id])
