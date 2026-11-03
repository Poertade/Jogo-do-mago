class_name ContentDB
extends RefCounted
## Todo o conteúdo do jogo (pasta data/), carregado e verificado.
## Os erros encontrados (identificador repetido, referência quebrada…) ficam em `errors`,
## com mensagens em português, para quem adiciona conteúdo saber o que corrigir.

const DATA_ROOT := "res://data"

var player: PlayerData
var settings_defaults: SettingsDefaults
var research_rules: ResearchRules
var sound_bank: SoundBank
var presets: Array[GraphicsPreset] = []
var rooms: Dictionary[StringName, RoomData] = {}
var aspects: Dictionary[StringName, AspectData] = {}
var scannables: Dictionary[StringName, ScannableData] = {}
var pages: Dictionary[StringName, ResearchPageData] = {}
var wands: Dictionary[StringName, WandData] = {}
var foci: Dictionary[StringName, FocusData] = {}
var enemies: Dictionary[StringName, EnemyData] = {}
var errors: PackedStringArray = []


## Carrega tudo de `root` (normalmente res://data) e verifica.
func load_all(root := DATA_ROOT) -> void:
	player = _load_single(root.path_join("player/player.tres")) as PlayerData
	settings_defaults = _load_single(root.path_join("settings/defaults.tres")) as SettingsDefaults
	research_rules = _load_single(root.path_join("research/rules.tres")) as ResearchRules
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
	for resource in _load_folder(root.path_join("wands")):
		if resource is WandData:
			_add_unique(wands, resource, "Varinha")
	for resource in _load_folder(root.path_join("foci")):
		if resource is FocusData:
			_add_unique(foci, resource, "Focus")
	for resource in _load_folder(root.path_join("enemies")):
		if resource is EnemyData:
			add_enemy(resource)
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


## Páginas de pesquisa a partir de uma lista de identificadores (ignora os desconhecidos).
func pages_by_id(ids: Array[StringName]) -> Array[ResearchPageData]:
	var result: Array[ResearchPageData] = []
	for id in ids:
		if id in pages:
			result.append(pages[id])
	return result


## Páginas em ordem de custo total, para a Mesa de Pesquisa.
func sorted_pages() -> Array[ResearchPageData]:
	var result: Array[ResearchPageData] = []
	result.assign(pages.values())
	result.sort_custom(_page_before)
	return result


func _page_before(a: ResearchPageData, b: ResearchPageData) -> bool:
	var cost_a := _total(a.cost)
	var cost_b := _total(b.cost)
	return cost_a < cost_b or (cost_a == cost_b and a.id < b.id)


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
	return tier(a.id) < tier(b.id) or (tier(a.id) == tier(b.id) and a.id < b.id)


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
			or research_rules.combine_cost <= 0 or research_rules.combine_yield <= 0:
		errors.append("rules.tres: tempos, pontos e custos de combinação precisam ser maiores que zero.")
	if sound_bank == null:
		errors.append("Falta o banco de sons (data/audio/sound_bank.tres).")
	if settings_defaults == null:
		errors.append("Faltam as opções padrão (data/settings/defaults.tres).")
	else:
		_validate_settings()
	for room: RoomData in rooms.values():
		_validate_room(room)
	for aspect: AspectData in aspects.values():
		_validate_aspect(aspect)
	for scannable: ScannableData in scannables.values():
		_validate_aspect_amounts("Escaneável '%s'" % scannable.id, scannable.aspects)
	for page: ResearchPageData in pages.values():
		_validate_page(page)
	for wand: WandData in wands.values():
		_validate_wand(wand)
	for focus: FocusData in foci.values():
		_validate_focus(focus)
	for enemy: EnemyData in enemies.values():
		_validate_enemy(enemy)


func _validate_player() -> void:
	if player.max_health <= 0:
		errors.append("player.tres: max_health precisa ser maior que zero.")
	if player.starting_wand == null or player.starting_focus == null:
		errors.append("player.tres: faltam a varinha ou o Focus iniciais.")
		return
	for aspect_id in player.starting_focus.cost:
		if player.starting_wand.capacity.get(aspect_id, 0) < player.starting_focus.cost[aspect_id]:
			errors.append("A varinha inicial não guarda %s suficiente para o Focus inicial." % aspect_id)


func _validate_wand(wand: WandData) -> void:
	if wand.efficiency <= 0.0:
		errors.append("Varinha '%s': efficiency precisa ser maior que zero." % wand.id)
	_validate_aspect_amounts("Varinha '%s'" % wand.id, wand.capacity)


func _validate_focus(focus: FocusData) -> void:
	var owner := "Focus '%s'" % focus.id
	if not focus.spell_type in FocusData.SPELL_TYPES:
		errors.append("%s: tipo de magia desconhecido '%s'." % [owner, focus.spell_type])
	if not focus.element in aspects:
		errors.append("%s: elemento '%s' não é um aspecto." % [owner, focus.element])
	_validate_aspect_amounts(owner, focus.cost)
	if focus.damage <= 0.0 or focus.charge_time < 0.0 or focus.cooldown < 0.0:
		errors.append("%s: dano precisa ser positivo e tempos não podem ser negativos." % owner)
	if focus.spell_type == FocusData.SPELL_PROJECTILE and (focus.projectile_speed <= 0.0 or focus.projectile_lifetime <= 0.0):
		errors.append("%s: projétil precisa de velocidade e duração positivas." % owner)


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
	_validate_aspect_amounts(owner, page.cost)
	for required in page.required_pages:
		if not required in pages:
			errors.append("%s: página exigida '%s' não existe." % [owner, required])
	for required in page.required_aspects:
		if not required in aspects:
			errors.append("%s: aspecto exigido '%s' não existe." % [owner, required])
	for effect in page.effects:
		if effect == null or not effect.type in PageEffect.TYPES:
			errors.append("%s: efeito de tipo desconhecido." % owner)


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
