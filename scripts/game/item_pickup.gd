class_name ItemPickup
extends Interactable
## Material achado na Dungeon (bolsa de prata, cacos de vidro). E guarda; o material só fica
## na escola se o jogador voltar vivo.

## Material (data/items/) e quantidade (definidos pela Dungeon, com a semente da incursão).
@export var item: StringName = &"silver"
@export var amount := 5


func interact(_player: Node3D) -> void:
	Game.find_item(item, amount)
	Audio.play(&"coin")
	queue_free()
