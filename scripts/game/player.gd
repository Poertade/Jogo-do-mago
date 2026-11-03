class_name Player
extends CharacterBody3D
## Jogador em primeira pessoa: anda (WASD), corre (Shift), pula (Espaço), olha com o mouse,
## interage (E) e escaneia com a Lente (botão direito).
## Os valores de movimento vêm de data/player/player.tres.

@export var stats: PlayerData

## Graus de rotação por pixel de movimento do mouse. Vem das opções do jogador.
var mouse_sensitivity := 0.15

## O que está na mira, atualizado a cada quadro de física.
var aimed_interactable: Interactable
var aimed_scannable: ScannableData

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var scanner: Scanner = %Scanner


func _ready() -> void:
	head.position.y = stats.eye_height


## Coloca o jogador num ponto da sala, olhando na mesma direção do marcador.
func place_at(marker: Node3D) -> void:
	global_position = marker.global_position
	rotation = Vector3(0.0, marker.global_rotation.y, 0.0)
	head.rotation = Vector3.ZERO
	velocity = Vector3.ZERO


## A mão esquerda pode erguer a Lente? Não enquanto a varinha carrega uma magia.
func can_use_lens() -> bool:
	return not Game.run.caster.is_busy()


## A mão direita pode carregar uma magia? Não enquanto a Lente está erguida.
func can_cast() -> bool:
	return not scanner.is_raised()


## Ponto do mundo para onde a mira aponta (até `max_distance` metros), para mirar projéteis.
func aim_point(max_distance: float) -> Vector3:
	var from := camera.global_position
	var to := from - camera.global_basis.z * max_distance
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else to


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		# Movimento horizontal gira o corpo; vertical inclina só a cabeça (limitada para não dar cambalhota).
		rotate_y(deg_to_rad(-motion.relative.x * mouse_sensitivity))
		head.rotation.x = clampf(head.rotation.x - deg_to_rad(motion.relative.y * mouse_sensitivity),
			deg_to_rad(-89.0), deg_to_rad(89.0))


func _physics_process(delta: float) -> void:
	_move(delta)
	_update_aim()
	if Input.is_action_just_pressed("interact") and aimed_interactable != null \
			and aimed_interactable.is_available():
		aimed_interactable.interact(self)


func _move(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = stats.jump_velocity

	# Direção pedida pelo teclado, girada para onde o jogador está olhando.
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var speed := stats.run_speed if Input.is_action_pressed("run") else stats.walk_speed
	var target := direction * speed
	velocity.x = move_toward(velocity.x, target.x, stats.acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, stats.acceleration * delta)
	move_and_slide()


## Lança um raio do centro da câmera e guarda o que ele atinge primeiro.
func _update_aim() -> void:
	aimed_interactable = null
	aimed_scannable = null
	var scan_range := Content.db.research_rules.scan_range
	var max_range := maxf(scan_range, stats.interact_range)
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * max_range)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var distance := from.distance_to(hit.position)
	if distance <= stats.interact_range:
		aimed_interactable = Interactable.find_on(hit.collider)
	if distance <= scan_range:
		aimed_scannable = ScannableProp.find_on(hit.collider)
