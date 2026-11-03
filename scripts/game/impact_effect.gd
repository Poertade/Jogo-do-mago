class_name ImpactEffect
extends Node3D
## Clarão curto no ponto de impacto: a esfera cresce e a luz se apaga, depois o nó some.

@export var duration := 0.35

@onready var flash: MeshInstance3D = $Flash
@onready var light: OmniLight3D = $Light


func _ready() -> void:
	var start_energy := light.light_energy
	var tween := create_tween().set_parallel()
	tween.tween_property(flash, "scale", Vector3.ONE * 3.0, duration).from(Vector3.ONE * 0.5)
	tween.tween_property(light, "light_energy", 0.0, duration).from(start_energy)
	tween.chain().tween_callback(queue_free)
