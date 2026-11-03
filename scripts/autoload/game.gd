extends Node
## Autoload "Game": o estado do jogador que atravessa salas e mortes.
## - knowledge: o progresso permanente, gravado em user://save.json a cada descoberta;
## - modifiers: os efeitos das páginas estudadas.
## Também serve de "central de avisos" entre o mundo e a interface (sinais abaixo).

## Um objeto do mundo pediu uma tela (ex.: &"research_table").
signal screen_requested(screen: StringName)
## Um escaneamento terminou.
signal scan_completed(result: ScanResult)
## Uma página foi estudada.
signal page_studied(page: ResearchPageData)

const SAVE_PATH := "user://save.json"

var knowledge: Knowledge
var modifiers := Modifiers.new()


func _ready() -> void:
	knowledge = _load_save()
	knowledge.changed.connect(_on_knowledge_changed)
	_update_modifiers()


## Registra um escaneamento completo e avisa a interface.
func complete_scan(target: ScannableData) -> ScanResult:
	var result := knowledge.register_scan(target, Content.db.research_rules)
	scan_completed.emit(result)
	return result


## Estuda uma página, se possível, e avisa a interface.
func study(page: ResearchPageData) -> bool:
	if not knowledge.study(page):
		return false
	page_studied.emit(page)
	return true


func _on_knowledge_changed() -> void:
	_update_modifiers()
	save()


func _update_modifiers() -> void:
	modifiers = Modifiers.from_pages(Content.db.pages_by_id(knowledge.studied_pages))


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível gravar o save em %s." % SAVE_PATH)
		return
	file.store_string(SaveGame.to_json(knowledge))


func _load_save() -> Knowledge:
	if not FileAccess.file_exists(SAVE_PATH):
		return Knowledge.new()
	var loaded := SaveGame.from_json(FileAccess.get_file_as_string(SAVE_PATH))
	if loaded == null:
		# Save corrompido ou de uma versão mais nova: guarda uma cópia e começa do zero.
		var backup := SAVE_PATH + ".bak"
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(backup))
		push_warning("Save inválido; cópia guardada em %s. Começando do zero." % backup)
		return Knowledge.new()
	return loaded
