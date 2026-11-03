class_name WandData
extends Resource
## Uma varinha: quanto Vis ela guarda e com que eficiência o gasta. Ela tem um recipiente para
## cada aspecto (Ignis, Aqua, Perditio…), cada um com o mesmo limite, e um limite para a soma
## de todos. Cada varinha é um arquivo em data/wands/.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

@export var id: StringName
## Chave de tradução do nome (em locales/content.csv).
@export var name_key: String
## Aspectos que têm recipiente na varinha, na ordem em que o HUD mostra os frascos.
## Vis de um aspecto fora desta lista não entra.
@export var aspects: Array[StringName] = []
## Limite da soma de todos os recipientes (ex.: 30).
@export var capacity: int = 0
## Limite de cada recipiente (ex.: 10 de Ignis, 10 de Aqua…).
@export var aspect_capacity: int = 0
## Eficiência: o custo de cada magia é dividido por ela (1 = normal; 2 = gasta metade).
@export var efficiency: float = 0.0
