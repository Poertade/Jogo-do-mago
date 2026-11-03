class_name WandData
extends Resource
## Uma varinha montada: quanto Vis ela guarda e com que eficiência o gasta. Ela tem um
## recipiente para cada aspecto (Ignis, Aqua, Perditio…), cada um com o mesmo limite, e um
## limite para a soma de todos. O jogo monta a varinha com um núcleo (WandCoreData, os limites)
## e uma ponteira (WandCapData, a eficiência), veja `assemble`.

## Aspectos que têm recipiente na varinha, na ordem em que o HUD mostra os frascos.
## Vis de um aspecto fora desta lista não entra.
@export var aspects: Array[StringName] = []
## Limite da soma de todos os recipientes (ex.: 30).
@export var capacity: int = 0
## Limite de cada recipiente (ex.: 10 de Ignis, 10 de Aqua…).
@export var aspect_capacity: int = 0
## Eficiência: o custo de cada magia é dividido por ela (1 = normal; 2 = gasta metade).
@export var efficiency: float = 0.0
## Peças de que a varinha é feita (vazias numa varinha montada à mão, como nos testes).
@export var core: WandCoreData
@export var cap: WandCapData


## Monta a varinha com um núcleo e uma ponteira.
static func assemble(core_data: WandCoreData, cap_data: WandCapData, wand_aspects: Array[StringName]) -> WandData:
	var wand := WandData.new()
	wand.aspects = wand_aspects.duplicate()
	wand.capacity = core_data.capacity
	wand.aspect_capacity = core_data.aspect_capacity
	wand.efficiency = cap_data.efficiency
	wand.core = core_data
	wand.cap = cap_data
	return wand
