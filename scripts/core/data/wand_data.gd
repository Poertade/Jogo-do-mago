class_name WandData
extends Resource
## Uma varinha: define quanta energia de cada aspecto primal ela guarda e com que eficiência
## a gasta. Cada varinha é um arquivo em data/wands/.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

@export var id: StringName
## Chave de tradução do nome (em locales/content.csv).
@export var name_key: String
## Reserva máxima por aspecto (ex.: fire = 30).
@export var capacity: Dictionary[StringName, int] = {}
## Eficiência: o custo de cada magia é dividido por ela (1 = normal; 2 = gasta metade).
@export var efficiency: float = 0.0
