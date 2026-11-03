class_name Enemy
extends CharacterBody3D
## Inimigo corpo a corpo. A decisão (parado, perseguindo, atacando, reação ao dano, morte)
## fica em EnemyBrain (scripts/core); o corpo e as animações ficam no EnemyRig (nó "Rig");
## aqui ficam o movimento, a visão, o dano e os sons.
## Pode ser escaneado pela Lente (get_scannable) e recebe dano (take_damage).

signal died

## Tipo de inimigo (preenchido pelo EnemySpawn; pode ser definido no editor para testes).
@export var data: EnemyData

var health: Health
var brain: EnemyBrain
var _player: Node3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var rig: EnemyRig = $Rig


func _ready() -> void:
	health = Health.new(data.max_health)
	brain = EnemyBrain.new(data)
	brain.attack_landed.connect(_on_attack_landed)
	health.died.connect(_on_died)
	_player = get_tree().get_first_node_in_group(&"player")


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
		Audio.play_at(&"enemy_hurt", global_position + Vector3.UP, get_parent())


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
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
	if brain.wants_to_move() and distance > data.attack_range * 0.8:
		move = to_player.normalized() * data.move_speed
	velocity.x = move.x
	velocity.z = move.z
	if brain.state != EnemyBrain.State.IDLE and distance > 0.01:
		# Vira devagar para o jogador.
		var target_yaw := atan2(-to_player.x, -to_player.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-6.0 * delta))
	move_and_slide()
	var alert := brain.state != EnemyBrain.State.IDLE
	rig.update_pose(delta, Vector2(velocity.x, velocity.z).length(), data.move_speed, brain.windup_ratio(), alert)


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
	Game.damage_player(data.damage)


func _on_died() -> void:
	brain.on_died()
	$CollisionShape3D.set_deferred("disabled", true)
	rig.play_death()
	Audio.play_at(&"enemy_death", global_position + Vector3.UP, get_parent())
	died.emit()


## Gemido ao notar o jogador; sopro ao começar o golpe (o aviso para esquivar).
func _play_state_sounds(previous: EnemyBrain.State, current: EnemyBrain.State) -> void:
	if previous == current:
		return
	if previous == EnemyBrain.State.IDLE and current == EnemyBrain.State.CHASE:
		Audio.play_at(&"enemy_alert", global_position + Vector3.UP * 1.5, get_parent())
	elif current == EnemyBrain.State.ATTACK:
		Audio.play_at(&"enemy_swing", global_position + Vector3.UP, get_parent())
