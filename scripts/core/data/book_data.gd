class_name BookData
extends Resource
## Um livro perdido na Dungeon: é pego lá e só pode ser lido na escola (no atril do Salão de
## Estudos). Ensina receitas de aspectos que a Mesa não deixa combinar sem elas.
## Cada livro é um arquivo em data/books/.

@export var id: StringName
## Título (em locales/content.csv).
@export var name_key: String
## Texto lido no atril (em locales/content.csv; "{aspecto}" vira o nome do aspecto).
@export var text_key: String
## Aspectos cuja receita o livro ensina (aspectos compostos com `needs_recipe`).
@export var teaches: Array[StringName] = []
## Região da Dungeon onde o livro pode ser achado (school, caves, abyss).
@export var zone: StringName
