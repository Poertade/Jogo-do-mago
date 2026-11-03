class_name ScanProgress
extends RefCounted
## Andamento de um escaneamento: a barra enche enquanto o botão está seguro sobre o mesmo alvo.
## Soltar o botão ou mudar de alvo recomeça do zero. Depois de completar, é preciso soltar
## o botão para escanear de novo.

var duration: float
var target_id: StringName = &""
var elapsed := 0.0
var completed := false


func _init(scan_duration: float) -> void:
	duration = maxf(scan_duration, 0.01)


## Avança o escaneamento. Devolve true só no quadro em que ele completa.
## `current_target` vazio significa que não há alvo na mira.
func update(current_target: StringName, holding: bool, delta: float) -> bool:
	if not holding or current_target == &"":
		reset()
		return false
	if current_target != target_id:
		reset()
		target_id = current_target
	if completed:
		return false
	elapsed += delta
	if elapsed >= duration:
		completed = true
		return true
	return false


func reset() -> void:
	target_id = &""
	elapsed = 0.0
	completed = false


## Fração completa, de 0 a 1 (para a barra do HUD).
func ratio() -> float:
	return clampf(elapsed / duration, 0.0, 1.0)


func is_active() -> bool:
	return target_id != &""
