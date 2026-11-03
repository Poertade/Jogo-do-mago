class_name Portal
extends Interactable
## O portal da escola: a única passagem para a Dungeon. Atravessá-lo começa uma incursão numa
## das âncoras sintonizadas (com mais de uma, a tela do portal pergunta para onde ir).

## Ligado: começa uma incursão. Desligado: vai direto para `target_room` (útil para testar uma
## sala sozinha).
@export var starts_incursion := true
@export var target_room: StringName = &"test_room"
@export var target_entrance: StringName = &"default"


func interact(_player: Node3D) -> void:
	if starts_incursion:
		Game.enter_portal()
	else:
		Game.travel(target_room, target_entrance)
