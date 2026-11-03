class_name WandState
extends RefCounted
## A varinha durante o jogo: quanto de cada aspecto ainda resta na reserva.

## Emitido quando alguma reserva muda (para o HUD).
signal reserves_changed

var wand: WandData
var _reserves: Dictionary[StringName, int] = {}


func _init(wand_data: WandData) -> void:
	wand = wand_data
	refill_all()


func capacity(aspect_id: StringName) -> int:
	return wand.capacity.get(aspect_id, 0)


func reserve(aspect_id: StringName) -> int:
	return _reserves.get(aspect_id, 0)


## Custo real de uma magia nesta varinha: o custo dividido pela eficiência, arredondado para cima.
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


## Gasta o custo da reserva. Devolve false (sem gastar nada) se não houver energia suficiente.
func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	var real := effective_cost(cost)
	for aspect_id in real:
		_reserves[aspect_id] = reserve(aspect_id) - real[aspect_id]
	reserves_changed.emit()
	return true


## Enche a reserva de um aspecto até a capacidade.
func refill(aspect_id: StringName) -> void:
	_reserves[aspect_id] = capacity(aspect_id)
	reserves_changed.emit()


func refill_all() -> void:
	for aspect_id in wand.capacity:
		_reserves[aspect_id] = wand.capacity[aspect_id]
	reserves_changed.emit()


func is_full(aspect_id: StringName) -> bool:
	return reserve(aspect_id) >= capacity(aspect_id)
