extends GutTest
## Garante que a pesquisa tem solução com o conteúdo de data/: escaneando tudo o que dá e
## combinando aspectos na Mesa, todos os objetos e inimigos podem ser escaneados e a página
## "Compreensão de Ignis" pode ser estudada. Se este teste falhar depois de adicionar
## conteúdo, faltam pontos de algum aspecto: acrescente objetos que o rendam.

var db: ContentDB
var knowledge: Knowledge


func before_each() -> void:
	db = ContentDB.new()
	db.load_all()
	knowledge = Knowledge.new()
	# Os livros das receitas escondidas são achados na Dungeon: aqui, todos já foram lidos.
	for book: BookData in db.books.values():
		knowledge.read_book(book)


## Garante 1 ponto do aspecto (e que ele seja conhecido), combinando o que for preciso.
func _obtain_point(aspect_id: StringName, depth := 0) -> bool:
	if knowledge.points(aspect_id) > 0 and knowledge.knows_aspect(aspect_id):
		return true
	var aspect: AspectData = db.aspects.get(aspect_id)
	if aspect == null or not aspect.is_compound() or depth > 12:
		return false
	for parent in aspect.parents:
		if not _obtain_point(parent, depth + 1):
			return false
	return knowledge.combine(aspect, db.research_rules)


func _all_targets() -> Array[ScannableData]:
	var targets: Array[ScannableData] = []
	targets.assign(db.scannables.values())
	targets.append_array(db.enemies.values())
	return targets


func _scan_everything_possible() -> bool:
	var progressed := false
	for target in _all_targets():
		if not knowledge.has_scanned(target.id):
			var result := knowledge.register_scan(target, db.aspects, db.research_rules)
			progressed = progressed or result.new_target
	return progressed


func test_everything_can_eventually_be_scanned() -> void:
	for round in 200:
		var progressed := _scan_everything_possible()
		var pending: Array[ScannableData] = []
		for target in _all_targets():
			if not knowledge.has_scanned(target.id):
				pending.append(target)
		if pending.is_empty():
			break
		if not progressed:
			var discovered := false
			for target in pending:
				for missing in knowledge.missing_aspects(target, db.aspects):
					if _obtain_point(missing):
						discovered = true
						break
				if discovered:
					break
			if not discovered:
				break
	var stuck: PackedStringArray = []
	for target in _all_targets():
		if not knowledge.has_scanned(target.id):
			stuck.append("%s (faltam %s)" % [target.id, knowledge.missing_aspects(target, db.aspects)])
	assert_eq(stuck, PackedStringArray(), "Alvos impossíveis de escanear com os pontos disponíveis")

	# Depois de tudo, ainda dá para resolver a nota da página e estudá-la.
	_solve_note(db.pages[&"fire_comprehension"])


## Resolve a nota da página como um jogador faria: descobre os aspectos dela que faltam e liga
## os alvos com as correntes mais curtas, escrevendo (e pagando) cada aspecto.
func _solve_note(page: ResearchPageData) -> void:
	for aspect_id in page.note_aspects:
		if not knowledge.knows_aspect(aspect_id):
			assert_true(_obtain_point(aspect_id), "Descobrir %s para a nota" % aspect_id)
	var note := knowledge.note_for(page)
	var targets: Array = note.targets.keys()
	for i in range(1, targets.size()):
		note = knowledge.note_for(page)
		var network: Array[Vector2i] = []
		for cell in note.connected_cells(targets[0], db.aspects):
			network.append(cell)
		if targets[i] in network:
			continue
		var allowed: Array[StringName] = []
		for aspect_id in knowledge.discovered_aspects:
			if knowledge.points(aspect_id) > 0:
				allowed.append(aspect_id)
		var chain := note.find_chain(targets[i], network, allowed, db.aspects)
		assert_false(chain.is_empty(), "Corrente até o alvo %s" % note.targets[targets[i]])
		for cell in chain:
			# Um aspecto pode aparecer várias vezes na corrente: combina mais pontos se faltar.
			assert_true(_obtain_point(chain[cell]), "Pontos de %s" % chain[cell])
			assert_true(knowledge.write_on_note(page, cell, chain[cell], db.research_rules), "Escrever %s" % chain[cell])
	assert_eq(knowledge.check_study(page, db.aspects), Knowledge.StudyCheck.OK, "A nota deve ficar completa")


func test_school_alone_unlocks_the_research_page() -> void:
	# Só com o que existe na escola (sem a Dungeon), a página já pode ser estudada.
	var dungeon_only := [&"damp_stone", &"rubble", &"rotten_desk", &"iron_bars", &"torch", &"arrival_glyph", &"pale_light"]
	for target: ScannableData in db.scannables.values():
		if not target.id in dungeon_only:
			knowledge.register_scan(target, db.aspects, db.research_rules)
	_solve_note(db.pages[&"fire_comprehension"])
