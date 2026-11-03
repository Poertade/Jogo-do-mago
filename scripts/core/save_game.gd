class_name SaveGame
extends RefCounted
## Converte o conhecimento do jogador para o save (JSON legível) e de volta.
## O arquivo é user://save.json; quem lê e grava o arquivo é o autoload Game.

## Versão do formato. Ao mudar o formato, aumente e trate a versão antiga em _migrate().
const FORMAT_VERSION := 1


static func to_dict(knowledge: Knowledge) -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"knowledge": {
			"discovered_aspects": _to_strings(knowledge.discovered_aspects),
			"scanned_targets": _to_strings(knowledge.scanned_targets),
			"research_points": knowledge.research_points,
			"studied_pages": _to_strings(knowledge.studied_pages),
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
	var points = saved.get("research_points", 0)
	knowledge.research_points = maxi(int(points), 0) if (points is float or points is int) else 0
	return knowledge


## Atualiza saves de versões antigas para o formato atual. (Ainda só existe a versão 1.)
static func _migrate(data: Dictionary, _from_version: int) -> Dictionary:
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
