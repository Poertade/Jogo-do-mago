extends GutTest
## Testes da IA do inimigo: parado, perseguindo, atacando, reação ao dano e morte.

var data: EnemyData


func before_each() -> void:
	data = EnemyData.new()
	data.sight_range = 10.0
	data.attack_range = 1.6
	data.attack_windup = 0.7
	data.attack_cooldown = 1.5
	data.hurt_stun = 0.35


func test_starts_idle_and_ignores_unseen_player() -> void:
	var brain := EnemyBrain.new(data)
	assert_eq(brain.state, EnemyBrain.State.IDLE)
	brain.update(0.1, 5.0, false)
	assert_eq(brain.state, EnemyBrain.State.IDLE, "Não vê o jogador atrás da parede")
	brain.update(0.1, 15.0, true)
	assert_eq(brain.state, EnemyBrain.State.IDLE, "Jogador longe demais")


func test_chases_when_player_is_seen_in_range() -> void:
	var brain := EnemyBrain.new(data)
	brain.update(0.1, 8.0, true)
	assert_eq(brain.state, EnemyBrain.State.CHASE)
	assert_true(brain.wants_to_move())


func test_attacks_in_range_and_hits_after_windup() -> void:
	var brain := EnemyBrain.new(data)
	watch_signals(brain)
	brain.update(0.1, 8.0, true)
	brain.update(0.1, 1.5, true)
	assert_eq(brain.state, EnemyBrain.State.ATTACK)
	assert_false(brain.wants_to_move(), "Para enquanto prepara o golpe")
	brain.update(0.5, 1.5, true)
	assert_signal_not_emitted(brain, "attack_landed")
	brain.update(0.25, 1.5, true)
	assert_signal_emitted(brain, "attack_landed")
	assert_eq(brain.state, EnemyBrain.State.CHASE)


func test_player_can_dodge_by_stepping_back() -> void:
	var brain := EnemyBrain.new(data)
	watch_signals(brain)
	brain.update(0.1, 8.0, true)
	brain.update(0.1, 1.5, true)
	brain.update(0.8, 4.0, true)
	assert_signal_not_emitted(brain, "attack_landed")


func test_cooldown_between_attacks() -> void:
	var brain := EnemyBrain.new(data)
	watch_signals(brain)
	brain.update(0.1, 8.0, true)
	brain.update(0.1, 1.5, true)
	brain.update(0.8, 1.5, true)
	brain.update(0.1, 1.5, true)
	assert_eq(brain.state, EnemyBrain.State.CHASE, "Ainda em intervalo")
	brain.update(1.5, 1.5, true)
	assert_eq(brain.state, EnemyBrain.State.ATTACK)


func test_damage_interrupts_attack() -> void:
	var brain := EnemyBrain.new(data)
	watch_signals(brain)
	brain.update(0.1, 8.0, true)
	brain.update(0.1, 1.5, true)
	brain.on_damaged()
	assert_eq(brain.state, EnemyBrain.State.HURT)
	brain.update(0.5, 1.5, true)
	assert_signal_not_emitted(brain, "attack_landed")
	assert_eq(brain.state, EnemyBrain.State.CHASE)


func test_damage_wakes_idle_enemy() -> void:
	var brain := EnemyBrain.new(data)
	brain.on_damaged()
	brain.update(0.4, 12.0, false)
	assert_eq(brain.state, EnemyBrain.State.CHASE)


func test_loses_interest_when_player_escapes() -> void:
	var brain := EnemyBrain.new(data)
	brain.update(0.1, 8.0, true)
	brain.update(0.1, 20.0, false)
	assert_eq(brain.state, EnemyBrain.State.IDLE)


func test_dead_stays_dead() -> void:
	var brain := EnemyBrain.new(data)
	brain.on_died()
	brain.on_damaged()
	brain.update(1.0, 1.0, true)
	assert_eq(brain.state, EnemyBrain.State.DEAD)
	assert_false(brain.wants_to_move())


func test_enrages_once_below_the_threshold() -> void:
	data.enrage_at = 0.5
	data.enrage_speed = 2.0
	var brain := EnemyBrain.new(data)
	assert_false(brain.check_enrage(0.8))
	assert_eq(brain.speed_multiplier(), 1.0)
	assert_true(brain.check_enrage(0.5), "Na metade da vida, enfurece")
	assert_false(brain.check_enrage(0.3), "Só uma vez")
	assert_eq(brain.speed_multiplier(), 2.0)


func test_enraged_attacks_faster() -> void:
	data.enrage_at = 0.5
	data.enrage_speed = 2.0
	var brain := EnemyBrain.new(data)
	brain.check_enrage(0.2)
	brain.update(0.1, 1.0, true)
	brain.update(0.1, 1.0, true)
	assert_eq(brain.state, EnemyBrain.State.ATTACK)
	watch_signals(brain)
	brain.update(0.36, 1.0, true)
	assert_signal_emitted(brain, "attack_landed", "Preparação de 0,7 s cai para 0,35 s")


func test_never_enrages_without_threshold() -> void:
	var brain := EnemyBrain.new(data)
	assert_false(brain.check_enrage(0.01))


func test_unshakable_enemy_keeps_attacking() -> void:
	data.hurt_stun = 0.0
	var brain := EnemyBrain.new(data)
	brain.on_damaged()
	assert_eq(brain.state, EnemyBrain.State.CHASE, "Acorda com o dano")
	brain.update(0.1, 1.0, true)
	assert_eq(brain.state, EnemyBrain.State.ATTACK)
	brain.on_damaged()
	assert_eq(brain.state, EnemyBrain.State.ATTACK, "O golpe não é interrompido")
