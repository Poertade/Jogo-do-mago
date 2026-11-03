class_name EconomyRules
extends Resource
## Quanto custam os potes de Vis e de onde vêm os materiais. O arquivo fica em
## data/economy/rules.tres; os materiais (prata, cacos de vidro), em data/items/.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

## Preço de um pote no Almoxarife da escola: {material: quantidade}.
@export var jar_price: Dictionary[StringName, int] = {}
## Materiais gastos para fabricar um pote na bancada de vidraria.
@export var jar_materials: Dictionary[StringName, int] = {}
## Vis tirado da varinha para fabricar um pote (como na Bancada Arcana do Thaumcraft).
@export var jar_vis: Dictionary[StringName, int] = {}
## Cacos de vidro que um pote selado da Dungeon deixa ao ser esvaziado.
@export var glass_per_sealed_jar: int = 0
