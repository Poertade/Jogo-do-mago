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


func test_recipe_is_needed_to_combine_hidden_aspects() -> void:
	var rules := ResearchRules.new()
	rules.combine_cost = 1
	rules.combine_yield = 1
	var shadow := AspectData.new()
	shadow.id = &"darkness"
	shadow.kind = "compound"
	shadow.parents = [&"void", &"light"] as Array[StringName]
	shadow.needs_recipe = true
	var knowledge := Knowledge.new()
	knowledge.discovered_aspects.append_array([&"void", &"light"])
	knowledge.aspect_points = {&"void": 3, &"light": 3} as Dictionary[StringName, int]
	assert_eq(knowledge.check_combine(shadow, rules), Knowledge.CombineCheck.UNKNOWN_RECIPE)
	var book := BookData.new()
	book.id = &"treatise"
	book.teaches = [&"darkness"] as Array[StringName]
	assert_eq(knowledge.read_book(book), [&"darkness"] as Array[StringName])
	assert_true(knowledge.has_read(&"treatise"))
	assert_eq(knowledge.check_combine(shadow, rules), Knowledge.CombineCheck.OK)
	assert_eq(knowledge.read_book(book).size(), 0, "Ler de novo não ensina nada novo")


func test_books_and_recipes_survive_the_save() -> void:
	var knowledge := Knowledge.new()
	knowledge.books_read.append(&"treatise")
	knowledge.learned_recipes.append(&"darkness")
	var loaded := SaveGame.from_json(SaveGame.to_json(knowledge))
	assert_eq(loaded.books_read, [&"treatise"] as Array[StringName])
	assert_eq(loaded.learned_recipes, [&"darkness"] as Array[StringName])
	var old := SaveGame.from_dict({"format_version": 4, "knowledge": {"discovered_aspects": ["fire"]}})
	assert_eq(old.learned_recipes.size(), 0, "Saves antigos começam sem receitas")


func test_real_books_teach_every_hidden_recipe() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	var hidden := db.aspects.values().filter(func(a): return a.needs_recipe)
	assert_gt(hidden.size(), 0)
	for aspect: AspectData in hidden:
		assert_false(db.books_teaching(aspect.id).is_empty(), "Nenhum livro ensina %s" % aspect.id)
