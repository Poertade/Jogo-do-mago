class_name SpellCaster
extends RefCounted
## A magia do Focus equipado: segurar o botão carrega; soltar com a carga completa lança
## (e só então gasta a energia); soltar antes cancela sem custo. Depois de lançar, há um
## intervalo até poder carregar de novo.

enum State { IDLE, CHARGING, CHARGED }
## Por que a carga não começou.
enum Failure { NONE, COOLDOWN, NO_ENERGY, BUSY }

var focus: FocusData
var wand: WandState
var state := State.IDLE
var charge_elapsed := 0.0
var cooldown_left := 0.0


func _init(focus_data: FocusData, wand_state: WandState) -> void:
	focus = focus_data
	wand = wand_state


## Começa a carregar. Devolve o motivo se não for possível.
func start_charge() -> Failure:
	if state != State.IDLE:
		return Failure.BUSY
	if cooldown_left > 0.0:
		return Failure.COOLDOWN
	if not wand.can_pay(focus.cost):
		return Failure.NO_ENERGY
	state = State.CHARGING
	charge_elapsed = 0.0
	return Failure.NONE


## Avança o tempo de carga e do intervalo.
func update(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if state == State.CHARGING:
		charge_elapsed += delta
		if charge_elapsed >= focus.charge_time:
			state = State.CHARGED


## Solta o botão. Devolve true se a magia foi lançada (e a energia, gasta).
func release() -> bool:
	var was_charged := state == State.CHARGED
	state = State.IDLE
	charge_elapsed = 0.0
	if not was_charged or not wand.pay(focus.cost):
		return false
	cooldown_left = focus.cooldown
	return true


## Troca o Focus encaixado na varinha (a carga em andamento se perde, sem custo).
func equip(focus_data: FocusData) -> void:
	cancel()
	focus = focus_data


func cancel() -> void:
	state = State.IDLE
	charge_elapsed = 0.0


## Está carregando ou com a carga pronta (a mão da varinha está ocupada)?
func is_busy() -> bool:
	return state != State.IDLE


func charge_ratio() -> float:
	if state == State.CHARGED:
		return 1.0
	if state == State.IDLE or focus.charge_time <= 0.0:
		return 0.0
	return clampf(charge_elapsed / focus.charge_time, 0.0, 1.0)


## Dano do disparo, com os efeitos das páginas estudadas (antes das fraquezas do alvo).
func damage(modifiers: Modifiers) -> float:
	return focus.damage * modifiers.damage_multiplier(focus.element)
