class_name EnemyShot
extends Node3D
## Tiro de um inimigo à distância (o Olho Vigia): uma bola de luz que voa em linha reta, devagar
## o bastante para o jogador desviar. Acertando o jogador, causa dano; acertando uma parede, some.

const LIFETIME := 4.0

var _velocity := Vector3.ZERO
var _damage := 0.0
var _shooter: RID
var _time := 0.0


func setup(velocity: Vector3, damage: float, color: Color, shooter: RID) -> void:
	_velocity = velocity
	_damage = damage
	_shooter = shooter
	var core := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.radial_segments = 6
	mesh.rings = 3
	core.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/render/ps1.gdshader")
	material.set_shader_parameter(&"albedo_color", Color.BLACK)
	material.set_shader_parameter(&"emission_color", color)
	material.set_shader_parameter(&"emission_energy", 2.5)
	core.material_override = material
	add_child(core)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 3.5
	add_child(light)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time > LIFETIME:
		queue_free()
		return
	var from := global_position
	var to := from + _velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_shooter]
	# Paredes e o jogador (camada 1); decorações (camada 2) não param o tiro.
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		return
	if hit.collider is Node and (hit.collider as Node).is_in_group(&"player"):
		Game.damage_player(_damage)
	Audio.play_at(&"fire_impact", hit.position, get_parent())
	queue_free()
