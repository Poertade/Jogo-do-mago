class_name TreasureChest
extends Interactable
## Baú da Dungeon: aparece um por incursão, num dos lugares de baú do mapa. E abre o baú e
## guarda o que tem dentro (prata e materiais), que só fica na escola se o jogador voltar vivo.

## O que há no baú: {material: quantidade} (sorteado pela Dungeon).
@export var contents: Dictionary = {}

var _open := false

@onready var lid: Node3D = $Lid


func is_available() -> bool:
	return not _open


func current_prompt_key() -> String:
	return "" if _open else prompt_key


func interact(_player: Node3D) -> void:
	if _open:
		return
	_open = true
	var ids: Array = contents.keys()
	ids.sort_custom(ContentDB.by_name)
	for item_id in ids:
		Game.find_item(item_id, contents[item_id])
	Audio.play_at(&"coin", global_position, get_parent())
	# A tampa abre para trás.
	var tween := create_tween()
	tween.tween_property(lid, "rotation:x", deg_to_rad(-100.0), 0.5).set_trans(Tween.TRANS_BACK)
