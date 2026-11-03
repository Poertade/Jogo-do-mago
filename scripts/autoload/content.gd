extends Node
## Autoload "Content": todo o conteúdo de data/, carregado uma vez ao abrir o jogo.
## Qualquer script acessa com Content.db (por exemplo, Content.db.rooms).

var db := ContentDB.new()


func _init() -> void:
	db.load_all()
	for message in db.errors:
		push_error("Conteúdo: " + message)
