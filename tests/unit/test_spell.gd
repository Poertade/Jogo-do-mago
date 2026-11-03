extends GutTest
## Testes da varinha (reserva, custo, eficiência, recarga) e da magia (carga, disparo, intervalo).

var wand_data: WandData
var focus: FocusData


func before_each() -> void:
	wand_data = WandData.new()
	var capacity: Dictionary[StringName, int] = {&"fire": 30}
	wand_data.capacity = capacity
	wand_data.efficiency = 1.0
	focus = FocusData.new()
	focus.element = &"fire"
	var cost: Dictionary[StringName, int] = {&"fire": 5}
	focus.cost = cost
	focus.charge_time = 0.6
	focus.cooldown = 0.4
	focus.damage = 15.0


func test_wand_starts_full() -> void:
	var wand := WandState.new(wand_data)
	assert_eq(wand.reserve(&"fire"), 30)
	assert_true(wand.is_full(&"fire"))


func test_paying_reduces_reserve() -> void:
	var wand := WandState.new(wand_data)
	assert_true(wand.pay(focus.cost))
	assert_eq(wand.reserve(&"fire"), 25)


func test_six_shots_empty_the_reserve() -> void:
	var wand := WandState.new(wand_data)
	for i in 6:
		assert_true(wand.pay(focus.cost), "Disparo %d" % (i + 1))
	assert_eq(wand.reserve(&"fire"), 0)
	assert_false(wand.pay(focus.cost), "Sétimo disparo sem Ignis")
	assert_eq(wand.reserve(&"fire"), 0)


func test_efficiency_divides_cost_rounding_up() -> void:
	wand_data.efficiency = 2.0
	var wand := WandState.new(wand_data)
	assert_eq(wand.effective_cost(focus.cost)[&"fire"], 3)
	wand.pay(focus.cost)
	assert_eq(wand.reserve(&"fire"), 27)


func test_refill_restores_capacity() -> void:
	var wand := WandState.new(wand_data)
	wand.pay(focus.cost)
	wand.refill(&"fire")
	assert_eq(wand.reserve(&"fire"), 30)


func test_release_before_charge_cancels_without_cost() -> void:
	var wand := WandState.new(wand_data)
	var caster := SpellCaster.new(focus, wand)
	assert_eq(caster.start_charge(), SpellCaster.Failure.NONE)
	caster.update(0.3)
	assert_false(caster.release())
	assert_eq(wand.reserve(&"fire"), 30)


func test_full_charge_casts_and_pays() -> void:
	var wand := WandState.new(wand_data)
	var caster := SpellCaster.new(focus, wand)
	caster.start_charge()
	caster.update(0.6)
	assert_eq(caster.state, SpellCaster.State.CHARGED)
	assert_true(caster.release())
	assert_eq(wand.reserve(&"fire"), 25)


func test_cooldown_blocks_next_charge() -> void:
	var caster := SpellCaster.new(focus, WandState.new(wand_data))
	caster.start_charge()
	caster.update(0.6)
	caster.release()
	assert_eq(caster.start_charge(), SpellCaster.Failure.COOLDOWN)
	caster.update(0.4)
	assert_eq(caster.start_charge(), SpellCaster.Failure.NONE)


func test_cannot_charge_without_energy() -> void:
	var wand := WandState.new(wand_data)
	for i in 6:
		wand.pay(focus.cost)
	var caster := SpellCaster.new(focus, wand)
	assert_eq(caster.start_charge(), SpellCaster.Failure.NO_ENERGY)
	assert_false(caster.is_busy())


func test_damage_uses_research_modifiers() -> void:
	var caster := SpellCaster.new(focus, WandState.new(wand_data))
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
	var caster := SpellCaster.new(focus, WandState.new(wand_data))
	assert_eq(caster.charge_ratio(), 0.0)
	caster.start_charge()
	caster.update(0.3)
	assert_almost_eq(caster.charge_ratio(), 0.5, 0.001)
