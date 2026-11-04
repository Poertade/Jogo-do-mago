class_name Crucible
extends RefCounted
## O cadinho do laboratório da escola, como o do Thaumcraft 4: um material jogado nele se desfaz
## na essência dos aspectos de que é feito (ItemData.aspects), e a essência fica no cadinho (vai
## para o save). Com ela o jogador:
## - anota pontos de pesquisa (1 de essência vira 1 ponto do aspecto, se ele já o descobriu);
## - prepara receitas alquímicas (AlchemyRecipeData): elixires e Vis destilado em potes.

## Emitido a cada mudança (quem grava o save escuta este sinal).
signal changed

## Aspecto → quanto há de essência dele no cadinho.
var essentia: Dictionary[StringName, int] = {}


func amount(aspect_id: StringName) -> int:
	return essentia.get(aspect_id, 0)


## Joga uma unidade do material no cadinho (tirando-a do que está guardado na escola).
## Devolve false se o material não se dissolve ou se não há nenhum guardado.
func dissolve(item: ItemData, stash: Stash) -> bool:
	if item == null or item.aspects.is_empty() or stash.count(item.id) <= 0:
		return false
	stash.spend({item.id: 1})
	for aspect_id in item.aspects:
		essentia[aspect_id] = amount(aspect_id) + item.aspects[aspect_id]
	changed.emit()
	return true


## O que falta no cadinho para pagar `cost` ({aspecto: quanto falta}).
func missing(cost: Dictionary) -> Dictionary:
	var result := {}
	for aspect_id in cost:
		var lacking: int = cost[aspect_id] - amount(aspect_id)
		if lacking > 0:
			result[aspect_id] = lacking
	return result


## Gasta a essência de `cost` (tudo ou nada).
func spend(cost: Dictionary) -> bool:
	if not missing(cost).is_empty():
		return false
	for aspect_id in cost:
		essentia[aspect_id] = amount(aspect_id) - cost[aspect_id]
		if essentia[aspect_id] <= 0:
			essentia.erase(aspect_id)
	changed.emit()
	return true


## Tira toda a essência de um aspecto (para anotar). Devolve quanto havia.
func take_all(aspect_id: StringName) -> int:
	var taken := amount(aspect_id)
	if taken > 0:
		essentia.erase(aspect_id)
		changed.emit()
	return taken
