class_name Interactable
extends Node3D
## Algo com que o jogador interage apertando E ao mirar de perto (mesa, braseiro, portal…).
## Os filhos com colisão (por exemplo, GreyboxBlock) é que recebem a mira; o jogador sobe
## pela árvore de nós até achar o Interactable. Subclasses reescrevem `interact()`.

## Chave de tradução do texto mostrado no HUD (ex.: PROMPT_RESEARCH_TABLE).
@export var prompt_key: String
## Texto mostrado quando ainda não dá para usar (ex.: a grade fechada). Vazio: nada aparece.
@export var locked_prompt_key: String


## Chamado quando o jogador aperta E mirando este objeto.
func interact(_player: Node3D) -> void:
	pass


## Pode ser usado agora? (Ex.: a saída da Dungeon só depois de vencer.)
func is_available() -> bool:
	return true


## Chave do texto que o HUD deve mostrar agora (vazio: nenhum).
func current_prompt_key() -> String:
	return prompt_key if is_available() else locked_prompt_key


## Procura um Interactable em `node` ou nos seus pais.
static func find_on(node: Node) -> Interactable:
	while node != null:
		if node is Interactable:
			return node
		node = node.get_parent()
	return null
