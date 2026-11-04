extends Node
## Autoload "Game": o estado do jogador que atravessa salas e mortes.
## - knowledge: o conhecimento, progresso permanente, gravado em user://save.json a cada mudança;
## - world: o que o jogador já mudou no mapa da Dungeon (atalhos, chaves, âncoras), também salvo;
## - stash: o que ele guarda na escola (prata, cacos de vidro, potes), também salvo;
## - modifiers: os efeitos das páginas estudadas;
## - run: a incursão atual (vida, Vis, achados), reiniciada ao morrer;
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
## Uma incursão começou: a cena principal monta a Dungeon (com transição), com inimigos e achados
## sorteados por `incursion_seed`, e põe o jogador na âncora `anchor_id`.
signal dungeon_requested(incursion_seed: int, anchor_id: StringName)
## O jogador entrou numa região nova da Dungeon (o HUD mostra o nome dela).
signal zone_entered(zone: StringName)
## O jogador entrou numa sala (o HUD mostra o nome dela no canto, na Dungeon).
signal room_entered(room: RoomData)
## Um inimigo notou o jogador: os que estão perto acordam também.
signal enemy_alerted(at: Vector3)
## Barulho (uma magia lançada): acorda os inimigos até `radius` metros.
signal noise_made(at: Vector3, radius: float)
## Um chefe notou o jogador (o HUD mostra a barra de vida dele).
signal boss_engaged(enemy: Node3D)
## A varinha mudou (outro núcleo ou outra ponteira): a varinha na mão muda de cor.
signal wand_changed
## Um texto pronto para ler (título e corpo já traduzidos), como um livro com as receitas.
signal text_requested(title: String, body: String)
## Um texto para ler (placa, anotação), com título e corpo (chaves de tradução).
signal note_requested(title_key: String, body_key: String)

const SAVE_PATH := "user://save.json"

var knowledge: Knowledge
var world: DungeonProgress
var stash: Stash
var crucible: Crucible
var modifiers := Modifiers.new()
var run: RunState
var rng := GameRng.new(0)


func _ready() -> void:
	_load_save()
	# As receitas dos compostos simples já vêm sabidas (não vão para o save).
	knowledge.free_recipes = Content.db.free_recipes()
	knowledge.changed.connect(_on_knowledge_changed)
	world.changed.connect(save)
	stash.changed.connect(save)
	crucible.changed.connect(save)
	_update_modifiers()
	run = RunState.new(Content.db.player, stash.jars)
	_apply_wand()
	# Saves de antes das relíquias: chefes já vencidos ainda não tinham deixado a deles.
	for enemy: EnemyData in Content.db.enemies.values():
		if enemy.material_safe and world.is_defeated(enemy.id):
			give_relic(enemy)


## Pede a troca de sala (quem faz a transição é a cena principal).
func travel(room_id: StringName, entrance_id: StringName) -> void:
	travel_requested.emit(room_id, entrance_id)


## O portal da escola: com uma âncora só, leva direto a ela; com mais, a tela do portal pergunta
## para onde ir (e chama `start_dungeon`).
func enter_portal() -> void:
	var anchors := attuned_anchors()
	if anchors.size() > 1:
		screen_requested.emit(&"portal")
	elif not anchors.is_empty():
		start_dungeon(anchors[0])


## Âncoras aonde o portal pode levar, na ordem das regras (a primeira está sempre sintonizada).
func attuned_anchors() -> Array[StringName]:
	var rules := Content.db.dungeon_rules
	var result: Array[StringName] = []
	for i in rules.anchors.size():
		if i == 0 or world.is_attuned(rules.anchors[i]):
			result.append(rules.anchors[i])
	return result


## Começa uma incursão na âncora `anchor_id`: sorteia a semente (de inimigos e achados) com o
## gerador do jogo e pede a montagem da Dungeon.
func start_dungeon(anchor_id: StringName) -> void:
	var incursion_seed := rng.range_int(0, 2147483646)
	print("Incursão: semente %d, âncora %s" % [incursion_seed, anchor_id])
	run.start_dungeon(incursion_seed)
	dungeon_requested.emit(incursion_seed, anchor_id)


## Volta à escola com vida (por uma âncora ou pela saída do Grande Arquivo): os achados vão junto.
func return_to_school() -> void:
	var rules := Content.db.dungeon_rules
	travel(rules.return_room, rules.return_entrance)


## Chegou vivo à escola: guarda o que foi achado na incursão (a cena principal chama).
func arrive_at_school() -> void:
	var was_in_dungeon := run.in_dungeon()
	run.leave_dungeon()
	run.health.restore()
	var found := run.take_found()
	if found.is_empty() or not was_in_dungeon:
		return
	stash.add(found)
	message(Text.tr_key("UI_MSG_BANKED") % items_text(found), Color(0.95, 0.85, 0.6))


## Um material achado na Dungeon (bolsa de prata, cacos, prata de um inimigo).
func find_item(item_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	run.find(item_id, amount)
	var item: ItemData = Content.db.items.get(item_id)
	message(Text.tr_key("UI_MSG_FOUND_ITEM") % [Text.tr_key(item.name_key) if item != null else String(item_id), amount],
		item.color if item != null else Color.WHITE)


## Texto de uma lista de materiais: "Prata 20, Cacos de vidro 3".
func items_text(amounts: Dictionary) -> String:
	var parts: PackedStringArray = []
	var ids: Array = amounts.keys()
	ids.sort_custom(ContentDB.by_name)
	for item_id in ids:
		var item: ItemData = Content.db.items.get(item_id)
		parts.append("%s %d" % [Text.tr_key(item.name_key) if item != null else String(item_id), amounts[item_id]])
	return ", ".join(parts)


## Quanto o jogador tem de um material: o guardado na escola mais o achado nesta incursão.
func item_count(item_id: StringName) -> int:
	return stash.count(item_id) + run.found.get(item_id, 0)


## O cinto já tem todos os potes que cabem?
func belt_full() -> bool:
	return stash.jars >= Content.db.player.jar_slots


## Compra um pote no Almoxarife. Devolve false se não der (sem prata ou o cinto cheio).
func buy_jar() -> bool:
	if belt_full() or not stash.spend(Content.db.economy.jar_price):
		return false
	_gain_jar()
	return true


## Vis da varinha que falta para fabricar um pote ({aspecto: quanto falta}).
func missing_jar_vis() -> Dictionary:
	return missing_vis(Content.db.economy.jar_vis)


## Vis que falta na varinha para pagar `cost` agora ({aspecto: quanto falta}).
func missing_vis(cost: Dictionary) -> Dictionary:
	var result := {}
	var now := run.wand.cost_now(cost)
	for aspect_id in now:
		var lacking: int = now[aspect_id] - run.wand.reserve(aspect_id)
		if lacking > 0:
			result[aspect_id] = lacking
	return result


## Fabrica um pote na bancada de vidraria: gasta os cacos de vidro e o Vis da varinha.
func craft_jar() -> bool:
	var economy := Content.db.economy
	if belt_full() or not stash.can_afford(economy.jar_materials) or not run.wand.can_pay(economy.jar_vis):
		return false
	stash.spend(economy.jar_materials)
	run.wand.pay(economy.jar_vis)
	_gain_jar()
	return true


## Relíquia de um chefe (material com `material_safe`): vai direto para a escola, uma vez só.
## A entrega fica marcada no mapa (como uma chave), para não se repetir.
func give_relic(enemy: EnemyData) -> void:
	if not world.take_key(StringName("relic_" + String(enemy.id))):
		return
	stash.add({enemy.material: enemy.material_amount})
	var item: ItemData = Content.db.items.get(enemy.material)
	message(Text.tr_key("UI_MSG_RELIC") % Text.tr_key(item.name_key if item != null else String(enemy.material)), Color(0.8, 0.7, 1.0))


# --- Alquimia (cadinho) --------------------------------------------------------------

## Joga uma unidade do material no cadinho: ela vira essência dos aspectos dela.
func dissolve(item: ItemData) -> bool:
	if not crucible.dissolve(item, stash):
		return false
	Audio.play(&"glass")
	return true


## Anota toda a essência de um aspecto (já descoberto) como pontos de pesquisa.
func note_essence(aspect_id: StringName) -> int:
	if not knowledge.knows_aspect(aspect_id):
		return 0
	var amount := crucible.take_all(aspect_id)
	knowledge.add_points(aspect_id, amount)
	if amount > 0:
		Audio.play(&"scan_complete")
		message(Text.tr_key("UI_MSG_ESSENCE_NOTED") % [amount, Text.aspect_name(aspect_id)], Content.db.aspects[aspect_id].color)
	return amount


## Por que a receita não pode ser preparada agora (chave de texto), ou vazio se pode.
func brew_problem(recipe: AlchemyRecipeData) -> String:
	for aspect_id in recipe.cost:
		if not knowledge.knows_aspect(aspect_id):
			return "UI_ALCHEMY_UNKNOWN"
	if not crucible.missing(recipe.cost).is_empty():
		return "UI_ALCHEMY_NOT_ENOUGH"
	if recipe.elixir != null and stash.elixir_total() >= Content.db.player.max_elixirs:
		return "UI_ALCHEMY_ELIXIRS_FULL"
	if recipe.jar_aspect != &"" and not run.jars.jars.any(func(jar): return jar.is_empty()):
		return "UI_ALCHEMY_NO_EMPTY_JAR"
	return ""


## Prepara a receita: gasta a essência e dá o elixir, ou enche um pote vazio do cinto.
func brew(recipe: AlchemyRecipeData) -> bool:
	if brew_problem(recipe) != "":
		return false
	crucible.spend(recipe.cost)
	if recipe.elixir != null:
		stash.add_elixir(recipe.elixir.id, Content.db.player.max_elixirs)
	else:
		run.jars.store(recipe.jar_aspect, recipe.jar_amount)
	Audio.play(&"page_studied")
	message(Text.tr_key("UI_MSG_BREWED") % Text.expand(recipe.name_key), Color(0.75, 0.9, 0.8))
	return true


## Bebe um elixir (tecla F), o primeiro que houver. Devolve false se não havia ou não precisava.
func drink_elixir() -> bool:
	var ids: Array = stash.elixirs.keys()
	ids.sort_custom(ContentDB.by_name)
	if ids.is_empty():
		message(Text.tr_key("UI_MSG_NO_ELIXIR"))
		return false
	var elixir: ElixirData = Content.db.elixirs.get(ids[0])
	if elixir == null:
		return false
	if run.health.current >= run.health.max_health:
		message(Text.tr_key("UI_MSG_HEALTH_FULL"))
		return false
	stash.use_elixir(elixir.id)
	var healed := run.health.heal(elixir.heal)
	Audio.play(&"recharge")
	message(Text.tr_key("UI_MSG_ELIXIR_DRUNK") % [Text.tr_key(elixir.name_key), roundi(healed)], elixir.color)
	return true


# --- Peças de varinha (Bancada Arcana) -------------------------------------------------

## Núcleo montado na varinha agora.
func equipped_core() -> WandCoreData:
	var player := Content.db.player
	var core: WandCoreData = Content.db.cores.get(stash.core)
	return core if core != null and owns_part(core) else player.starting_core


## Ponteira montada na varinha agora.
func equipped_cap() -> WandCapData:
	var player := Content.db.player
	var cap: WandCapData = Content.db.caps.get(stash.cap)
	return cap if cap != null and owns_part(cap) else player.starting_cap


## O jogador já tem a peça (as iniciais vêm com ele)?
func owns_part(part: Resource) -> bool:
	var player := Content.db.player
	if part == player.starting_core or part == player.starting_cap:
		return true
	return part.id in (stash.cores if part is WandCoreData else stash.caps)


## Alguma página estudada liberou a peça (as iniciais estão sempre liberadas)?
func part_unlocked(part: Resource) -> bool:
	return owns_part(part) or part in modifiers.unlocked_parts


## Faz uma peça na Bancada Arcana: gasta os materiais e o Vis da varinha e já a monta.
func build_part(part: Resource) -> bool:
	if owns_part(part) or not part_unlocked(part) or not stash.can_afford(part.cost) or not run.wand.can_pay(part.vis_cost):
		return false
	stash.spend(part.cost)
	run.wand.pay(part.vis_cost)
	if part is WandCoreData:
		stash.add_core(part.id)
	else:
		stash.add_cap(part.id)
	_apply_wand()
	Audio.play(&"page_studied")
	message(Text.tr_key("UI_MSG_PART_MADE") % Text.tr_key(part.name_key), Color(0.8, 0.7, 1.0))
	return true


## Monta na varinha uma peça que o jogador já tem.
func equip_part(part: Resource) -> bool:
	if not owns_part(part):
		return false
	stash.equip(part.id, part is WandCoreData)
	_apply_wand()
	Audio.play(&"recharge")
	return true


## Monta a varinha com o núcleo e a ponteira escolhidos (o Vis que couber continua nela).
func _apply_wand() -> void:
	run.wand.set_wand(Content.db.player.make_wand(equipped_core(), equipped_cap()))
	wand_changed.emit()


func _gain_jar() -> void:
	stash.add_jar(Content.db.player.jar_slots)
	run.jars.set_count(stash.jars)
	Audio.play(&"recharge")
	message(Text.tr_key("UI_MSG_JAR_GAINED") % [stash.jars, Content.db.player.jar_slots], Color(0.75, 0.9, 0.85))


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
	file.store_string(SaveGame.to_json(knowledge, world, stash, crucible))


func _load_save() -> void:
	knowledge = Knowledge.new()
	world = DungeonProgress.new()
	stash = Stash.new()
	crucible = Crucible.new()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data := SaveGame.parse(FileAccess.get_file_as_string(SAVE_PATH))
	var loaded := SaveGame.from_dict(data) if not data.is_empty() else null
	if loaded == null:
		# Save corrompido ou de uma versão mais nova: guarda uma cópia e começa do zero.
		var backup := SAVE_PATH + ".bak"
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(backup))
		push_warning("Save inválido; cópia guardada em %s. Começando do zero." % backup)
		return
	knowledge = loaded
	world = SaveGame.world_from_dict(data)
	stash = SaveGame.stash_from_dict(data)
	crucible = SaveGame.crucible_from_dict(data)
