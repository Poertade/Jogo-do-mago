extends GutTest
## Testes da incursão: sorteio das salas com semente, progresso na RunState e as cenas das
## salas sorteáveis (entrada e saída que a incursão usa).

const LAYOUT: Array[StringName] = [&"combat", &"combat", &"rest", &"combat", &"boss"]
var pool := {&"combat": [&"c1", &"c2", &"c3", &"c4"], &"rest": [&"r1"], &"boss": [&"b1"]}


func test_same_seed_gives_the_same_plan() -> void:
	var a := DungeonPlan.generate(LAYOUT, pool, 1234)
	var b := DungeonPlan.generate(LAYOUT, pool, 1234)
	assert_eq(a.rooms, b.rooms)
	assert_eq(a.size(), 5)


func test_order_of_the_pool_does_not_change_the_plan() -> void:
	var shuffled := {&"combat": [&"c3", &"c1", &"c4", &"c2"], &"rest": [&"r1"], &"boss": [&"b1"]}
	assert_eq(DungeonPlan.generate(LAYOUT, pool, 77).rooms, DungeonPlan.generate(LAYOUT, shuffled, 77).rooms)


func test_different_seeds_vary() -> void:
	var plans := {}
	for seed_value in 20:
		plans[str(DungeonPlan.generate(LAYOUT, pool, seed_value).rooms)] = true
	assert_gt(plans.size(), 3, "Sementes diferentes devem dar roteiros diferentes")


func test_plan_follows_the_layout_without_repeating() -> void:
	for seed_value in 30:
		var plan := DungeonPlan.generate(LAYOUT, pool, seed_value)
		assert_true(plan.rooms[2] == &"r1" and plan.rooms[4] == &"b1")
		var combat := [plan.rooms[0], plan.rooms[1], plan.rooms[3]]
		for id in combat:
			assert_true(id in pool[&"combat"])
			assert_eq(combat.count(id), 1, "Sala repetida na semente %d" % seed_value)


func test_small_pool_repeats_but_not_in_a_row() -> void:
	var small := {&"combat": [&"c1", &"c2"]}
	var layout: Array[StringName] = [&"combat", &"combat", &"combat", &"combat"]
	for seed_value in 30:
		var plan := DungeonPlan.generate(layout, small, seed_value)
		assert_eq(plan.size(), 4)
		for i in range(1, plan.size()):
			assert_ne(plan.rooms[i], plan.rooms[i - 1], "Mesma sala seguida na semente %d" % seed_value)


func test_room_seeds_are_stable_and_different() -> void:
	var plan := DungeonPlan.generate(LAYOUT, pool, 5)
	assert_eq(plan.room_seed(2), DungeonPlan.generate(LAYOUT, pool, 5).room_seed(2))
	assert_ne(plan.room_seed(0), plan.room_seed(1))


func test_run_walks_through_the_plan() -> void:
	var run := _run()
	var plan := DungeonPlan.generate(LAYOUT, pool, 9)
	assert_false(run.in_dungeon())
	assert_eq(run.start_dungeon(plan), plan.rooms[0])
	assert_true(run.in_dungeon())
	for i in range(1, 5):
		assert_eq(run.advance(), plan.rooms[i])
	assert_eq(run.advance(), &"", "Depois da última sala, a incursão acaba")
	assert_false(run.in_dungeon())
	assert_eq(run.advance(), &"")


func test_death_ends_the_incursion() -> void:
	var run := _run()
	run.start_dungeon(DungeonPlan.generate(LAYOUT, pool, 3))
	run.advance()
	run.reset()
	assert_false(run.in_dungeon())
	assert_eq(run.current_room_seed(), 0)


func test_real_layout_has_rooms_for_every_kind() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	var plan := DungeonPlan.generate(db.dungeon_rules.layout, db.rooms_by_kind(), 42)
	assert_eq(plan.size(), db.dungeon_rules.layout.size())


## Toda sala sorteável precisa da entrada da incursão e de uma saída para a próxima sala.
func test_dungeon_room_scenes_have_entrance_and_exit() -> void:
	var db := ContentDB.new()
	db.load_all()
	var entrance := 'id = &"%s"' % db.dungeon_rules.entrance_id
	for room: RoomData in db.rooms.values():
		if room.kind == &"":
			continue
		var text := FileAccess.get_file_as_string(room.scene_path)
		assert_string_contains(text, entrance, "Sala '%s' sem a entrada da incursão" % room.id)
		assert_string_contains(text, "goes_deeper = true", "Sala '%s' sem saída para a próxima sala" % room.id)


func test_missing_kind_is_reported() -> void:
	var db := ContentDB.new()
	db.load_all()
	db.errors.clear()
	db.dungeon_rules = db.dungeon_rules.duplicate()
	db.dungeon_rules.layout = [&"combat", &"treasure"] as Array[StringName]
	db.validate()
	assert_true("\n".join(db.errors).contains("treasure"))


func _run() -> RunState:
	var player := PlayerData.new()
	player.max_health = 100
	var wand := WandData.new()
	wand.aspects = [&"fire"] as Array[StringName]
	wand.capacity = 10
	wand.aspect_capacity = 10
	wand.efficiency = 1.0
	player.starting_wand = wand
	player.starting_focus = FocusData.new()
	return RunState.new(player)
