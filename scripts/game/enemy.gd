class_name Enemy
extends CharacterBody3D
## Inimigo. A decisão (parado, perseguindo, atacando, reação ao dano, morte) fica em EnemyBrain
## (scripts/core); o corpo e as animações ficam no nó "Rig" (um EnemyBody: EnemyRig para
## humanoides, BlobRig para a gosma, EyeRig para os olhos que flutuam). Os de corpo a corpo
## golpeiam de perto; os à distância (`ranged`) mantêm distância e atiram (EnemyShot);
## aqui ficam o movimento, a visão, o dano e os sons.
## Pode ser escaneado pela Lente (get_scannable) e recebe dano (take_damage).
## Na Dungeon, anda pela malha de navegação (NavigationAgent3D), contornando pilares e móveis;
## ao notar o jogador, acorda os inimigos por perto, e o barulho das magias também os acorda.

signal died

## Raio em que um inimigo que nota o jogador acorda os outros, em metros.
const ALERT_RADIUS := 9.0

## Tipo de inimigo (preenchido pelo EnemySpawn; pode ser definido no editor para testes).
@export var data: EnemyData

var health: Health
var brain: EnemyBrain
## Lentidão (Focus de Gelo): fração da velocidade e segundos que ainda faltam.
var _slow_factor := 1.0
var _slow_left := 0.0
var _agent: NavigationAgent3D
var _player: Node3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var rig: EnemyBody = $Rig


func _ready() -> void:
	health = Health.new(data.max_health)
	brain = EnemyBrain.new(data)
	brain.attack_landed.connect(_on_attack_landed)
	health.died.connect(_on_died)
	_player = get_tree().get_first_node_in_group(&"player")
	# O Focus de Choque procura os próximos alvos da corrente neste grupo.
	add_to_group(&"enemies")
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 0.8
	_agent.radius = 0.45
	_agent.height = 1.8
	add_child(_agent)
	Game.enemy_alerted.connect(_on_alerted)
	Game.noise_made.connect(_on_noise)


func get_scannable() -> ScannableData:
	return data


## Recebe dano de um elemento; as fraquezas do inimigo multiplicam o valor.
func take_damage(amount: float, element: StringName) -> void:
	if health.is_dead():
		return
	health.take_damage(Combat.damage_against(amount, element, data.weaknesses))
	if not health.is_dead():
		brain.on_damaged()
		rig.play_hurt()
		if brain.check_enrage(health.current / health.max_health):
			_enrage()
		Audio.play_at(_sound(&"hurt"), global_position + Vector3.UP, get_parent())


## Fica lento por `seconds` segundos: anda, prepara o golpe e se anima a `factor` da velocidade.
func apply_slow(factor: float, seconds: float) -> void:
	if health.is_dead():
		return
	_slow_factor = clampf(factor, 0.05, 1.0)
	_slow_left = maxf(_slow_left, seconds)
	rig.set_frost(1.0)


func _physics_process(real_delta: float) -> void:
	# Lento: o tempo do inimigo passa mais devagar (passos, preparação do golpe, animação).
	var delta := real_delta
	if _slow_left > 0.0:
		_slow_left -= real_delta
		delta *= _slow_factor
		if _slow_left <= 0.0:
			rig.set_frost(0.0)
	if not is_on_floor():
		velocity.y -= _gravity * real_delta
	if brain.state == EnemyBrain.State.DEAD or _player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	var previous := brain.state
	brain.update(delta, distance, _can_see_player())
	_play_state_sounds(previous, brain.state)
	if previous == EnemyBrain.State.ATTACK and brain.state != EnemyBrain.State.ATTACK \
			and brain.state != EnemyBrain.State.HURT:
		rig.play_strike()

	var move := Vector3.ZERO
	var facing := to_player
	if data.ranged:
		move = _ranged_move(to_player, distance)
	elif brain.wants_to_move() and distance > data.attack_range * 0.8:
		var direction := _chase_direction(to_player)
		move = direction * data.move_speed * brain.speed_multiplier() * (_slow_factor if _slow_left > 0.0 else 1.0)
		# Longe, olha para onde anda (contornando); perto, encara o jogador.
		if distance > data.attack_range * 2.0:
			facing = direction
	velocity.x = move.x
	velocity.z = move.z
	if brain.state != EnemyBrain.State.IDLE and facing.length() > 0.01:
		# Vira devagar.
		var target_yaw := atan2(-facing.x, -facing.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-6.0 * delta))
	move_and_slide()
	var alert := brain.state != EnemyBrain.State.IDLE
	rig.update_pose(delta, Vector2(velocity.x, velocity.z).length(), data.move_speed, brain.windup_ratio(), alert)


## Inimigos à distância: chegam até ter o jogador ao alcance e à vista, recuam se ele chega
## perto demais e, no meio-termo, ficam parados mirando.
func _ranged_move(to_player: Vector3, distance: float) -> Vector3:
	if not brain.wants_to_move():
		return Vector3.ZERO
	var speed := data.move_speed * brain.speed_multiplier() * (_slow_factor if _slow_left > 0.0 else 1.0)
	if distance < data.keep_distance:
		return -to_player.normalized() * speed
	if distance > data.attack_range * 0.85 or not _can_see_player():
		return _chase_direction(to_player) * speed
	return Vector3.ZERO


## Para onde andar para chegar ao jogador: pelo caminho da malha de navegação (em volta dos
## obstáculos) quando a sala tem uma; em linha reta, se não tiver.
func _chase_direction(to_player: Vector3) -> Vector3:
	if _agent != null and _has_navigation():
		_agent.target_position = _player.global_position
		var next := _agent.get_next_path_position() - global_position
		next.y = 0.0
		if next.length() > 0.05:
			return next.normalized()
	return to_player.normalized()


func _has_navigation() -> bool:
	var map := get_world_3d().navigation_map
	return NavigationServer3D.map_get_iteration_id(map) > 0 and not NavigationServer3D.map_get_regions(map).is_empty()


func _on_alerted(at: Vector3) -> void:
	if not health.is_dead() and global_position.distance_to(at) <= ALERT_RADIUS:
		brain.alert()


func _on_noise(at: Vector3, radius: float) -> void:
	if not health.is_dead() and global_position.distance_to(at) <= radius:
		brain.alert()


## Enxerga o jogador se nada bloqueia a linha entre os olhos dele e a cabeça do jogador.
func _can_see_player() -> bool:
	var from := global_position + Vector3.UP * 1.5
	var to := _player.global_position + Vector3.UP * 1.5
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	# Só paredes e corpos (camada 1); decorações escaneáveis (camada 2) não tapam a visão.
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == _player


func _on_attack_landed() -> void:
	if not data.ranged:
		Game.damage_player(data.damage)
		return
	# Tiro (ou leque de tiros) dos olhos em direção ao peito do jogador.
	var from: Vector3 = rig.shot_origin() if rig.has_method(&"shot_origin") else global_position + Vector3.UP * 1.4
	var target := _player.global_position + Vector3.UP * 1.2
	var count := maxi(data.shot_count, 1)
	for i in count:
		var spread := deg_to_rad(12.0) * (i - (count - 1) / 2.0)
		var direction: Vector3 = (target - from).normalized().rotated(Vector3.UP, spread)
		var shot := EnemyShot.new()
		get_parent().add_child(shot)
		shot.global_position = from
		shot.setup(direction * data.shot_speed, data.damage, data.shot_color, get_rid())
	Audio.play_at(_sound(&"swing"), from, get_parent())


func _on_died() -> void:
	brain.on_died()
	$CollisionShape3D.set_deferred("disabled", true)
	rig.play_death()
	Audio.play_at(_sound(&"death"), global_position + Vector3.UP, get_parent())
	# Espólio: a prata vai direto para o que foi achado na incursão.
	if data.silver_max > 0:
		Game.find_item(&"silver", Game.rng.range_int(data.silver_min, data.silver_max))
	if data.material != &"" and Game.rng.next_float() < data.material_chance:
		if data.material_safe:
			Game.give_relic(data)
		else:
			Game.find_item(data.material, data.material_amount)
	died.emit()


## Fúria (chefes): avisa, brilha mais e chama ajuda, que aparece em volta dele.
func _enrage() -> void:
	if data.enrage_message_key != "":
		Game.message(Text.expand(data.enrage_message_key), Color(0.9, 0.5, 0.45))
	rig.play_enrage()
	Audio.play_at(_sound(&"alert"), global_position + Vector3.UP * 1.5, get_parent())
	var room := get_parent() as Room
	if room == null:
		return
	for i in data.enrage_summons.size():
		var angle := TAU * i / data.enrage_summons.size() + rotation.y
		var at := global_position + Vector3(cos(angle), 0.0, sin(angle)) * 2.2
		var summoned := room.spawn_enemy(data.enrage_summons[i], Transform3D(global_basis, at))
		summoned.brain.on_damaged()


## Gemido ao notar o jogador; sopro ao começar o golpe (o aviso para esquivar).
func _play_state_sounds(previous: EnemyBrain.State, current: EnemyBrain.State) -> void:
	if previous == current:
		return
	if previous == EnemyBrain.State.IDLE and current != EnemyBrain.State.DEAD:
		# Acordou: chama os que estão por perto (o sinal volta para ele também, sem efeito).
		Game.enemy_alerted.emit.call_deferred(global_position)
		if data.show_health_bar:
			Game.boss_engaged.emit(self)
	if previous == EnemyBrain.State.IDLE and current == EnemyBrain.State.CHASE:
		Audio.play_at(_sound(&"alert"), global_position + Vector3.UP * 1.5, get_parent())
	elif current == EnemyBrain.State.ATTACK:
		Audio.play_at(_sound(&"swing"), global_position + Vector3.UP, get_parent())


## Nome do som deste inimigo para o evento (alert, swing, hurt, death): o do conjunto próprio
## (`sound_set`), se existir no banco; senão, o genérico.
func _sound(kind: StringName) -> StringName:
	var own := StringName("%s_%s" % [data.sound_set, kind])
	return own if data.sound_set != &"" and Audio.has_sound(own) else StringName("enemy_" + String(kind))
