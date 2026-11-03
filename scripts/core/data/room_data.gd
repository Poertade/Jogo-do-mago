class_name RoomData
extends Resource
## Uma sala do jogo: identificador, cena e atmosfera.
## Cada sala é um arquivo em data/rooms/. A geometria, as luzes e os pontos de entrada
## ficam na cena (scenes/rooms/), montada no editor.

## Identificador interno, único entre as salas. É por ele que portais e saídas apontam para a sala.
@export var id: StringName
## Cena da sala.
@export_file("*.tscn") var scene_path: String
## Tipo da sala na Dungeon, para o sorteio das incursões (data/dungeon/rules.tres):
## combat (combate), rest (descanso, com Nódulo) ou boss (chefe). Vazio: a sala não é sorteada
## (escola, sala de teste).
@export var kind: StringName

@export_group("Atmosfera")
## Cor da névoa e do fundo.
@export var fog_color: Color = Color.BLACK
## Distância, em metros, em que a névoa começa.
@export var fog_near: float = 0.0
## Distância, em metros, em que a névoa cobre tudo.
@export var fog_far: float = 0.0
## Luz ambiente: ilumina tudo por igual, sem direção.
@export var ambient_color: Color = Color.BLACK
@export var ambient_energy: float = 0.0

@export_group("Som")
## Som de ambiente que toca em repetição na sala (vazio: silêncio).
@export var ambience: AudioStream
