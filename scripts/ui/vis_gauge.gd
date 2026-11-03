class_name VisGauge
extends Control
## Mostrador de Vis da varinha, no canto do HUD (inspirado no do Thaumcraft 4): no centro, o
## orbe do Focus equipado; em volta, em leque, um frasco para cada recipiente da varinha, cheio
## até onde há Vis daquele aspecto. Embaixo, o total guardado e o limite da varinha.
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
const FONT_SIZE := 10

const GLASS := Color(0.06, 0.05, 0.07, 0.9)
const GLASS_EDGE := Color(0.0, 0.0, 0.0)
const BRASS := Color(0.69, 0.54, 0.24)
const TEXT := Color(0.86, 0.8, 0.68)

var _wand: WandState
var _focus_color := Color.WHITE


func _init() -> void:
	custom_minimum_size = Vector2(100, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Atualiza o que o mostrador exibe.
func show_wand(wand: WandState, focus_color: Color) -> void:
	_wand = wand
	_focus_color = focus_color
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
	var total_at := Vector2(2, size.y - 2)
	draw_string_outline(font, total_at, total, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, Color.BLACK)
	draw_string(font, total_at, total, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)


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
