class_name ScannableData
extends Resource
## Algo que a Lente consegue escanear: um objeto do cenário ou uma criatura.
## Objetos ficam em data/scannables/; inimigos (EnemyData) herdam desta classe.

## Identificador interno, único entre objetos e inimigos (ex.: candle).
@export var id: StringName
## Chave de tradução do nome (em locales/content.csv).
@export var name_key: String
## Aspectos e quantidades (ex.: fire = 3).
@export var aspects: Dictionary[StringName, int] = {}
