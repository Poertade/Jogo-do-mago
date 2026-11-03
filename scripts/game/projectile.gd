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
	var target := _find_damageable(hit.collider)
	if target != null:
		target.take_damage(damage, element)
	_explode()


## Procura em `node` ou nos seus pais algo que receba dano.
static func _find_damageable(node: Node) -> Node:
	while node != null:
		if node.has_method(&"take_damage"):
			return node
		node = node.get_parent()
	return null


func _explode() -> void:
	Audio.play_at(&"fire_impact", global_position, get_parent())
	if impact_scene != null:
		var impact: Node3D = impact_scene.instantiate()
		get_parent().add_child(impact)
		impact.global_position = global_position
	queue_free()
