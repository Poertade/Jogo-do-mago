class_name EnemyBrain
extends RefCounted
## O "cérebro" de um inimigo: decide o que fazer a partir da distância até o jogador e de se ele
## está à vista. Não move nada: quem move é o nó Enemy (scripts/game). Inimigos à distância
## (`ranged`) só atacam enxergando o jogador; o "golpe" deles é um tiro.
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
## Enfurecido (chefes, abaixo de `enrage_at` da vida): mais rápido.
var enraged := false
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
			if distance_to_player <= data.attack_range and _cooldown_left <= 0.0 and (can_see_player or not data.ranged):
				state = State.ATTACK
				_timer = _windup()
			elif not can_see_player and distance_to_player > data.sight_range * LOSE_INTEREST_FACTOR:
				state = State.IDLE
		State.ATTACK:
			_timer -= delta
			if _timer <= 0.0:
				if distance_to_player <= data.attack_range * ATTACK_REACH_TOLERANCE:
					attack_landed.emit()
				_cooldown_left = data.attack_cooldown / speed_multiplier()
				state = State.CHASE
		State.HURT:
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHASE
	return state


## Reação ao dano: interrompe o golpe e para um instante. Depois, persegue quem o atingiu.
## Quem tem `hurt_stun` 0 não se abala: só acorda, se estava parado.
func on_damaged() -> void:
	if state == State.DEAD:
		return
	if data.hurt_stun <= 0.0:
		if state == State.IDLE:
			state = State.CHASE
		return
	state = State.HURT
	_timer = data.hurt_stun


func on_died() -> void:
	state = State.DEAD


## Alguém avisou (outro inimigo que viu o jogador, ou o barulho de uma magia): se estava
## parado, passa a perseguir.
func alert() -> void:
	if state == State.IDLE:
		state = State.CHASE


## Confere a fúria com a fração de vida que resta. Devolve true só na vez em que ele se
## enfurece (para o jogo chamar ajuda e avisar).
func check_enrage(health_ratio: float) -> bool:
	if enraged or data.enrage_at <= 0.0 or state == State.DEAD or health_ratio > data.enrage_at:
		return false
	enraged = true
	return true


## Quanto mais rápido ele anda e golpeia (1 = normal).
func speed_multiplier() -> float:
	return maxf(data.enrage_speed, 0.01) if enraged else 1.0


func _windup() -> float:
	return data.attack_windup / speed_multiplier()


func wants_to_move() -> bool:
	return state == State.CHASE


## Fração da preparação do golpe (0 a 1), para a animação.
func windup_ratio() -> float:
	if state != State.ATTACK or _windup() <= 0.0:
		return 0.0
	return clampf(1.0 - _timer / _windup(), 0.0, 1.0)
