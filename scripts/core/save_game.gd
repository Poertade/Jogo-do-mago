class_name SaveGame
extends RefCounted
## Converte o progresso do jogador para o save (JSON legível) e de volta: o conhecimento
## (Knowledge), o que ele mudou no mapa da Dungeon (DungeonProgress) e o que guarda na escola
## (Stash). O arquivo é user://save.json; quem lê e grava o arquivo é o autoload Game.

## Versão do formato. Ao mudar o formato, aumente e trate a versão antiga em _migrate().
## 1: pontos de pesquisa num único total (até o M5).
## 2: pontos de pesquisa por aspecto (pesquisa no estilo do Thaumcraft 4).
## 3: notas de pesquisa em andamento.
## 4: páginas só contam como estudadas com a nota resolvida (as de saves antigos reabrem).
## 5: livros lidos e receitas aprendidas.
## 6: o mapa fixo da Dungeon (atalhos, chaves, âncoras, chefes) e o que fica guardado na escola
##    (prata, cacos de vidro, potes).
const FORMAT_VERSION := 6


static func to_dict(knowledge: Knowledge, world: DungeonProgress = null, stash: Stash = null) -> Dictionary:
	var points := {}
	for aspect_id in knowledge.aspect_points:
		points[String(aspect_id)] = knowledge.aspect_points[aspect_id]
	# Notas: {"página": {"q,r": "aspecto"}}
	var notes := {}
	for page_id in knowledge.notes:
		var cells := {}
		for cell: Vector2i in knowledge.notes[page_id]:
			cells["%d,%d" % [cell.x, cell.y]] = String(knowledge.notes[page_id][cell])
		notes[String(page_id)] = cells
	return {
		"format_version": FORMAT_VERSION,
		"knowledge": {
			"discovered_aspects": _to_strings(knowledge.discovered_aspects),
			"aspect_points": points,
			"scanned_targets": _to_strings(knowledge.scanned_targets),
			"studied_pages": _to_strings(knowledge.studied_pages),
			"research_notes": notes,
			"books_read": _to_strings(knowledge.books_read),
			"learned_recipes": _to_strings(knowledge.learned_recipes),
		},
		"world": _world_to_dict(world if world != null else DungeonProgress.new()),
		"stash": _stash_to_dict(stash if stash != null else Stash.new()),
	}


static func to_json(knowledge: Knowledge, world: DungeonProgress = null, stash: Stash = null) -> String:
	return JSON.stringify(to_dict(knowledge, world, stash), "  ")


## Lê o texto de um save. Devolve um dicionário vazio se não for JSON de um objeto.
static func parse(text: String) -> Dictionary:
	# JSON.new().parse() só devolve um código de erro (parse_string registraria um erro no motor).
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	return json.data


## Lê o conhecimento de um save. Devolve null se o texto não for um save válido ou vier de uma
## versão mais nova.
static func from_json(text: String) -> Knowledge:
	var data := parse(text)
	return from_dict(data) if not data.is_empty() else null


## O mapa da Dungeon guardado no save (vazio em saves antigos, de antes do mapa fixo).
static func world_from_dict(data: Dictionary) -> DungeonProgress:
	var world := DungeonProgress.new()
	var saved = data.get("world", {})
	if saved is Dictionary:
		world.open_passages = _to_names(saved.get("open_passages", []))
		world.keys = _to_names(saved.get("keys", []))
		world.anchors = _to_names(saved.get("anchors", []))
		world.defeated = _to_names(saved.get("defeated", []))
	return world


## O que o jogador guarda na escola (vazio em saves antigos: começa sem potes).
static func stash_from_dict(data: Dictionary) -> Stash:
	var stash := Stash.new()
	var saved = data.get("stash", {})
	if saved is Dictionary:
		var items = saved.get("items", {})
		if items is Dictionary:
			for key in items:
				var value = items[key]
				if key is String and (value is float or value is int) and int(value) > 0:
					stash.items[StringName(key)] = int(value)
		var jars = saved.get("jars", 0)
		if jars is float or jars is int:
			stash.jars = maxi(int(jars), 0)
	return stash


static func _world_to_dict(world: DungeonProgress) -> Dictionary:
	return {
		"open_passages": _to_strings(world.open_passages),
		"keys": _to_strings(world.keys),
		"anchors": _to_strings(world.anchors),
		"defeated": _to_strings(world.defeated),
	}


static func _stash_to_dict(stash: Stash) -> Dictionary:
	var items := {}
	for item_id in stash.items:
		if stash.items[item_id] > 0:
			items[String(item_id)] = stash.items[item_id]
	return {"items": items, "jars": stash.jars}


static func from_dict(data: Dictionary) -> Knowledge:
	var version = data.get("format_version")
	if not (version is float or version is int) or int(version) > FORMAT_VERSION or int(version) < 1:
		return null
	data = _migrate(data, int(version))
	var saved = data.get("knowledge", {})
	if not saved is Dictionary:
		return null
	var knowledge := Knowledge.new()
	knowledge.discovered_aspects = _to_names(saved.get("discovered_aspects", []))
	knowledge.scanned_targets = _to_names(saved.get("scanned_targets", []))
	knowledge.studied_pages = _to_names(saved.get("studied_pages", []))
	# A versão 4 não tinha livros: os campos ficam vazios.
	knowledge.books_read = _to_names(saved.get("books_read", []))
	knowledge.learned_recipes = _to_names(saved.get("learned_recipes", []))
	var points = saved.get("aspect_points", {})
	if points is Dictionary:
		for key in points:
			var value = points[key]
			if key is String and (value is float or value is int) and int(value) > 0:
				knowledge.aspect_points[StringName(key)] = int(value)
	var notes = saved.get("research_notes", {})
	if notes is Dictionary:
		for page_id in notes:
			if not (page_id is String and notes[page_id] is Dictionary):
				continue
			var cells := {}
			for key in notes[page_id]:
				var parts: PackedStringArray = String(key).split(",")
				var aspect = notes[page_id][key]
				if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int() and aspect is String:
					cells[Vector2i(parts[0].to_int(), parts[1].to_int())] = StringName(aspect)
			knowledge.notes[StringName(page_id)] = cells
	return knowledge


## Atualiza saves de versões antigas para o formato atual.
static func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	if from_version < 2:
		# A versão 1 tinha um total único de pontos, que não tem como ser dividido entre
		# aspectos: ele é descartado. Os escaneamentos antigos também são esquecidos, para que
		# os objetos voltem a render pontos por aspecto. Aspectos e páginas são mantidos.
		var old: Dictionary = data.get("knowledge", {}) if data.get("knowledge") is Dictionary else {}
		data = {"format_version": 2, "knowledge": {
			"discovered_aspects": old.get("discovered_aspects", []),
			"aspect_points": {},
			"scanned_targets": [],
			"studied_pages": old.get("studied_pages", []),
		}}
	# A versão 2 não tinha notas de pesquisa: a 3 só acrescenta o campo (vazio).
	if from_version < 4:
		# Até a versão 3, uma página podia constar como estudada sem nota resolvida (era paga
		# direto com pontos, no sistema antigo). Agora só a nota resolvida estuda a página:
		# essas páginas voltam a ficar abertas, para o jogador resolver a nota.
		var saved = data.get("knowledge")
		if saved is Dictionary and saved.get("studied_pages") is Array:
			var notes = saved.get("research_notes", {})
			var kept := []
			for page_id in saved["studied_pages"]:
				if notes is Dictionary and notes.get(page_id) is Dictionary and not notes[page_id].is_empty():
					kept.append(page_id)
			saved["studied_pages"] = kept
	return data


static func _to_strings(names: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for item in names:
		result.append(String(item))
	return result


static func _to_names(values) -> Array[StringName]:
	var result: Array[StringName] = []
	if values is Array:
		for item in values:
			if item is String and not StringName(item) in result:
				result.append(StringName(item))
	return result
