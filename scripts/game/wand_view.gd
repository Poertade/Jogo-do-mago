class_name WandView
extends Node3D
## A varinha na mão direita, com o Focus na ponta. Segure o botão esquerdo para carregar a
## magia (a ponta acende e treme) e solte para lançar. A lógica de carga, custo e intervalo
## fica em SpellCaster (scripts/core); aqui ficam a entrada, o visual e o projétil.

@export var player: Player
@export var projectile_scene: PackedScene
## Posição normal da varinha e quanto ela recua ao disparar, em relação à câmera.
@export var rest_position := Vector3(0.22, -0.26, -0.42)
@export var recoil := Vector3(0.0, 0.02, 0.08)

@onready var tip: Node3D = $Tip
@onready var tip_light: OmniLight3D = $Tip/Light
@onready var tip_glow: MeshInstance3D = $Tip/Glow

var _shake_time := 0.0
var _charge_sound: AudioStreamPlayer


func _ready() -> void:
	position = rest_position
	_update_tip(0.0)


func _physics_process(delta: float) -> void:
	var caster := Game.run.caster
	caster.update(delta)
	var playing := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if playing and Input.is_action_just_pressed("switch_focus") and not caster.is_busy():
		Game.cycle_focus()
	if playing and Input.is_action_just_pressed("cast") and player.can_cast():
		var failure := caster.start_charge()
		if failure == SpellCaster.Failure.NONE:
			_charge_sound = Audio.play(&"spell_charge")
		elif failure == SpellCaster.Failure.NO_ENERGY:
			Audio.play(&"no_energy")
			var names: PackedStringArray = []
			for aspect_id in caster.focus.cost:
				names.append(Text.aspect_name(aspect_id))
			Game.message(Text.tr_key("UI_MSG_NO_ENERGY") % " / ".join(names))
	if caster.is_busy() and (not Input.is_action_pressed("cast") or not playing):
		Audio.fade_out(_charge_sound)
		_charge_sound = null
		if caster.release() and playing:
			_fire(caster)
	_update_tip(caster.charge_ratio())
	_animate(delta, caster)


func _fire(caster: SpellCaster) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	var world := player.get_parent() as World
	world.spawn(projectile)
	projectile.global_position = tip.global_position
	# Mira: do bico da varinha até o ponto que está no centro da tela.
	var target := player.aim_point(caster.focus.projectile_speed * caster.focus.projectile_lifetime)
	var direction := (target - tip.global_position).normalized()
	var ignore: Array[RID] = [player.get_rid()]
	projectile.setup(caster.focus, direction, caster.damage(Game.modifiers), ignore)
	position = rest_position + recoil
	Audio.play(&"spell_cast")


## A ponta brilha mais conforme a carga, na cor do Focus encaixado.
func _update_tip(charge: float) -> void:
	var color := Game.run.caster.focus.light_color
	tip_light.light_color = color
	(tip_glow.material_override as ShaderMaterial).set_shader_parameter(&"emission_color", color)
	tip_light.light_energy = lerpf(0.15, 1.6, charge)
	tip_glow.scale = Vector3.ONE * lerpf(0.6, 1.4, charge)


## Volta suave para a posição de descanso e tremor quando a carga está completa.
func _animate(delta: float, caster: SpellCaster) -> void:
	var goal := rest_position
	if caster.state == SpellCaster.State.CHARGED:
		_shake_time += delta
		goal += Vector3(sin(_shake_time * 70.0), cos(_shake_time * 53.0), 0.0) * 0.003
	elif caster.state == SpellCaster.State.CHARGING:
		goal += Vector3(0.0, 0.01, 0.03) * caster.charge_ratio()
	position = position.lerp(goal, 1.0 - exp(-16.0 * delta))
