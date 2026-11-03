class_name PortalAnchor
extends Interactable
## Âncora do portal: um cristal que prende o portal da escola a este lugar do mapa (como os
## cristais de viagem do Lunacid). Ao tocá-la pela primeira vez, ela é sintonizada (vai para o
## save) e o portal passa a poder trazer o jogador até aqui. Depois, ela leva de volta à escola
## com vida, e o que foi achado na incursão vai junto.

## Identificador da âncora (o mesmo de data/dungeon/rules.tres).
@export var anchor_id: StringName

var _time := 0.0

@onready var arrival: Marker3D = $Arrival
@onready var crystal: Node3D = $Crystal


func is_attuned() -> bool:
	return Game.attuned_anchors().has(anchor_id)


func current_prompt_key() -> String:
	return "PROMPT_ANCHOR_RETURN" if is_attuned() else "PROMPT_ANCHOR_ATTUNE"


func interact(_player: Node3D) -> void:
	if is_attuned():
		Game.return_to_school()
		return
	Game.world.attune(anchor_id)
	var name_key: String = Content.db.dungeon_rules.anchor_names.get(anchor_id, "")
	Game.message(Text.tr_key("UI_MSG_ANCHOR_ATTUNED") % Text.tr_key(name_key), Color(0.75, 0.65, 1.0))
	Audio.play(&"portal")


func _process(delta: float) -> void:
	_time += delta
	crystal.rotation.y = _time * 0.6
	crystal.position.y = 1.25 + 0.08 * sin(_time * 1.6)
