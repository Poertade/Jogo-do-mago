class_name Room
extends Node3D
## Raiz de uma cena de sala (scenes/rooms/). A sala é montada no editor com GreyboxBlock,
## luzes e marcadores: EntrancePoint (onde o jogador aparece), EnemySpawn (onde nascem os
## inimigos), LootSpot (achados) e saídas (ExitPoint). As salas da Dungeon ficam no mapa fixo
## (scenes/dungeon/dungeon.tscn); a cada incursão, os EnemySpawn sorteiam os inimigos com o
## gerador `rng`.

## Todos os inimigos da sala foram derrotados.
signal cleared

## Qual sala é esta (data/rooms/): dá a atmosfera, o nome e a região.
@export var room_id: StringName

## Gerador com a semente desta sala (definido pelo World antes de a sala entrar na árvore).
var rng := GameRng.new(0)
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
	var data := spawn.pick(rng)
	if data == null:
		return
	# Chefe já vencido numa incursão anterior: não volta.
	if spawn.unique_id != &"" and Game.world.is_defeated(spawn.unique_id):
		return
	var enemy := spawn_enemy(data, spawn.global_transform)
	if spawn.unique_id != &"":
		enemy.died.connect(func(): Game.world.defeat(spawn.unique_id))


## Cria um inimigo na sala (também usado por chefes que chamam ajuda).
func spawn_enemy(data: EnemyData, at: Transform3D) -> Enemy:
	var enemy: Enemy = (load(data.scene_path) as PackedScene).instantiate()
	enemy.data = data
	add_child(enemy)
	enemy.global_transform = at
	_enemies_alive += 1
	enemy.died.connect(_on_enemy_died)
	return enemy


func _on_enemy_died() -> void:
	_enemies_alive -= 1
	if _enemies_alive == 0:
		cleared.emit()
