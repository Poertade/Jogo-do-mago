class_name VisNode
extends Interactable
## Nódulo de Vis (inspirado nos nódulos de aura do Thaumcraft): um núcleo de energia de um
## aspecto primal, com bolinhas de Vis em órbita. Segure E mirando o nódulo para drenar Vis para
## o recipiente desse aspecto na varinha: as bolinhas voam até a ponta dela.
## Os nódulos da escola não acabam; os da Dungeon (sala de descanso, D054) têm `vis_amount` e se
## apagam quando esgotam.

## Aspecto do nódulo: dá a cor e diz para qual recipiente da varinha o Vis vai.
@export var aspect: StringName = &"fire"
## Outros aspectos que o nódulo também dá, drenados junto (como nos nódulos do Thaumcraft, que
## guardam vários aspectos). Ex.: o nódulo de Aqua da escola também dá Ordo.
@export var other_aspects: Array[StringName] = []
## Quanto Vis o nódulo tem (-1: não acaba, como o da escola). Ao esgotar, ele se apaga.
@export var vis_amount := -1
## Pontos de reserva drenados por segundo enquanto E está seguro.
@export var drain_rate := 12.0
## Quantas bolinhas de Vis voam até a varinha por segundo durante a drenagem.
@export var sparks_per_second := 14.0

var _drain_buffer := 0.0
var _spark_buffer := 0.0
var _time := 0.0
var _draining := false
var _drained_total := 0
var _empty := false
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
	# Com outros aspectos, parte das bolinhas fica na cor deles.
	var all := _aspects()
	for i in orbs.get_child_count():
		var orb_aspect := all[i % all.size()]
		if orb_aspect != aspect:
			var material := orb_material.duplicate() as ShaderMaterial
			material.set_shader_parameter(&"emission_color", Content.db.aspects[orb_aspect].color.lightened(0.25))
			(orbs.get_child(i) as MeshInstance3D).material_override = material
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
		if _all_full(wand):
			_say_full(wand, "UI_MSG_ALREADY_FULL")
		else:
			_sound = Audio.play(&"recharge")
	if _all_full(wand):
		return
	_drain_buffer += drain_rate * delta
	var whole := floori(_drain_buffer)
	if whole > 0:
		_drain_buffer -= whole
		var added := 0
		for drained in _aspects():
			var amount := whole if vis_amount < 0 else mini(whole, vis_amount - added)
			added += wand.add(drained, amount)
		_drained_total += added
		if vis_amount >= 0:
			vis_amount -= added
			if vis_amount <= 0:
				_go_out()
				return
		if _all_full(wand):
			_say_full(wand, "UI_MSG_RECHARGED")
	_spark_buffer += sparks_per_second * delta
	while _spark_buffer >= 1.0:
		_spark_buffer -= 1.0
		_launch_spark((player as Player).wand_view.tip)


## Avisa que não cabe mais nada: o recipiente do aspecto está cheio, ou a varinha toda está
## (o limite total).
func _say_full(wand: WandState, aspect_key: String) -> void:
	if not wand.is_total_full():
		var names: PackedStringArray = []
		for drained in _aspects():
			names.append(Text.aspect_name(drained))
		Game.message(Text.tr_key(aspect_key) % " / ".join(names), Content.db.aspects[aspect].color)
	else:
		Game.message(Text.tr_key("UI_MSG_WAND_FULL") % wand.total_capacity())


## O aspecto principal e os outros.
func _aspects() -> Array[StringName]:
	var result: Array[StringName] = [aspect]
	result.append_array(other_aspects)
	return result


## Nenhum dos aspectos do nódulo cabe mais na varinha?
func _all_full(wand: WandState) -> bool:
	for drained in _aspects():
		if not wand.is_full(drained):
			return false
	return true


func is_available() -> bool:
	return not _empty


## O nódulo esgotou: o núcleo e as bolinhas somem, sobra uma brasa fraca.
func _go_out() -> void:
	_empty = true
	release_hold()
	Game.message(Text.tr_key("UI_MSG_NODE_EMPTY") % Text.aspect_name(aspect), Content.db.aspects[aspect].color.darkened(0.3))
	var tween := create_tween().set_parallel()
	tween.tween_property(core, "scale", Vector3.ONE * 0.15, 0.6)
	tween.tween_property(light, "light_energy", 0.15, 0.6)
	orbs.visible = false


func release_hold() -> void:
	_draining = false
	_drain_buffer = 0.0
	Audio.fade_out(_sound, 0.2)
	_sound = null


func _process(delta: float) -> void:
	if _empty:
		return
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
