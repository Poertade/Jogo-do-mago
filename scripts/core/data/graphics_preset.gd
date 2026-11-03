class_name GraphicsPreset
extends Resource
## Filtro visual pronto (por exemplo, "Crocante" ou "Limpo"): uma combinação dos efeitos PS1.
## Cada filtro é um arquivo em data/settings/presets/.

## Identificador interno, único entre os filtros.
@export var id: StringName
## Chave de tradução do nome exibido no menu (em locales/ui.csv).
@export var name_key: String

@export_group("Efeitos")
## Vértices "tremem" presos a uma grade de pixels.
@export var vertex_snap: bool = false
## Texturas deformam em polígonos grandes, como no PS1.
@export var affine_mapping: bool = false
## Névoa que esconde o que está longe.
@export var fog: bool = false
## Poucas cores por canal (o PS1 usava 5 bits).
@export var color_limit: bool = false
## Padrão de pontos que disfarça a falta de cores. Só tem efeito com a cor limitada.
@export var dithering: bool = false

## Altura da imagem interna, em linhas. A largura acompanha a proporção da janela.
@export var internal_height: int = 0
