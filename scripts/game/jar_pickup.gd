class_name JarPickup
extends Interactable
## Pote selado de Vis achado na Dungeon. E guarda o Vis no cinto de potes; se não couber tudo,
## o resto fica no pote, e ele continua ali.

## Aspecto e quantidade do Vis guardado (definidos pelo DungeonBuilder).
@export var aspect: StringName = &"fire"
@export var amount := 8

@onready var liquid: MeshInstance3D = $Liquid
@onready var glow: OmniLight3D = $Glow


func _ready() -> void:
	var color: Color = Content.db.aspects[aspect].color
	var material := (liquid.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	material.set_shader_parameter(&"emission_color", color)
	liquid.material_override = material
	glow.light_color = color


func interact(_player: Node3D) -> void:
	var stored := Game.run.jars.store(aspect, amount)
	if stored <= 0:
		Game.message(Text.tr_key("UI_MSG_BELT_FULL"))
		return
	amount -= stored
	Game.message(Text.tr_key("UI_MSG_JAR_TAKEN") % [stored, Text.aspect_name(aspect)], Content.db.aspects[aspect].color)
	Audio.play(&"recharge")
	if amount <= 0:
		queue_free()
