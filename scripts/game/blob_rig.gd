class_name BlobRig
extends EnemyBody
## Corpo de gosma (Lodo de Tinta): uma massa que se arrasta encolhendo e esticando, com um
## braço de tinta (pseudópode) que se ergue para golpear. Animado "aos trancos", como o EnemyRig.
##
## Nós esperados (filhos deste nó): Body (com Blob, Eyes e Drips) e Body/Arm (o braço).

## Quanto a massa encolhe e estica ao se arrastar (0,15 = 15%).
@export var squash := 0.15
## Ângulo do braço em repouso, erguido na preparação e no fim do golpe (graus, eixo X; o braço
## sai do corpo para cima, e ângulos negativos o inclinam para a frente).
@export var arm_rest_degrees := -35.0
@export var arm_raised_degrees := 45.0
@export var arm_slam_degrees := -115.0

var _time := 0.0
var _frame_time := 0.0
var _phase := 0.0
var _move := 0.0
var _strike_time := 0.0
var _hurt_time := 0.0
var _dead := false

@onready var body: Node3D = $Body
@onready var blob: Node3D = $Body/Blob
@onready var eyes: Node3D = $Body/Eyes
@onready var drips: Node3D = $Body/Drips
@onready var arm: Node3D = $Body/Arm


func update_pose(delta: float, speed: float, max_speed: float, windup: float, alert: bool) -> void:
	if _dead:
		return
	_time += delta
	_strike_time = maxf(_strike_time - delta, 0.0)
	_hurt_time = maxf(_hurt_time - delta, 0.0)
	_move = move_toward(_move, clampf(speed / maxf(max_speed, 0.01), 0.0, 1.0), delta * 4.0)
	_phase += delta * (1.5 + 5.0 * _move)
	_frame_time += delta
	if _frame_time < 1.0 / animation_fps:
		return
	_frame_time = 0.0
	_apply_pose(windup, alert)


func _apply_pose(windup: float, alert: bool) -> void:
	# A massa encolhe e estica; parada, só "respira".
	var wave := sin(_phase * 2.0) * (squash * (0.3 + 0.7 * _move))
	var stretch := 1.0 + wave
	blob.scale = Vector3(1.0 / sqrt(stretch), stretch, 1.0 / sqrt(stretch))
	body.rotation.x = -0.12 * _move
	# Gotas giram devagar em volta da base.
	drips.rotation.y = _time * 0.7
	eyes.position.y = 0.55 + wave * 0.3
	# Braço: em repouso, erguido na preparação, desce de uma vez no golpe.
	var angle := arm_rest_degrees + sin(_time * 1.7) * 8.0 + (12.0 if alert else 0.0)
	if windup > 0.0:
		angle = lerpf(angle, arm_raised_degrees, ease(windup, 0.5))
	if _strike_time > 0.0:
		var t := 1.0 - _strike_time / 0.3
		angle = lerpf(arm_raised_degrees, arm_slam_degrees, minf(t * 3.0, 1.0))
	arm.rotation.x = deg_to_rad(angle)
	# Dano: a massa treme.
	if _hurt_time > 0.0:
		var k := _hurt_time / 0.3
		body.position = Vector3(sin(_time * 60.0) * 0.05 * k, 0.0, 0.0)
	else:
		body.position = Vector3.ZERO


func play_strike() -> void:
	_strike_time = 0.3


func play_hurt() -> void:
	super.play_hurt()
	_hurt_time = 0.3


## Derrete: a massa se espalha numa poça e os olhos se apagam.
func play_death() -> void:
	_dead = true
	eyes.visible = false
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(blob, "scale", Vector3(1.7, 0.12, 1.7), 0.8)
	tween.tween_property(arm, "scale", Vector3(1.0, 0.05, 1.0), 0.5)
	tween.tween_property(drips, "scale", Vector3(1.6, 0.3, 1.6), 0.8)
