class_name PageEffect
extends Resource
## Um efeito permanente de uma página de pesquisa estudada.

## Tipos conhecidos de efeito.
const DAMAGE_MULTIPLIER := &"damage_multiplier"
const UNLOCK_FOCUS := &"unlock_focus"
const TYPES: Array[StringName] = [DAMAGE_MULTIPLIER, UNLOCK_FOCUS]

## Tipo do efeito. "damage_multiplier": multiplica o dano de um elemento.
## "unlock_focus": libera o Focus `focus` (o jogador passa a poder trocar para ele com Q).
@export var type: StringName
## Elemento afetado (ex.: fire).
@export var element: StringName
## Valor do efeito (ex.: 1.2 = +20%).
@export var value: float = 1.0
## Focus liberado (para "unlock_focus").
@export var focus: FocusData
