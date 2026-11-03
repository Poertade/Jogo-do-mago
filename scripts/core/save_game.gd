class_name SaveGame
extends RefCounted
## Converte o conhecimento do jogador para o save (JSON legível) e de volta.
## O arquivo é user://save.json; quem lê e grava o arquivo é o autoload Game.

## Versão do formato. Ao mudar o formato, aumente e trate a versão antiga em _migrate().
## 1: pontos de pesquisa num único total (até o M5).
## 2: pontos de pesquisa por aspecto (pesquisa no estilo do Thaumcraft 4).
## 3: notas de pesquisa em andamento.
const FORMAT_VERSION := 3


static func to_dict(knowledge: Knowledge) -> Dictionary:
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
		},
	}


static func to_json(knowledge: Knowledge) -> String:
	return JSON.stringify(to_dict(knowledge), "  ")


## Lê um save. Devolve null se o texto não for um save válido ou vier de uma versão mais nova.
static func from_json(text: String) -> Knowledge:
	# JSON.new().parse() só devolve um código de erro (parse_string registraria um erro no motor).
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return null
	return from_dict(json.data)


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
