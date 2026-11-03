extends GutTest
## Testes da descoberta de aspectos, dos pontos de pesquisa e do estudo de páginas.

var rules: ResearchRules


func before_each() -> void:
	rules = ResearchRules.new()
	rules.points_per_new_aspect = 1
	rules.points_per_new_target = 0


func _target(id: StringName, aspects: Dictionary) -> ScannableData:
	var target := ScannableData.new()
	target.id = id
	var typed: Dictionary[StringName, int] = {}
	for key in aspects:
		typed[key] = aspects[key]
	target.aspects = typed
	return target


func _page(id: StringName, cost: int, required_aspects: Array[StringName] = [], required_pages: Array[StringName] = []) -> ResearchPageData:
	var page := ResearchPageData.new()
	page.id = id
	page.cost = cost
	page.required_aspects = required_aspects
	page.required_pages = required_pages
	return page


func test_first_scan_discovers_aspects_and_gives_points() -> void:
	var knowledge := Knowledge.new()
	var result := knowledge.register_scan(_target(&"candle", {&"fire": 3}), rules)
	assert_true(result.new_target)
	assert_eq(result.new_aspects, [&"fire"] as Array[StringName])
	assert_eq(result.points, 1)
	assert_true(knowledge.knows_aspect(&"fire"))
	assert_true(knowledge.has_scanned(&"candle"))
	assert_eq(knowledge.research_points, 1)


func test_one_point_per_new_aspect() -> void:
	var knowledge := Knowledge.new()
	var result := knowledge.register_scan(_target(&"enemy", {&"entropy": 3, &"earth": 1}), rules)
	assert_eq(result.points, 2)
	assert_eq(knowledge.research_points, 2)


func test_scanning_again_gives_nothing() -> void:
	var knowledge := Knowledge.new()
	var candle := _target(&"candle", {&"fire": 3})
	knowledge.register_scan(candle, rules)
	var again := knowledge.register_scan(candle, rules)
	assert_false(again.discovered_something())
	assert_eq(again.points, 0)
	assert_eq(knowledge.research_points, 1)


func test_new_target_with_known_aspects_gives_only_target_points() -> void:
	rules.points_per_new_target = 2
	var knowledge := Knowledge.new()
	knowledge.register_scan(_target(&"candle", {&"fire": 3}), rules)
	var brazier := knowledge.register_scan(_target(&"brazier", {&"fire": 3}), rules)
	assert_true(brazier.new_target)
	assert_eq(brazier.new_aspects.size(), 0)
	assert_eq(brazier.points, 2)


func test_changed_is_emitted_only_on_discovery() -> void:
	var knowledge := Knowledge.new()
	watch_signals(knowledge)
	var candle := _target(&"candle", {&"fire": 3})
	knowledge.register_scan(candle, rules)
	knowledge.register_scan(candle, rules)
	assert_signal_emit_count(knowledge, "changed", 1)


func test_study_spends_points_and_records_page() -> void:
	var knowledge := Knowledge.new()
	knowledge.research_points = 5
	knowledge.discovered_aspects.append(&"fire")
	var page := _page(&"fire_comprehension", 3, [&"fire"])
	assert_eq(knowledge.check_study(page), Knowledge.StudyCheck.OK)
	assert_true(knowledge.study(page))
	assert_eq(knowledge.research_points, 2)
	assert_true(knowledge.has_studied(&"fire_comprehension"))
	assert_eq(knowledge.check_study(page), Knowledge.StudyCheck.ALREADY_STUDIED)
	assert_false(knowledge.study(page))
	assert_eq(knowledge.research_points, 2)


func test_study_needs_points() -> void:
	var knowledge := Knowledge.new()
	knowledge.research_points = 2
	var page := _page(&"page", 3)
	assert_eq(knowledge.check_study(page), Knowledge.StudyCheck.NOT_ENOUGH_POINTS)
	assert_false(knowledge.study(page))
	assert_eq(knowledge.research_points, 2)


func test_study_needs_required_aspect_and_page() -> void:
	var knowledge := Knowledge.new()
	knowledge.research_points = 10
	assert_eq(knowledge.check_study(_page(&"a", 1, [&"fire"])), Knowledge.StudyCheck.MISSING_ASPECT)
	assert_eq(knowledge.check_study(_page(&"b", 1, [], [&"a"])), Knowledge.StudyCheck.MISSING_PAGE)
