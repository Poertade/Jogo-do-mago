class_name ContentDB
extends RefCounted
## Todo o conteúdo do jogo (pasta data/), carregado e verificado.
## Os erros encontrados (identificador repetido, cena inexistente…) ficam em `errors`,
## com mensagens em português, para quem adiciona conteúdo saber o que corrigir.

const DATA_ROOT := "res://data"

var player: PlayerData
var settings_defaults: SettingsDefaults
var presets: Array[GraphicsPreset] = []
var rooms: Dictionary[StringName, RoomData] = {}
var errors: PackedStringArray = []


## Carrega tudo de `root` (normalmente res://data) e verifica.
func load_all(root := DATA_ROOT) -> void:
	player = _load_single(root.path_join("player/player.tres")) as PlayerData
	settings_defaults = _load_single(root.path_join("settings/defaults.tres")) as SettingsDefaults
	for resource in _load_folder(root.path_join("settings/presets")):
		if resource is GraphicsPreset:
			presets.append(resource)
	for resource in _load_folder(root.path_join("rooms")):
		if resource is RoomData:
			add_room(resource)
	validate()


## Registra uma sala. Também usado pelos testes, sem passar pelo disco.
func add_room(room: RoomData) -> void:
	if room.id in rooms:
		errors.append("Sala com identificador repetido: '%s'." % room.id)
		return
	rooms[room.id] = room


## Verifica referências e valores. Acrescenta mensagens em `errors`.
func validate() -> void:
	if player == null:
		errors.append("Faltam os dados do jogador (data/player/player.tres).")
	if settings_defaults == null:
		errors.append("Faltam as opções padrão (data/settings/defaults.tres).")
	else:
		_validate_settings()
	for room: RoomData in rooms.values():
		_validate_room(room)


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
	if room.id == &"":
		errors.append("Sala sem identificador: %s." % room.resource_path)
	if room.scene_path.is_empty() or not ResourceLoader.exists(room.scene_path):
		errors.append("Sala '%s': cena não encontrada ('%s')." % [room.id, room.scene_path])
	if room.fog_far <= room.fog_near:
		errors.append("Sala '%s': fog_far precisa ser maior que fog_near." % room.id)


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
