class_name ResearchTable
extends Interactable
## Mesa de Pesquisa: interagir abre a tela de estudo das páginas de pesquisa.


func interact(_player: Node3D) -> void:
	Game.screen_requested.emit(&"research_table")
