class_name RoomData
extends Resource
## Uma sala do jogo: identificador, nome, cena e atmosfera.
## Cada sala é um arquivo em data/rooms/. A geometria, as luzes e os pontos de entrada
## ficam na cena (scenes/rooms/), montada no editor. As salas da Dungeon ficam no mapa
## (scenes/dungeon/dungeon.tscn), cada uma com o `room_id` dela.

## Identificador interno, único entre as salas. É por ele que portais e saídas apontam para a sala.
@export var id: StringName
## Nome mostrado no canto da tela ao entrar na sala (em locales/content.csv). Vazio: nenhum.
@export var name_key: String
## Cena da sala.
@export_file("*.tscn") var scene_path: String
## Região da Dungeon a que a sala pertence (school, caves, abyss). Vazio: fora da Dungeon.
@export var zone: StringName
## Medidas internas da sala, em metros (largura em X, profundidade em Z). A cena tem o centro
## do chão na origem. O mapa usa isso para saber em que sala o jogador está.
@export var width: float = 0.0
@export var depth: float = 0.0
@export var height: float = 0.0

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
