class_name ResearchPageData
extends Resource
## Uma página de pesquisa: estudada na Mesa de Pesquisa gastando pontos de aspectos,
## dá um benefício permanente. Cada página é um arquivo em data/research/pages/.
## Os requisitos ligam as páginas numa árvore.

@export var id: StringName
## Chaves de tradução (em locales/content.csv). O texto pode citar aspectos como {fire}.
@export var name_key: String
@export var description_key: String
## Pontos de pesquisa gastos para estudar, por aspecto (ex.: fire = 4, energy = 2).
@export var cost: Dictionary[StringName, int] = {}
## Páginas que precisam estar estudadas antes.
@export var required_pages: Array[StringName] = []
## Aspectos que precisam estar descobertos antes.
@export var required_aspects: Array[StringName] = []
## Benefícios permanentes.
@export var effects: Array[PageEffect] = []
