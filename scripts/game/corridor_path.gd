@tool
class_name CorridorPath
extends Node3D
## Corredor da Dungeon, montado a partir de uma linha de pontos (o centro do chão), no editor e
## no jogo. Cada trecho entre dois pontos é reto, na direção X ou Z, e desce ou sobe em rampa se
## os dois pontos tiverem alturas diferentes. Nos pontos do meio o corredor faz a curva (o ponto
## de curva é plano). As pontas ficam abertas, encostadas nas portas das salas.
##
## Para mudar um corredor: selecione o nó e edite `points` no inspetor. As paredes, o chão, o
## teto e as luzes se refazem sozinhos (são criados por código e não vão para a cena).
## Rampas: para o jogador subir andando, o trecho deve ter pelo menos 2,2 vezes o comprimento
## da diferença de altura (uns 25 graus).

const WALL := 0.4

## Pontos do centro do chão, em metros, relativos a este nó.
@export var points: PackedVector3Array = []:
	set(value):
		points = value
		_rebuild()
## Região: materiais das paredes, do chão e do teto, e as luzes.
@export var zone: DungeonZone:
	set(value):
		zone = value
		_rebuild()
@export var width := 2.4:
	set(value):
		width = value
		_rebuild()
@export var height := 2.8:
	set(value):
		height = value
		_rebuild()
## Liga as luzes da região ao longo do corredor.
@export var lights := true:
	set(value):
		lights = value
		_rebuild()

var _built: Node3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _built != null:
		_built.free()
	_built = Node3D.new()
	_built.name = "Built"
	add_child(_built)
	if zone == null or points.size() < 2:
		return
	var half := width / 2.0
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var direction := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
		# Nos pontos de curva, o trecho para na borda do quadrado da curva.
		var start := a + direction * half if i > 0 else a
		var end := b - direction * half if i + 1 < points.size() - 1 else b
		_segment(start, end, i)
	for i in range(1, points.size() - 1):
		var incoming := Vector3(points[i].x - points[i - 1].x, 0.0, points[i].z - points[i - 1].z).normalized()
		var outgoing := Vector3(points[i + 1].x - points[i].x, 0.0, points[i + 1].z - points[i].z).normalized()
		_corner(points[i], incoming, outgoing)


## Um trecho reto de `a` a `b`, com rampa se as alturas forem diferentes.
func _segment(a: Vector3, b: Vector3, index: int) -> void:
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var length := flat.length()
	if length < 0.01:
		return
	var rise := b.y - a.y
	var frame := Node3D.new()
	frame.name = "Segment%d" % index
	_built.add_child(frame)
	# O trecho corre ao longo do -Z do quadro, de +length/2 (início) a -length/2 (fim).
	frame.position = (a + b) / 2.0
	frame.basis = Basis.looking_at(flat.normalized(), Vector3.UP)
	var slope := atan2(rise, length)
	var ramp := sqrt(length * length + rise * rise)
	var outer := width + 2.0 * WALL
	# O chão fica 2 cm abaixo do das salas: onde os dois se encontram, não piscam um sobre o outro.
	_block(frame, Vector3(outer, 0.2, ramp), Vector3(0, -0.12, 0), Vector3(slope, 0, 0), zone.floor_material, zone.floor_scannable)
	_block(frame, Vector3(outer, 0.2, ramp), Vector3(0, height + 0.1, 0), Vector3(slope, 0, 0), zone.ceiling_material, null)
	for side in [-1.0, 1.0]:
		_block(frame, Vector3(WALL, height + absf(rise) + 0.4, length), Vector3(side * (width / 2.0 + WALL / 2.0), height / 2.0, 0),
			Vector3.ZERO, zone.wall_material, zone.wall_scannable)
	if lights:
		_lights(frame, length, rise)


## O quadrado de uma curva: chão e teto planos e paredes nos lados que não continuam.
func _corner(at: Vector3, incoming: Vector3, outgoing: Vector3) -> void:
	var frame := Node3D.new()
	frame.name = "Corner"
	frame.position = at
	_built.add_child(frame)
	var outer := width + 2.0 * WALL
	_block(frame, Vector3(outer, 0.2, outer), Vector3(0, -0.12, 0), Vector3.ZERO, zone.floor_material, zone.floor_scannable)
	_block(frame, Vector3(outer, 0.2, outer), Vector3(0, height + 0.1, 0), Vector3.ZERO, zone.ceiling_material, null)
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		# Abertos: de onde o corredor vem e para onde ele vai.
		if side.is_equal_approx(-incoming) or side.is_equal_approx(outgoing):
			continue
		var size := Vector3(WALL, height + 0.4, outer) if side.x != 0.0 else Vector3(outer, height + 0.4, WALL)
		_block(frame, size, side * (width / 2.0 + WALL / 2.0) + Vector3(0, height / 2.0, 0), Vector3.ZERO,
			zone.wall_material, zone.wall_scannable)


## Luzes da região ao longo do trecho: tochas nas paredes ou brilhos soltos.
func _lights(frame: Node3D, length: float, rise: float) -> void:
	if zone.light_spacing <= 0.0:
		return
	var count := maxi(1, floori(length / zone.light_spacing))
	for i in count:
		var t := (i + 0.5) / count
		var side := -1.0 if i % 2 == 0 else 1.0
		var at := Vector3(side * (width / 2.0 - 0.1), 1.9 - rise / 2.0 + t * rise, length / 2.0 - t * length)
		var light := OmniLight3D.new()
		light.light_color = zone.light_color
		light.light_energy = zone.light_energy
		light.omni_range = 5.5
		light.omni_attenuation = 1.2
		light.position = at - Vector3(side * 0.35, -0.3, 0)
		frame.add_child(light)
		var glow := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, 0.14, 0.08) if zone.torches else Vector3(0.18, 0.18, 0.18)
		glow.mesh = mesh
		glow.material_override = _glow_material(Color(1.0, 0.69, 0.44) if zone.torches else zone.light_color)
		glow.position = at + Vector3(0, 0.27 if zone.torches else 0.0, 0)
		glow.rotation.y = PI / 4.0
		frame.add_child(glow)
		if zone.torches:
			var holder := MeshInstance3D.new()
			var holder_mesh := BoxMesh.new()
			holder_mesh.size = Vector3(0.12, 0.4, 0.12)
			holder.mesh = holder_mesh
			holder.material_override = load("res://assets/materials/dark_wood.tres")
			holder.position = at
			frame.add_child(holder)


func _block(parent: Node3D, block_size: Vector3, at: Vector3, rotation_radians: Vector3, material: Material, data: ScannableData) -> void:
	var block := GreyboxBlock.new()
	block.size = block_size
	block.material = material
	block.scannable = data
	block.position = at
	block.rotation = rotation_radians
	parent.add_child(block)


func _glow_material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/render/ps1.gdshader")
	material.set_shader_parameter(&"albedo_color", Color.BLACK)
	material.set_shader_parameter(&"emission_color", color)
	material.set_shader_parameter(&"emission_energy", 2.0)
	return material
