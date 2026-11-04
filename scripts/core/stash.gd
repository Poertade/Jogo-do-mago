class_name Stash
extends RefCounted
## O que o jogador guarda na escola, para sempre (vai para o save): materiais (prata, cacos de
## vidro, osso…), quantos potes de Vis ele tem e as peças de varinha que já fez (núcleos e
## ponteiras), com as que estão montadas. O que é achado numa incursão só entra aqui quando
## ele volta vivo (veja RunState.found); morrer não tira nada daqui.

## Emitido a cada mudança (quem grava o save escuta este sinal).
signal changed

## Material → quantidade (ex.: &"silver" → 25). Os materiais ficam em data/items/.
var items: Dictionary[StringName, int] = {}
## Potes de Vis que o jogador tem (vão no cinto a cada incursão).
var jars := 0
## Núcleos e ponteiras já feitos na Bancada Arcana (além dos iniciais) e os que estão montados
## (vazio: o inicial).
var cores: Array[StringName] = []
var caps: Array[StringName] = []
var core: StringName = &""
var cap: StringName = &""
## Elixires preparados no cadinho: elixir → quantos (vão junto em toda incursão).
var elixirs: Dictionary[StringName, int] = {}


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


## Guarda um núcleo novo e o monta na varinha.
func add_core(core_id: StringName) -> void:
	if not core_id in cores:
		cores.append(core_id)
	core = core_id
	changed.emit()


## Guarda uma ponteira nova e a monta na varinha.
func add_cap(cap_id: StringName) -> void:
	if not cap_id in caps:
		caps.append(cap_id)
	cap = cap_id
	changed.emit()


## Monta na varinha um núcleo (`is_core`) ou uma ponteira que o jogador já tem.
func equip(part_id: StringName, is_core: bool) -> void:
	if is_core:
		core = part_id
	else:
		cap = part_id
	changed.emit()


## Quantos elixires o jogador tem, somando todos.
func elixir_total() -> int:
	var total := 0
	for elixir_id in elixirs:
		total += elixirs[elixir_id]
	return total


## Guarda um elixir, se ainda couber (`max_elixirs` no total). Devolve false se não couber.
func add_elixir(elixir_id: StringName, max_elixirs: int) -> bool:
	if elixir_total() >= max_elixirs:
		return false
	elixirs[elixir_id] = elixirs.get(elixir_id, 0) + 1
	changed.emit()
	return true


## Gasta um elixir. Devolve false se não havia nenhum.
func use_elixir(elixir_id: StringName) -> bool:
	if elixirs.get(elixir_id, 0) <= 0:
		return false
	elixirs[elixir_id] -= 1
	if elixirs[elixir_id] <= 0:
		elixirs.erase(elixir_id)
	changed.emit()
	return true
