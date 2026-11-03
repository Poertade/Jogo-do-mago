class_name PageEffect
extends Resource
## Um efeito permanente de uma página de pesquisa estudada.

## Tipos conhecidos de efeito.
const DAMAGE_MULTIPLIER := &"damage_multiplier"
const TYPES: Array[StringName] = [DAMAGE_MULTIPLIER]

## Tipo do efeito. "damage_multiplier": multiplica o dano de um elemento.
@export var type: StringName = DAMAGE_MULTIPLIER
## Elemento afetado (ex.: fire).
@export var element: StringName
## Valor do efeito (ex.: 1.2 = +20%).
@export var value: float = 1.0
