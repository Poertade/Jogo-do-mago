class_name ResearchNoteView
extends Control
## Desenha a nota de pesquisa no pergaminho: os hexágonos (círculos de tinta), os aspectos
## escritos com seus ícones e as ligações entre vizinhos. Clique esquerdo num hexágono vazio
## pede para escrever; clique direito num aspecto escrito pede para apagar.

signal cell_clicked(cell: Vector2i, button: MouseButton)

const INK := Color(0.16, 0.1, 0.06)
const TARGET_INK := Color(0.36, 0.07, 0.04)
const LINK := Color(0.34, 0.12, 0.42)

var note: ResearchNote
## Aspectos que o jogador ainda não descobriu aparecem como "?" nos alvos.
var known: Callable = func(_id): return true
var finished := false

var _hover := Vector2i(999, 999)


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_note(new_note: ResearchNote, is_known: Callable, is_finished: bool) -> void:
	note = new_note
	known = is_known
	finished = is_finished
	queue_redraw()


func _hex_size() -> float:
	if note == null:
		return 0.0
	var span := note.radius * 2 + 1
	return minf(size.x / (sqrt(3.0) * span), size.y / (1.5 * span + 0.5)) * 0.98


## Centro do hexágono, arredondado para um pixel inteiro (desenho nítido na interface 640x360).
func cell_center(cell: Vector2i) -> Vector2:
	var s := _hex_size()
	return (size / 2.0 + Vector2(s * sqrt(3.0) * (cell.x + cell.y / 2.0), s * 1.5 * cell.y)).floor()


func cell_at(point: Vector2) -> Vector2i:
	var best := Vector2i(999, 999)
	var best_distance := _hex_size() * 0.9
	for cell in note.cells():
		var d := point.distance_to(cell_center(cell))
		if d < best_distance:
			best_distance = d
			best = cell
	return best


func _gui_input(event: InputEvent) -> void:
	if note == null:
		return
	if event is InputEventMouseMotion:
		var cell := cell_at(event.position)
		if cell != _hover:
			_hover = cell
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		var cell := cell_at(event.position)
		if note.contains(cell):
			cell_clicked.emit(cell, event.button_index)
			accept_event()


func _draw() -> void:
	if note == null:
		return
	var s := _hex_size()
	var aspects := Content.db.aspects
	# Ligações primeiro, por baixo dos círculos.
	for pair in note.links(aspects):
		draw_line(cell_center(pair[0]), cell_center(pair[1]), LINK, 3.0)
	var font := get_theme_default_font()
	var radius := floorf(s * 0.62)
	for cell in note.cells():
		var center := cell_center(cell)
		var aspect_id := note.aspect_at(cell)
		if note.is_target(cell):
			draw_circle(center, radius, Color(0.3, 0.2, 0.12, 0.35))
			draw_arc(center, radius, 0, TAU, 32, TARGET_INK, 2.0)
		else:
			draw_arc(center, radius, 0, TAU, 32, INK, 1.0)
		if cell == _hover and not finished and note.can_write(cell):
			draw_circle(center, radius - 2, Color(1, 0.95, 0.8, 0.18))
		if aspect_id == &"":
			continue
		var aspect: AspectData = aspects.get(aspect_id)
		if note.is_target(cell) and not known.call(aspect_id):
			var width := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(font, center + Vector2(-floorf(width / 2.0), 7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, TARGET_INK)
		elif aspect != null and aspect.icon != null:
			# Ícone no tamanho original (16x16), em posição inteira.
			draw_texture_rect(aspect.icon, Rect2(center - Vector2(8, 8), Vector2(16, 16)), false)
