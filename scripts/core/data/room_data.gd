class_name RoomData
extends Resource
## Uma sala do jogo: identificador, cena e atmosfera.
## Cada sala é um arquivo em data/rooms/. A geometria, as luzes e os pontos de entrada
## ficam na cena (scenes/rooms/), montada no editor.

## Identificador interno, único entre as salas. É por ele que portais e saídas apontam para a sala.
@export var id: StringName
## Cena da sala.
@export_file("*.tscn") var scene_path: String

@export_group("Atmosfera")
## Cor da névoa e do fundo.
@export var fog_color: Color = Color(0.04, 0.045, 0.06)
## Distância, em metros, em que a névoa começa.
@export var fog_near: float = 2.0
## Distância, em metros, em que a névoa cobre tudo.
@export var fog_far: float = 12.0
## Luz ambiente: ilumina tudo por igual, sem direção.
@export var ambient_color: Color = Color(0.25, 0.27, 0.33)
@export var ambient_energy: float = 0.3
