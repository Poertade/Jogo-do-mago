class_name DungeonRules
extends Resource
## Como a Dungeon funciona. O arquivo fica em data/dungeon/rules.tres.
## A Dungeon é um mapa fixo, feito à mão (scenes/dungeon/dungeon.tscn): as mesmas salas a cada
## incursão, com inimigos e achados sorteados. O portal da escola leva a uma das âncoras que o
## jogador já sintonizou; a primeira da lista está sempre sintonizada.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

## Cena do mapa.
@export_file("*.tscn") var map_scene: String
## Âncoras do portal, na ordem em que aparecem no portal da escola (a primeira é a chegada).
@export var anchors: Array[StringName] = []
## Nome de cada âncora (chave de locales/content.csv).
@export var anchor_names: Dictionary[StringName, String] = {}
## Para onde se volta ao sair da Dungeon (sala e entrada).
@export var return_room: StringName
@export var return_entrance: StringName
## Altura (m) abaixo da qual quem caiu para fora do mapa é trazido de volta à âncora.
@export var fall_limit: float = 0.0
