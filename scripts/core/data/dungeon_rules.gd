class_name DungeonRules
extends Resource
## Como uma incursão é montada. O arquivo fica em data/dungeon/rules.tres.
## A Dungeon é um caminho contínuo: cada passo (`steps`) sorteia uma sala da região e do tipo
## pedidos, e salas seguidas são ligadas por corredores que descem — das ruínas da escola às
## grutas, e das grutas ao Avesso.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

## O caminho, da primeira à última sala.
@export var steps: Array[DungeonStep] = []
## Comprimento dos corredores entre as salas, sorteado entre os dois valores (metros).
@export var corridor_length_min: float = 0.0
@export var corridor_length_max: float = 0.0
## Para onde a saída da última sala leva (sala e entrada).
@export var return_room: StringName
@export var return_entrance: StringName
