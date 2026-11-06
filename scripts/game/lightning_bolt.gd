class_name LightningBolt
extends Node3D
## O raio do Focus de Choque: segmentos em zigue-zague entre os pontos da corrente, com um clarão,
## que somem em uma fração de segundo.

const LIFETIME := 0.22
const JITTER := 0.18

var _time := 0.0
var _material: ShaderMaterial
var _light: OmniLight3D


## Desenha o raio passando por `points` (no espaço do mundo), na cor `color`.
func setup(points: Array[Vector3], color: Color) -> void:
	_material = ShaderMaterial.new()
	_material.shader = load("res://scripts/render/ps1.gdshader")
	_material.set_shader_parameter(&"albedo_color", Color.BLACK)
	_material.set_shader_parameter(&"emission_color", color)
	_material.set_shader_parameter(&"emission_energy", 3.0)
	for i in points.size() - 1:
		_zigzag(points[i], points[i + 1])
	_light = OmniLight3D.new()
	_light.light_color = color
	_light.light_energy = 3.0
	_light.omni_range = 6.0
	add_child(_light)
	_light.global_position = points.back()


## Um trecho do raio, quebrado em pedaços tortos.
func _zigzag(from: Vector3, to: Vector3) -> void:
	var pieces := maxi(2, ceili(from.distance_to(to) / 0.8))
	var previous := from
	for i in range(1, pieces + 1):
		var t := float(i) / pieces
		var point := from.lerp(to, t)
		if i < pieces:
			point += Vector3(randf_range(-JITTER, JITTER), randf_range(-JITTER, JITTER), randf_range(-JITTER, JITTER))
		_segment(previous, point)
		previous = point


func _segment(a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 0.01:
		return
	var piece := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.035, 0.035, length)
	piece.mesh = mesh
	piece.material_override = _material
	add_child(piece)
	piece.global_position = (a + b) / 2.0
	piece.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)


func _process(delta: float) -> void:
	_time += delta
	var fade := clampf(1.0 - _time / LIFETIME, 0.0, 1.0)
	_material.set_shader_parameter(&"emission_energy", 3.0 * fade)
	_light.light_energy = 3.0 * fade
	if _time >= LIFETIME:
		queue_free()
