class_name ExitPoint
extends Interactable
## Saída de uma sala da Dungeon. Fica fechada (com a grade `barrier`) até a sala ser limpa,
## se `requires_clear` estiver ligado. O destino é um dado (sala e entrada).

@export var target_room: StringName = &"school"
@export var target_entrance: StringName = &"from_dungeon"
## Só abre depois que todos os inimigos da sala forem derrotados.
@export var requires_clear := true
## Nó que bloqueia a passagem enquanto a saída está fechada (desce para o chão ao abrir).
@export var barrier: Node3D

var _room: Room


func _ready() -> void:
	_room = _find_room()
	if _room != null:
		_room.cleared.connect(_open)
		# A sala cria os inimigos no _ready dela, que roda depois do nosso: confere no fim do quadro.
		_open_if_already_clear.call_deferred()


func _open_if_already_clear() -> void:
	if _room.is_cleared():
		_open()


func is_available() -> bool:
	return not requires_clear or (_room != null and _room.is_cleared())


func interact(_player: Node3D) -> void:
	Game.travel(target_room, target_entrance)


func _open() -> void:
	if barrier == null:
		return
	# A grade afunda no chão; a colisão sai junto quando termina.
	var tween := create_tween()
	tween.tween_property(barrier, "position:y", barrier.position.y - 3.2, 1.6).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(barrier.queue_free)


func _find_room() -> Room:
	var node := get_parent()
	while node != null and not node is Room:
		node = node.get_parent()
	return node
