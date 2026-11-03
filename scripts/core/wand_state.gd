class_name WandState
extends RefCounted
## A varinha durante o jogo: quanto Vis ainda resta na reserva (única, como no Thaumcraft 3).

## Emitido quando a reserva muda (para o HUD).
signal reserves_changed

var wand: WandData
var vis := 0


func _init(wand_data: WandData) -> void:
	wand = wand_data
	refill()


func capacity() -> int:
	return wand.capacity


## Custo real de uma magia nesta varinha: o custo dividido pela eficiência, arredondado para cima.
func effective_cost(cost: int) -> int:
	return ceili(cost / maxf(wand.efficiency, 0.01))


func can_pay(cost: int) -> bool:
	return vis >= effective_cost(cost)


## Gasta o custo da reserva. Devolve false (sem gastar nada) se não houver Vis suficiente.
func pay(cost: int) -> bool:
	if not can_pay(cost):
		return false
	vis -= effective_cost(cost)
	reserves_changed.emit()
	return true


## Acrescenta Vis, sem passar da capacidade. Devolve quanto entrou.
func add(amount: int) -> int:
	var added := clampi(amount, 0, capacity() - vis)
	if added > 0:
		vis += added
		reserves_changed.emit()
	return added


## Enche a reserva até a capacidade.
func refill() -> void:
	vis = capacity()
	reserves_changed.emit()


func is_full() -> bool:
	return vis >= capacity()
