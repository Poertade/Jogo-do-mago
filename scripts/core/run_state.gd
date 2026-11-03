class_name RunState
extends RefCounted
## O estado de uma incursão: vida, Vis da varinha, a magia equipada e o roteiro de salas da
## Dungeon (com a sala em que o jogador está). Ao contrário do conhecimento, é reiniciado
## quando o jogador morre.

var health: Health
var wand: WandState
var caster: SpellCaster
## Roteiro da incursão atual (null fora da Dungeon) e a posição nele (0 = primeira sala).
var dungeon: DungeonPlan
var room_index := -1
var _player: PlayerData


func _init(player: PlayerData) -> void:
	_player = player
	health = Health.new(player.max_health)
	wand = WandState.new(player.starting_wand, player.starting_vis)
	caster = SpellCaster.new(player.starting_focus, wand)


## Começa de novo: vida cheia, a varinha com o Vis inicial e a magia parada.
func reset() -> void:
	health.restore()
	wand.reset(_player.starting_vis)
	caster.cancel()
	caster.cooldown_left = 0.0
	leave_dungeon()


## Começa uma incursão com o roteiro `plan`. Devolve a primeira sala.
func start_dungeon(plan: DungeonPlan) -> StringName:
	dungeon = plan
	room_index = 0
	return current_room()


## Avança para a próxima sala do roteiro. Devolve o identificador dela, ou vazio se a
## incursão acabou (ou se não há incursão).
func advance() -> StringName:
	if dungeon == null:
		return &""
	room_index += 1
	if room_index >= dungeon.size():
		leave_dungeon()
		return &""
	return current_room()


func current_room() -> StringName:
	if dungeon == null or room_index < 0 or room_index >= dungeon.size():
		return &""
	return dungeon.rooms[room_index]


## Semente da sala atual (0 fora da Dungeon).
func current_room_seed() -> int:
	return dungeon.room_seed(room_index) if in_dungeon() else 0


func in_dungeon() -> bool:
	return current_room() != &""


func leave_dungeon() -> void:
	dungeon = null
	room_index = -1
