class_name Plaque
extends Interactable
## Placa ou anotação para ler: interagir abre um texto (título e corpo em locales/content.csv).

@export var title_key: String
@export var body_key: String


func interact(_player: Node3D) -> void:
	Game.note_requested.emit(title_key, body_key)
