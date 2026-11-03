extends GutTest
## Testes dos potes de Vis (cinto) e dos livros que ensinam receitas escondidas.

var wand_data: WandData


func before_each() -> void:
	wand_data = WandData.new()
	wand_data.aspects = [&"fire", &"water", &"order"] as Array[StringName]
	wand_data.capacity = 30
	wand_data.aspect_capacity = 10
	wand_data.efficiency = 1.0


func test_store_fills_same_aspect_first_then_empty_jars() -> void:
	var belt := VisJarBelt.new(3, 10)
	assert_eq(belt.store(&"fire", 7), 7)
	assert_eq(belt.store(&"fire", 6), 6, "Completa o pote de Ignis e abre outro")
	assert_eq(belt.jars[0].amount, 10)
	assert_eq(belt.jars[1].aspect, &"fire")
	assert_eq(belt.jars[1].amount, 3)
	assert_eq(belt.store(&"water", 15), 10, "Só sobrou um pote vazio")
	assert_eq(belt.total(&"fire"), 13)
	assert_false(belt.has_room_for(&"order"))
	assert_true(belt.has_room_for(&"fire"))


func test_pour_refills_the_wand_and_keeps_the_rest() -> void:
	var belt := VisJarBelt.new(3, 10)
	belt.store(&"fire", 10)
	var wand := WandState.new(wand_data, {&"fire": 4})
	assert_eq(belt.pour_into(wand, [&"fire"]), 6, "Só cabem 6 no recipiente de Ignis")
	assert_eq(wand.reserve(&"fire"), 10)
	assert_eq(belt.total(&"fire"), 4, "O resto fica no pote")
	assert_eq(belt.pour_into(wand, [&"fire"]), 0, "Varinha cheia: nada a despejar")


func test_pour_picks_a_jar_the_focus_uses() -> void:
	var belt := VisJarBelt.new(3, 10)
	belt.store(&"fire", 5)
	belt.store(&"order", 5)
	var wand := WandState.new(wand_data, {&"water": 10})
	assert_eq(belt.pour_into(wand, [&"water", &"order"]), 5, "Aqua cheia: despeja o Ordo")
	assert_eq(wand.reserve(&"order"), 5)
	assert_eq(belt.total(&"fire"), 5, "O Ignis não foi tocado")
	assert_eq(belt.jars[1].aspect, &"", "Pote vazio fica livre para outro aspecto")


## Aspectos de teste: Aqua e Terra (primais), Victus = Aqua + Terra, Herba = Terra + Victus.
func _aspects() -> Dictionary:
	var result := {}
	for spec in [["water", []], ["earth", []], ["life", ["water", "earth"]], ["plant", ["earth", "life"]]]:
		var aspect := AspectData.new()
		aspect.id = StringName(spec[0])
		aspect.kind = "compound" if not spec[1].is_empty() else "primal"
		aspect.parents.assign(spec[1].map(func(p): return StringName(p)))
		result[aspect.id] = aspect
	return result


func test_combining_needs_the_recipe() -> void:
	var rules := ResearchRules.new()
	rules.combine_cost = 1
	rules.combine_yield = 1
	var aspects := _aspects()
	var knowledge := Knowledge.new()
	knowledge.discovered_aspects.append_array([&"water", &"earth"])
	knowledge.aspect_points = {&"water": 3, &"earth": 3} as Dictionary[StringName, int]
	assert_eq(knowledge.check_combine(aspects[&"life"], rules), Knowledge.CombineCheck.UNKNOWN_RECIPE)
	knowledge.free_recipes = [&"life"] as Array[StringName]
	assert_eq(knowledge.check_combine(aspects[&"life"], rules), Knowledge.CombineCheck.OK, "Receita simples já vem sabida")
	assert_true(knowledge.combine(aspects[&"life"], rules))
	knowledge.free_recipes.clear()
	assert_true(knowledge.knows_recipe(&"life"), "Quem descobriu o aspecto conhece a receita")


func test_book_teaches_a_recipe_you_do_not_have() -> void:
	var aspects := _aspects()
	var book := BookData.new()
	book.id = &"notes"
	var knowledge := Knowledge.new()
	assert_eq(knowledge.unknown_recipes(aspects), [&"life", &"plant"] as Array[StringName])
	var first := knowledge.read_book(book, aspects, 0.0)
	assert_true(first in [&"life", &"plant"])
	assert_true(knowledge.knows_recipe(first))
	var second := knowledge.read_book(book, aspects, 0.99)
	assert_ne(second, first, "O segundo livro ensina outra receita")
	assert_eq(knowledge.read_book(book, aspects, 0.5), &"", "Sem receitas novas, nada a aprender")
	assert_eq(knowledge.books_read, [&"notes"] as Array[StringName])


func test_book_prefers_a_recipe_you_can_make_now() -> void:
	var aspects := _aspects()
	var knowledge := Knowledge.new()
	knowledge.discovered_aspects.append_array([&"water", &"earth"])
	# Victus dá para fazer já (pais descobertos); Herba precisa de Victus antes.
	for roll in [0.0, 0.5, 0.99]:
		var copy := Knowledge.new()
		copy.discovered_aspects = knowledge.discovered_aspects.duplicate()
		assert_eq(copy.read_book(BookData.new(), aspects, roll), &"life")


func test_books_and_recipes_survive_the_save() -> void:
	var knowledge := Knowledge.new()
	knowledge.books_read.append(&"treatise")
	knowledge.learned_recipes.append(&"darkness")
	var loaded := SaveGame.from_json(SaveGame.to_json(knowledge))
	assert_eq(loaded.books_read, [&"treatise"] as Array[StringName])
	assert_eq(loaded.learned_recipes, [&"darkness"] as Array[StringName])
	var old := SaveGame.from_dict({"format_version": 4, "knowledge": {"discovered_aspects": ["fire"]}})
	assert_eq(old.learned_recipes.size(), 0, "Saves antigos começam sem receitas")


func test_simple_recipes_are_free_and_every_zone_has_books() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	var free := db.free_recipes()
	assert_true(&"energy" in free and &"light" in free, "Compostos de dois primais já vêm sabidos")
	assert_false(&"tree" in free, "Arbor precisa de livro")
	for step in db.dungeon_rules.steps:
		assert_false(db.books_in(step.zone).is_empty(), "Região %s sem livros" % step.zone)
