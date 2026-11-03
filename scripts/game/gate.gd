class_name Gate
extends Interactable
## Grade de ferro numa passagem do mapa. Aberta uma vez, fica aberta para sempre (vai para o
## save, em DungeonProgress). Dois usos, como nos mapas do Lunacid e dos King's Field:
## - atalho (`one_way`): o ferrolho fica de um lado só, o da frente (a seta azul, -Z). Quem chega
##   pelo outro lado vê a grade fechada e precisa dar a volta; ao abrir, o caminho fica mais curto;
## - porta trancada (`needs_key`): só abre com a chave, achada em outro lugar do mapa.

## Identificador único da passagem no mapa (é o que vai para o save).
@export var passage_id: StringName
## Chave necessária para abrir (vazio: nenhuma).
@export var needs_key: StringName
## Ligado: só abre de quem está na frente (lado -Z).
@export var one_way := false
## As barras que bloqueiam a passagem (afundam no chão ao abrir).
@export var bars: Node3D

var _opening := false


func _ready() -> void:
	if Game.world.is_open(passage_id) and bars != null:
		# Já aberta numa incursão anterior: some antes da malha de navegação ser gerada.
		remove_child(bars)
		bars.queue_free()
		bars = null


func is_available() -> bool:
	return bars != null and not _opening and _has_key() and _on_lever_side()


func current_prompt_key() -> String:
	if bars == null or _opening:
		return ""
	if not _has_key():
		return "PROMPT_GATE_NEEDS_KEY"
	if not _on_lever_side():
		return "PROMPT_GATE_OTHER_SIDE"
	return "PROMPT_GATE_UNLOCK" if needs_key != &"" else "PROMPT_GATE_OPEN"


func interact(_player: Node3D) -> void:
	if not is_available():
		return
	_opening = true
	Game.world.open(passage_id)
	Game.message(Text.tr_key("UI_MSG_GATE_KEY" if needs_key != &"" else "UI_MSG_GATE_SHORTCUT"), Color(0.85, 0.8, 0.65))
	Audio.play_at(&"gate", global_position, get_parent())
	# A grade afunda no chão; a colisão sai junto quando termina.
	var tween := create_tween()
	tween.tween_property(bars, "position:y", bars.position.y - 3.2, 1.6).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(bars.queue_free)
	tween.tween_callback(func(): bars = null)


func _has_key() -> bool:
	return needs_key == &"" or Game.world.has_key(needs_key)


## O jogador está do lado do ferrolho? (Sempre, se a grade abre dos dois lados.)
func _on_lever_side() -> bool:
	if not one_way:
		return true
	var camera := get_viewport().get_camera_3d()
	return camera != null and to_local(camera.global_position).z < 0.0
