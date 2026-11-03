class_name Room
extends Node3D
## Raiz de uma cena de sala (scenes/rooms/). A sala é montada no editor com GreyboxBlock,
## luzes e marcadores: EntrancePoint (onde o jogador aparece), EnemySpawn (onde nascem os
## inimigos) e saídas (ExitPoint). Por ser feita só de marcadores e dados, a mesma estrutura
## servirá para montar Dungeons combinando salas.

## Todos os inimigos da sala foram derrotados.
signal cleared

var _enemies_alive := 0


func _ready() -> void:
	for node in find_children("*", "EnemySpawn", true, false):
		_spawn(node as EnemySpawn)


func is_cleared() -> bool:
	return _enemies_alive == 0


## Procura uma entrada pelo identificador. Se não achar, devolve a primeira que houver.
func get_entrance(entrance_id: StringName) -> EntrancePoint:
	var first: EntrancePoint = null
	for node in find_children("*", "EntrancePoint", true, false):
		var entrance := node as EntrancePoint
		if entrance.id == entrance_id:
			return entrance
		if first == null:
			first = entrance
	if first != null:
		push_warning("Sala '%s': entrada '%s' não existe; usando '%s'." % [name, entrance_id, first.id])
	return first


func _spawn(spawn: EnemySpawn) -> void:
	if spawn.enemy == null:
		push_warning("EnemySpawn '%s' sem inimigo definido." % spawn.name)
		return
	var enemy: Enemy = (load(spawn.enemy.scene_path) as PackedScene).instantiate()
	enemy.data = spawn.enemy
	add_child(enemy)
	enemy.global_transform = spawn.global_transform
	_enemies_alive += 1
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died() -> void:
	_enemies_alive -= 1
	if _enemies_alive == 0:
		cleared.emit()
