class_name AspectCell
extends Button
## Uma casinha com o ícone de um aspecto e, embaixo à direita, quantos pontos você tem dele.
## Usada na grade de aspectos e nos espaços de combinação da Mesa de Pesquisa.
## Desenhada em pixels da interface (640x360): o ícone fica no tamanho original, 16x16.

## Aspecto mostrado (vazio: a casinha fica vazia ou com `placeholder`).
var aspect_id: StringName = &"":
	set(value):
		aspect_id = value
		_update_tooltip()
		queue_redraw()
## Número no canto (-1: não mostra).
var count := -1:
	set(value):
		count = value
		queue_redraw()
## Texto no lugar do ícone quando não há aspecto (ex.: "?").
var placeholder := "":
	set(value):
		placeholder = value
		queue_redraw()
## Desenha um fundo escuro com borda (para os espaços de combinação).
@export var framed := false
## Destaque de seleção.
var selected := false:
	set(value):
		selected = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(24, 24)
	flat = true
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _update_tooltip() -> void:
	var aspect: AspectData = Content.db.aspects.get(aspect_id)
	tooltip_text = "%s (%s)" % [Text.aspect_name(aspect_id), tr(aspect.meaning_key)] if aspect != null else ""


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if framed:
		draw_rect(rect, Color(0.05, 0.03, 0.02, 0.95))
		draw_rect(Rect2(0.5, 0.5, size.x - 1, size.y - 1), Color(0.45, 0.33, 0.19), false, 1.0)
	if selected:
		draw_rect(rect, Color(0.9, 0.7, 0.3, 0.2))
		draw_rect(Rect2(0.5, 0.5, size.x - 1, size.y - 1), Color(0.92, 0.74, 0.35), false, 1.0)
	elif is_hovered():
		draw_rect(rect, Color(1, 1, 1, 0.07))
	var aspect: AspectData = Content.db.aspects.get(aspect_id)
	var font := get_theme_default_font()
	if aspect != null and aspect.icon != null:
		# Tamanho original e posição inteira: os pixels do ícone ficam do tamanho dos da tela.
		var icon_position := ((size - Vector2(16, 16)) / 2.0 - Vector2(0, 2)).floor()
		draw_texture_rect(aspect.icon, Rect2(icon_position, Vector2(16, 16)), false)
	elif placeholder != "":
		var width := font.get_string_size(placeholder, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(font, Vector2(floorf((size.x - width) / 2.0), floorf(size.y / 2.0) + 7), placeholder,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.82, 0.72, 0.53))
	if count >= 0:
		var text := str(count)
		var text_position := Vector2(size.x - 1 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x, size.y - 1).floor()
		draw_string_outline(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, Color(0.05, 0.03, 0.02))
		draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.88, 0.72))
