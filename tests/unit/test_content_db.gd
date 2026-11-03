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
	# Conteúdo novo é bem-vindo (README, "Como estender"): aqui só se exige o da especificação.
	for aspect_id in [&"fire", &"water", &"earth", &"air", &"order", &"entropy"]:
		assert_has(db.aspects, aspect_id, "Aspecto primal da especificação")
		assert_false(db.aspects[aspect_id].is_compound())
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
	assert_gt(db.research_rules.points_per_amount, 0)
	assert_eq(db.pages[&"fire_comprehension"].note_aspects, [&"fire", &"energy", &"light"] as Array[StringName])
	assert_almost_eq(db.pages[&"fire_comprehension"].effects[0].value, 1.2, 0.0001)
	# Varinha, Focus de Fogo e jogador (seção 6)
	assert_eq(db.player.max_health, 100)
	assert_eq(db.player.starting_wand.capacity, 30, "Limite total de Vis (pedido do usuário, D051)")
	assert_eq(db.player.starting_wand.aspect_capacity, 10, "Limite de cada recipiente (D051)")
	assert_eq(db.player.starting_vis, {&"fire": 10, &"order": 10, &"water": 10} as Dictionary[StringName, int], "Os recipientes dos dois Focus (D059)")
	var focus := db.player.starting_focus
	assert_eq(focus.cost, {&"fire": 1} as Dictionary[StringName, int], "Ajustado em D055: 10 disparos por recipiente, para a incursão de 5 salas")
	assert_eq(focus.damage, 15.0)
	assert_eq(focus.charge_time, 0.6)
	assert_eq(focus.cooldown, 0.4)
	assert_eq(focus.element, &"fire")
	# Inimigo (seção 6)
	var beadle := db.enemies[&"bone_beadle"]
	assert_eq(beadle.max_health, 50.0, "Ajustado no M5 (D034): a página de pesquisa precisa fazer diferença")
	assert_eq(beadle.damage, 10.0)
	assert_eq(beadle.weaknesses[&"fire"], 1.5)
	assert_false(beadle.aspects.is_empty(), "O inimigo pode ser escaneado")
	assert_eq(db.find_scannable(&"bone_beadle"), beadle)
	assert_has(db.rooms, &"stone_chamber")
	# Sons: todo evento do banco aponta para um som
	assert_not_null(db.sound_bank)
	for event in [&"spell_cast", &"fire_impact", &"scan_complete", &"enemy_hurt", &"player_hurt", &"portal"]:
		assert_not_null(db.sound_bank.sounds.get(event), "Som do evento %s" % event)
	assert_not_null(db.rooms[&"school"].ambience)


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


func test_research_page_saves_a_shot_against_the_enemy() -> void:
	# Balanceamento (D034): estudar "Compreensão de Ignis" precisa ser perceptível.
	var db := ContentDB.new()
	db.load_all()
	var focus := db.player.starting_focus
	var beadle := db.enemies[&"bone_beadle"]
	var page := db.pages[&"fire_comprehension"]
	var base := Combat.damage_against(focus.damage, focus.element, beadle.weaknesses)
	var studied := Combat.damage_against(focus.damage * Modifiers.from_pages([page] as Array[ResearchPageData]).damage_multiplier(focus.element),
		focus.element, beadle.weaknesses)
	var shots_without := ceili(beadle.max_health / base)
	var shots_with := ceili(beadle.max_health / studied)
	assert_lt(shots_with, shots_without, "A página deve poupar pelo menos um disparo")
	var wand := WandState.new(db.player.starting_wand, db.player.starting_vis)
	var shots_per_reserve := wand.casts_available(focus.cost)
	assert_lt(shots_without, shots_per_reserve, "Sem a página ainda deve dar para vencer com uma reserva")


func test_compound_recipes_follow_thaumcraft_4() -> void:
	# Receitas usadas como base (Thaumcraft 4.2); os nomes exibidos ficam em locales/names.csv.
	var db := ContentDB.new()
	db.load_all()
	var recipes := {&"life": [&"water", &"earth"], &"plant": [&"earth", &"life"], &"tree": [&"air", &"plant"],
		&"death": [&"life", &"entropy"], &"soul": [&"life", &"death"], &"mind": [&"fire", &"soul"],
		&"undead": [&"motion", &"death"], &"energy": [&"order", &"fire"], &"magic": [&"void", &"energy"]}
	for id in recipes:
		var parents: Array = db.aspects[id].parents
		assert_true(parents.has(recipes[id][0]) and parents.has(recipes[id][1]), "Receita de %s" % id)
	assert_eq(db.tier(&"fire"), 0)
	assert_eq(db.tier(&"life"), 1)
	assert_eq(db.tier(&"mind"), 4)


func test_frost_focus_and_its_page() -> void:
	var db := ContentDB.new()
	db.load_all()
	var frost: FocusData = db.foci[&"frost_focus"]
	assert_eq(frost.element, &"cold")
	assert_eq(frost.cost, {&"water": 1, &"order": 1} as Dictionary[StringName, int], "Gasta Aqua e Ordo (D054)")
	assert_lt(frost.slow_factor, 1.0, "Deixa o alvo lento")
	assert_eq(db.aspects[&"cold"].parents, [&"fire", &"entropy"] as Array[StringName], "Gelum = Ignis + Perditio (Thaumcraft 4)")
	var unlocked := Modifiers.from_pages([db.pages[&"frost_focus"]] as Array[ResearchPageData]).unlocked_foci
	assert_eq(unlocked, [frost] as Array[FocusData], "A página libera o Focus de Gelo")
	assert_gt(db.enemies[&"ink_ooze"].weaknesses[&"cold"], 1.0, "O Lodo resiste a fogo, mas é fraco a frio")


func test_boss_room_closes_the_layout() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.dungeon_rules.layout.back(), &"boss")
	var boss: EnemyData = db.enemies[&"archivist"]
	assert_true(boss.show_health_bar)
	assert_eq(boss.hurt_stun, 0.0, "O chefe não é interrompido a cada disparo")
	assert_gt(boss.enrage_at, 0.0)
	assert_false(boss.enrage_summons.is_empty())


func test_bad_slow_and_enrage_values_are_reported() -> void:
	var db := ContentDB.new()
	db.load_all()
	db.errors.clear()
	var focus: FocusData = db.foci[&"frost_focus"].duplicate()
	focus.slow_factor = 0.0
	db.foci[&"frost_focus"] = focus
	var boss: EnemyData = db.enemies[&"archivist"].duplicate()
	boss.enrage_at = 1.5
	db.enemies[&"archivist"] = boss
	db.validate()
	var text := "\n".join(db.errors)
	assert_string_contains(text, "slow_factor")
	assert_string_contains(text, "enrage_at")
