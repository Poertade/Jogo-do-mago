class_name VisNode
extends Interactable
## Nódulo de Vis (inspirado nos nódulos de aura do Thaumcraft): um núcleo de energia, com
## bolinhas de Vis em órbita. Segure E mirando o nódulo para drenar Vis para a reserva única
## da varinha: as bolinhas voam até a ponta dela. Pela decisão 3, só há nódulos na escola
## (fora dela, a reserva não recarrega).

## Aspecto que dá a cor ao nódulo (o Vis drenado vai para a reserva única da varinha).
@export var aspect: StringName = &"fire"
## Pontos de reserva drenados por segundo enquanto E está seguro.
@export var drain_rate := 12.0
## Quantas bolinhas de Vis voam até a varinha por segundo durante a drenagem.
@export var sparks_per_second := 14.0

var _drain_buffer := 0.0
var _spark_buffer := 0.0
var _time := 0.0
var _draining := false
var _drained_total := 0
var _sound: AudioStreamPlayer
var _spark_mesh: SphereMesh
var _spark_material: ShaderMaterial

@onready var core: Node3D = $Core
@onready var orbs: Node3D = $Core/Orbs
@onready var light: OmniLight3D = $Core/Light
@onready var glow_material: ShaderMaterial = $Core/Glow.material_override
@onready var orb_material: ShaderMaterial = ($Core/Orbs.get_child(0) as MeshInstance3D).material_override


func _ready() -> void:
	hold_to_use = true
	var color: Color = Content.db.aspects[aspect].color
	glow_material.set_shader_parameter(&"emission_color", color)
	orb_material.set_shader_parameter(&"emission_color", color.lightened(0.25))
	light.light_color = color
	# Bolinhas que voam até a varinha: uma malha e um material para todas.
	_spark_mesh = SphereMesh.new()
	_spark_mesh.radius = 0.025
	_spark_mesh.height = 0.05
	_spark_mesh.radial_segments = 4
	_spark_mesh.rings = 2
	_spark_material = orb_material.duplicate()


func hold(player: Node3D, delta: float) -> void:
	var wand := Game.run.wand
	if not _draining:
		_draining = true
		_drained_total = 0
		if wand.is_full():
			Game.message(Text.tr_key("UI_MSG_ALREADY_FULL") % Text.tr_key("TERM_VIS"))
		else:
			_sound = Audio.play(&"recharge")
	if wand.is_full():
		return
	_drain_buffer += drain_rate * delta
	var whole := floori(_drain_buffer)
	if whole > 0:
		_drain_buffer -= whole
		_drained_total += wand.add(whole)
		if wand.is_full():
			Game.message(Text.tr_key("UI_MSG_RECHARGED") % Text.tr_key("TERM_VIS"), Content.db.aspects[aspect].color)
	_spark_buffer += sparks_per_second * delta
	while _spark_buffer >= 1.0:
		_spark_buffer -= 1.0
		_launch_spark((player as Player).wand_view.tip)


func release_hold() -> void:
	_draining = false
	_drain_buffer = 0.0
	Audio.fade_out(_sound, 0.2)
	_sound = null


func _process(delta: float) -> void:
	_time += delta
	var speed := 3.0 if _draining else 1.0
	# Núcleo pulsa; as bolinhas giram em órbitas inclinadas e sobem e descem.
	var pulse := 1.0 + 0.08 * sin(_time * 3.1) + (0.12 if _draining else 0.0)
	core.scale = Vector3.ONE * pulse
	core.position.y = 1.35 + 0.04 * sin(_time * 1.3)
	orbs.rotation.y += delta * 0.9 * speed
	for i in orbs.get_child_count():
		var orb := orbs.get_child(i) as Node3D
		var angle := _time * (1.1 + 0.25 * i) * speed + i * 1.7
		var radius := 0.26 + 0.05 * (i % 3)
		orb.position = Vector3(cos(angle) * radius, 0.12 * sin(angle * 1.3 + i), sin(angle) * radius)
	light.light_energy = (2.4 if _draining else 1.6) * (1.0 + 0.1 * sin(_time * 7.0))


## Uma bolinha de Vis sai de uma das órbitas e voa até a ponta da varinha.
func _launch_spark(target: Node3D) -> void:
	var spark := MeshInstance3D.new()
	spark.mesh = _spark_mesh
	spark.material_override = _spark_material
	get_parent().add_child(spark)
	var start := orbs.get_child(randi() % orbs.get_child_count()) as Node3D
	spark.global_position = start.global_position
	var tween := spark.create_tween()
	tween.tween_method(_move_spark.bind(spark, start.global_position, target), 0.0, 1.0, 0.35)
	tween.tween_callback(spark.queue_free)


## Posição da bolinha no caminho (t de 0 a 1) até a ponta da varinha, que pode estar se mexendo.
func _move_spark(t: float, spark: Node3D, from: Vector3, target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	spark.global_position = from.lerp(target.global_position, t * t)
	spark.scale = Vector3.ONE * lerpf(1.2, 0.4, t)
