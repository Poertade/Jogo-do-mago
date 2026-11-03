class_name Enemy
extends CharacterBody3D
## Inimigo corpo a corpo. A decisão (parado, perseguindo, atacando, reação ao dano, morte)
## fica em EnemyBrain (scripts/core); aqui ficam o movimento, a visão, as animações e o dano.
## Pode ser escaneado pela Lente (get_scannable) e recebe dano (take_damage).

signal died

## Tipo de inimigo (preenchido pelo EnemySpawn; pode ser definido no editor para testes).
@export var data: EnemyData

var health: Health
var brain: EnemyBrain
var _player: Node3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _walk_time := 0.0

@onready var model: Node3D = $Model
@onready var arm: Node3D = $Model/ArmPivot
@onready var eyes: Node3D = $Model/Eyes
@onready var flash_material: ShaderMaterial = $Model/Robe.material_override


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
		_flash()


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
	brain.update(delta, distance, _can_see_player())

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
	_animate(delta, move.length() > 0.0)


## Enxerga o jogador se nada bloqueia a linha entre os olhos dele e a cabeça do jogador.
func _can_see_player() -> bool:
	var from := global_position + Vector3.UP * 1.5
	var to := _player.global_position + Vector3.UP * 1.5
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == _player


func _on_attack_landed() -> void:
	Game.damage_player(data.damage)


func _on_died() -> void:
	brain.on_died()
	$CollisionShape3D.set_deferred("disabled", true)
	eyes.visible = false
	# Desmorona: tomba para trás e afunda um pouco.
	var tween := create_tween().set_parallel()
	tween.tween_property(model, "rotation:x", deg_to_rad(80.0), 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(model, "position:y", -0.5, 0.6)
	died.emit()


## Clarão branco rápido ao tomar dano.
func _flash() -> void:
	var tween := create_tween()
	tween.tween_method(func(v: float): flash_material.set_shader_parameter(&"emission_energy", v), 1.2, 0.0, 0.25)


## Balanço ao andar e braço erguido na preparação do golpe.
func _animate(delta: float, walking: bool) -> void:
	if walking:
		_walk_time += delta * 6.0
	model.position.y = absf(sin(_walk_time)) * 0.05 if walking else move_toward(model.position.y, 0.0, delta)
	model.rotation.z = sin(_walk_time) * 0.06 if walking else 0.0
	var raise := brain.windup_ratio()
	arm.rotation.x = lerpf(0.0, deg_to_rad(-150.0), raise) if brain.state == EnemyBrain.State.ATTACK else \
		move_toward(arm.rotation.x, 0.0, delta * 12.0)
