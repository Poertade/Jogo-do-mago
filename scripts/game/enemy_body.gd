class_name EnemyBody
extends Node3D
## Corpo animado de um inimigo (o nó "Rig" da cena do inimigo). O Enemy chama estes métodos a
## cada quadro e nos eventos (golpe, dano, morte); cada formato de corpo tem o seu script:
## EnemyRig (humanoide articulado) e BlobRig (gosma). Para um formato novo, crie um script que
## herde deste e reescreva os métodos.

## Quadros de animação por segundo (o PS1 animava "aos trancos").
@export var animation_fps := 12.0

## Cor da geada que cobre o corpo quando o inimigo está lento (Focus de Gelo).
const FROST_COLOR := Color(0.55, 0.8, 1.0)
const FROST_ENERGY := 0.45

## Materiais que piscam em branco ao tomar dano (os que não brilham sozinhos).
var _flash_materials: Array[ShaderMaterial] = []
var _flash := 0.0
var _frost := 0.0


func _ready() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		var material := (node as MeshInstance3D).material_override as ShaderMaterial
		if material == null or material in _flash_materials:
			continue
		# Sem emissão definida (null) conta como zero: o material não brilha sozinho.
		var energy = material.get_shader_parameter(&"emission_energy")
		if energy == null or float(energy) == 0.0:
			_flash_materials.append(material)


## Atualiza a pose. `speed`: velocidade atual (m/s); `max_speed`: a de perseguição;
## `windup`: preparação do golpe, de 0 a 1 (0 quando não está atacando); `alert`: viu o jogador.
func update_pose(_delta: float, _speed: float, _max_speed: float, _windup: float, _alert: bool) -> void:
	pass


## O golpe desce (chamado quando a preparação termina).
func play_strike() -> void:
	pass


## Reação ao dano. A base faz o clarão branco; os corpos acrescentam o tranco.
func play_hurt() -> void:
	var tween := create_tween()
	tween.tween_method(_set_flash, 1.0, 0.0, 0.25)


func play_death() -> void:
	set_frost(0.0)


## Fúria (chefes): a base só pisca; os corpos acrescentam o que quiserem (olhos mais fortes).
func play_enrage() -> void:
	play_hurt()


## Geada sobre o corpo (0 = nada, 1 = coberto), enquanto o inimigo está lento.
func set_frost(amount: float) -> void:
	_frost = amount
	_update_glow()


func _set_flash(value: float) -> void:
	_flash = value
	_update_glow()


## O clarão do dano (branco) vale mais que a geada (azul) enquanto estiver mais forte.
func _update_glow() -> void:
	var frost := _frost * FROST_ENERGY
	for material in _flash_materials:
		material.set_shader_parameter(&"emission_color", Color.WHITE if _flash >= frost else FROST_COLOR)
		material.set_shader_parameter(&"emission_energy", maxf(_flash, frost))
