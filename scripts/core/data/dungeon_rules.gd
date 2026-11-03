class_name DungeonRules
extends Resource
## Como uma incursão na Dungeon é montada. O arquivo fica em data/dungeon/rules.tres.
## A cada incursão, o jogo sorteia (com semente) uma sala para cada posição de `layout`,
## entre as salas de data/rooms/ daquele tipo (`kind`).
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

## A sequência de tipos de sala, da primeira à última (ex.: combat, combat, rest, combat, boss).
@export var layout: Array[StringName] = []
## Entrada usada ao chegar em cada sala da Dungeon (todas as salas sorteáveis precisam dela).
@export var entrance_id: StringName
## Para onde a saída da última sala leva (sala e entrada).
@export var return_room: StringName
@export var return_entrance: StringName
