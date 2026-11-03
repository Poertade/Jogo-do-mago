class_name ResearchPageData
extends Resource
## Uma página de pesquisa: para estudá-la, o jogador resolve a nota de pesquisa na Mesa
## (ligando os aspectos da nota, como no Thaumcraft 4) e ganha um benefício permanente.
## Cada página é um arquivo em data/research/pages/. Os requisitos ligam as páginas numa árvore.

@export var id: StringName
## Chaves de tradução (em locales/content.csv). O texto pode citar aspectos como {fire}.
@export var name_key: String
@export var description_key: String
## Aspectos já escritos na nota (os alvos que o jogador precisa ligar), na borda da grade.
@export var note_aspects: Array[StringName] = []
## Tamanho da grade da nota: anéis de hexágonos em volta do centro (2 = 19 hexágonos).
@export var note_radius: int = 0
## Páginas que precisam estar estudadas antes.
@export var required_pages: Array[StringName] = []
## Aspectos que precisam estar descobertos antes.
@export var required_aspects: Array[StringName] = []
## Benefícios permanentes.
@export var effects: Array[PageEffect] = []
