class_name Player
extends CharacterBody3D
## Jogador em primeira pessoa: anda (WASD), corre (Shift), pula (Espaço) e olha com o mouse.
## Os valores de movimento vêm de data/player/player.tres.

@export var stats: PlayerData

## Graus de rotação por pixel de movimento do mouse. Vem das opções do jogador.
var mouse_sensitivity := 0.15

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	head.position.y = stats.eye_height


## Coloca o jogador num ponto da sala, olhando na mesma direção do marcador.
func place_at(marker: Node3D) -> void:
	global_position = marker.global_position
	rotation = Vector3(0.0, marker.global_rotation.y, 0.0)
	head.rotation = Vector3.ZERO
	velocity = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		# Movimento horizontal gira o corpo; vertical inclina só a cabeça (limitada para não dar cambalhota).
		rotate_y(deg_to_rad(-motion.relative.x * mouse_sensitivity))
		head.rotation.x = clampf(head.rotation.x - deg_to_rad(motion.relative.y * mouse_sensitivity),
			deg_to_rad(-89.0), deg_to_rad(89.0))


func _physics_process(delta: float) -> void:
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
