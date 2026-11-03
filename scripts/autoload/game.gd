extends Node
## Autoload "Game": o estado do jogador que atravessa salas e mortes.
## - knowledge: o progresso permanente, gravado em user://save.json a cada descoberta;
## - modifiers: os efeitos das páginas estudadas;
## - run: a incursão atual (vida, Vis da varinha, roteiro de salas), reiniciada ao morrer;
## - rng: o gerador com semente (definido pela cena principal), que sorteia cada incursão.
## Também serve de "central de avisos" entre o mundo e a interface (sinais abaixo).

## Um objeto do mundo pediu uma tela (ex.: &"research_table").
signal screen_requested(screen: StringName)
## Um escaneamento terminou.
signal scan_completed(result: ScanResult)
## Uma página foi estudada.
signal page_studied(page: ResearchPageData)
## Dois aspectos foram combinados na Mesa (`discovered`: o composto era novo).
signal aspect_combined(compound: AspectData, discovered: bool)
## Um aviso curto para o HUD.
signal message_requested(text: String, color: Color)
## Um portal ou saída pediu para ir a outra sala.
signal travel_requested(room_id: StringName, entrance_id: StringName)
## O jogador tomou dano / morreu.
signal player_damaged(amount: float)
signal player_died
## A incursão foi sorteada: a cena principal monta a Dungeon (com transição).
signal dungeon_requested(plan: DungeonPlan)
## O jogador entrou numa região nova da Dungeon (o HUD mostra o nome dela).
signal zone_entered(zone: StringName)
## Um inimigo notou o jogador: os que estão perto acordam também.
signal enemy_alerted(at: Vector3)
## Barulho (uma magia lançada): acorda os inimigos até `radius` metros.
signal noise_made(at: Vector3, radius: float)
## Um chefe notou o jogador (o HUD mostra a barra de vida dele).
signal boss_engaged(enemy: Node3D)
## Um texto pronto para ler (título e corpo já traduzidos), como um livro com as receitas.
signal text_requested(title: String, body: String)
## Um texto para ler (placa, anotação), com título e corpo (chaves de tradução).
signal note_requested(title_key: String, body_key: String)

const SAVE_PATH := "user://save.json"

var knowledge: Knowledge
var modifiers := Modifiers.new()
var run: RunState
var rng := GameRng.new(0)


func _ready() -> void:
	knowledge = _load_save()
	# As receitas dos compostos simples já vêm sabidas (não vão para o save).
	knowledge.free_recipes = Content.db.free_recipes()
	knowledge.changed.connect(_on_knowledge_changed)
	_update_modifiers()
	run = RunState.new(Content.db.player)


## Pede a troca de sala (quem faz a transição é a cena principal).
func travel(room_id: StringName, entrance_id: StringName) -> void:
	travel_requested.emit(room_id, entrance_id)


## Começa uma incursão: sorteia o roteiro de salas (com uma semente tirada do gerador do jogo)
## e pede a montagem da Dungeon.
func start_dungeon() -> void:
	var incursion_seed := rng.range_int(0, 2147483646)
	var plan := DungeonPlan.generate(Content.db.dungeon_rules, Content.db.rooms_by_slot(), incursion_seed)
	print("Incursão: semente %d, salas %s" % [incursion_seed, plan.rooms])
	run.start_dungeon(plan)
	dungeon_requested.emit(plan)


## Sai da Dungeon pela última sala: volta à escola (os livros achados vão junto).
func finish_dungeon() -> void:
	var rules := Content.db.dungeon_rules
	travel(rules.return_room, rules.return_entrance)


## Aplica dano no jogador. Na vida zero, avisa a morte (uma vez).
func damage_player(amount: float) -> void:
	if run.health.is_dead():
		return
	var applied := run.health.take_damage(amount)
	if applied > 0.0:
		player_damaged.emit(applied)
	if run.health.is_dead():
		player_died.emit()


## Mostra um aviso curto no HUD.
func message(text: String, color := Color(0.9, 0.86, 0.78)) -> void:
	message_requested.emit(text, color)


## Alvos que a Lente analisou sem conseguir escanear (por falta de um aspecto composto) nesta
## sessão: o HUD mostra a composição deles, com "?" no que falta descobrir.
var analyzed_targets: Dictionary[StringName, bool] = {}


## Registra um escaneamento completo e avisa a interface.
func complete_scan(target: ScannableData) -> ScanResult:
	var result := knowledge.register_scan(target, Content.db.aspects, Content.db.research_rules)
	if result.blocked:
		analyzed_targets[target.id] = true
	scan_completed.emit(result)
	return result


## Combina os pais de um aspecto composto na Mesa de Pesquisa.
func combine(compound: AspectData) -> bool:
	var was_known := knowledge.knows_aspect(compound.id)
	if not knowledge.combine(compound, Content.db.research_rules):
		return false
	aspect_combined.emit(compound, not was_known)
	return true


## Escreve um aspecto num hexágono da nota de pesquisa da página.
func write_on_note(page: ResearchPageData, cell: Vector2i, aspect_id: StringName) -> bool:
	return knowledge.write_on_note(page, cell, aspect_id, Content.db.research_rules)


## Apaga um aspecto da nota (os pontos voltam).
func erase_from_note(page: ResearchPageData, cell: Vector2i) -> bool:
	return knowledge.erase_from_note(page, cell, Content.db.research_rules)


## Estuda uma página (a nota precisa estar completa) e avisa a interface.
func study(page: ResearchPageData) -> bool:
	var foci_before := available_foci().size()
	if not knowledge.study(page, Content.db.aspects):
		return false
	page_studied.emit(page)
	var foci := available_foci()
	if foci.size() > foci_before:
		message(Text.tr_key("UI_MSG_FOCUS_UNLOCKED") % Text.tr_key(foci.back().name_key), Color(0.7, 0.85, 1.0))
	return true


## Despeja na varinha um pote do cinto (tecla R): primeiro os aspectos que o Focus encaixado
## gasta, depois qualquer um que caiba. Devolve quanto Vis entrou.
func pour_jar() -> int:
	var wanted: Array = run.caster.focus.cost.keys()
	for aspect_id in run.wand.wand.aspects:
		if not aspect_id in wanted:
			wanted.append(aspect_id)
	var poured := run.jars.pour_into(run.wand, wanted)
	if poured > 0:
		Audio.play(&"recharge")
		message(Text.tr_key("UI_MSG_JAR_POURED") % poured)
	else:
		message(Text.tr_key("UI_MSG_NO_JAR"))
	return poured


## Guarda um livro achado na Dungeon (lido só no atril da escola).
func take_book(book: BookData) -> void:
	if run.carry_book(book):
		message(Text.tr_key("UI_MSG_BOOK_TAKEN") % Text.tr_key(book.name_key), Color(0.95, 0.85, 0.6))


## Lê o próximo livro trazido: aprende uma receita sorteada entre as que o jogador ainda não
## conhece e mostra o texto do livro, com a receita no fim.
func read_next_book() -> void:
	if run.carried_books.is_empty():
		return
	var book: BookData = run.carried_books.pop_front()
	var learned := knowledge.read_book(book, Content.db.aspects, rng.next_float())
	var body := Text.expand(book.text_key) + "\n\n"
	if learned == &"":
		body += Text.tr_key("UI_BOOK_NOTHING_NEW")
	else:
		var aspect: AspectData = Content.db.aspects[learned]
		body += Text.tr_key("UI_RECIPE_LEARNED") % [Text.aspect_name(learned),
			Text.aspect_name(aspect.parents[0]), Text.aspect_name(aspect.parents[1])]
	text_requested.emit(Text.tr_key(book.name_key), body)


## Os Focus que o jogador pode usar: o inicial e os liberados por páginas estudadas.
func available_foci() -> Array[FocusData]:
	var foci: Array[FocusData] = [Content.db.player.starting_focus]
	for focus in modifiers.unlocked_foci:
		if not focus in foci:
			foci.append(focus)
	return foci


## Troca para o próximo Focus disponível (tecla Q). Devolve false se só houver um.
func cycle_focus() -> bool:
	var foci := available_foci()
	if foci.size() < 2:
		return false
	var index := foci.find(run.caster.focus)
	run.caster.equip(foci[(index + 1) % foci.size()])
	message(Text.tr_key("UI_MSG_FOCUS_EQUIPPED") % Text.tr_key(run.caster.focus.name_key))
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
