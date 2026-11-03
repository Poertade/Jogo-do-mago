extends GutTest
## Testes da pesquisa no estilo do Thaumcraft 4: escaneamento, pontos por aspecto,
## combinação de aspectos na Mesa e estudo de páginas.

var rules: ResearchRules
var aspects: Dictionary = {}


func _aspect(id: StringName, parents: Array[StringName] = []) -> AspectData:
	var aspect := AspectData.new()
	aspect.id = id
	aspect.kind = "compound" if parents.size() == 2 else "primal"
	aspect.parents = parents
	aspects[id] = aspect
	return aspect


func before_each() -> void:
	rules = ResearchRules.new()
	rules.points_per_amount = 2
	rules.combine_cost = 1
	rules.combine_yield = 1
	aspects.clear()
	for id in [&"fire", &"water", &"earth", &"air", &"order", &"entropy"]:
		_aspect(id)
	_aspect(&"life", [&"water", &"earth"])
	_aspect(&"plant", [&"earth", &"life"])


func _target(id: StringName, amounts: Dictionary) -> ScannableData:
	var target := ScannableData.new()
	target.id = id
	var typed: Dictionary[StringName, int] = {}
	for key in amounts:
		typed[key] = amounts[key]
	target.aspects = typed
	return target


## Página cuja nota (raio 1) tem Aqua e Herba em lados opostos: escrever Victus no centro liga
## os dois (Victus = Aqua + Terra; Herba = Terra + Victus).
func _page(id: StringName, required_pages: Array[StringName] = []) -> ResearchPageData:
	var page := ResearchPageData.new()
	page.id = id
	page.note_aspects = [&"water", &"plant"] as Array[StringName]
	page.note_radius = 1
	page.required_pages = required_pages
	return page


## Conhecimento com todas as receitas destes testes sabidas (as receitas têm testes próprios).
func _new() -> Knowledge:
	var knowledge := Knowledge.new()
	for aspect: AspectData in aspects.values():
		if aspect.is_compound():
			knowledge.free_recipes.append(aspect.id)
	return knowledge


func _knowing(ids: Array[StringName], amount := 5) -> Knowledge:
	var knowledge := _new()
	for id in ids:
		knowledge.discovered_aspects.append(id)
		knowledge.aspect_points[id] = amount
	return knowledge


func test_first_scan_discovers_primals_and_gives_points_per_amount() -> void:
	var knowledge := _new()
	var result := knowledge.register_scan(_target(&"candle", {&"fire": 3}), aspects, rules)
	assert_false(result.blocked)
	assert_true(result.new_target)
	assert_eq(result.new_aspects, [&"fire"] as Array[StringName])
	assert_eq(result.points[&"fire"], 6, "3 de Ignis × 2 pontos por unidade")
	assert_eq(knowledge.points(&"fire"), 6)
	assert_true(knowledge.knows_aspect(&"fire"))


func test_scanning_again_gives_nothing() -> void:
	var knowledge := _new()
	var candle := _target(&"candle", {&"fire": 3})
	knowledge.register_scan(candle, aspects, rules)
	var again := knowledge.register_scan(candle, aspects, rules)
	assert_false(again.discovered_something())
	assert_eq(again.total_points(), 0)
	assert_eq(knowledge.points(&"fire"), 6)


func test_unknown_compound_blocks_the_scan() -> void:
	var knowledge := _new()
	var sprout := _target(&"sprout", {&"plant": 1, &"earth": 1})
	var result := knowledge.register_scan(sprout, aspects, rules)
	assert_true(result.blocked, "Herba não descoberta: conhecimento insuficiente")
	assert_eq(result.missing, [&"plant"] as Array[StringName])
	assert_false(knowledge.has_scanned(&"sprout"))
	assert_false(knowledge.knows_aspect(&"earth"), "Escaneamento bloqueado não ensina nada")
	assert_eq(knowledge.points(&"earth"), 0)


func test_combining_discovers_compound_and_spends_parents() -> void:
	var knowledge := _new()
	knowledge.register_scan(_target(&"jug", {&"water": 2}), aspects, rules)
	knowledge.register_scan(_target(&"pot", {&"earth": 2}), aspects, rules)
	var life: AspectData = aspects[&"life"]
	assert_eq(knowledge.check_combine(life, rules), Knowledge.CombineCheck.OK)
	assert_true(knowledge.combine(life, rules))
	assert_true(knowledge.knows_aspect(&"life"))
	assert_eq(knowledge.points(&"life"), 1)
	assert_eq(knowledge.points(&"water"), 3)
	assert_eq(knowledge.points(&"earth"), 3)


func test_combining_needs_known_parents_and_points() -> void:
	var knowledge := _new()
	var life: AspectData = aspects[&"life"]
	assert_eq(knowledge.check_combine(life, rules), Knowledge.CombineCheck.UNKNOWN_PARENT)
	knowledge.discovered_aspects.append_array([&"water", &"earth"])
	assert_eq(knowledge.check_combine(life, rules), Knowledge.CombineCheck.NOT_ENOUGH_POINTS)
	assert_false(knowledge.combine(life, rules))
	assert_eq(knowledge.check_combine(aspects[&"fire"], rules), Knowledge.CombineCheck.NOT_COMPOUND)


func test_after_discovering_compound_the_scan_works() -> void:
	var knowledge := _new()
	knowledge.register_scan(_target(&"jug", {&"water": 2}), aspects, rules)
	knowledge.register_scan(_target(&"pot", {&"earth": 2}), aspects, rules)
	var sprout := _target(&"sprout", {&"plant": 1, &"earth": 1})
	assert_true(knowledge.register_scan(sprout, aspects, rules).blocked)
	knowledge.combine(aspects[&"life"], rules)
	knowledge.combine(aspects[&"plant"], rules)
	var result := knowledge.register_scan(sprout, aspects, rules)
	assert_false(result.blocked)
	assert_eq(result.points[&"plant"], 2)


func test_changed_is_emitted_on_scan_and_combine_only() -> void:
	var knowledge := _new()
	watch_signals(knowledge)
	var jug := _target(&"jug", {&"water": 2})
	knowledge.register_scan(jug, aspects, rules)
	knowledge.register_scan(jug, aspects, rules)
	knowledge.register_scan(_target(&"sprout", {&"plant": 1}), aspects, rules)
	assert_signal_emit_count(knowledge, "changed", 1)


func test_writing_on_the_note_spends_points_and_erasing_refunds() -> void:
	rules.note_write_cost = 1
	var knowledge := _knowing([&"water", &"plant", &"life"])
	var page := _page(&"p")
	assert_true(knowledge.write_on_note(page, Vector2i.ZERO, &"life", rules))
	assert_eq(knowledge.points(&"life"), 4)
	assert_false(knowledge.write_on_note(page, Vector2i.ZERO, &"water", rules), "Hexágono ocupado")
	assert_true(knowledge.erase_from_note(page, Vector2i.ZERO, rules))
	assert_eq(knowledge.points(&"life"), 5)


func test_cannot_write_on_targets_unknown_aspects_or_without_points() -> void:
	rules.note_write_cost = 1
	var page := _page(&"p")
	var target_cell: Vector2i = ResearchNote.for_page(page).targets.keys()[0]
	var knowledge := _knowing([&"water", &"plant", &"life"])
	assert_false(knowledge.write_on_note(page, target_cell, &"life", rules), "Alvo já escrito")
	assert_false(knowledge.write_on_note(page, Vector2i(5, 5), &"life", rules), "Fora da grade")
	assert_false(knowledge.write_on_note(page, Vector2i.ZERO, &"fire", rules), "Aspecto desconhecido")
	var poor := _knowing([&"life"], 0)
	assert_false(poor.write_on_note(page, Vector2i.ZERO, &"life", rules), "Sem pontos")


func test_study_needs_the_note_complete() -> void:
	rules.note_write_cost = 1
	var knowledge := _knowing([&"water", &"plant", &"life", &"earth"])
	var page := _page(&"p")
	assert_eq(knowledge.check_study(page, aspects), Knowledge.StudyCheck.NOTE_INCOMPLETE)
	knowledge.write_on_note(page, Vector2i.ZERO, &"earth", rules)
	assert_eq(knowledge.check_study(page, aspects), Knowledge.StudyCheck.NOTE_INCOMPLETE, "Terra não liga com Aqua")
	knowledge.erase_from_note(page, Vector2i.ZERO, rules)
	knowledge.write_on_note(page, Vector2i.ZERO, &"life", rules)
	assert_eq(knowledge.check_study(page, aspects), Knowledge.StudyCheck.OK)
	assert_true(knowledge.study(page, aspects))
	assert_true(knowledge.has_studied(&"p"))
	assert_eq(knowledge.note_for(page).aspect_at(Vector2i.ZERO), &"life", "A nota resolvida continua guardada")
	var life_points := knowledge.points(&"life")
	assert_false(knowledge.erase_from_note(page, Vector2i.ZERO, rules), "Nota resolvida não se apaga")
	assert_eq(knowledge.points(&"life"), life_points, "Nem devolve pontos")
	assert_eq(knowledge.check_study(page, aspects), Knowledge.StudyCheck.ALREADY_STUDIED)


func test_study_needs_known_note_aspects_and_pages() -> void:
	var knowledge := _new()
	assert_eq(knowledge.check_study(_page(&"a"), aspects), Knowledge.StudyCheck.MISSING_ASPECT)
	knowledge = _knowing([&"water", &"plant"])
	assert_eq(knowledge.check_study(_page(&"b", [&"a"]), aspects), Knowledge.StudyCheck.MISSING_PAGE)
