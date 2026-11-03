extends GutTest
## Testes da incursão: sorteio das salas por região e tipo, com semente; a planta contínua
## (salas em fila ligadas por corredores que descem); o progresso na RunState; e as cenas das
## salas sorteáveis.

var rules: DungeonRules
var pool := {"school/combat": [&"c1", &"c2", &"c3"], "caves/rest": [&"r1"], "abyss/boss": [&"b1"]}


func before_each() -> void:
	rules = DungeonRules.new()
	rules.corridor_length_min = 5.0
	rules.corridor_length_max = 9.0
	for slot in [["school", "combat", 0.0, 1.0], ["school", "combat", 0.0, 1.0], ["caves", "rest", 2.0, 3.0], ["abyss", "boss", 3.0, 4.0]]:
		var step := DungeonStep.new()
		step.zone = StringName(slot[0])
		step.kind = StringName(slot[1])
		step.drop_min = slot[2]
		step.drop_max = slot[3]
		rules.steps.append(step)


func test_same_seed_gives_the_same_plan() -> void:
	var a := DungeonPlan.generate(rules, pool, 1234)
	var b := DungeonPlan.generate(rules, pool, 1234)
	assert_eq(a.rooms, b.rooms)
	assert_eq(a.corridor_lengths, b.corridor_lengths)
	assert_eq(a.corridor_drops, b.corridor_drops)
	assert_eq(a.size(), 4)


func test_order_of_the_pool_does_not_change_the_plan() -> void:
	var shuffled := {"school/combat": [&"c3", &"c1", &"c2"], "caves/rest": [&"r1"], "abyss/boss": [&"b1"]}
	assert_eq(DungeonPlan.generate(rules, pool, 77).rooms, DungeonPlan.generate(rules, shuffled, 77).rooms)


func test_plan_follows_zones_and_kinds_without_repeating() -> void:
	var plans := {}
	for seed_value in 30:
		var plan := DungeonPlan.generate(rules, pool, seed_value)
		assert_true(plan.rooms[0] in pool["school/combat"] and plan.rooms[1] in pool["school/combat"])
		assert_ne(plan.rooms[0], plan.rooms[1], "Sala repetida na semente %d" % seed_value)
		assert_eq(plan.rooms[2], &"r1")
		assert_eq(plan.rooms[3], &"b1")
		for i in plan.size():
			assert_between(plan.corridor_lengths[i], 5.0, maxf(9.0, plan.corridor_drops[i] * 2.2 + 0.5))
			assert_true(plan.corridor_lengths[i] >= plan.corridor_drops[i] * 2.2 - 0.3, "Rampa suave")
			assert_between(plan.corridor_drops[i], rules.steps[i].drop_min, rules.steps[i].drop_max)
		plans[str(plan.rooms)] = true
	assert_gt(plans.size(), 2, "Sementes diferentes devem dar roteiros diferentes")


func test_layout_chains_rooms_with_descending_corridors() -> void:
	var plan := DungeonPlan.generate(rules, pool, 9)
	var layout := DungeonLayout.build(plan, _rooms(plan.size()))
	assert_eq(layout.room_origins.size(), 4)
	var previous_exit := Vector3.ZERO
	for i in 4:
		var corridor := layout.corridors[i]
		assert_eq(corridor.from, previous_exit, "O corredor sai de onde a sala anterior termina")
		assert_almost_eq(corridor.length(), plan.corridor_lengths[i], 0.001)
		assert_almost_eq(corridor.drop(), plan.corridor_drops[i], 0.001)
		assert_almost_eq(layout.room_origins[i].z, corridor.to.z - 5.0, 0.001, "Entrada da sala no fim do corredor")
		previous_exit = corridor.to + Vector3(0, 0, -10.0)
	assert_lt(layout.room_origins[3].y, layout.room_origins[0].y, "O caminho desce")


func test_room_at_finds_rooms_and_their_corridors() -> void:
	var plan := DungeonPlan.generate(rules, pool, 3)
	var layout := DungeonLayout.build(plan, _rooms(plan.size()))
	for i in 4:
		assert_eq(layout.room_at(layout.room_origins[i] + Vector3(0, 1, 0)), i)
		var corridor_middle := (layout.corridors[i].from + layout.corridors[i].to) / 2.0 + Vector3(0, 1, 0)
		assert_eq(layout.room_at(corridor_middle), i, "O corredor conta como parte da sala a que leva")
	assert_eq(layout.room_at(Vector3(50, 0, 0)), -1)


func test_run_tracks_the_room_the_player_is_in() -> void:
	var run := _run()
	var plan := DungeonPlan.generate(rules, pool, 9)
	assert_false(run.in_dungeon())
	assert_eq(run.start_dungeon(plan), plan.rooms[0])
	run.enter_room(2)
	assert_eq(run.current_room(), plan.rooms[2])
	run.enter_room(9)
	assert_eq(run.room_index, 2, "Índice fora do roteiro é ignorado")
	assert_ne(run.current_room_seed(), 0)


func test_death_ends_the_incursion_and_empties_the_belt() -> void:
	var run := _run()
	run.start_dungeon(DungeonPlan.generate(rules, pool, 3))
	run.jars.store(&"fire", 7)
	run.carry_book(BookData.new())
	run.reset()
	assert_false(run.in_dungeon())
	assert_eq(run.jars.total(&"fire"), 0)
	assert_eq(run.carried_books.size(), 0, "Livros não lidos se perdem")


func test_real_rules_build_a_plan_and_a_layout() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	var plan := DungeonPlan.generate(db.dungeon_rules, db.rooms_by_slot(), 42)
	assert_eq(plan.size(), db.dungeon_rules.steps.size())
	var data := plan.rooms.map(func(id): return db.rooms[id])
	var layout := DungeonLayout.build(plan, data)
	assert_eq(layout.room_origins.size(), plan.size())
	assert_eq(db.dungeon_rules.steps.back().kind, &"boss")


## Toda sala sorteável precisa da porta de entrada aberta, da saída com grade e da passagem
## de saída (que a montagem tira quando a sala não é a última).
func test_dungeon_room_scenes_follow_the_convention() -> void:
	var db := ContentDB.new()
	db.load_all()
	for room: RoomData in db.rooms.values():
		if room.kind == &"":
			continue
		var text := FileAccess.get_file_as_string(room.scene_path)
		assert_string_contains(text, 'node name="SouthDoorway"', "Sala '%s' sem porta ao sul" % room.id)
		assert_string_contains(text, 'node name="ExitPassage"', "Sala '%s' sem passagem de saída" % room.id)
		assert_string_contains(text, "goes_deeper = true", "Sala '%s' sem saída para a próxima sala" % room.id)


func test_missing_slot_is_reported() -> void:
	var db := ContentDB.new()
	db.load_all()
	db.errors.clear()
	db.dungeon_rules = db.dungeon_rules.duplicate()
	var step := DungeonStep.new()
	step.zone = &"sky"
	step.kind = &"combat"
	db.dungeon_rules.steps = [step] as Array[DungeonStep]
	db.validate()
	assert_true("\n".join(db.errors).contains("sky/combat"))


func _rooms(count: int) -> Array:
	var result := []
	for i in count:
		var room := RoomData.new()
		room.width = 8.0
		room.depth = 10.0
		room.height = 4.0
		result.append(room)
	return result


func _run() -> RunState:
	var player := PlayerData.new()
	player.max_health = 100
	player.jar_slots = 3
	player.jar_capacity = 10
	var wand := WandData.new()
	wand.aspects = [&"fire"] as Array[StringName]
	wand.capacity = 10
	wand.aspect_capacity = 10
	wand.efficiency = 1.0
	player.starting_wand = wand
	player.starting_focus = FocusData.new()
	return RunState.new(player)
