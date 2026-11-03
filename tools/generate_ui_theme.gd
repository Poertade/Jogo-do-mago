extends SceneTree
## Gera a aparência de pergaminho dos menus: as texturas (pergaminho com borda rasgada e
## moldura de madeira escura) em assets/ui/ e o tema assets/ui/parchment_theme.tres, com a
## fonte Pixelify Sans (assets/fonts/). Rodar a partir da pasta do projeto:
##   godot --headless --path . -s tools/generate_ui_theme.gd
## O tema também pode ser ajustado à mão no editor (abrir o .tres mostra o editor de temas).

const INK := Color(0.23, 0.16, 0.1)
const INK_SOFT := Color(0.36, 0.26, 0.17)
const PAPER := Color(0.87, 0.79, 0.6)
const LIGHT_ON_WOOD := Color(0.93, 0.85, 0.68)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/ui")
	_parchment().save_png("res://assets/ui/parchment.png")
	_wood().save_png("res://assets/ui/wood_frame.png")
	print("Texturas geradas; rode de novo com as texturas importadas para gerar o tema.")
	if ResourceLoader.exists("res://assets/ui/parchment.png") and FileAccess.file_exists("res://assets/ui/parchment.png.import"):
		print("Tema: ", ResourceSaver.save(_theme(), "res://assets/ui/parchment_theme.tres"))
	quit()


## Pergaminho 160x160: papel amarelado com fibras e manchas, borda escurecida (queimada) e
## rasgada (pixels transparentes irregulares). O miolo se repete sem emenda: o desenho do papel
## é feito num "ladrilho" de TILE pixels que dá a volta (o que sai por um lado volta pelo outro).
const PARCHMENT_SIZE := 160
const PARCHMENT_MARGIN := 24
const TILE := PARCHMENT_SIZE - 2 * PARCHMENT_MARGIN


func _parchment() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var paper := _paper_tile(rng)
	var size := PARCHMENT_SIZE
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var tear := []
	for i in size:
		tear.append(rng.randi_range(0, 3))
	for y in size:
		for x in size:
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var torn: int = maxi(tear[x], tear[y]) if edge < 4 else 0
			if edge < torn:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var color: Color = paper[posmod(y - PARCHMENT_MARGIN, TILE)][posmod(x - PARCHMENT_MARGIN, TILE)]
			if edge < 12:
				color = color.darkened((12 - edge) * 0.03)
			if edge <= torn + 1:
				color = Color(0.35, 0.22, 0.12)
			image.set_pixel(x, y, color)
	return image


## O desenho do papel num ladrilho TILE x TILE que se repete sem emenda.
func _paper_tile(rng: RandomNumberGenerator) -> Array:
	var rows := []
	for v in TILE:
		var row := []
		for u in TILE:
			# Ondas suaves com período que cabe no ladrilho, mais um grão aleatório por pixel.
			var wave := sin(TAU * (u * 2.0 + v) / TILE) + 0.6 * sin(TAU * (v * 3.0 - u) / TILE)
			row.append(PAPER.darkened(0.025 * (wave + 1.6) + rng.randf_range(0.0, 0.05)))
		rows.append(row)
	# Fibras: risquinhos horizontais um pouco mais escuros.
	for fiber in 40:
		var u0 := rng.randi_range(0, TILE - 1)
		var v0 := rng.randi_range(0, TILE - 1)
		for step in rng.randi_range(3, 9):
			var u := posmod(u0 + step, TILE)
			rows[v0][u] = (rows[v0][u] as Color).darkened(0.07)
	# Manchas (a distância também dá a volta no ladrilho).
	for stain in 4:
		var center := Vector2(rng.randf_range(0, TILE), rng.randf_range(0, TILE))
		var radius := rng.randf_range(6, 14)
		for v in TILE:
			for u in TILE:
				var d := Vector2(u, v) - center
				d.x = d.x - TILE * round(d.x / TILE)
				d.y = d.y - TILE * round(d.y / TILE)
				if d.length() < radius:
					rows[v][u] = (rows[v][u] as Color).darkened(0.07 * (1.0 - d.length() / radius))
	return rows


## Madeira escura 64x64 em tábuas verticais, com moldura mais escura na borda.
func _wood() -> Image:
	var size := 64
	var rng := RandomNumberGenerator.new()
	rng.seed = 2424
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var base := Color(0.25, 0.17, 0.11)
	for y in size:
		for x in size:
			var plank := x / 16
			var color := base.lightened(0.04 * (plank % 2)).darkened(rng.randf_range(0.0, 0.08))
			color = color.lightened(0.05 * maxf(sin(y * 0.4 + plank * 2.0 + x * 0.1), 0.0))
			if x % 16 == 0:
				color = color.darkened(0.45)
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			if edge < 4:
				color = Color(0.13, 0.08, 0.05) if edge != 2 else Color(0.42, 0.3, 0.18)
			image.set_pixel(x, y, color)
	return image


func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/PixelifySans.ttf")
	theme.default_font_size = 18

	# Pergaminho: o painel padrão dos menus.
	var parchment := StyleBoxTexture.new()
	parchment.texture = load("res://assets/ui/parchment.png")
	parchment.set_texture_margin_all(PARCHMENT_MARGIN)
	parchment.set_content_margin_all(22)
	parchment.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	parchment.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	theme.set_stylebox("panel", "PanelContainer", parchment)
	theme.set_stylebox("panel", "PopupMenu", parchment)
	theme.set_stylebox("panel", "TooltipPanel", parchment)

	# Moldura de madeira (variação "WoodPanel" de PanelContainer).
	var wood := StyleBoxTexture.new()
	wood.texture = load("res://assets/ui/wood_frame.png")
	wood.set_texture_margin_all(8)
	wood.set_content_margin_all(14)
	wood.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	wood.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	theme.set_type_variation("WoodPanel", "PanelContainer")
	theme.set_stylebox("panel", "WoodPanel", wood)

	# Texto: tinta marrom no pergaminho; claro sobre a madeira (variação "WoodLabel").
	theme.set_color("font_color", "Label", INK)
	theme.set_color("default_color", "RichTextLabel", INK)
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", Color(0.5, 0.15, 0.1))
	theme.set_color("font_color", "TooltipLabel", INK)
	theme.set_type_variation("WoodLabel", "Label")
	theme.set_color("font_color", "WoodLabel", LIGHT_ON_WOOD)
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_color("font_color", "TitleLabel", Color(0.45, 0.13, 0.08))
	theme.set_font_size("font_size", "TitleLabel", 28)

	# Botões de papel com borda de tinta.
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.set_border_width_all(2)
		box.border_color = INK_SOFT
		box.set_content_margin_all(6)
		box.content_margin_left = 12
		box.content_margin_right = 12
		match state:
			"normal":
				box.bg_color = Color(0.82, 0.72, 0.52)
			"hover":
				box.bg_color = Color(0.9, 0.81, 0.6)
			"pressed":
				box.bg_color = Color(0.72, 0.6, 0.42)
			"disabled":
				box.bg_color = Color(0.78, 0.71, 0.56, 0.6)
				box.border_color = Color(0.5, 0.42, 0.32, 0.6)
			"focus":
				box.draw_center = false
				box.border_color = Color(0.55, 0.15, 0.1)
		for type in ["Button", "OptionButton"]:
			theme.set_stylebox(state, type, box)
	for type in ["Button", "OptionButton", "CheckButton"]:
		theme.set_color("font_color", type, INK)
		theme.set_color("font_hover_color", type, Color(0.1, 0.06, 0.03))
		theme.set_color("font_pressed_color", type, Color(0.1, 0.06, 0.03))
		theme.set_color("font_focus_color", type, INK)
		theme.set_color("font_disabled_color", type, Color(0.45, 0.38, 0.3))

	var line := StyleBoxLine.new()
	line.color = Color(0.42, 0.3, 0.2)
	line.thickness = 2
	theme.set_stylebox("separator", "HSeparator", line)

	# Trilho e marcador do controle deslizante.
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.6, 0.48, 0.32)
	track.set_content_margin_all(3)
	theme.set_stylebox("slider", "HSlider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.13, 0.08)
	fill.set_content_margin_all(3)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	return theme
