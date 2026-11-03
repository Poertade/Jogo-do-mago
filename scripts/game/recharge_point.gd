class_name RechargePoint
extends Interactable
## Ponto de recarga (o braseiro do Salão de Estudos): interagir enche a reserva da varinha
## de um aspecto. Pela decisão 3, não há recarga fora da escola.

## Aspecto recarregado (ex.: fire).
@export var aspect: StringName = &"fire"


func interact(_player: Node3D) -> void:
	var wand := Game.run.wand
	var aspect_name := Text.aspect_name(aspect)
	if wand.is_full(aspect):
		Game.message(Text.tr_key("UI_MSG_ALREADY_FULL") % aspect_name)
		return
	wand.refill(aspect)
	Game.message(Text.tr_key("UI_MSG_RECHARGED") % aspect_name, Content.db.aspects[aspect].color)
