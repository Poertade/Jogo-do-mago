class_name BookData
extends Resource
## Um livro perdido na Dungeon: é pego lá e só pode ser lido na escola (no atril do Salão de
## Estudos). Ao ser lido, ensina uma receita sorteada entre as que o jogador ainda não conhece
## (a Mesa só combina um composto com a receita dele). O livro em si dá o título e o texto.
## Cada livro é um arquivo em data/books/.

@export var id: StringName
## Título (em locales/content.csv).
@export var name_key: String
## Texto lido no atril (em locales/content.csv). A receita aprendida aparece depois dele.
@export var text_key: String
## Região da Dungeon onde o livro pode ser achado (school, caves, abyss).
@export var zone: StringName
