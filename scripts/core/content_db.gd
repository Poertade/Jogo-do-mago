class_name ContentDB
extends RefCounted
## Todo o conteúdo do jogo (pasta data/), carregado e verificado.
## Os erros encontrados (identificador repetido, referência quebrada…) ficam em `errors`,
## com mensagens em português, para quem adiciona conteúdo saber o que corrigir.

const DATA_ROOT := "res://data"

var player: PlayerData
var settings_defaults: SettingsDefaults
var research_rules: ResearchRules
var dungeon_rules: DungeonRules
var economy: EconomyRules
var sound_bank: SoundBank
var presets: Array[GraphicsPreset] = []
var rooms: Dictionary[StringName, RoomData] = {}
var aspects: Dictionary[StringName, AspectData] = {}
var scannables: Dictionary[StringName, ScannableData] = {}
var pages: Dictionary[StringName, ResearchPageData] = {}
## Peças de varinha: núcleos (data/wands/cores/) e ponteiras (data/wands/caps/).
var cores: Dictionary[StringName, WandCoreData] = {}
var caps: Dictionary[StringName, WandCapData] = {}
var foci: Dictionary[StringName, FocusData] = {}
var enemies: Dictionary[StringName, EnemyData] = {}
var books: Dictionary[StringName, BookData] = {}
var zones: Dictionary[StringName, DungeonZone] = {}
var items: Dictionary[StringName, ItemData] = {}
## Alquimia: receitas do cadinho e elixires.
var recipes: Dictionary[StringName, AlchemyRecipeData] = {}
var elixirs: Dictionary[StringName, ElixirData] = {}
var errors: PackedStringArray = []


## Carrega tudo de `root` (normalmente res://data) e verifica.
func load_all(root := DATA_ROOT) -> void:
	player = _load_single(root.path_join("player/player.tres")) as PlayerData
	settings_defaults = _load_single(root.path_join("settings/defaults.tres")) as SettingsDefaults
	research_rules = _load_single(root.path_join("research/rules.tres")) as ResearchRules
	dungeon_rules = _load_single(root.path_join("dungeon/rules.tres")) as DungeonRules
	economy = _load_single(root.path_join("economy/rules.tres")) as EconomyRules
	sound_bank = _load_single(root.path_join("audio/sound_bank.tres")) as SoundBank
	for resource in _load_folder(root.path_join("settings/presets")):
		if resource is GraphicsPreset:
			presets.append(resource)
	for resource in _load_folder(root.path_join("rooms")):
		if resource is RoomData:
			add_room(resource)
	for resource in _load_folder(root.path_join("aspects")):
		if resource is AspectData:
			add_aspect(resource)
	for resource in _load_folder(root.path_join("scannables")):
		if resource is ScannableData:
			add_scannable(resource)
	for resource in _load_folder(root.path_join("research/pages")):
		if resource is ResearchPageData:
			add_page(resource)
	for resource in _load_folder(root.path_join("wands/cores")):
		if resource is WandCoreData:
			_add_unique(cores, resource, "Núcleo")
	for resource in _load_folder(root.path_join("wands/caps")):
		if resource is WandCapData:
			_add_unique(caps, resource, "Ponteira")
	for resource in _load_folder(root.path_join("foci")):
		if resource is FocusData:
			_add_unique(foci, resource, "Focus")
	for resource in _load_folder(root.path_join("enemies")):
		if resource is EnemyData:
			add_enemy(resource)
	for resource in _load_folder(root.path_join("books")):
		if resource is BookData:
			_add_unique(books, resource, "Livro")
	for resource in _load_folder(root.path_join("dungeon/zones")):
		if resource is DungeonZone:
			_add_unique(zones, resource, "Região")
	for resource in _load_folder(root.path_join("items")):
		if resource is ItemData:
			_add_unique(items, resource, "Material")
	for resource in _load_folder(root.path_join("alchemy/elixirs")):
		if resource is ElixirData:
			_add_unique(elixirs, resource, "Elixir")
	for resource in _load_folder(root.path_join("alchemy/recipes")):
		if resource is AlchemyRecipeData:
			_add_unique(recipes, resource, "Receita alquímica")
	validate()


# --- Registro (também usado pelos testes, sem passar pelo disco) ---

func add_room(room: RoomData) -> void:
	_add_unique(rooms, room, "Sala")


func add_aspect(aspect: AspectData) -> void:
	_add_unique(aspects, aspect, "Aspecto")


## Objetos e inimigos dividem o mesmo espaço de identificadores: o Livro de Pesquisa
## guarda os alvos escaneados só pelo id.
func add_scannable(scannable: ScannableData) -> void:
	_add_unique(scannables, scannable, "Escaneável")


## Inimigos também são escaneáveis: o identificador não pode repetir o de um objeto.
func add_enemy(enemy: EnemyData) -> void:
	if enemy.id in scannables:
		errors.append("Inimigo '%s' usa o identificador de um objeto escaneável." % enemy.id)
		return
	_add_unique(enemies, enemy, "Inimigo")


func add_page(page: ResearchPageData) -> void:
	_add_unique(pages, page, "Página de pesquisa")


func _add_unique(table: Dictionary, item: Resource, label: String) -> void:
	var id: StringName = item.get("id")
	if id == &"":
		errors.append("%s sem identificador: %s." % [label, item.resource_path])
	elif id in table:
		errors.append("%s com identificador repetido: '%s'." % [label, id])
	else:
		table[id] = item


# --- Consultas ---

## Algo escaneável (objeto ou inimigo) pelo identificador, ou null.
func find_scannable(id: StringName) -> ScannableData:
	if id in scannables:
		return scannables[id]
	return enemies.get(id)


## Ordem alfabética de identificadores. (Ordenar StringName direto não segue o alfabeto: a
## ordem pode mudar de uma execução para outra, e o sorteio com semente deixaria de se repetir.)
static func by_name(a: StringName, b: StringName) -> bool:
	return String(a) < String(b)


## Compostos cuja receita já vem sabida (até o nível `free_recipe_tier` das regras).
func free_recipes() -> Array[StringName]:
	var result: Array[StringName] = []
	for aspect: AspectData in aspects.values():
		if aspect.is_compound() and tier(aspect.id) <= research_rules.free_recipe_tier:
			result.append(aspect.id)
	result.sort_custom(by_name)
	return result


## Os livros que podem aparecer na região.
func books_in(zone: StringName) -> Array[BookData]:
	var result: Array[BookData] = []
	for book: BookData in books.values():
		if book.zone == zone:
			result.append(book)
	result.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return result


## Páginas de pesquisa a partir de uma lista de identificadores (ignora os desconhecidos).
func pages_by_id(ids: Array[StringName]) -> Array[ResearchPageData]:
	var result: Array[ResearchPageData] = []
	for id in ids:
		if id in pages:
			result.append(pages[id])
	return result


## Páginas em ordem de tamanho da nota, para a Mesa de Pesquisa.
func sorted_pages() -> Array[ResearchPageData]:
	var result: Array[ResearchPageData] = []
	result.assign(pages.values())
	result.sort_custom(_page_before)
	return result


func _page_before(a: ResearchPageData, b: ResearchPageData) -> bool:
	return a.order < b.order or (a.order == b.order and String(a.id) < String(b.id))


## O aspecto composto formado por `a` e `b` (em qualquer ordem), ou null.
func compound_of(a: StringName, b: StringName) -> AspectData:
	for aspect: AspectData in aspects.values():
		if aspect.is_compound() and aspect.parents.size() == 2 \
				and ((aspect.parents[0] == a and aspect.parents[1] == b) or (aspect.parents[0] == b and aspect.parents[1] == a)):
			return aspect
	return null


## "Nível" de um aspecto: 0 para primais; para compostos, 1 + o maior nível dos pais.
func tier(aspect_id: StringName) -> int:
	var aspect: AspectData = aspects.get(aspect_id)
	if aspect == null or not aspect.is_compound():
		return 0
	var highest := 0
	for parent in aspect.parents:
		if parent != aspect_id:
			highest = maxi(highest, tier(parent))
	return highest + 1


## Aspectos compostos em ordem de nível (primeiro os mais simples), para a Mesa de Pesquisa.
func compounds_by_tier() -> Array[AspectData]:
	var result: Array[AspectData] = []
	for aspect: AspectData in aspects.values():
		if aspect.is_compound():
			result.append(aspect)
	result.sort_custom(_aspect_before)
	return result


func _aspect_before(a: AspectData, b: AspectData) -> bool:
	return tier(a.id) < tier(b.id) or (tier(a.id) == tier(b.id) and String(a.id) < String(b.id))


static func _total(amounts: Dictionary) -> int:
	var total := 0
	for key in amounts:
		total += amounts[key]
	return total


# --- Verificação ---

## Verifica referências e valores. Acrescenta mensagens em `errors`.
func validate() -> void:
	if player == null:
		errors.append("Faltam os dados do jogador (data/player/player.tres).")
	else:
		_validate_player()
	if research_rules == null:
		errors.append("Faltam as regras de pesquisa (data/research/rules.tres).")
	elif research_rules.scan_duration <= 0.0 or research_rules.points_per_amount <= 0 \
			or research_rules.combine_cost <= 0 or research_rules.combine_yield <= 0 or research_rules.note_write_cost <= 0:
		errors.append("rules.tres: tempos, pontos e custos de combinação precisam ser maiores que zero.")
	if sound_bank == null:
		errors.append("Falta o banco de sons (data/audio/sound_bank.tres).")
	if settings_defaults == null:
		errors.append("Faltam as opções padrão (data/settings/defaults.tres).")
	else:
		_validate_settings()
	for room: RoomData in rooms.values():
		_validate_room(room)
	if dungeon_rules == null:
		errors.append("Faltam as regras da Dungeon (data/dungeon/rules.tres).")
	else:
		_validate_dungeon()
	if economy == null:
		errors.append("Faltam as regras dos potes e materiais (data/economy/rules.tres).")
	else:
		_validate_economy()
	for aspect: AspectData in aspects.values():
		_validate_aspect(aspect)
	for scannable: ScannableData in scannables.values():
		_validate_aspect_amounts("Escaneável '%s'" % scannable.id, scannable.aspects)
	for page: ResearchPageData in pages.values():
		_validate_page(page)
	for part: Resource in cores.values() + caps.values():
		_validate_part(part)
	for focus: FocusData in foci.values():
		_validate_focus(focus)
	for enemy: EnemyData in enemies.values():
		_validate_enemy(enemy)


func _validate_player() -> void:
	if player.max_health <= 0:
		errors.append("player.tres: max_health precisa ser maior que zero.")
	if player.jar_slots < 0 or (player.jar_slots > 0 and player.jar_capacity <= 0):
		errors.append("player.tres: jar_slots não pode ser negativo, e com lugar para potes jar_capacity precisa ser maior que zero.")
	if player.starting_core == null or player.starting_cap == null or player.starting_focus == null:
		errors.append("player.tres: faltam o núcleo, a ponteira ou o Focus iniciais.")
		return
	if player.wand_aspects.is_empty():
		errors.append("player.tres: a lista de recipientes da varinha (wand_aspects) está vazia.")
	var repeated := {}
	for aspect_id in player.wand_aspects:
		if aspect_id in repeated:
			errors.append("player.tres: recipiente de '%s' repetido em wand_aspects." % aspect_id)
		repeated[aspect_id] = 1
	_validate_vis_amounts("player.tres (wand_aspects)", repeated)
	var wand := player.make_wand()
	for aspect_id in player.starting_focus.cost.keys() + player.starting_vis.keys():
		if not aspect_id in wand.aspects:
			errors.append("A varinha inicial não tem recipiente de '%s' (usado pelo Focus ou por starting_vis)." % aspect_id)
	var shot := WandState.new(wand).effective_cost(player.starting_focus.cost)
	var shot_total := 0
	for aspect_id in shot:
		shot_total += shot[aspect_id]
		if shot[aspect_id] > wand.aspect_capacity:
			errors.append("A varinha inicial não guarda %s suficiente para um disparo do Focus inicial." % aspect_id)
	if shot_total > wand.capacity:
		errors.append("A varinha inicial não guarda Vis suficiente (no total) para um disparo do Focus inicial.")
	_validate_vis_amounts("player.tres (starting_vis)", player.starting_vis)
	var start_total := 0
	for aspect_id in player.starting_vis:
		start_total += player.starting_vis[aspect_id]
		if player.starting_vis[aspect_id] > wand.aspect_capacity:
			errors.append("player.tres: starting_vis de %s passa do limite do recipiente da varinha." % aspect_id)
	if start_total > wand.capacity:
		errors.append("player.tres: a soma de starting_vis passa do limite total da varinha.")


## Núcleo ou ponteira de varinha: valores positivos e custos com materiais e Vis que existem.
func _validate_part(part: Resource) -> void:
	var owner := "Peça de varinha '%s'" % part.id
	if part is WandCoreData and (part.capacity <= 0 or part.aspect_capacity <= 0 or part.aspect_capacity > part.capacity):
		errors.append("%s: capacity e aspect_capacity precisam ser maiores que zero, e aspect_capacity não passa de capacity." % owner)
	if part is WandCapData and part.efficiency <= 0.0:
		errors.append("%s: efficiency precisa ser maior que zero." % owner)
	for item_id in part.cost:
		if not item_id in items:
			errors.append("%s: o material '%s' não existe em data/items/." % [owner, item_id])
		elif part.cost[item_id] <= 0:
			errors.append("%s: quantidades precisam ser maiores que zero ('%s')." % [owner, item_id])
	_validate_vis_amounts(owner + " (vis_cost)", part.vis_cost)
	var starting: bool = player != null and (part == player.starting_core or part == player.starting_cap)
	if not starting and part.cost.is_empty():
		errors.append("%s: só as peças iniciais podem não ter custo." % owner)
	if not starting and not _page_unlocks(part):
		errors.append("%s: nenhuma página de pesquisa libera esta peça (efeito unlock_wand_part)." % owner)


func _page_unlocks(part: Resource) -> bool:
	for page: ResearchPageData in pages.values():
		for effect in page.effects:
			if effect.type == PageEffect.UNLOCK_WAND_PART and effect.wand_part == part:
				return true
	return false


## Vis só existe dos aspectos primais (como no Thaumcraft): custos e reservas usam só eles.
func _validate_vis_amounts(owner: String, amounts: Dictionary) -> void:
	if amounts.is_empty():
		return
	_validate_aspect_amounts(owner, amounts)
	for aspect_id in amounts:
		var aspect: AspectData = aspects.get(aspect_id)
		if aspect != null and aspect.is_compound():
			errors.append("%s: '%s' não é primal; Vis só existe dos aspectos primais." % [owner, aspect_id])


func _validate_focus(focus: FocusData) -> void:
	var owner := "Focus '%s'" % focus.id
	if not focus.spell_type in FocusData.SPELL_TYPES:
		errors.append("%s: tipo de magia desconhecido '%s'." % [owner, focus.spell_type])
	if not focus.element in aspects:
		errors.append("%s: elemento '%s' não é um aspecto." % [owner, focus.element])
	if focus.cost.is_empty():
		errors.append("%s: falta o custo em Vis (aspecto → quantidade)." % owner)
	_validate_vis_amounts(owner, focus.cost)
	if focus.damage <= 0.0 or focus.charge_time < 0.0 or focus.cooldown < 0.0:
		errors.append("%s: dano precisa ser positivo e tempos não podem ser negativos." % owner)
	if focus.spell_type == FocusData.SPELL_PROJECTILE and (focus.projectile_speed <= 0.0 or focus.projectile_lifetime <= 0.0):
		errors.append("%s: projétil precisa de velocidade e duração positivas." % owner)
	if focus.slow_factor <= 0.0 or focus.slow_factor > 1.0 or focus.slow_seconds < 0.0:
		errors.append("%s: slow_factor fica entre 0 e 1 (1 = sem lentidão) e slow_seconds não pode ser negativo." % owner)
	if focus.spell_type == FocusData.SPELL_CHAIN and (focus.chain_range <= 0.0 or focus.chain_jumps < 0 \
			or focus.chain_jump_range < 0.0 or focus.chain_falloff <= 0.0 or focus.chain_falloff > 1.0):
		errors.append("%s: a corrente precisa de chain_range positivo, saltos e distância não negativos e chain_falloff entre 0 e 1." % owner)


func _validate_enemy(enemy: EnemyData) -> void:
	var owner := "Inimigo '%s'" % enemy.id
	_validate_aspect_amounts(owner, enemy.aspects)
	if enemy.scene_path.is_empty() or not ResourceLoader.exists(enemy.scene_path):
		errors.append("%s: cena não encontrada ('%s')." % [owner, enemy.scene_path])
	if enemy.max_health <= 0.0 or enemy.move_speed <= 0.0 or enemy.attack_range <= 0.0:
		errors.append("%s: vida, velocidade e alcance precisam ser maiores que zero." % owner)
	for element in enemy.weaknesses:
		if not element in aspects:
			errors.append("%s: fraqueza a '%s', que não é um aspecto." % [owner, element])
	if enemy.enrage_at < 0.0 or enemy.enrage_at >= 1.0 or enemy.enrage_speed <= 0.0:
		errors.append("%s: enrage_at fica entre 0 e 1 e enrage_speed precisa ser maior que zero." % owner)
	for summon in enemy.enrage_summons:
		if summon == null or summon == enemy:
			errors.append("%s: enrage_summons tem um inimigo vazio ou ele mesmo." % owner)
	if enemy.silver_min < 0 or enemy.silver_max < enemy.silver_min:
		errors.append("%s: silver_min não pode ser negativo nem maior que silver_max." % owner)
	if enemy.material != &"" and (not enemy.material in items or enemy.material_amount <= 0):
		errors.append("%s: o material '%s' não existe em data/items/, ou material_amount é zero." % [owner, enemy.material])


func _validate_settings() -> void:
	var seen: Dictionary[StringName, bool] = {}
	for preset in presets:
		if preset.id == &"":
			errors.append("Filtro visual sem identificador: %s." % preset.resource_path)
		elif preset.id in seen:
			errors.append("Filtro visual com identificador repetido: '%s'." % preset.id)
		seen[preset.id] = true
		if not preset.internal_height in settings_defaults.internal_heights:
			errors.append("Filtro '%s': resolução %d não está na lista de defaults.tres." % [preset.id, preset.internal_height])
	if not settings_defaults.default_preset_id in seen:
		errors.append("Filtro padrão '%s' não existe em data/settings/presets." % settings_defaults.default_preset_id)
	if settings_defaults.internal_heights.is_empty():
		errors.append("defaults.tres: a lista de resoluções internas está vazia.")


func _validate_room(room: RoomData) -> void:
	if room.scene_path.is_empty() or not ResourceLoader.exists(room.scene_path):
		errors.append("Sala '%s': cena não encontrada ('%s')." % [room.id, room.scene_path])
	if room.fog_far <= room.fog_near:
		errors.append("Sala '%s': fog_far precisa ser maior que fog_near." % room.id)


func _validate_dungeon() -> void:
	var rules := dungeon_rules
	if rules.map_scene.is_empty() or not ResourceLoader.exists(rules.map_scene):
		errors.append("dungeon/rules.tres: cena do mapa não encontrada ('%s')." % rules.map_scene)
	if rules.anchors.is_empty():
		errors.append("dungeon/rules.tres: a lista de âncoras está vazia (a primeira é a chegada).")
	for anchor_id in rules.anchors:
		if not anchor_id in rules.anchor_names:
			errors.append("dungeon/rules.tres: a âncora '%s' não tem nome (anchor_names)." % anchor_id)
	if not rules.return_room in rooms:
		errors.append("dungeon/rules.tres: a sala de volta '%s' não existe." % rules.return_room)
	var used_zones: Dictionary[StringName, bool] = {}
	for room: RoomData in rooms.values():
		if room.zone == &"":
			continue
		used_zones[room.zone] = true
		if not room.zone in zones:
			errors.append("Sala '%s': a região '%s' não existe em data/dungeon/zones/." % [room.id, room.zone])
		if room.width <= 0.0 or room.depth <= 0.0 or room.height <= 0.0:
			errors.append("Sala '%s': salas da Dungeon precisam de width, depth e height." % room.id)
	for zone: DungeonZone in zones.values():
		if zone.wall_material == null or zone.floor_material == null or zone.ceiling_material == null:
			errors.append("Região '%s': faltam materiais dos corredores." % zone.id)
	for book: BookData in books.values():
		if not book.zone in zones:
			errors.append("Livro '%s': a região '%s' não existe." % [book.id, book.zone])
	for zone_id in used_zones:
		if books_in(zone_id).is_empty():
			errors.append("Região '%s': nenhum livro pode aparecer nela (data/books/, campo zone)." % zone_id)


func _validate_economy() -> void:
	for cost in [economy.jar_price, economy.jar_materials]:
		if cost.is_empty():
			errors.append("economy/rules.tres: o preço e os materiais do pote não podem ficar vazios.")
		for item_id in cost:
			if not item_id in items:
				errors.append("economy/rules.tres: o material '%s' não existe em data/items/." % item_id)
			elif cost[item_id] <= 0:
				errors.append("economy/rules.tres: quantidades precisam ser maiores que zero ('%s')." % item_id)
	_validate_vis_amounts("economy/rules.tres (jar_vis)", economy.jar_vis)
	if economy.glass_per_sealed_jar < 0:
		errors.append("economy/rules.tres: glass_per_sealed_jar não pode ser negativo.")
	for item_id in [&"silver", &"glass"]:
		if not item_id in items:
			errors.append("Falta o material '%s' em data/items/ (usado pelo jogo)." % item_id)
	for item: ItemData in items.values():
		if item.pickup_scene != "" and not ResourceLoader.exists(item.pickup_scene):
			errors.append("Material '%s': cena do achado não encontrada ('%s')." % [item.id, item.pickup_scene])
		# Sem aspectos, o material não se dissolve no cadinho (raridades como o Selo).
		if not item.aspects.is_empty():
			_validate_aspect_amounts("Material '%s'" % item.id, item.aspects)
	for elixir: ElixirData in elixirs.values():
		if elixir.heal <= 0.0:
			errors.append("Elixir '%s': heal precisa ser maior que zero." % elixir.id)
	for recipe: AlchemyRecipeData in recipes.values():
		var owner := "Receita alquímica '%s'" % recipe.id
		if recipe.cost.is_empty():
			errors.append("%s: falta a essência gasta (cost)." % owner)
		_validate_aspect_amounts(owner, recipe.cost)
		var makes_jar := recipe.jar_aspect != &""
		if (recipe.elixir == null) == (not makes_jar):
			errors.append("%s: dê um resultado só, um elixir ou Vis num pote (jar_aspect)." % owner)
		if makes_jar:
			_validate_vis_amounts(owner + " (jar_aspect)", {recipe.jar_aspect: maxi(recipe.jar_amount, 1)})
			if recipe.jar_amount <= 0:
				errors.append("%s: jar_amount precisa ser maior que zero." % owner)


func _validate_aspect(aspect: AspectData) -> void:
	if aspect.is_compound():
		if aspect.parents.size() != 2:
			errors.append("Aspecto composto '%s' precisa de exatamente 2 pais." % aspect.id)
		for parent in aspect.parents:
			if not parent in aspects:
				errors.append("Aspecto '%s': pai '%s' não existe." % [aspect.id, parent])
			elif parent == aspect.id:
				errors.append("Aspecto '%s' não pode ser pai de si mesmo." % aspect.id)
	elif not aspect.parents.is_empty():
		errors.append("Aspecto primal '%s' não pode ter pais." % aspect.id)


func _validate_aspect_amounts(owner: String, amounts: Dictionary) -> void:
	if amounts.is_empty():
		errors.append("%s não tem aspectos." % owner)
	for aspect_id in amounts:
		if not aspect_id in aspects:
			errors.append("%s: aspecto '%s' não existe." % [owner, aspect_id])
		elif amounts[aspect_id] <= 0:
			errors.append("%s: quantidade de '%s' precisa ser maior que zero." % [owner, aspect_id])


func _validate_page(page: ResearchPageData) -> void:
	var owner := "Página '%s'" % page.id
	if page.note_aspects.size() < 2 or page.note_radius < 1:
		errors.append("%s: a nota precisa de pelo menos 2 aspectos e raio 1 ou mais." % owner)
	elif page.note_aspects.size() > page.note_radius * 6:
		errors.append("%s: aspectos demais para a borda da nota (máximo %d)." % [owner, page.note_radius * 6])
	for aspect_id in page.note_aspects:
		if not aspect_id in aspects:
			errors.append("%s: aspecto da nota '%s' não existe." % [owner, aspect_id])
	for required in page.required_pages:
		if not required in pages:
			errors.append("%s: página exigida '%s' não existe." % [owner, required])
	for required in page.required_aspects:
		if not required in aspects:
			errors.append("%s: aspecto exigido '%s' não existe." % [owner, required])
	for effect in page.effects:
		if effect == null or not effect.type in PageEffect.TYPES:
			errors.append("%s: efeito de tipo desconhecido." % owner)
		elif effect.type == PageEffect.UNLOCK_FOCUS and effect.focus == null:
			errors.append("%s: o efeito unlock_focus precisa de um Focus." % owner)
		elif effect.type == PageEffect.UNLOCK_WAND_PART and not (effect.wand_part is WandCoreData or effect.wand_part is WandCapData):
			errors.append("%s: o efeito unlock_wand_part precisa de um núcleo ou de uma ponteira." % owner)


# --- Leitura de arquivos ---

func _load_single(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		return null
	return load(path)


## Carrega todos os recursos de uma pasta (sem subpastas).
func _load_folder(path: String) -> Array[Resource]:
	var result: Array[Resource] = []
	if not DirAccess.dir_exists_absolute(path):
		return result
	# list_directory devolve os nomes originais dos arquivos mesmo no jogo exportado.
	for file_name in ResourceLoader.list_directory(path):
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var resource := load(path.path_join(file_name))
			if resource == null:
				errors.append("Não foi possível carregar '%s'." % path.path_join(file_name))
			else:
				result.append(resource)
	return result
