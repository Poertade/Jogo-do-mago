class_name KeyPickup
extends Interactable
## Uma chave do mapa (abre uma porta trancada, Gate com `needs_key`). Pegou uma vez, é para
## sempre: vai para o save e não aparece mais.

## Identificador da chave (o mesmo de `needs_key` na porta).
@export var key_id: StringName
## Nome da chave (em locales/content.csv).
@export var name_key: String

var _time := 0.0

@onready var model: Node3D = $Model


func _ready() -> void:
	if Game.world.has_key(key_id):
		queue_free()


func interact(_player: Node3D) -> void:
	Game.world.take_key(key_id)
	Game.message(Text.tr_key("UI_MSG_KEY_TAKEN") % Text.tr_key(name_key), Color(0.95, 0.8, 0.45))
	Audio.play(&"page_studied")
	queue_free()


func _process(delta: float) -> void:
	# Gira devagar e flutua um pouco, para chamar atenção no escuro.
	_time += delta
	model.rotation.y = _time * 0.8
	model.position.y = 0.05 * sin(_time * 2.0)
