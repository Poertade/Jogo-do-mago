class_name WandData
extends Resource
## Uma varinha: define quanto Vis ela guarda e com que eficiência o gasta. A reserva é única:
## todo Vis drenado dos nódulos vai para ela, e todas as magias saem dela.
## Cada varinha é um arquivo em data/wands/.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

@export var id: StringName
## Chave de tradução do nome (em locales/content.csv).
@export var name_key: String
## Reserva máxima de Vis.
@export var capacity: int = 0
## Eficiência: o custo de cada magia é dividido por ela (1 = normal; 2 = gasta metade).
@export var efficiency: float = 0.0
