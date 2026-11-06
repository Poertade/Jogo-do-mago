extends GutTest
## Testes do M10: a corrente do Focus de Choque e os dados dos Focus de Choque e de Escavação.


func test_chain_jumps_to_the_nearest_targets_in_range() -> void:
	var positions: Array[Vector3] = [Vector3(0, 0, 0), Vector3(4, 0, 0), Vector3(30, 0, 0), Vector3(7, 0, 0), Vector3(1, 0, 3)]
	var order := ChainLightning.pick_targets(0, positions, 2, 5.0)
	assert_eq(order, [0, 4, 1] as Array[int], "Do primeiro, salta para o mais perto, depois para o mais perto desse")
	assert_eq(ChainLightning.pick_targets(2, positions, 2, 5.0), [2] as Array[int], "Ninguém a até 5 m: não salta")
	assert_eq(ChainLightning.pick_targets(0, positions, 5, 5.0), [0, 4, 1, 3] as Array[int], "Não repete alvo")
	assert_true(ChainLightning.pick_targets(9, positions, 2, 5.0).is_empty())


func test_chain_damage_falls_off_each_jump() -> void:
	var amounts := ChainLightning.damages(10.0, 3, 0.7)
	assert_eq(amounts.size(), 3)
	assert_almost_eq(amounts[0], 10.0, 0.001)
	assert_almost_eq(amounts[1], 7.0, 0.001)
	assert_almost_eq(amounts[2], 4.9, 0.001)


func test_new_foci_are_unlocked_by_pages() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	var shock: FocusData = db.foci[&"shock_focus"]
	assert_eq(shock.spell_type, FocusData.SPELL_CHAIN)
	assert_eq(shock.cost, {&"air": 1} as Dictionary[StringName, int], "O Choque gasta Aer")
	assert_gt(shock.chain_jumps, 0)
	var dig: FocusData = db.foci[&"excavation_focus"]
	assert_true(dig.digs, "A Escavação quebra paredes rachadas")
	assert_eq(dig.cost, {&"earth": 1} as Dictionary[StringName, int], "A Escavação gasta Terra")
	for page_id in [&"shock_focus", &"excavation_focus"]:
		var unlocked := Modifiers.from_pages([db.pages[page_id]] as Array[ResearchPageData]).unlocked_foci
		assert_eq(unlocked.size(), 1, "A página %s libera um Focus" % page_id)
	assert_gt(db.enemies[&"ink_ooze"].weaknesses.get(&"air", 1.0), 1.0, "O Lodo de Tinta é fraco ao Choque")
