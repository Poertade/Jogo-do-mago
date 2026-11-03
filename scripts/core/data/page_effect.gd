class_name PageEffect
extends Resource
## Um efeito permanente de uma página de pesquisa estudada.

## Tipos conhecidos de efeito.
const DAMAGE_MULTIPLIER := &"damage_multiplier"
const UNLOCK_FOCUS := &"unlock_focus"
const UNLOCK_WAND_PART := &"unlock_wand_part"
const TYPES: Array[StringName] = [DAMAGE_MULTIPLIER, UNLOCK_FOCUS, UNLOCK_WAND_PART]

## Tipo do efeito. "damage_multiplier": multiplica o dano de um elemento.
## "unlock_focus": libera o Focus `focus` (o jogador passa a poder trocar para ele com Q).
## "unlock_wand_part": libera o núcleo ou a ponteira `wand_part` na Bancada Arcana.
@export var type: StringName
## Elemento afetado (ex.: fire).
@export var element: StringName
## Valor do efeito (ex.: 1.2 = +20%).
@export var value: float = 1.0
## Focus liberado (para "unlock_focus").
@export var focus: FocusData
## Núcleo (WandCoreData) ou ponteira (WandCapData) liberado (para "unlock_wand_part").
@export var wand_part: Resource
