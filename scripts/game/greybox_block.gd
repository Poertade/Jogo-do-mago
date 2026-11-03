@tool
class_name GreyboxBlock
extends StaticBody3D
## Bloco de greybox: uma caixa sólida (com colisão) para montar salas no editor.
## Ajuste `size` e `material` no inspetor; a malha e a colisão se refazem sozinhas.
## A malha é subdividida (cerca de 1 divisão por metro) para o mapeamento afim
## não deformar demais a textura e a iluminação por vértice ter onde variar.

## Tamanho da caixa, em metros.
@export var size := Vector3.ONE:
	set(value):
		size = value
		_rebuild()
## Material da caixa (normalmente um dos materiais PS1 de assets/materials/).
@export var material: Material:
	set(value):
		material = value
		_rebuild()
## O que a Lente revela ao escanear este bloco (data/scannables/). Vazio: a busca sobe para o
## objeto de que o bloco faz parte (por exemplo, a mesa).
@export var scannable: ScannableData
## Divisões da malha por metro.
@export_range(0.25, 4.0, 0.25) var subdivisions_per_meter := 1.0:
	set(value):
		subdivisions_per_meter = value
		_rebuild()

var _mesh_instance: MeshInstance3D
var _collision: CollisionShape3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	# Os nós filhos são criados por código e não são gravados na cena.
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance)
		_collision = CollisionShape3D.new()
		add_child(_collision)

	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.subdivide_width = _divisions(size.x)
	mesh.subdivide_height = _divisions(size.y)
	mesh.subdivide_depth = _divisions(size.z)
	_mesh_instance.mesh = mesh
	_mesh_instance.material_override = material

	var shape := BoxShape3D.new()
	shape.size = size
	_collision.shape = shape


func get_scannable() -> ScannableData:
	return scannable


## Quantos cortes extras um lado de `length` metros recebe.
func _divisions(length: float) -> int:
	return maxi(0, ceili(length * subdivisions_per_meter) - 1)
