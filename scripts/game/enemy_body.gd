class_name EnemyBody
extends Node3D
## Corpo animado de um inimigo (o nó "Rig" da cena do inimigo). O Enemy chama estes métodos a
## cada quadro e nos eventos (golpe, dano, morte); cada formato de corpo tem o seu script:
## EnemyRig (humanoide articulado) e BlobRig (gosma). Para um formato novo, crie um script que
## herde deste e reescreva os métodos.

## Quadros de animação por segundo (o PS1 animava "aos trancos").
@export var animation_fps := 12.0

## Materiais que piscam em branco ao tomar dano (os que não brilham sozinhos).
var _flash_materials: Array[ShaderMaterial] = []


func _ready() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		var material := (node as MeshInstance3D).material_override as ShaderMaterial
		if material != null and not material in _flash_materials \
				and float(material.get_shader_parameter(&"emission_energy")) == 0.0:
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
	pass


func _set_flash(value: float) -> void:
	for material in _flash_materials:
		material.set_shader_parameter(&"emission_color", Color.WHITE)
		material.set_shader_parameter(&"emission_energy", value)
