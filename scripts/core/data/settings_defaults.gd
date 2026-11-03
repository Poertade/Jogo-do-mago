class_name SettingsDefaults
extends Resource
## Valores iniciais das opções e limites oferecidos no menu.
## O arquivo fica em data/settings/defaults.tres.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam sempre no arquivo de dados.

## Filtro usado na primeira vez que o jogo abre.
@export var default_preset_id: StringName
## Alturas da imagem interna oferecidas no menu, em linhas.
@export var internal_heights: PackedInt32Array = []

@export_group("Mouse")
## Graus de rotação da câmera por pixel de movimento do mouse.
@export var mouse_sensitivity: float = 0.0
@export var mouse_sensitivity_min: float = 0.0
@export var mouse_sensitivity_max: float = 0.0

@export_group("Ajustes finos do visual")
## Bits por canal de cor quando a cor limitada está ligada (o PS1 usava 5).
@export var color_depth_bits: int = 0
## Tamanho da grade do vertex snapping, em pixels da imagem interna.
## 1 imita o PS1; valores maiores deixam o tremor mais forte.
@export var vertex_snap_pixel_size: float = 0.0
