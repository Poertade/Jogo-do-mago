class_name BookPickup
extends Interactable
## Livro perdido na Dungeon. E guarda o livro (ele só pode ser lido no atril da escola; quem
## morrer antes perde o livro, que volta a aparecer numa incursão futura).

## O livro (definido pelo DungeonBuilder).
@export var book: BookData

@onready var glow: OmniLight3D = $Glow
var _time := 0.0


func interact(_player: Node3D) -> void:
	if book == null:
		return
	Game.take_book(book)
	queue_free()


func _process(delta: float) -> void:
	# Brilho fraco que pulsa, para o livro ser achado no escuro.
	_time += delta
	glow.light_energy = 0.5 + 0.25 * sin(_time * 2.5)
