class_name CrackedWall
extends Interactable
## Parede rachada: só o Focus de Escavação (um projétil que escava) a derruba. Atrás dela há uma
## passagem. Derrubada uma vez, não volta (vai para o save, em DungeonProgress).

## Identificador único da passagem no mapa (é o que vai para o save).
@export var passage_id: StringName

var _broken := false


func _ready() -> void:
	locked_prompt_key = "PROMPT_CRACKED_WALL"
	if Game.world.is_open(passage_id):
		_broken = true
		# Já derrubada numa incursão anterior: some antes da malha de navegação ser gerada.
		for child in get_children():
			remove_child(child)
			child.queue_free()


## Só a Escavação abre: E não faz nada, e o texto avisa.
func is_available() -> bool:
	return false


func current_prompt_key() -> String:
	return "" if _broken else locked_prompt_key


## O projétil do Focus de Escavação acertou: a parede desaba.
func dig() -> void:
	if _broken:
		return
	_broken = true
	Game.world.open(passage_id)
	Game.message(Text.tr_key("UI_MSG_WALL_DUG"), Color(0.85, 0.7, 0.45))
	Audio.play_at(&"gate", global_position, get_parent())
	for block in find_children("*", "CollisionObject3D", true, false):
		(block as CollisionObject3D).collision_layer = 0
	# Os blocos afundam e somem, como entulho caindo.
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 2.6, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
