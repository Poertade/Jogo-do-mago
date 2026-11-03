class_name WandState
extends RefCounted
## A varinha durante o jogo: um recipiente de Vis para cada aspecto (os primais: Ignis, Aqua…).
## Há dois limites:
## - cada recipiente guarda no máximo `aspect_capacity` (ex.: 10 de Ignis);
## - a soma de todos os recipientes não passa de `capacity` (ex.: 30 no total).
## Exemplo: com 10 por aspecto e 30 no total, cabem 10 de Ignis, 10 de Aqua e 10 de Perditio,
## e mais nada.

## Emitido quando algum recipiente muda (para o HUD).
signal reserves_changed

var wand: WandData
var _reserves: Dictionary[StringName, int] = {}


## `initial`: Vis com que a varinha começa (aspecto → quantidade).
func _init(wand_data: WandData, initial: Dictionary = {}) -> void:
	wand = wand_data
	reset(initial)


## Limite da soma de todos os recipientes.
func total_capacity() -> int:
	return wand.capacity


## Limite de cada recipiente.
func aspect_capacity() -> int:
	return wand.aspect_capacity


## Quanto Vis do aspecto está guardado.
func reserve(aspect_id: StringName) -> int:
	return _reserves.get(aspect_id, 0)


## Soma de todos os recipientes.
func total() -> int:
	var sum := 0
	for aspect_id in _reserves:
		sum += _reserves[aspect_id]
	return sum


## A varinha tem recipiente para este aspecto?
func has_container(aspect_id: StringName) -> bool:
	return aspect_id in wand.aspects


## Quanto ainda cabe do aspecto: o espaço do recipiente, sem passar do total.
func room_for(aspect_id: StringName) -> int:
	if not has_container(aspect_id):
		return 0
	return maxi(mini(aspect_capacity() - reserve(aspect_id), total_capacity() - total()), 0)


## Custo real de uma magia nesta varinha: cada custo dividido pela eficiência, arredondado
## para cima.
func effective_cost(cost: Dictionary) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for aspect_id: StringName in cost:
		result[aspect_id] = ceili(cost[aspect_id] / maxf(wand.efficiency, 0.01))
	return result


func can_pay(cost: Dictionary) -> bool:
	var real := effective_cost(cost)
	for aspect_id in real:
		if reserve(aspect_id) < real[aspect_id]:
			return false
	return true


## Gasta o custo dos recipientes. Devolve false (sem gastar nada) se faltar Vis de algum aspecto.
func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	var real := effective_cost(cost)
	for aspect_id in real:
		_reserves[aspect_id] = reserve(aspect_id) - real[aspect_id]
	reserves_changed.emit()
	return true


## Acrescenta Vis ao recipiente do aspecto, sem passar dos limites. Devolve quanto entrou.
func add(aspect_id: StringName, amount: int) -> int:
	var added := clampi(amount, 0, room_for(aspect_id))
	if added > 0:
		_reserves[aspect_id] = reserve(aspect_id) + added
		reserves_changed.emit()
	return added


## Esvazia a varinha e a enche com `initial` (aspecto → quantidade), respeitando os limites.
func reset(initial: Dictionary = {}) -> void:
	_reserves.clear()
	for aspect_id: StringName in initial:
		var amount: int = clampi(initial[aspect_id], 0, room_for(aspect_id))
		if amount > 0:
			_reserves[aspect_id] = amount
	reserves_changed.emit()


## O recipiente do aspecto não aceita mais nada (cheio, ou a varinha toda cheia)?
func is_full(aspect_id: StringName) -> bool:
	return room_for(aspect_id) <= 0


## Quantos disparos dá para fazer agora com este custo.
func casts_available(cost: Dictionary) -> int:
	var real := effective_cost(cost)
	var casts := -1
	for aspect_id in real:
		if real[aspect_id] > 0:
			var possible := reserve(aspect_id) / real[aspect_id]
			casts = possible if casts < 0 else mini(casts, possible)
	return maxi(casts, 0)


## A soma chegou ao limite total?
func is_total_full() -> bool:
	return total() >= total_capacity()
