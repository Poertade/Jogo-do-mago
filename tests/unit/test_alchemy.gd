extends GutTest
## Testes do M9 (alquimia): o cadinho desfaz materiais em essência, a essência vira pontos de
## pesquisa ou paga receitas, os elixires curam, e tudo vai para o save (formato 8).


func _item(id: StringName, aspects: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.aspects.assign(aspects)
	return item


func test_dissolving_turns_a_material_into_essence() -> void:
	var stash := Stash.new()
	stash.add({&"bone": 2})
	var crucible := Crucible.new()
	var bone := _item(&"bone", {&"death": 1, &"earth": 2})
	assert_true(crucible.dissolve(bone, stash))
	assert_eq(crucible.amount(&"death"), 1)
	assert_eq(crucible.amount(&"earth"), 2)
	assert_eq(stash.count(&"bone"), 1, "Uma unidade sai do que está guardado")
	assert_true(crucible.dissolve(bone, stash))
	assert_false(crucible.dissolve(bone, stash), "Sem osso guardado, nada a dissolver")
	assert_eq(crucible.amount(&"earth"), 4)


func test_materials_without_aspects_do_not_dissolve() -> void:
	var stash := Stash.new()
	stash.add({&"archivist_seal": 1})
	assert_false(Crucible.new().dissolve(_item(&"archivist_seal", {}), stash))
	assert_eq(stash.count(&"archivist_seal"), 1)


func test_essence_is_spent_all_or_nothing() -> void:
	var crucible := Crucible.new()
	crucible.essentia = {&"life": 3, &"water": 1} as Dictionary[StringName, int]
	assert_eq(crucible.missing({&"life": 3, &"water": 2}), {&"water": 1})
	assert_false(crucible.spend({&"life": 3, &"water": 2}))
	assert_eq(crucible.amount(&"life"), 3)
	assert_true(crucible.spend({&"life": 2, &"water": 1}))
	assert_eq(crucible.essentia, {&"life": 1} as Dictionary[StringName, int], "Aspecto zerado sai do cadinho")


func test_noting_essence_gives_research_points_only_for_known_aspects() -> void:
	var knowledge := Knowledge.new()
	knowledge.discovered_aspects.append(&"fire")
	assert_true(knowledge.add_points(&"fire", 4))
	assert_eq(knowledge.points(&"fire"), 4)
	assert_false(knowledge.add_points(&"mind", 2), "Aspecto não descoberto não ganha pontos")
	var crucible := Crucible.new()
	crucible.essentia = {&"fire": 5} as Dictionary[StringName, int]
	assert_eq(crucible.take_all(&"fire"), 5)
	assert_eq(crucible.amount(&"fire"), 0)


func test_elixirs_respect_the_limit_and_heal() -> void:
	var stash := Stash.new()
	for i in 3:
		stash.add_elixir(&"victus_elixir", 2)
	assert_eq(stash.elixir_total(), 2, "Leva no máximo 2")
	assert_true(stash.use_elixir(&"victus_elixir"))
	assert_eq(stash.elixir_total(), 1)
	var health := Health.new(100)
	health.take_damage(70)
	assert_eq(health.heal(40), 40.0)
	assert_eq(health.heal(40), 30.0, "Não passa do máximo")
	assert_eq(health.current, 100.0)


func test_crucible_and_elixirs_survive_the_save() -> void:
	var stash := Stash.new()
	stash.add_elixir(&"victus_elixir", 5)
	var crucible := Crucible.new()
	crucible.essentia = {&"life": 3, &"fire": 2} as Dictionary[StringName, int]
	var data := SaveGame.parse(SaveGame.to_json(Knowledge.new(), null, stash, crucible))
	assert_eq(int(data["format_version"]), 8)
	assert_eq(SaveGame.crucible_from_dict(data).essentia, crucible.essentia)
	assert_eq(SaveGame.stash_from_dict(data).elixirs, {&"victus_elixir": 1} as Dictionary[StringName, int])
	assert_true(SaveGame.crucible_from_dict({"format_version": 7}).essentia.is_empty(), "Saves antigos: cadinho vazio")


## Toda receita pode ser feita com a essência de materiais que existem no jogo.
func test_real_recipes_use_aspects_that_materials_give() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))
	var given := {}
	for item: ItemData in db.items.values():
		for aspect_id in item.aspects:
			given[aspect_id] = true
	assert_false(db.recipes.is_empty())
	for recipe: AlchemyRecipeData in db.recipes.values():
		for aspect_id in recipe.cost:
			assert_true(aspect_id in given, "A receita %s pede %s, que nenhum material dá" % [recipe.id, aspect_id])
	var elixir: AlchemyRecipeData = db.recipes[&"victus_elixir"]
	assert_eq(elixir.elixir.heal, 40.0)
	assert_gt(db.player.max_elixirs, 0)
