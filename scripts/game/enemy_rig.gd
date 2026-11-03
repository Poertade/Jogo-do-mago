class_name EnemyRig
extends EnemyBody
## Corpo articulado de um inimigo humanoide: "juntas" (nós Node3D) que giram para formar as
## poses, com as peças (malhas) penduradas nelas. A animação é calculada por código e
## "travada" em poucos quadros por segundo, como nos jogos de PS1.
##
## Juntas esperadas (por nome, filhas deste nó):
##   Hips/ThighL/KneeL, Hips/ThighR/KneeR, Hips/Spine, Hips/Spine/Neck/Head, .../Head/Jaw,
##   Hips/Spine/ShoulderL/ElbowL, Hips/Spine/ShoulderR/ElbowR e .../Head/Eyes (o brilho).
## Para um inimigo novo com o mesmo esqueleto, duplique a cena e troque as peças e materiais.

## Inclinação do tronco para a frente, em graus (corcunda).
@export var hunch_degrees := 16.0
## Altura do quadril em pé, em metros.
@export var hip_height := 0.92
## Amplitude da passada, em graus.
@export var stride_degrees := 32.0

var _time := 0.0
var _frame_time := 0.0
var _walk_phase := 0.0
var _walk_amount := 0.0
var _strike_time := 0.0
var _hurt_time := 0.0
var _dead := false

@onready var hips: Node3D = $Hips
@onready var thigh_l: Node3D = $Hips/ThighL
@onready var knee_l: Node3D = $Hips/ThighL/KneeL
@onready var thigh_r: Node3D = $Hips/ThighR
@onready var knee_r: Node3D = $Hips/ThighR/KneeR
@onready var spine: Node3D = $Hips/Spine
@onready var head: Node3D = $Hips/Spine/Neck/Head
@onready var jaw: Node3D = $Hips/Spine/Neck/Head/Jaw
@onready var eyes: Node3D = $Hips/Spine/Neck/Head/Eyes
@onready var shoulder_l: Node3D = $Hips/Spine/ShoulderL
@onready var elbow_l: Node3D = $Hips/Spine/ShoulderL/ElbowL
@onready var shoulder_r: Node3D = $Hips/Spine/ShoulderR
@onready var elbow_r: Node3D = $Hips/Spine/ShoulderR/ElbowR


func update_pose(delta: float, speed: float, max_speed: float, windup: float, alert: bool) -> void:
	if _dead:
		return
	_time += delta
	_strike_time = maxf(_strike_time - delta, 0.0)
	_hurt_time = maxf(_hurt_time - delta, 0.0)
	_walk_amount = move_toward(_walk_amount, clampf(speed / maxf(max_speed, 0.01), 0.0, 1.0), delta * 4.0)
	_walk_phase += delta * (2.0 + 3.0 * _walk_amount) * _walk_amount
	# Só muda a pose `animation_fps` vezes por segundo.
	_frame_time += delta
	if _frame_time < 1.0 / animation_fps:
		return
	_frame_time = 0.0
	_apply_pose(windup, alert)


func _apply_pose(windup: float, alert: bool) -> void:
	var walk := _walk_amount
	var s := sin(_walk_phase)
	var c := cos(_walk_phase)
	var stride := deg_to_rad(stride_degrees)
	var hunch := deg_to_rad(hunch_degrees)

	# Pernas: coxa vai e volta; o joelho dobra quando a perna está atrás.
	thigh_l.rotation.x = s * stride * walk
	thigh_r.rotation.x = -s * stride * walk
	knee_l.rotation.x = -maxf(0.0, -c) * 1.0 * walk - 0.08
	knee_r.rotation.x = -maxf(0.0, c) * 1.0 * walk - 0.08
	hips.position.y = hip_height - absf(s) * 0.04 * walk

	# Tronco curvado que balança; respiração lenta parado.
	var breathe := sin(_time * 1.3) * 0.025
	spine.rotation.x = -hunch - 0.06 * walk + breathe
	spine.rotation.z = s * 0.06 * walk
	spine.rotation.y = s * 0.08 * walk

	# Cabeça: compensa a corcunda e inclina de lado de vez em quando (inquietante).
	head.rotation.x = hunch * 0.7 + sin(_time * 0.8) * 0.06
	head.rotation.z = sin(_time * 0.55) * 0.18 + (0.25 if fmod(_time, 5.0) < 0.6 else 0.0)
	# Mandíbula bate quando ele está atrás do jogador.
	jaw.rotation.x = (0.35 if alert and sin(_time * 18.0) > 0.3 else 0.08)

	# Braço esquerdo (com as chaves): balança e, alerta, estica para a frente.
	shoulder_l.rotation.x = -s * 0.45 * walk + (0.55 if alert else 0.1)
	elbow_l.rotation.x = 0.5 if alert else 0.25
	shoulder_l.rotation.z = -0.12

	# Braço direito (com o bastão): parado, preparação (erguido) e golpe (desce de uma vez).
	var rest_r := 0.25 + s * 0.2 * walk
	var arm := rest_r
	var elbow := 0.35
	if windup > 0.0:
		var raise := ease(windup, 0.6)
		arm = lerpf(rest_r, 3.3, raise)
		elbow = lerpf(0.35, 0.9, raise)
		spine.rotation.x += 0.3 * raise
	if _strike_time > 0.0:
		var t := 1.0 - _strike_time / 0.3
		arm = lerpf(3.3, 0.6, minf(t * 2.5, 1.0))
		elbow = 0.2
		spine.rotation.x -= 0.35 * sin(t * PI)
	shoulder_r.rotation.x = arm
	elbow_r.rotation.x = elbow
	shoulder_r.rotation.z = 0.12

	# Reação ao dano: tranco para trás.
	if _hurt_time > 0.0:
		var k := _hurt_time / 0.3
		spine.rotation.x += 0.45 * k
		head.rotation.x -= 0.5 * k
		head.rotation.z += 0.3 * k


## O golpe desce (chamado quando a preparação termina).
func play_strike() -> void:
	_strike_time = 0.3


## Fúria: os olhos brilham o dobro e o corpo fica mais curvado, como quem vai avançar.
func play_enrage() -> void:
	super.play_enrage()
	var glow := eyes.get_node_or_null("Glow") as OmniLight3D
	if glow != null:
		glow.light_energy *= 2.5
		glow.omni_range *= 1.5
	for eye in eyes.get_children():
		if eye is MeshInstance3D:
			var material := (eye as MeshInstance3D).material_override as ShaderMaterial
			material.set_shader_parameter(&"emission_energy", 6.0)
	hunch_degrees += 8.0


## Tranco e clarão branco ao tomar dano.
func play_hurt() -> void:
	super.play_hurt()
	_hurt_time = 0.3


## Desmorona: os joelhos cedem, o tronco dobra, a cabeça tomba e o corpo cai num monte.
func play_death() -> void:
	super.play_death()
	_dead = true
	eyes.visible = false
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(knee_l, "rotation:x", -1.6, 0.35)
	tween.tween_property(knee_r, "rotation:x", -1.4, 0.4)
	tween.tween_property(thigh_l, "rotation:x", 1.2, 0.4)
	tween.tween_property(thigh_r, "rotation:x", 0.9, 0.45)
	tween.tween_property(hips, "position:y", 0.22, 0.45)
	tween.tween_property(spine, "rotation:x", -1.25, 0.55)
	tween.tween_property(head, "rotation:x", 0.9, 0.5)
	tween.tween_property(head, "rotation:z", 0.6, 0.5)
	tween.tween_property(shoulder_l, "rotation:x", -0.4, 0.5)
	tween.tween_property(shoulder_r, "rotation:x", -0.2, 0.5)
	tween.tween_property(jaw, "rotation:x", 0.6, 0.3)
	# Depois que cai, o monte tomba de lado e afunda um pouco.
	tween.chain().tween_property(self, "rotation:z", 0.35, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", -0.08, 0.4)
