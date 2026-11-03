extends GutTest
## Testes da nota de pesquisa (grade de hexágonos, ligações entre aspectos pai e filho).

var aspects: Dictionary = {}


func _aspect(id: StringName, parents: Array[StringName] = []) -> void:
	var aspect := AspectData.new()
	aspect.id = id
	aspect.kind = "compound" if parents.size() == 2 else "primal"
	aspect.parents = parents
	aspects[id] = aspect


func before_each() -> void:
	aspects.clear()
	for id in [&"fire", &"water", &"earth", &"air", &"order", &"entropy"]:
		_aspect(id)
	_aspect(&"light", [&"air", &"fire"])
	_aspect(&"energy", [&"order", &"fire"])
	_aspect(&"life", [&"water", &"earth"])


func _page(note_aspects: Array[StringName], radius: int) -> ResearchPageData:
	var page := ResearchPageData.new()
	page.id = &"p"
	page.note_aspects = note_aspects
	page.note_radius = radius
	return page


func test_grid_sizes() -> void:
	var note := ResearchNote.for_page(_page([&"fire", &"light"], 2))
	assert_eq(note.cells().size(), 19, "Raio 2: 1 + 6 + 12 hexágonos")
	assert_eq(note.ring(2).size(), 12)
	assert_eq(ResearchNote.distance(Vector2i(2, -1), Vector2i(-1, 1)), 3)


func test_targets_go_on_the_border() -> void:
	var note := ResearchNote.for_page(_page([&"fire", &"energy", &"light"], 2))
	assert_eq(note.targets.size(), 3)
	for cell in note.targets:
		assert_eq(ResearchNote.distance(cell, Vector2i.ZERO), 2)


func test_parent_and_child_are_related_but_not_siblings_or_same() -> void:
	assert_true(ResearchNote.related(&"fire", &"light", aspects))
	assert_true(ResearchNote.related(&"light", &"air", aspects))
	assert_false(ResearchNote.related(&"light", &"energy", aspects), "Irmãos (ambos filhos de Ignis) não ligam")
	assert_false(ResearchNote.related(&"fire", &"fire", aspects), "O mesmo aspecto não liga")


func test_chain_through_shared_parent_completes_the_note() -> void:
	# Potentia e Lux em lados opostos; Ignis no meio é pai dos dois.
	var note := ResearchNote.for_page(_page([&"energy", &"light"], 1))
	assert_false(note.is_complete(aspects))
	note.placed[Vector2i.ZERO] = &"fire"
	assert_true(note.is_complete(aspects))
	assert_eq(note.links(aspects).size(), 2)


func test_find_chain_builds_a_valid_path() -> void:
	var note := ResearchNote.for_page(_page([&"energy", &"light", &"order"], 2))
	var cells: Array = note.targets.keys()
	var allowed: Array[StringName] = [&"fire", &"water", &"earth", &"air", &"order", &"entropy", &"light", &"energy", &"life"]
	for i in range(1, cells.size()):
		var network: Array[Vector2i] = []
		for cell in note.connected_cells(cells[0], aspects):
			network.append(cell)
		var chain := note.find_chain(cells[i], network, allowed, aspects)
		assert_false(chain.is_empty(), "Deve haver caminho até o alvo %d" % i)
		for cell in chain:
			note.placed[cell] = chain[cell]
	assert_true(note.is_complete(aspects))
