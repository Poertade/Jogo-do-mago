class_name Lectern
extends Interactable
## Atril de leitura do Salão de Estudos: E lê um dos livros trazidos da Dungeon e aprende as
## receitas dele (que a Mesa de Pesquisa passa a aceitar).


func is_available() -> bool:
	return not Game.run.carried_books.is_empty()


func interact(_player: Node3D) -> void:
	Game.read_next_book()
