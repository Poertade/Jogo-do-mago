class_name World
extends Node3D
## O mundo 3D: carrega uma sala pelo identificador (data/rooms/) ou o mapa da Dungeon
## (Dungeon), aplica a atmosfera da sala em que o jogador está (névoa, luz ambiente, som) e
## coloca o jogador numa entrada ou numa âncora do portal.

@export var player: Player
@export var world_environment: WorldEnvironment

## Segundos para a névoa e a luz passarem de uma sala para a outra, na Dungeon.
const ATMOSPHERE_BLEND := 1.2

var current_room: Room
var current_room_data: RoomData
## O mapa da Dungeon (null na escola) e a âncora onde o jogador chegou.
var dungeon: Dungeon
var _arrival: Node3D
var _area: Node3D
var _atmosphere_tween: Tween
## Névoa aplicada agora (para a transição partir dela).
var _fog_color := Color.BLACK
var _fog_near := 0.0
var _fog_far := 1.0


## Troca a sala atual pela sala `room_id`, com o jogador na entrada `entrance_id`.
## `room_seed` sorteia o que varia na sala (quais inimigos aparecem).
func load_room(room_id: StringName, entrance_id: StringName = &"default", room_seed := 0) -> void:
	var data: RoomData = Content.db.rooms.get(room_id)
	if data == null:
		push_error("Sala '%s' não existe em data/rooms/." % room_id)
		return
	_clear()
	current_room = (load(data.scene_path) as PackedScene).instantiate() as Room
	current_room.rng = GameRng.new(room_seed)
	current_room_data = data
	_area = current_room
	add_child(current_room)
	_apply_atmosphere(data)
	Audio.set_ambience(data.ambience)
	var entrance := current_room.get_entrance(entrance_id)
	if entrance != null:
		player.place_at(entrance)
	Game.room_entered.emit(data)


## Monta o mapa da Dungeon (inimigos e achados sorteados com `incursion_seed`) e põe o jogador
## na âncora `anchor_id`.
func load_dungeon(incursion_seed: int, anchor_id: StringName) -> void:
	_clear()
	var rules := Content.db.dungeon_rules
	dungeon = (load(rules.map_scene) as PackedScene).instantiate() as Dungeon
	dungeon.prepare(incursion_seed)
	_area = dungeon
	add_child(dungeon)
	dungeon.bake_navigation()
	var target := dungeon.anchor(anchor_id)
	if target == null:
		push_error("Âncora '%s' não está no mapa; usando a primeira." % anchor_id)
		target = dungeon.anchor(rules.anchors[0])
	_arrival = target.arrival
	player.place_at(_arrival)
	var index := dungeon.room_index_at(player.global_position)
	_enter_dungeon_room(maxi(index, 0), false)


## Na Dungeon, acompanha em que sala o jogador está e troca a atmosfera devagar. Quem cair para
## fora do mapa volta para a âncora de chegada.
func _physics_process(_delta: float) -> void:
	if dungeon == null:
		return
	if player.global_position.y < Content.db.dungeon_rules.fall_limit:
		player.place_at(_arrival)
	var index := dungeon.room_index_at(player.global_position)
	if index >= 0 and dungeon.rooms[index] != current_room:
		_enter_dungeon_room(index, true)


func _enter_dungeon_room(index: int, blend: bool) -> void:
	var previous_zone := current_room_data.zone if current_room_data != null else &""
	current_room = dungeon.rooms[index]
	current_room_data = Content.db.rooms[current_room.room_id]
	Game.room_entered.emit(current_room_data)
	if blend:
		_blend_atmosphere(current_room_data)
	else:
		_apply_atmosphere(current_room_data)
	Audio.set_ambience(current_room_data.ambience)
	if current_room_data.zone != previous_zone:
		Game.zone_entered.emit(current_room_data.zone)


func _clear() -> void:
	if _area != null:
		_area.queue_free()
	_area = null
	dungeon = null
	_arrival = null
	current_room = null
	current_room_data = null


## Passa a névoa e a luz ambiente para as da sala aos poucos (andando de uma sala para outra).
func _blend_atmosphere(data: RoomData) -> void:
	var environment := world_environment.environment
	if _atmosphere_tween != null:
		_atmosphere_tween.kill()
	_atmosphere_tween = create_tween().set_parallel()
	_atmosphere_tween.tween_property(environment, "background_color", data.fog_color, ATMOSPHERE_BLEND)
	_atmosphere_tween.tween_property(environment, "ambient_light_color", data.ambient_color, ATMOSPHERE_BLEND)
	_atmosphere_tween.tween_property(environment, "ambient_light_energy", data.ambient_energy, ATMOSPHERE_BLEND)
	var fog_from := _fog_color
	var near_from := _fog_near
	var far_from := _fog_far
	_atmosphere_tween.tween_method(func(t: float):
		_set_fog(fog_from.lerp(data.fog_color, t), lerpf(near_from, data.fog_near, t), lerpf(far_from, data.fog_far, t)),
		0.0, 1.0, ATMOSPHERE_BLEND)


func _set_fog(color: Color, near: float, far: float) -> void:
	_fog_color = color
	_fog_near = near
	_fog_far = far
	RenderingServer.global_shader_parameter_set(&"ps1_fog_color", color)
	RenderingServer.global_shader_parameter_set(&"ps1_fog_near", near)
	RenderingServer.global_shader_parameter_set(&"ps1_fog_far", far)


func _apply_atmosphere(data: RoomData) -> void:
	var environment := world_environment.environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = data.fog_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = data.ambient_color
	environment.ambient_light_energy = data.ambient_energy
	_set_fog(data.fog_color, data.fog_near, data.fog_far)


## Coloca um nó (projétil, efeito) na área atual (sala ou Dungeon): ele some junto quando a
## área for trocada.
func spawn(node: Node3D) -> void:
	if _area != null:
		_area.add_child(node)
	else:
		add_child(node)
