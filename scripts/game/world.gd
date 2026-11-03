class_name World
extends Node3D
## O mundo 3D: carrega salas pelo identificador (data/rooms/), aplica a atmosfera
## da sala (névoa e luz ambiente) e coloca o jogador numa entrada.

@export var player: Player
@export var world_environment: WorldEnvironment

var current_room: Room
var current_room_data: RoomData


## Troca a sala atual pela sala `room_id`, com o jogador na entrada `entrance_id`.
func load_room(room_id: StringName, entrance_id: StringName = &"default") -> void:
	var data: RoomData = Content.db.rooms.get(room_id)
	if data == null:
		push_error("Sala '%s' não existe em data/rooms/." % room_id)
		return
	if current_room != null:
		current_room.queue_free()
	current_room = (load(data.scene_path) as PackedScene).instantiate() as Room
	current_room_data = data
	add_child(current_room)
	_apply_atmosphere(data)
	var entrance := current_room.get_entrance(entrance_id)
	if entrance != null:
		player.place_at(entrance)


func _apply_atmosphere(data: RoomData) -> void:
	var environment := world_environment.environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = data.fog_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = data.ambient_color
	environment.ambient_light_energy = data.ambient_energy
	RenderingServer.global_shader_parameter_set(&"ps1_fog_color", data.fog_color)
	RenderingServer.global_shader_parameter_set(&"ps1_fog_near", data.fog_near)
	RenderingServer.global_shader_parameter_set(&"ps1_fog_far", data.fog_far)
