class_name Stash
extends RefCounted
## O que o jogador guarda na escola, para sempre (vai para o save): materiais (prata, cacos de
## vidro…) e quantos potes de Vis ele tem. O que é achado numa incursão só entra aqui quando
## ele volta vivo (veja RunState.found); morrer não tira nada daqui.

## Emitido a cada mudança (quem grava o save escuta este sinal).
signal changed

## Material → quantidade (ex.: &"silver" → 25). Os materiais ficam em data/items/.
var items: Dictionary[StringName, int] = {}
## Potes de Vis que o jogador tem (vão no cinto a cada incursão).
var jars := 0


func count(item_id: StringName) -> int:
	return items.get(item_id, 0)


## Guarda materiais: {material: quantidade}.
func add(amounts: Dictionary) -> void:
	var added := false
	for item_id: StringName in amounts:
		if amounts[item_id] > 0:
			items[item_id] = count(item_id) + amounts[item_id]
			added = true
	if added:
		changed.emit()


## O que falta para pagar `cost` ({material: quantidade}); vazio se der para pagar.
func missing(cost: Dictionary) -> Dictionary:
	var result := {}
	for item_id: StringName in cost:
		var lacking: int = cost[item_id] - count(item_id)
		if lacking > 0:
			result[item_id] = lacking
	return result


func can_afford(cost: Dictionary) -> bool:
	return missing(cost).is_empty()


## Gasta os materiais de `cost` (tudo ou nada). Devolve false se faltar algo.
func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for item_id: StringName in cost:
		items[item_id] = count(item_id) - cost[item_id]
	changed.emit()
	return true


## Ganha um pote, se ainda couber no cinto (`max_jars`). Devolve false se não couber.
func add_jar(max_jars: int) -> bool:
	if jars >= max_jars:
		return false
	jars += 1
	changed.emit()
	return true
