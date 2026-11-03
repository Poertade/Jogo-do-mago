class_name Text
## Funções de texto da interface: nomes de aspectos e textos com aspectos citados.
## Os nomes dos aspectos vêm de locales/names.csv; num texto, "{fire}" vira o nome do aspecto fire
## e "{TERM_VIS}" vira o termo TERM_VIS (também de names.csv).


static func tr_key(key: String) -> String:
	return TranslationServer.translate(key)


## Nome exibido de um aspecto (ex.: fire → "Ignis").
static func aspect_name(aspect_id: StringName) -> String:
	var aspect: AspectData = Content.db.aspects.get(aspect_id)
	return tr_key(aspect.name_key) if aspect != null else String(aspect_id)


## Traduz `key` e troca cada {id_de_aspecto} pelo nome do aspecto e cada {TERMO} (em
## maiúsculas) pela tradução do termo.
static func expand(key: String) -> String:
	var text := tr_key(key)
	for aspect_id: StringName in Content.db.aspects:
		text = text.replace("{%s}" % aspect_id, aspect_name(aspect_id))
	var terms := RegEx.create_from_string("\\{([A-Z_]+)\\}")
	for found in terms.search_all(text):
		text = text.replace(found.get_string(0), tr_key(found.get_string(1)))
	return text


## Nome exibido de um escaneável (objetos podem citar termos, como {TERM_NODE}).
static func target_name(target: ScannableData) -> String:
	return expand(target.name_key)


## Lista de aspectos com quantidades e cores, em BBCode (para RichTextLabel).
## Ex.: "[color=#e0602a]Ignis 3[/color]"
static func aspect_amounts_bbcode(amounts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for aspect_id: StringName in amounts:
		parts.append(aspect_bbcode(aspect_id, tr_key("UI_ASPECT_AMOUNT") % [aspect_name(aspect_id), amounts[aspect_id]]))
	return "  ".join(parts)


## Um texto pintado com a cor do aspecto.
static func aspect_bbcode(aspect_id: StringName, text: String) -> String:
	var aspect: AspectData = Content.db.aspects.get(aspect_id)
	var color := aspect.color if aspect != null else Color.WHITE
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]
