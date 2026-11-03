class_name SecretWall
extends Interactable
## Parede falsa: parece pedra como as outras, mas se desfaz ao toque (E) ou com uma magia,
## revelando uma passagem escondida. Não mostra texto de interação; a pista é a Lente, que a
## revela como ilusão. Desfeita uma vez, não volta (vai para o save, em DungeonProgress).

## Identificador único da passagem no mapa (é o que vai para o save).
@export var passage_id: StringName

var _revealed := false


func _ready() -> void:
	if Game.world.is_open(passage_id):
		_revealed = true
		# Já desfeita numa incursão anterior: some antes da malha de navegação ser gerada.
		for child in get_children():
			remove_child(child)
			child.queue_free()


func is_available() -> bool:
	return not _revealed


func interact(_player: Node3D) -> void:
	reveal()


## Uma magia acerta a parede: ela também se desfaz.
func take_damage(_amount: float, _element: StringName) -> void:
	reveal()


func reveal() -> void:
	if _revealed:
		return
	_revealed = true
	Game.world.open(passage_id)
	Game.message(Text.tr_key("UI_MSG_SECRET_WALL"), Color(0.75, 0.65, 0.95))
	Audio.play_at(&"portal", global_position, get_parent())
	for block in find_children("*", "CollisionObject3D", true, false):
		(block as CollisionObject3D).collision_layer = 0
	# A pedra encolhe e some, como fumaça.
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0, 0.02, 1.0), 0.9).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(queue_free)
