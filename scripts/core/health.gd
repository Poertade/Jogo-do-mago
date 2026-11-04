class_name Health
extends RefCounted
## Vida de quem pode tomar dano (o jogador ou um inimigo).

signal damaged(amount: float)
signal died

var max_health: float
var current: float


func _init(maximum: float) -> void:
	max_health = maximum
	current = maximum


## Aplica dano (já com fraquezas calculadas). Devolve o dano efetivamente tirado.
func take_damage(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var applied := minf(amount, current)
	current -= applied
	damaged.emit(applied)
	if current <= 0.0:
		died.emit()
	return applied


func is_dead() -> bool:
	return current <= 0.0


func restore() -> void:
	current = max_health


## Cura (sem passar do máximo; quem já caiu não se levanta). Devolve quanto curou.
func heal(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var healed := minf(amount, max_health - current)
	current += healed
	return healed


func ratio() -> float:
	return current / max_health if max_health > 0.0 else 0.0
