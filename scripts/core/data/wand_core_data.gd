class_name WandCoreData
extends Resource
## Núcleo de varinha (como as hastes do Thaumcraft): decide quanto Vis cabe em cada recipiente e
## no total. É montado na Bancada Arcana da escola com materiais da Dungeon.
## Cada núcleo é um arquivo em data/wands/cores/.

@export var id: StringName
## Nome e descrição (em locales/content.csv).
@export var name_key: String
@export var description_key: String
## Ordem na Bancada (os mais simples primeiro).
@export var tier: int = 0
## Limite de cada recipiente e da soma de todos.
@export var aspect_capacity: int = 0
@export var capacity: int = 0
## Materiais gastos para fazer o núcleo (vazio: já vem com o jogador).
@export var cost: Dictionary[StringName, int] = {}
## Vis tirado da varinha para fazer o núcleo.
@export var vis_cost: Dictionary[StringName, int] = {}
## Cor da haste da varinha na mão.
@export var color: Color = Color.WHITE
