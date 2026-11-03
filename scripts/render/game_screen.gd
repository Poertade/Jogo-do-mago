class_name GameScreen
extends TextureRect
## Mostra o mundo 3D na tela.
## O mundo é desenhado num SubViewport pequeno (por exemplo, 427x240) e esta TextureRect
## o amplia para a janela inteira com pixels nítidos, passando pelo pós-processamento PS1.
## Também aplica nos shaders as opções gráficas do jogador.

## Onde o mundo 3D é desenhado.
@export var viewport: SubViewport

var _internal_height := 240
var _snap_pixel_size := 1.0


func _ready() -> void:
	texture = viewport.get_texture()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch_mode = TextureRect.STRETCH_SCALE
	resized.connect(_update_viewport_size)


## Aplica as opções: efeitos dos shaders e resolução interna.
func apply_settings(settings: GameSettings, defaults: SettingsDefaults) -> void:
	RenderingServer.global_shader_parameter_set(&"ps1_vertex_snap", settings.vertex_snap)
	RenderingServer.global_shader_parameter_set(&"ps1_affine_mapping", settings.affine_mapping)
	RenderingServer.global_shader_parameter_set(&"ps1_fog", settings.fog)
	material.set_shader_parameter(&"color_limit", settings.color_limit)
	material.set_shader_parameter(&"dithering", settings.dithering)
	material.set_shader_parameter(&"color_levels", float(settings.color_levels()))
	_internal_height = settings.internal_height
	_snap_pixel_size = defaults.vertex_snap_pixel_size
	_update_viewport_size()


## A altura é a escolhida nas opções; a largura acompanha a proporção da janela.
func _update_viewport_size() -> void:
	if size.y <= 0:
		return
	var width := roundi(_internal_height * size.x / size.y)
	var internal_size := Vector2i(width, _internal_height)
	viewport.size = internal_size
	material.set_shader_parameter(&"source_size", Vector2(internal_size))
	RenderingServer.global_shader_parameter_set(&"ps1_snap_grid", Vector2(internal_size) / _snap_pixel_size)
