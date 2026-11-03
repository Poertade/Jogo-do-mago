class_name RunState
extends RefCounted
## O estado de uma incursão: vida, Vis da varinha, a magia equipada, os potes do cinto e o que
## foi achado na Dungeon. Ao contrário do conhecimento e do que está guardado na escola, é
## reiniciado quando o jogador morre.

var health: Health
var wand: WandState
var caster: SpellCaster
## Potes de Vis no cinto (os potes ficam com o jogador; o Vis dentro deles se perde ao morrer).
var jars: VisJarBelt
## Livros achados ainda não lidos (perdem-se ao morrer).
var carried_books: Array[BookData] = []
## Materiais achados nesta incursão (prata, cacos de vidro): só vão para a escola (Stash) se o
## jogador voltar vivo.
var found: Dictionary[StringName, int] = {}
## Semente da incursão atual (sorteia inimigos e achados) e se o jogador está na Dungeon.
var incursion_seed := 0
var _in_dungeon := false
var _player: PlayerData


## `jar_count`: quantos potes o jogador tem (Stash.jars).
func _init(player: PlayerData, jar_count := 0) -> void:
	_player = player
	health = Health.new(player.max_health)
	wand = WandState.new(player.starting_wand, player.starting_vis)
	caster = SpellCaster.new(player.starting_focus, wand)
	jars = VisJarBelt.new(jar_count, player.jar_capacity)


## Começa de novo: vida cheia, a varinha com o Vis inicial, a magia parada, os potes vazios e
## sem nada do que foi achado.
func reset() -> void:
	health.restore()
	wand.reset(_player.starting_vis)
	caster.cancel()
	caster.cooldown_left = 0.0
	jars.clear()
	carried_books.clear()
	found.clear()
	leave_dungeon()


## Guarda um livro achado (até ser lido na escola).
func carry_book(book: BookData) -> bool:
	carried_books.append(book)
	return true


## Guarda um material achado na Dungeon.
func find(item_id: StringName, amount: int) -> void:
	if amount > 0:
		found[item_id] = found.get(item_id, 0) + amount


## Tira tudo o que foi achado (para guardar na escola, ao voltar vivo).
func take_found() -> Dictionary[StringName, int]:
	var result := found.duplicate()
	found.clear()
	return result


## Começa uma incursão com a semente `new_seed`.
func start_dungeon(new_seed: int) -> void:
	incursion_seed = new_seed
	_in_dungeon = true


func in_dungeon() -> bool:
	return _in_dungeon


func leave_dungeon() -> void:
	_in_dungeon = false
