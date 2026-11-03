class_name ImpactEffect
extends Node3D
## Clarão curto no ponto de impacto: a esfera cresce e a luz se apaga, depois o nó some.

@export var duration := 0.35
## Cor do clarão (o projétil passa a cor do Focus).
var color := Color(1.0, 0.69, 0.31)

@onready var flash: MeshInstance3D = $Flash
@onready var light: OmniLight3D = $Light


func _ready() -> void:
	var material := (flash.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	material.set_shader_parameter(&"emission_color", color)
	flash.material_override = material
	light.light_color = color
	var start_energy := light.light_energy
	var tween := create_tween().set_parallel()
	tween.tween_property(flash, "scale", Vector3.ONE * 3.0, duration).from(Vector3.ONE * 0.5)
	tween.tween_property(light, "light_energy", 0.0, duration).from(start_energy)
	tween.chain().tween_callback(queue_free)
