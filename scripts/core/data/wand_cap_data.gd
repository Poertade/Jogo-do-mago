class_name WandCapData
extends Resource
## Ponteira de varinha (como as ponteiras do Thaumcraft): decide a eficiência, isto é, quanto
## as magias custam. Eficiência 1,25 = cada magia custa, em média, 80% do Vis.
## Cada ponteira é um arquivo em data/wands/caps/.

@export var id: StringName
## Nome e descrição (em locales/content.csv).
@export var name_key: String
@export var description_key: String
## Ordem na Bancada (as mais simples primeiro).
@export var tier: int = 0
## O custo das magias é dividido por ela (1 = normal).
@export var efficiency: float = 0.0
## Materiais gastos para fazer a ponteira (vazio: já vem com o jogador).
@export var cost: Dictionary[StringName, int] = {}
## Vis tirado da varinha para fazer a ponteira.
@export var vis_cost: Dictionary[StringName, int] = {}
## Cor das ponteiras da varinha na mão.
@export var color: Color = Color.WHITE
