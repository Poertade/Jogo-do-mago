class_name DungeonLayout
extends RefCounted
## Onde fica cada peça de uma incursão no espaço: as salas em fila, para o norte (-Z), cada uma
## ligada à anterior por um corredor reto que pode descer em rampa.
## Só calcula posições; quem cria as salas e os corredores é o DungeonBuilder (scripts/game).
##
## Convenção das salas (RoomData): centro do chão na origem da cena, entrada no meio da parede
## sul (z = +depth / 2), saída no meio da parede norte (z = -depth / 2).

## Um corredor: do ponto `from` (centro do chão, na saída da sala anterior) ao `to` (na entrada
## da próxima sala). Se `to.y` < `from.y`, ele desce.
class Corridor:
	var from: Vector3
	var to: Vector3

	func length() -> float:
		return absf(to.z - from.z)

	func drop() -> float:
		return from.y - to.y


## Centro do chão de cada sala, na ordem do roteiro.
var room_origins: Array[Vector3] = []
## O corredor que chega a cada sala (o primeiro sai do círculo de chegada, em `start`).
var corridors: Array[Corridor] = []
## Medidas de cada sala (largura, altura, profundidade), para saber em que sala o jogador está.
var room_sizes: Array[Vector3] = []
## Onde o jogador aparece ao chegar pelo portal.
var start := Vector3.ZERO


## `room_data`: os RoomData das salas do roteiro, na ordem.
static func build(plan: DungeonPlan, room_data: Array) -> DungeonLayout:
	var layout := DungeonLayout.new()
	var cursor := Vector3.ZERO
	for i in plan.size():
		var room: RoomData = room_data[i]
		var corridor := Corridor.new()
		corridor.from = cursor
		corridor.to = cursor + Vector3(0.0, -plan.corridor_drops[i], -plan.corridor_lengths[i])
		layout.corridors.append(corridor)
		layout.room_origins.append(corridor.to + Vector3(0.0, 0.0, -room.depth / 2.0))
		layout.room_sizes.append(Vector3(room.width, room.height, room.depth))
		cursor = corridor.to + Vector3(0.0, 0.0, -room.depth)
	return layout


## Índice da sala em que o ponto está (contando o corredor que chega a ela como parte da sala),
## ou -1 se estiver fora de tudo.
func room_at(point: Vector3) -> int:
	for i in room_origins.size():
		var origin := room_origins[i]
		var room_size := room_sizes[i]
		var south := corridors[i].from.z
		var north := origin.z - room_size.z / 2.0
		var bottom := minf(origin.y, corridors[i].to.y) - 1.0
		var top := maxf(corridors[i].from.y, origin.y) + room_size.y + 1.0
		if point.z <= south and point.z >= north and absf(point.x - origin.x) <= room_size.x / 2.0 + 0.5 \
				and point.y >= bottom and point.y <= top:
			return i
	return -1
