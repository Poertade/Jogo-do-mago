class_name EnemyBrain
extends RefCounted
## O "cérebro" de um inimigo corpo a corpo: decide o que fazer a partir da distância até o
## jogador e de se ele está à vista. Não move nada: quem move é o nó Enemy (scripts/game).
##
## Estados: IDLE (parado) → CHASE (perseguindo) → ATTACK (golpe com preparação).
## HURT é a reação ao dano (fica parado um instante); DEAD é o fim.

## O golpe acertou: o jogo aplica o dano no jogador.
signal attack_landed

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

## Com que folga o golpe ainda acerta se o jogador recuou durante a preparação.
const ATTACK_REACH_TOLERANCE := 1.2
## Desiste de perseguir quando o jogador some e está além de sight_range × este valor.
const LOSE_INTEREST_FACTOR := 1.5

var data: EnemyData
var state := State.IDLE
var _timer := 0.0
var _cooldown_left := 0.0


func _init(enemy_data: EnemyData) -> void:
	data = enemy_data


## Avança o tempo e decide o próximo estado.
func update(delta: float, distance_to_player: float, can_see_player: bool) -> State:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	match state:
		State.IDLE:
			if can_see_player and distance_to_player <= data.sight_range:
				state = State.CHASE
		State.CHASE:
			if distance_to_player <= data.attack_range and _cooldown_left <= 0.0:
				state = State.ATTACK
				_timer = data.attack_windup
			elif not can_see_player and distance_to_player > data.sight_range * LOSE_INTEREST_FACTOR:
				state = State.IDLE
		State.ATTACK:
			_timer -= delta
			if _timer <= 0.0:
				if distance_to_player <= data.attack_range * ATTACK_REACH_TOLERANCE:
					attack_landed.emit()
				_cooldown_left = data.attack_cooldown
				state = State.CHASE
		State.HURT:
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE
	return state


## Reação ao dano: interrompe o golpe e para um instante. Depois, persegue quem o atingiu.
func on_damaged() -> void:
	if state == State.DEAD:
		return
	state = State.HURT
	_timer = data.hurt_stun


func on_died() -> void:
	state = State.DEAD


func wants_to_move() -> bool:
	return state == State.CHASE


## Fração da preparação do golpe (0 a 1), para a animação.
func windup_ratio() -> float:
	if state != State.ATTACK or data.attack_windup <= 0.0:
		return 0.0
	return clampf(1.0 - _timer / data.attack_windup, 0.0, 1.0)
