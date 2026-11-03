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

	# Depois de tudo, ainda dá para estudar a página.
	var page := db.pages[&"fire_comprehension"]
	for aspect_id in page.cost:
		while knowledge.points(aspect_id) < page.cost[aspect_id]:
			if knowledge.points(aspect_id) > 0 and db.aspects[aspect_id].is_compound():
				var before := knowledge.points(aspect_id)
				if not knowledge.combine(db.aspects[aspect_id], db.research_rules) or knowledge.points(aspect_id) == before:
					break
			elif not _obtain_point(aspect_id):
				break
	assert_eq(knowledge.check_study(page), Knowledge.StudyCheck.OK, "A página deve ser alcançável")


func test_school_alone_unlocks_the_research_page() -> void:
	# Só com o que existe na escola (sem a Dungeon), a página já pode ser estudada.
	var dungeon_only := [&"damp_stone", &"rubble", &"rotten_desk", &"iron_bars", &"torch", &"arrival_glyph", &"pale_light"]
	for target: ScannableData in db.scannables.values():
		if not target.id in dungeon_only:
			knowledge.register_scan(target, db.aspects, db.research_rules)
	var page := db.pages[&"fire_comprehension"]
	for i in page.cost[&"energy"]:
		assert_true(_obtain_point_fresh(&"energy"), "Potentia combinável")
	assert_eq(knowledge.check_study(page), Knowledge.StudyCheck.OK)


## Combina mais um ponto do composto (mesmo que já haja pontos).
func _obtain_point_fresh(aspect_id: StringName) -> bool:
	var aspect: AspectData = db.aspects[aspect_id]
	for parent in aspect.parents:
		if knowledge.points(parent) < db.research_rules.combine_cost and not _obtain_point(parent):
			return false
	return knowledge.combine(aspect, db.research_rules)
