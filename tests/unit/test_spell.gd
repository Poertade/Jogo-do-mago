extends GutTest
## Testes da varinha (um recipiente de Vis por aspecto, com limite próprio e limite total;
## custo, eficiência, recarga) e da magia (carga, disparo, intervalo).

var wand_data: WandData
var focus: FocusData
## Vis com que a varinha começa nos testes: Ignis cheio.
var full_fire := {&"fire": 10}


func before_each() -> void:
	wand_data = WandData.new()
	wand_data.aspects = [&"air", &"earth", &"fire", &"water", &"order", &"entropy"] as Array[StringName]
	wand_data.capacity = 30
	wand_data.aspect_capacity = 10
	wand_data.efficiency = 1.0
	focus = FocusData.new()
	focus.element = &"fire"
	focus.cost = {&"fire": 2} as Dictionary[StringName, int]
	focus.charge_time = 0.6
	focus.cooldown = 0.4
	focus.damage = 15.0


func test_wand_starts_with_the_initial_vis() -> void:
	var wand := WandState.new(wand_data, full_fire)
	assert_eq(wand.reserve(&"fire"), 10)
	assert_eq(wand.reserve(&"water"), 0)
	assert_eq(wand.total(), 10)
	assert_true(wand.is_full(&"fire"))
	assert_false(wand.is_full(&"water"))


func test_each_container_has_its_own_limit() -> void:
	var wand := WandState.new(wand_data)
	assert_eq(wand.add(&"fire", 25), 10, "O recipiente de Ignis guarda no máximo 10")
	assert_eq(wand.add(&"water", 4), 4)
	assert_eq(wand.reserve(&"fire"), 10)
	assert_eq(wand.reserve(&"water"), 4)


func test_total_limit_holds_three_full_containers() -> void:
	# O exemplo do usuário: total 30, 10 por aspecto → 10 de Ignis, 10 de Aqua e 10 de Perditio.
	var wand := WandState.new(wand_data)
	for aspect_id in [&"fire", &"water", &"entropy"]:
		assert_eq(wand.add(aspect_id, 10), 10)
	assert_eq(wand.total(), 30)
	assert_true(wand.is_total_full())
	assert_eq(wand.add(&"air", 5), 0, "A varinha está cheia: não cabe Aer")
	assert_true(wand.is_full(&"air"))
	assert_eq(wand.room_for(&"air"), 0)


func test_total_limit_cuts_a_partial_fill() -> void:
	var wand := WandState.new(wand_data)
	wand.add(&"fire", 10)
	wand.add(&"water", 10)
	wand.add(&"order", 7)
	assert_eq(wand.room_for(&"entropy"), 3, "Só faltam 3 para o total")
	assert_eq(wand.add(&"entropy", 10), 3)
	assert_eq(wand.total(), 30)


func test_aspect_without_container_gets_nothing() -> void:
	var wand := WandState.new(wand_data)
	assert_false(wand.has_container(&"life"), "Vis só dos primais da lista")
	assert_eq(wand.add(&"life", 5), 0)
	assert_eq(wand.total(), 0)


func test_paying_takes_from_the_right_container() -> void:
	var wand := WandState.new(wand_data, {&"fire": 10, &"water": 5})
	assert_true(wand.pay(focus.cost))
	assert_eq(wand.reserve(&"fire"), 8)
	assert_eq(wand.reserve(&"water"), 5)


func test_five_shots_empty_the_fire_container() -> void:
	var wand := WandState.new(wand_data, full_fire)
	assert_eq(wand.casts_available(focus.cost), 5)
	for i in 5:
		assert_true(wand.pay(focus.cost), "Disparo %d" % (i + 1))
	assert_eq(wand.reserve(&"fire"), 0)
	assert_false(wand.pay(focus.cost), "Sexto disparo sem Ignis")
	assert_eq(wand.casts_available(focus.cost), 0)


func test_other_aspects_do_not_pay_for_fire() -> void:
	var wand := WandState.new(wand_data, {&"water": 10, &"entropy": 10})
	assert_false(wand.can_pay(focus.cost))
	assert_false(wand.pay(focus.cost))
	assert_eq(wand.total(), 20)


func test_efficiency_divides_cost_rounding_up() -> void:
	wand_data.efficiency = 2.0
	focus.cost = {&"fire": 3} as Dictionary[StringName, int]
	var wand := WandState.new(wand_data, full_fire)
	assert_eq(wand.effective_cost(focus.cost)[&"fire"], 2)
	wand.pay(focus.cost)
	assert_eq(wand.reserve(&"fire"), 8)


func test_reset_restores_the_initial_vis() -> void:
	var wand := WandState.new(wand_data, full_fire)
	wand.pay(focus.cost)
	wand.add(&"water", 6)
	wand.reset(full_fire)
	assert_eq(wand.reserve(&"fire"), 10)
	assert_eq(wand.reserve(&"water"), 0)


func test_reset_respects_the_limits() -> void:
	var wand := WandState.new(wand_data, {&"fire": 50, &"water": 10, &"air": 10, &"order": 10})
	assert_eq(wand.reserve(&"fire"), 10)
	assert_eq(wand.total(), 30, "O total corta o que passar")


func test_release_before_charge_cancels_without_cost() -> void:
	var wand := WandState.new(wand_data, full_fire)
	var caster := SpellCaster.new(focus, wand)
	assert_eq(caster.start_charge(), SpellCaster.Failure.NONE)
	caster.update(0.3)
	assert_false(caster.release())
	assert_eq(wand.reserve(&"fire"), 10)


func test_full_charge_casts_and_pays() -> void:
	var wand := WandState.new(wand_data, full_fire)
	var caster := SpellCaster.new(focus, wand)
	caster.start_charge()
	caster.update(0.6)
	assert_eq(caster.state, SpellCaster.State.CHARGED)
	assert_true(caster.release())
	assert_eq(wand.reserve(&"fire"), 8)


func test_cooldown_blocks_next_charge() -> void:
	var caster := SpellCaster.new(focus, WandState.new(wand_data, full_fire))
	caster.start_charge()
	caster.update(0.6)
	caster.release()
	assert_eq(caster.start_charge(), SpellCaster.Failure.COOLDOWN)
	caster.update(0.4)
	assert_eq(caster.start_charge(), SpellCaster.Failure.NONE)


func test_cannot_charge_without_energy() -> void:
	var caster := SpellCaster.new(focus, WandState.new(wand_data, {&"fire": 1}))
	assert_eq(caster.start_charge(), SpellCaster.Failure.NO_ENERGY)
	assert_false(caster.is_busy())


func test_damage_uses_research_modifiers() -> void:
	var caster := SpellCaster.new(focus, WandState.new(wand_data, full_fire))
	assert_eq(caster.damage(Modifiers.new()), 15.0)
	var effect := PageEffect.new()
	effect.type = PageEffect.DAMAGE_MULTIPLIER
	effect.element = &"fire"
	effect.value = 1.2
	var page := ResearchPageData.new()
	var effects: Array[PageEffect] = [effect]
	page.effects = effects
	var pages: Array[ResearchPageData] = [page]
	assert_almost_eq(caster.damage(Modifiers.from_pages(pages)), 18.0, 0.0001)


func test_charge_ratio_grows_with_time() -> void:
	var caster := SpellCaster.new(focus, WandState.new(wand_data, full_fire))
	assert_eq(caster.charge_ratio(), 0.0)
	caster.start_charge()
	caster.update(0.3)
	assert_almost_eq(caster.charge_ratio(), 0.5, 0.001)


func test_changes_emit_a_signal() -> void:
	var wand := WandState.new(wand_data)
	watch_signals(wand)
	wand.add(&"fire", 4)
	wand.pay({&"fire": 2})
	assert_signal_emit_count(wand, "reserves_changed", 2)
	wand.add(&"fire", 0)
	assert_signal_emit_count(wand, "reserves_changed", 2, "Nada entrou: sem sinal")


func test_equip_swaps_focus_and_cancels_the_charge() -> void:
	var wand := WandState.new(wand_data, {&"fire": 10, &"water": 10, &"order": 10})
	var caster := SpellCaster.new(focus, wand)
	caster.start_charge()
	var frost := FocusData.new()
	frost.cost = {&"water": 1, &"order": 1} as Dictionary[StringName, int]
	frost.charge_time = 0.5
	caster.equip(frost)
	assert_eq(caster.focus, frost)
	assert_false(caster.is_busy(), "Trocar de Focus perde a carga")
	caster.start_charge()
	caster.update(0.5)
	assert_true(caster.release())
	assert_eq(wand.reserve(&"water"), 9)
	assert_eq(wand.reserve(&"order"), 9)
	assert_eq(wand.reserve(&"fire"), 10, "O gelo não gasta Ignis")
