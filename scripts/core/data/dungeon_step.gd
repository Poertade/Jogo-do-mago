class_name DungeonStep
extends Resource
## Uma posição no caminho de uma incursão: de que região e de que tipo é a sala sorteada ali,
## e quanto o corredor que chega até ela desce (em metros).

## Região da Dungeon (school: ruínas da escola; caves: grutas; abyss: o Avesso).
@export var zone: StringName
## Tipo da sala: combat, rest ou boss.
@export var kind: StringName
## Descida do corredor antes desta sala, sorteada entre os dois valores.
@export var drop_min: float = 0.0
@export var drop_max: float = 0.0
