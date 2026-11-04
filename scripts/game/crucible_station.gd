class_name CrucibleStation
extends Interactable
## O cadinho do laboratório da escola: E abre a tela de alquimia (dissolver materiais, anotar
## essência e preparar receitas). A lógica fica em Crucible (scripts/core); aqui, o visual: o
## líquido toma a cor do aspecto que mais há dentro, e as bolhas sobem e estouram.

@export var liquid: MeshInstance3D
@export var bubbles: Node3D

var _time := 0.0
var _material: ShaderMaterial


func _ready() -> void:
	_material = (liquid.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	liquid.material_override = _material
	for bubble in bubbles.get_children():
		(bubble as MeshInstance3D).material_override = _material
	Game.crucible.changed.connect(_tint)
	_tint()


func interact(_player: Node3D) -> void:
	Game.screen_requested.emit(&"crucible")


## A cor do líquido: a do aspecto com mais essência (roxo, se o cadinho está vazio).
func _tint() -> void:
	var color := Color(0.38, 0.25, 0.75)
	var most := 0
	for aspect_id in Game.crucible.essentia:
		var aspect: AspectData = Content.db.aspects.get(aspect_id)
		if aspect != null and Game.crucible.essentia[aspect_id] > most:
			most = Game.crucible.essentia[aspect_id]
			color = aspect.color
	_material.set_shader_parameter(&"emission_color", color)


func _process(delta: float) -> void:
	# Bolhas sobem um pouco e voltam, cada uma no seu ritmo.
	_time += delta
	for i in bubbles.get_child_count():
		var bubble := bubbles.get_child(i) as Node3D
		var phase := fmod(_time * (0.8 + 0.3 * i) + i * 0.37, 1.0)
		bubble.position.y = phase * 0.08
		bubble.scale = Vector3.ONE * (1.0 - phase)
