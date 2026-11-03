extends SceneTree
## Gera os ícones dos aspectos (16x16, pixel art) em assets/icons/aspects/, um por aspecto de
## data/aspects/, na cor do aspecto e com contorno escuro. São símbolos originais e simples.
## Rodar a partir da pasta do projeto:
##   godot --headless --path . -s tools/generate_icons.gd
## Para trocar um ícone por um desenho próprio, substitua o PNG mantendo o nome.
## Aspecto novo: o .tres aponta para um ícone que ainda não existe e não carrega. Copie qualquer
## PNG de assets/icons/aspects/ com o nome novo, rode --import e depois esta ferramenta.

const SIZE := 16
const OUTPUT_DIR := "res://assets/icons/aspects"

var _image: Image
var _color: Color


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	for file_name in DirAccess.get_files_at("res://data/aspects"):
		if not file_name.ends_with(".tres"):
			continue
		var aspect: AspectData = load("res://data/aspects/" + file_name)
		if aspect == null:
			push_warning("Não carregou %s (ícone faltando? veja o comentário no topo)." % file_name)
			continue
		_image = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		_color = aspect.color
		if has_method("_glyph_" + aspect.id):
			call("_glyph_" + aspect.id)
		else:
			_disc(8, 8, 5)  # aspecto sem desenho próprio: uma bolinha
		_shade_and_outline()
		var path := OUTPUT_DIR.path_join(String(aspect.id) + ".png")
		_image.save_png(path)
		print("Gerado: ", path)
	quit()


# --- Desenhos (coordenadas de 0 a 15) -----------------------------------------

func _glyph_fire() -> void:
	_poly([Vector2(8, 0.5), Vector2(11.5, 6), Vector2(12.5, 10), Vector2(10.5, 14.5), Vector2(5.5, 14.5), Vector2(3.5, 10), Vector2(5, 5)])
	_disc(8, 11.2, 2.0, _color.lightened(0.45))
	_poly([Vector2(8, 6.5), Vector2(9.6, 10.5), Vector2(6.4, 10.5)], _color.lightened(0.45))

func _glyph_water() -> void:
	_disc(8, 10, 4.6)
	_poly([Vector2(8, 0.5), Vector2(12, 9), Vector2(4, 9)])
	_disc(6.5, 10.5, 1.2, _color.lightened(0.5))

func _glyph_earth() -> void:
	_poly([Vector2(0.5, 14.5), Vector2(6, 3), Vector2(9, 8.5), Vector2(11, 5.5), Vector2(15.5, 14.5)])
	_poly([Vector2(6, 3), Vector2(7.5, 6), Vector2(4.5, 6)], _color.lightened(0.4))

func _glyph_air() -> void:
	# Símbolo clássico de vento: três linhas retas, a do meio mais longa, com a ponta enrolada.
	for row in [[3.5, 8.5], [8.5, 12.5], [13.5, 7.5]]:
		_line(Vector2(1.5, row[0]), Vector2(row[1], row[0]), 0.5)
		_ring(row[1] + 0.5, row[0] - 1.5, 1.6, 1.1)

func _glyph_order() -> void:
	var outer := _hexagon(8, 8, 7)
	var inner := _hexagon(8, 8, 5)
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, outer) and not Geometry2D.is_point_in_polygon(p, inner):
				_image.set_pixel(x, y, _color)
	_disc(8, 8, 1.8)

func _glyph_entropy() -> void:
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x + 0.5 - 8, y + 0.5 - 8)
			var angle := atan2(d.y, d.x)
			if d.length() > 4.8 and d.length() < 7 and not (angle > 0.2 and angle < 1.2):
				_image.set_pixel(x, y, _color)
	_line(Vector2(11, 4), Vector2(5, 12), 1.2)

func _glyph_light() -> void:
	_disc(8, 8, 3.4)
	for i in 8:
		var a := i * TAU / 8
		_line(Vector2(8, 8) + Vector2(cos(a), sin(a)) * 5, Vector2(8, 8) + Vector2(cos(a), sin(a)) * 7.2, 0.9)

func _glyph_motion() -> void:
	_line(Vector2(1.5, 8), Vector2(11, 8), 1.4)
	_poly([Vector2(9, 2.5), Vector2(15, 8), Vector2(9, 13.5)])

func _glyph_void() -> void:
	_ring(8, 8, 6.6, 1.3)
	_disc(8, 8, 0.9, _color.darkened(0.3))

func _glyph_energy() -> void:
	_poly([Vector2(9.5, 0.5), Vector2(3.5, 9), Vector2(7.5, 9), Vector2(5.5, 15.5), Vector2(12.5, 6), Vector2(8.5, 6), Vector2(11, 0.5)])

func _glyph_life() -> void:
	_disc(5.3, 6, 3.2)
	_disc(10.7, 6, 3.2)
	_poly([Vector2(2.2, 7.2), Vector2(13.8, 7.2), Vector2(8, 14.5)])
	_disc(4.8, 5.2, 1, _color.lightened(0.5))

func _glyph_crystal() -> void:
	_poly([Vector2(8, 0.5), Vector2(13.5, 6), Vector2(8, 15.5), Vector2(2.5, 6)])
	_poly([Vector2(8, 1.5), Vector2(8, 14), Vector2(4, 6)], _color.lightened(0.35))

func _glyph_plant() -> void:
	_line(Vector2(8, 15), Vector2(8, 5), 1.2)
	_poly([Vector2(8, 10.5), Vector2(2.5, 7.5), Vector2(3.5, 3.5), Vector2(8, 8)])
	_poly([Vector2(8, 8), Vector2(13.5, 4.5), Vector2(12.5, 9), Vector2(8, 11)])

func _glyph_death() -> void:
	_line(Vector2(3, 3), Vector2(13, 13), 1.6)
	_line(Vector2(13, 3), Vector2(3, 13), 1.6)

func _glyph_magic() -> void:
	var points := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * TAU / 10
		var r := 7.3 if i % 2 == 0 else 3.0
		points.append(Vector2(8, 8.5) + Vector2(cos(a), sin(a)) * r)
	_poly(points)

func _glyph_metal() -> void:
	_poly([Vector2(1.5, 13.5), Vector2(4, 6.5), Vector2(12, 6.5), Vector2(14.5, 13.5)])
	_poly([Vector2(4.5, 7.5), Vector2(11.5, 7.5), Vector2(11, 9), Vector2(5, 9)], _color.lightened(0.45))

func _glyph_tree() -> void:
	_poly([Vector2(6.5, 15.5), Vector2(7, 9), Vector2(9, 9), Vector2(9.5, 15.5)], _color.darkened(0.25))
	_disc(8, 6, 5.3)
	_disc(6.5, 4.5, 1.5, _color.lightened(0.3))

func _glyph_soul() -> void:
	_disc(8, 6, 4.4)
	_poly([Vector2(3.8, 6.5), Vector2(12.2, 6.5), Vector2(10, 11), Vector2(11, 15.5), Vector2(8, 12.5), Vector2(5, 15.5), Vector2(6, 11)])
	_disc(6.5, 5.5, 0.9, _color.darkened(0.6))
	_disc(9.5, 5.5, 0.9, _color.darkened(0.6))

func _glyph_undead() -> void:
	_disc(8, 6.5, 5.6)
	_poly([Vector2(5, 10), Vector2(11, 10), Vector2(10.5, 14), Vector2(5.5, 14)])
	_clear_disc(5.8, 6.8, 1.6)
	_clear_disc(10.2, 6.8, 1.6)
	_clear_disc(8, 10, 0.8)
	for x in [6.5, 8.0, 9.5]:
		_clear_disc(x, 13.6, 0.5)

func _glyph_mind() -> void:
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(Vector2(8, 15)) < 10.2 and p.distance_to(Vector2(8, 1)) < 10.2:
				_image.set_pixel(x, y, _color)
	_clear_disc(8, 8, 2.7)
	_disc(8, 8, 1.4, _color.darkened(0.5))

func _glyph_cold() -> void:
	# Floco de neve: seis braços finos saindo do centro, com uma ponta em cada um.
	for i in 6:
		var a := PI / 2 + i * PI / 3
		var d := Vector2(cos(a), sin(a))
		# Centro no meio de um pixel, para os braços verticais terem 1 pixel de largura.
		_line(Vector2(7.5, 7.5), Vector2(7.5, 7.5) + d * 6.0, 0.5)
		_disc(7.5 + d.x * 6.0, 7.5 + d.y * 6.0, 1.1)

func _glyph_travel() -> void:
	# Trilha tracejada em curva, terminando numa seta: a jornada.
	var points: Array[Vector2] = []
	for step in 13:
		var t := step / 12.0
		points.append(Vector2(2 + t * 9, 14 - t * 10 + sin(t * PI * 1.5) * 2.5))
	for i in range(0, 12, 3):
		_line(points[i], points[i + 1], 0.7)
	_poly([Vector2(9, 3.5), Vector2(14.5, 1.5), Vector2(13, 7)])


# --- Ferramentas de desenho -----------------------------------------------------

func _dot(x: float, y: float, color := Color()) -> void:
	_disc(x, y, 0.9, color)

func _disc(cx: float, cy: float, r: float, color := Color()) -> void:
	var c := _color if color == Color() else color
	for y in SIZE:
		for x in SIZE:
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy)) <= r:
				_image.set_pixel(x, y, c)

func _ellipse(cx: float, cy: float, rx: float, ry: float) -> void:
	for y in SIZE:
		for x in SIZE:
			if Vector2((x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry).length() <= 1.0:
				_image.set_pixel(x, y, _color)

func _clear_disc(cx: float, cy: float, r: float) -> void:
	for y in SIZE:
		for x in SIZE:
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy)) <= r:
				_image.set_pixel(x, y, Color(0, 0, 0, 0))

func _ring(cx: float, cy: float, r: float, thickness: float) -> void:
	for y in SIZE:
		for x in SIZE:
			if absf(Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy)) - r) <= thickness / 2.0:
				_image.set_pixel(x, y, _color)

func _line(a: Vector2, b: Vector2, thickness: float) -> void:
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) <= thickness:
				_image.set_pixel(x, y, _color)

func _poly(points, color := Color()) -> void:
	var c := _color if color == Color() else color
	var polygon := PackedVector2Array(points)
	for y in SIZE:
		for x in SIZE:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
				_image.set_pixel(x, y, c)

func _hexagon(cx: float, cy: float, r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		var a := PI / 6 + i * TAU / 6
		points.append(Vector2(cx, cy) + Vector2(cos(a), sin(a)) * r)
	return points


## Clareia a borda de cima do desenho e contorna tudo de escuro, para ler bem no pergaminho.
func _shade_and_outline() -> void:
	var original := _image.duplicate() as Image
	var outline := _color.darkened(0.7)
	for y in SIZE:
		for x in SIZE:
			var filled := original.get_pixel(x, y).a > 0.5
			if filled:
				if y > 0 and original.get_pixel(x, y - 1).a < 0.5:
					_image.set_pixel(x, y, original.get_pixel(x, y).lightened(0.25))
				continue
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + offset
				if n.x >= 0 and n.y >= 0 and n.x < SIZE and n.y < SIZE and original.get_pixel(n.x, n.y).a > 0.5:
					_image.set_pixel(x, y, outline)
					break
