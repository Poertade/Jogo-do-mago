class_name AspectData
extends Resource
## Um aspecto: uma das "partes" de que tudo no mundo é feito.
## Primais são básicos; compostos (no futuro) são formados por dois outros aspectos.
## Cada aspecto é um arquivo em data/aspects/. O nome exibido vem de locales/names.csv
## (chave ASPECT_<ID>), o único arquivo com nomes que remetem a outras obras.

## Identificador interno, único entre os aspectos (ex.: fire).
@export var id: StringName
## Chave de tradução do nome (ex.: ASPECT_FIRE, em locales/names.csv).
@export var name_key: String
## Chave de tradução do significado (ex.: "fogo", em locales/content.csv).
@export var meaning_key: String
## "primal" (básico) ou "compound" (formado por dois aspectos pais).
@export_enum("primal", "compound") var kind: String = "primal"
## Os dois aspectos que formam um aspecto composto. Vazio para primais.
@export var parents: Array[StringName] = []
## Cor usada na interface (Livro de Pesquisa, HUD).
@export var color: Color = Color.WHITE
## Ícone (16x16) mostrado na Mesa de Pesquisa e no Livro (assets/icons/aspects/).
@export var icon: Texture2D
## Receita escondida: a Mesa só combina os pais depois que o jogador ler o livro que a ensina
## (data/books/). Vale para os aspectos estranhos das profundezas.
@export var needs_recipe := false


func is_compound() -> bool:
	return kind == "compound"
