class_name EyeRig
extends EnemyBody
## Corpo de olho que flutua (Olho Vigia e o Olho do Fundo): um globo com íris, que boia subindo
## e descendo, com nervos pendurados que balançam. Na preparação do tiro, a íris acende; na
## morte, o olho cai e se apaga. Animado "aos trancos", como os outros corpos.
##
## Nós esperados (filhos deste nó): Body (com Ball, Iris, Nerves e Glow).

## Altura em que o olho flutua e quanto ele sobe e desce.
@export var hover_height := 1.5
@export var bob := 0.12

var _time := 0.0
var _frame_time := 0.0
var _hurt_time := 0.0
var _dead := false
var _iris_material: ShaderMaterial

@onready var body: Node3D = $Body
@onready var iris: MeshInstance3D = $Body/Iris
@onready var nerves: Node3D = $Body/Nerves
@onready var glow: OmniLight3D = $Body/Glow


func _ready() -> void:
	super._ready()
	_iris_material = iris.material_override as ShaderMaterial


func update_pose(delta: float, _speed: float, _max_speed: float, windup: float, alert: bool) -> void:
	if _dead:
		return
	_time += delta
	_hurt_time = maxf(_hurt_time - delta, 0.0)
	_frame_time += delta
	if _frame_time < 1.0 / animation_fps:
		return
	_frame_time = 0.0
	body.position.y = hover_height + sin(_time * 1.8) * bob
	# Nervos balançam devagar.
	for i in nerves.get_child_count():
		(nerves.get_child(i) as Node3D).rotation.x = sin(_time * 2.2 + i * 1.3) * 0.35
	# A íris acende ao preparar o tiro (e um pouco quando está alerta).
	var energy := 1.2 + (0.6 if alert else 0.0) + windup * 3.0
	_iris_material.set_shader_parameter(&"emission_energy", energy)
	glow.light_energy = 0.4 + windup * 1.6
	if _hurt_time > 0.0:
		body.position.x = sin(_time * 60.0) * 0.05 * _hurt_time / 0.3
	else:
		body.position.x = 0.0


## De onde sai o tiro: o centro da íris.
func shot_origin() -> Vector3:
	return iris.global_position


func play_hurt() -> void:
	super.play_hurt()
	_hurt_time = 0.3


func play_enrage() -> void:
	super.play_enrage()
	_iris_material.set_shader_parameter(&"emission_color", Color(1.0, 0.3, 0.25))
	glow.light_color = Color(1.0, 0.3, 0.25)


## Cai no chão e a íris se apaga.
func play_death() -> void:
	super.play_death()
	_dead = true
	_iris_material.set_shader_parameter(&"emission_energy", 0.0)
	glow.visible = false
	var tween := create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "position:y", 0.35 * body.scale.y, 0.7)
