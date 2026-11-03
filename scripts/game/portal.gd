class_name Portal
extends Interactable
## O portal da escola: a única passagem para a Dungeon. O destino é um dado (sala e entrada),
## para que no futuro ele leve a salas geradas.

@export var target_room: StringName = &"stone_chamber"
@export var target_entrance: StringName = &"from_portal"


func interact(_player: Node3D) -> void:
	Game.travel(target_room, target_entrance)
