class_name AspectCell
extends Button
## Uma casinha com o ícone de um aspecto e, embaixo à direita, quantos pontos você tem dele.
## Usada na grade de aspectos e nos espaços de combinação da Mesa de Pesquisa.

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
	custom_minimum_size = Vector2(52, 52)
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
		draw_rect(rect, Color(0.08, 0.05, 0.03, 0.85))
		draw_rect(rect.grow(-1), Color(0.55, 0.42, 0.26), false, 2.0)
	if selected:
		draw_rect(rect.grow(-1), Color(1.0, 0.9, 0.5, 0.25))
		draw_rect(rect.grow(-1), Color(1.0, 0.85, 0.4), false, 2.0)
	elif is_hovered():
		draw_rect(rect.grow(-1), Color(1, 1, 1, 0.08))
	var aspect: AspectData = Content.db.aspects.get(aspect_id)
	var font := get_theme_default_font()
	if aspect != null and aspect.icon != null:
		var icon_size := minf(size.x, size.y) - 14.0
		draw_texture_rect(aspect.icon, Rect2((size - Vector2(icon_size, icon_size)) / 2.0 - Vector2(0, 3), Vector2(icon_size, icon_size)), false)
	elif placeholder != "":
		draw_string(font, Vector2(0, size.y / 2 + 9), placeholder, HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, Color(0.93, 0.85, 0.68))
	if count >= 0:
		var text := str(count)
		var text_position := Vector2(size.x - 4 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x, size.y - 4)
		draw_string_outline(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color(0.08, 0.05, 0.03))
		draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.97, 0.92, 0.8))
