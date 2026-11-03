extends GutTest
## Testes de vida, dano por elemento e reinício da incursão.


func test_weakness_multiplies_damage() -> void:
	assert_almost_eq(Combat.damage_against(15.0, &"fire", {&"fire": 1.5}), 22.5, 0.0001)
	assert_eq(Combat.damage_against(15.0, &"water", {&"fire": 1.5}), 15.0)


func test_enemy_dies_after_two_fire_hits() -> void:
	# Valores da especificação: 40 de vida, 15 de dano, fraqueza 1,5 a fogo.
	var health := Health.new(40)
	health.take_damage(Combat.damage_against(15.0, &"fire", {&"fire": 1.5}))
	assert_false(health.is_dead())
	health.take_damage(Combat.damage_against(15.0, &"fire", {&"fire": 1.5}))
	assert_true(health.is_dead())


func test_died_is_emitted_once() -> void:
	var health := Health.new(10)
	watch_signals(health)
	health.take_damage(8)
	health.take_damage(8)
	health.take_damage(8)
	assert_signal_emit_count(health, "died", 1)
	assert_eq(health.current, 0.0)


func test_run_reset_restores_health_and_reserve() -> void:
	var player := PlayerData.new()
	player.max_health = 100
	var wand := WandData.new()
	wand.capacity = 30
	wand.efficiency = 1.0
	var focus := FocusData.new()
	focus.cost = 5
	player.starting_wand = wand
	player.starting_focus = focus
	var run := RunState.new(player)
	run.health.take_damage(60)
	run.wand.pay(focus.cost)
	run.reset()
	assert_eq(run.health.current, 100.0)
	assert_eq(run.wand.vis, 30)
