class_name Room
extends Node3D
## Raiz de uma cena de sala (scenes/rooms/). A sala é montada no editor com
## GreyboxBlock, luzes e marcadores (EntrancePoint) como filhos.


## Procura uma entrada pelo identificador. Se não achar, devolve a primeira que houver.
func get_entrance(entrance_id: StringName) -> EntrancePoint:
	var first: EntrancePoint = null
	for node in find_children("*", "EntrancePoint", true, false):
		var entrance := node as EntrancePoint
		if entrance.id == entrance_id:
			return entrance
		if first == null:
			first = entrance
	if first != null:
		push_warning("Sala '%s': entrada '%s' não existe; usando '%s'." % [name, entrance_id, first.id])
	return first
