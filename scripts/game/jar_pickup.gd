class_name JarPickup
extends Interactable
## Pote selado de Vis achado na Dungeon. E tira o Vis dele: primeiro para os potes do cinto,
## depois para a varinha. O que não couber fica no pote, e ele continua ali. Vazio, o pote se
## parte e deixa cacos de vidro (para fabricar potes na escola).

## Aspecto e quantidade do Vis guardado (definidos pela Dungeon).
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
	stored += Game.run.wand.add(aspect, amount - stored)
	if stored <= 0:
		Game.message(Text.tr_key("UI_MSG_BELT_FULL"))
		return
	amount -= stored
	Game.message(Text.tr_key("UI_MSG_JAR_TAKEN") % [stored, Text.aspect_name(aspect)], Content.db.aspects[aspect].color)
	Audio.play(&"recharge")
	if amount <= 0:
		Audio.play_at(&"glass", global_position, get_parent())
		Game.find_item(&"glass", Content.db.economy.glass_per_sealed_jar)
		queue_free()
