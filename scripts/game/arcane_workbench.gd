class_name ArcaneWorkbench
extends Interactable
## Bancada Arcana da escola: abre a tela onde o jogador faz núcleos e ponteiras de varinha com
## materiais da Dungeon e Vis da varinha, e escolhe quais montar (como no Thaumcraft).


func interact(_player: Node3D) -> void:
	Game.screen_requested.emit(&"arcane_workbench")
