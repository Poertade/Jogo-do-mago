class_name Projectile
extends Node3D
## Projétil de magia: voa em linha reta, ilumina o caminho e, ao bater em algo, causa dano
## (se o alvo tiver `take_damage`) e explode.
## A colisão é testada com um raio entre a posição atual e a próxima, para não atravessar
## paredes finas mesmo em alta velocidade.

## Efeito criado no ponto de impacto.
@export var impact_scene: PackedScene

var velocity := Vector3.ZERO
var damage := 0.0
var element: StringName
var lifetime := 0.0
var exclude: Array[RID] = []
var color := Color.WHITE
var slow_factor := 1.0
var slow_seconds := 0.0
## Escava (Focus de Escavação): quebra paredes rachadas e extrai veios de cristal.
var digs := false

@onready var light: OmniLight3D = $Light


## Prepara o projétil a partir do Focus. `direction` precisa estar normalizada.
func setup(focus: FocusData, direction: Vector3, damage_amount: float, ignore: Array[RID]) -> void:
	velocity = direction * focus.projectile_speed
	damage = damage_amount
	element = focus.element
	lifetime = focus.projectile_lifetime
	exclude = ignore
	$Light.light_color = focus.light_color
	$Light.light_energy = focus.light_energy
	$Light.omni_range = focus.light_range
	color = focus.light_color
	slow_factor = focus.slow_factor
	slow_seconds = focus.slow_seconds
	digs = focus.digs
	# O brilho do projétil tem a cor do Focus (laranja no fogo, azul-claro no gelo).
	_tint($Core, focus.light_color.lightened(0.6))
	_tint($Shell, focus.light_color)


func _tint(mesh: MeshInstance3D, tint: Color) -> void:
	var material := (mesh.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	material.set_shader_parameter(&"emission_color", tint)
	mesh.material_override = material


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()
		return
	var from := global_position
	var to := from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		return
	global_position = hit.position - velocity.normalized() * 0.05
	var diggable := _find_with(hit.collider, &"dig")
	if digs and diggable != null:
		diggable.dig()
		_explode()
		return
	var target := _find_damageable(hit.collider)
	if target != null:
		target.take_damage(damage, element)
		if slow_seconds > 0.0 and target.has_method(&"apply_slow"):
			target.apply_slow(slow_factor, slow_seconds)
	_explode()


## Procura em `node` ou nos seus pais algo que receba dano.
static func _find_damageable(node: Node) -> Node:
	return _find_with(node, &"take_damage")


## Procura em `node` ou nos seus pais algo com o método `method`.
static func _find_with(node: Node, method: StringName) -> Node:
	while node != null:
		if node.has_method(method):
			return node
		node = node.get_parent()
	return null


func _explode() -> void:
	Audio.play_at(&"fire_impact", global_position, get_parent())
	if impact_scene != null:
		var impact: Node3D = impact_scene.instantiate()
		impact.set(&"color", color)
		get_parent().add_child(impact)
		impact.global_position = global_position
	queue_free()
