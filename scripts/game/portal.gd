class_name Portal
extends Interactable
## O portal da escola: a única passagem para a Dungeon. Atravessá-lo começa uma incursão,
## com as salas sorteadas a partir de data/dungeon/rules.tres.

## Ligado: começa uma incursão sorteada. Desligado: vai direto para `target_room` (útil para
## testar uma sala).
@export var starts_incursion := true
@export var target_room: StringName = &"stone_chamber"
@export var target_entrance: StringName = &"south"


func interact(_player: Node3D) -> void:
	if starts_incursion:
		Game.start_dungeon()
	else:
		Game.travel(target_room, target_entrance)
