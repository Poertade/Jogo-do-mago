class_name WandState
extends RefCounted
## A varinha durante o jogo: um recipiente de Vis para cada aspecto (os primais: Ignis, Aqua…).
## Há dois limites:
## - cada recipiente guarda no máximo `aspect_capacity` (ex.: 10 de Ignis);
## - a soma de todos os recipientes não passa de `capacity` (ex.: 30 no total).
## Exemplo: com 10 por aspecto e 30 no total, cabem 10 de Ignis, 10 de Aqua e 10 de Perditio,
## e mais nada.
##
## Eficiência (dada pela ponteira): o custo de cada magia é dividido por ela, em média. Como o
## Vis é contado em números inteiros, a economia se acumula: com eficiência 1,25, cada disparo
## de 1 de Ignis poupa 0,2; a cada cinco, um sai de graça.

## Emitido quando algum recipiente muda (para o HUD).
signal reserves_changed

var wand: WandData
var _reserves: Dictionary[StringName, int] = {}
## Economia acumulada de cada aspecto (a fração de Vis já poupada que ainda não virou 1).
var _saved: Dictionary[StringName, float] = {}


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


## O maior custo de uma magia nesta varinha (sem economia acumulada): cada custo dividido
## pela eficiência, arredondado para cima.
func effective_cost(cost: Dictionary) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for aspect_id: StringName in cost:
		result[aspect_id] = ceili(cost[aspect_id] / maxf(wand.efficiency, 0.01) - 0.0001)
	return result


## Quanto a próxima magia custa agora, contando a economia acumulada.
func cost_now(cost: Dictionary) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for aspect_id: StringName in cost:
		var amount: int = cost[aspect_id]
		result[aspect_id] = maxi(amount - floori(_saved.get(aspect_id, 0.0) + _saving(amount) + 0.0001), 0)
	return result


func can_pay(cost: Dictionary) -> bool:
	var now := cost_now(cost)
	for aspect_id in now:
		if reserve(aspect_id) < now[aspect_id]:
			return false
	return true


## Gasta o custo dos recipientes. Devolve false (sem gastar nada) se faltar Vis de algum aspecto.
func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	var now := cost_now(cost)
	for aspect_id in now:
		var amount: int = cost[aspect_id]
		_reserves[aspect_id] = reserve(aspect_id) - now[aspect_id]
		# O que foi poupado de verdade sai da economia; o resto (a fração) continua guardado.
		_saved[aspect_id] = _saved.get(aspect_id, 0.0) + _saving(amount) - (amount - now[aspect_id])
	reserves_changed.emit()
	return true


## Quanto Vis a eficiência poupa num custo de `amount` (pode ser fração).
func _saving(amount: int) -> float:
	return amount - amount / maxf(wand.efficiency, 0.01)


## Troca a varinha (outro núcleo ou outra ponteira), mantendo o Vis que couber nela.
func set_wand(wand_data: WandData) -> void:
	wand = wand_data
	for aspect_id in _reserves.keys():
		if not has_container(aspect_id):
			_reserves.erase(aspect_id)
		else:
			_reserves[aspect_id] = mini(_reserves[aspect_id], aspect_capacity())
	# Se a soma passar do novo limite total, tira primeiro dos recipientes mais cheios.
	while total() > total_capacity():
		var fullest: StringName = _reserves.keys()[0]
		for aspect_id in _reserves:
			if _reserves[aspect_id] > _reserves[fullest]:
				fullest = aspect_id
		_reserves[fullest] -= 1
	reserves_changed.emit()


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
	_saved.clear()
	for aspect_id: StringName in initial:
		var amount: int = clampi(initial[aspect_id], 0, room_for(aspect_id))
		if amount > 0:
			_reserves[aspect_id] = amount
	reserves_changed.emit()


## O recipiente do aspecto não aceita mais nada (cheio, ou a varinha toda cheia)?
func is_full(aspect_id: StringName) -> bool:
	return room_for(aspect_id) <= 0


## Quantos disparos dá para fazer agora com este custo (contando a economia da eficiência).
func casts_available(cost: Dictionary) -> int:
	var copy := WandState.new(wand)
	copy._reserves = _reserves.duplicate()
	copy._saved = _saved.duplicate()
	var casts := 0
	while casts < 1000 and copy.pay(cost):
		casts += 1
	return casts


## A soma chegou ao limite total?
func is_total_full() -> bool:
	return total() >= total_capacity()
