class_name VisGauge
extends Control
## Mostrador de Vis da varinha, no canto do HUD (inspirado no do Thaumcraft 4): no centro, o
## orbe do Focus equipado; em volta, em leque, um frasco para cada recipiente da varinha, cheio
## até onde há Vis daquele aspecto. Embaixo, o total guardado e o limite da varinha, os potes
## do cinto (cheios até onde há Vis, na cor do aspecto), quantos livros o jogador carrega e os
## materiais (prata e cacos de vidro: o guardado na escola mais o achado na incursão).
## Desenhado em pixels da interface (640x360); o HUD chama `show_wand` a cada quadro.

## Centro do orbe, raio do orbe e onde os frascos começam e terminam (distância do centro).
const ORB_CENTER := Vector2(22, 22)
const ORB_RADIUS := 11.0
const VIAL_START := 15.0
const VIAL_LENGTH := 30.0
const VIAL_WIDTH := 7.0
## Ângulos do primeiro e do último frasco, em graus (0 = direita, 90 = para baixo).
const FAN_FROM := -8.0
const FAN_TO := 98.0
const FONT_SIZE := 11

const GLASS := Color(0.06, 0.05, 0.07, 0.9)
const GLASS_EDGE := Color(0.0, 0.0, 0.0)
const BRASS := Color(0.69, 0.54, 0.24)
const TEXT := Color(0.86, 0.8, 0.68)

var _wand: WandState
var _focus_color := Color.WHITE
var _jars: VisJarBelt
var _books := 0
var _items: Dictionary = {}
var _elixirs := 0
var _elixir_color := Color(0.9, 0.25, 0.3)


func _init() -> void:
	custom_minimum_size = Vector2(110, 128)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Atualiza o que o mostrador exibe.
## `items`: material → quantidade (ex.: {&"silver": 12, &"glass": 2}).
## `elixirs`: quantos elixires o jogador leva (F bebe um), e a cor do frasco.
func show_wand(wand: WandState, focus_color: Color, jars: VisJarBelt = null, books := 0, items := {}, elixirs := 0,
		elixir_color := Color(0.9, 0.25, 0.3)) -> void:
	_wand = wand
	_focus_color = focus_color
	_jars = jars
	_books = books
	_items = items
	_elixirs = elixirs
	_elixir_color = elixir_color
	queue_redraw()


func _draw() -> void:
	if _wand == null:
		return
	var containers := _wand.wand.aspects
	var font := get_theme_default_font()
	for i in containers.size():
		var aspect_id := containers[i]
		var aspect: AspectData = Content.db.aspects.get(aspect_id)
		var color := aspect.color if aspect != null else Color.WHITE
		var t := 0.5 if containers.size() == 1 else float(i) / (containers.size() - 1)
		var angle := deg_to_rad(lerpf(FAN_FROM, FAN_TO, t))
		var amount := _wand.reserve(aspect_id)
		_draw_vial(angle, color, float(amount) / maxf(_wand.aspect_capacity(), 1.0))
		if amount > 0:
			var direction := Vector2.from_angle(angle)
			var label_center := ORB_CENTER + direction * (VIAL_START + VIAL_LENGTH + 8.0)
			var text := str(amount)
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
			var at := (label_center + Vector2(-width / 2.0, 4)).round()
			draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, Color.BLACK)
			draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color.lightened(0.25))
	_draw_orb()
	var total := "%s %d/%d" % [Text.tr_key("TERM_VIS"), _wand.total(), _wand.total_capacity()]
	var total_at := Vector2(2, 91)
	draw_string_outline(font, total_at, total, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, Color.BLACK)
	draw_string(font, total_at, total, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)
	_draw_belt(font)
	_draw_items(font)


## Os materiais: um ícone na cor de cada um (moeda, caco) e a quantidade.
func _draw_items(font: Font) -> void:
	var x := 2.0
	var y := 113.0
	var ids: Array = _items.keys()
	ids.sort_custom(ContentDB.by_name)
	ids.reverse()  # prata primeiro, depois cacos (silver > glass)
	for item_id in ids:
		var item: ItemData = Content.db.items.get(item_id)
		var color := item.color if item != null else Color.WHITE
		if item_id == &"silver":
			draw_circle(Vector2(x + 4, y + 5), 4.0, Color.BLACK)
			draw_circle(Vector2(x + 4, y + 5), 3.0, color)
			draw_rect(Rect2(x + 3, y + 3, 2, 1), color.lightened(0.5))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(x + 1, y + 9), Vector2(x + 3, y + 1), Vector2(x + 8, y + 3), Vector2(x + 6, y + 9)]), Color.BLACK)
			draw_colored_polygon(PackedVector2Array([Vector2(x + 2, y + 8), Vector2(x + 3.5, y + 2), Vector2(x + 7, y + 3.5), Vector2(x + 5.5, y + 8)]), color)
		var text := str(_items[item_id])
		var at := Vector2(x + 11, y + 9)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, Color.BLACK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)
		x += 16.0 + font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


## Os potes do cinto (vidro, líquido do aspecto, tampa de latão) e os livros carregados.
func _draw_belt(font: Font) -> void:
	if _jars == null:
		return
	var y := 96.0
	for i in _jars.jars.size():
		var jar := _jars.jars[i]
		var x := 2.0 + i * 15.0
		draw_rect(Rect2(x, y, 11, 15), GLASS_EDGE)
		draw_rect(Rect2(x + 1, y + 2, 9, 12), GLASS)
		if not jar.is_empty():
			var aspect: AspectData = Content.db.aspects.get(jar.aspect)
			var height := roundf(11.0 * jar.amount / maxf(_jars.capacity, 1.0))
			draw_rect(Rect2(x + 2, y + 13 - height, 7, height), aspect.color if aspect != null else Color.WHITE)
		draw_rect(Rect2(x, y, 11, 2), BRASS)
	var x_next := 6.0 + _jars.jars.size() * 15.0
	if _books > 0:
		var x := x_next
		x_next += 30.0
		draw_rect(Rect2(x, y + 2, 9, 12), Color(0.36, 0.12, 0.08))
		draw_rect(Rect2(x + 1, y + 3, 7, 1), Color(0.88, 0.76, 0.42))
		var text := "x%d" % _books
		draw_string_outline(font, Vector2(x + 11, y + 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, Color.BLACK)
		draw_string(font, Vector2(x + 11, y + 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)
	if _elixirs > 0:
		# Frasco de elixir: gargalo, bojo na cor do elixir e a quantidade.
		var x := x_next
		draw_rect(Rect2(x + 2, y, 5, 4), GLASS_EDGE)
		draw_rect(Rect2(x + 3, y + 1, 3, 3), BRASS)
		draw_circle(Vector2(x + 4.5, y + 9), 5.0, GLASS_EDGE)
		draw_circle(Vector2(x + 4.5, y + 9), 4.0, _elixir_color)
		draw_rect(Rect2(x + 3, y + 7, 1, 2), _elixir_color.lightened(0.5))
		var count := "x%d" % _elixirs
		draw_string_outline(font, Vector2(x + 11, y + 12), count, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, Color.BLACK)
		draw_string(font, Vector2(x + 11, y + 12), count, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)


## Um frasco: vidro escuro, o líquido do aspecto até `ratio` e uma tampa de latão na ponta.
func _draw_vial(angle: float, color: Color, ratio: float) -> void:
	draw_set_transform(ORB_CENTER, angle)
	var half := VIAL_WIDTH / 2.0
	draw_rect(Rect2(VIAL_START - 1, -half - 1, VIAL_LENGTH + 2, VIAL_WIDTH + 2), GLASS_EDGE)
	draw_rect(Rect2(VIAL_START, -half, VIAL_LENGTH, VIAL_WIDTH), GLASS)
	var fill := roundf((VIAL_LENGTH - 3) * clampf(ratio, 0.0, 1.0))
	if fill > 0:
		draw_rect(Rect2(VIAL_START, -half + 1, fill, VIAL_WIDTH - 2), color)
		draw_rect(Rect2(VIAL_START, -half + 1, fill, 1), color.lightened(0.45))
	# Reflexo no vidro e a tampa de latão.
	draw_rect(Rect2(VIAL_START + 2, half - 2, VIAL_LENGTH - 6, 1), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(VIAL_START + VIAL_LENGTH - 3, -half - 1, 4, VIAL_WIDTH + 2), BRASS)
	draw_rect(Rect2(VIAL_START + VIAL_LENGTH - 3, -half - 1, 4, 1), BRASS.lightened(0.3))
	draw_set_transform(Vector2.ZERO)


## O orbe do Focus: aro de latão, miolo na cor do elemento e um brilho.
func _draw_orb() -> void:
	draw_circle(ORB_CENTER, ORB_RADIUS + 2, Color.BLACK)
	draw_circle(ORB_CENTER, ORB_RADIUS + 1, BRASS.darkened(0.25))
	draw_circle(ORB_CENTER, ORB_RADIUS - 1, BRASS)
	draw_circle(ORB_CENTER, ORB_RADIUS - 2, _focus_color.darkened(0.45))
	draw_circle(ORB_CENTER + Vector2(-1, -1), ORB_RADIUS - 4, _focus_color)
	draw_circle(ORB_CENTER + Vector2(-3, -3), 2.0, _focus_color.lightened(0.6))
