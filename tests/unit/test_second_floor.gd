extends GutTest
## Testes do M11: o inimigo à distância (só atira enxergando o jogador) e o conteúdo do segundo
## andar (o Olho Vigia, o chefe, a grade do Arquivista e o Núcleo Estelar).


func _ranged() -> EnemyData:
	var data := EnemyData.new()
	data.ranged = true
	data.sight_range = 12.0
	data.attack_range = 10.0
	data.attack_windup = 0.5
	data.attack_cooldown = 1.0
	data.keep_distance = 4.0
	return data


func test_ranged_enemy_only_shoots_what_it_sees() -> void:
	var brain := EnemyBrain.new(_ranged())
	brain.alert()
	assert_eq(brain.update(0.1, 8.0, false), EnemyBrain.State.CHASE, "Sem ver o jogador, não prepara o tiro")
	assert_eq(brain.update(0.1, 8.0, true), EnemyBrain.State.ATTACK, "Vendo, ao alcance: prepara o tiro")
	watch_signals(brain)
	brain.update(0.6, 8.0, true)
	assert_signal_emitted(brain, "attack_landed", "O tiro sai depois da preparação")


func test_melee_enemy_still_strikes_without_line_of_sight_check() -> void:
	var data := _ranged()
	data.ranged = false
	data.attack_range = 1.5
	var brain := EnemyBrain.new(data)
	brain.alert()
	assert_eq(brain.update(0.1, 1.0, false), EnemyBrain.State.ATTACK, "Corpo a corpo não depende da visão para golpear")


func test_second_floor_content() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	var eye: EnemyData = db.enemies[&"watcher_eye"]
	assert_true(eye.ranged)
	assert_gt(eye.attack_range, eye.keep_distance, "Atira de mais longe do que a distância que mantém")
	var boss: EnemyData = db.enemies[&"deep_eye"]
	assert_true(boss.show_health_bar and boss.ranged)
	assert_gt(boss.shot_count, 1, "O chefe atira em leque")
	assert_eq(boss.enrage_summons, [eye, eye] as Array[EnemyData])
	assert_true(boss.material_safe and boss.material == &"star_shard", "O chefe deixa fragmentos de estrela guardados")
	assert_eq(db.rooms[&"broken_dome"].zone, &"observatory")
	assert_false(db.books_in(&"observatory").is_empty())
	assert_true(&"cistern" in db.dungeon_rules.anchors)
	var map := FileAccess.get_file_as_string("res://scenes/dungeon/dungeon.tscn")
	assert_string_contains(map, 'requires_defeat = &"archivist"', "O segundo andar abre depois do Arquivista")
	assert_gt(db.cores[&"star"].capacity, db.cores[&"crystal"].capacity, "O Núcleo Estelar é o maior")
