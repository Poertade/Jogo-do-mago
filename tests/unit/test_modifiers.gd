extends GutTest
## Testes dos efeitos permanentes das páginas estudadas.


func _page_with_multiplier(element: StringName, value: float) -> ResearchPageData:
	var effect := PageEffect.new()
	effect.type = PageEffect.DAMAGE_MULTIPLIER
	effect.element = element
	effect.value = value
	var page := ResearchPageData.new()
	var effects: Array[PageEffect] = [effect]
	page.effects = effects
	return page


func test_no_pages_means_no_change() -> void:
	assert_eq(Modifiers.from_pages([]).damage_multiplier(&"fire"), 1.0)


func test_fire_comprehension_gives_twenty_percent() -> void:
	var pages: Array[ResearchPageData] = [_page_with_multiplier(&"fire", 1.2)]
	var modifiers := Modifiers.from_pages(pages)
	assert_almost_eq(modifiers.damage_multiplier(&"fire"), 1.2, 0.0001)
	assert_eq(modifiers.damage_multiplier(&"water"), 1.0)


func test_multipliers_stack_by_multiplication() -> void:
	var pages: Array[ResearchPageData] = [_page_with_multiplier(&"fire", 1.2), _page_with_multiplier(&"fire", 1.2)]
	assert_almost_eq(Modifiers.from_pages(pages).damage_multiplier(&"fire"), 1.44, 0.0001)
