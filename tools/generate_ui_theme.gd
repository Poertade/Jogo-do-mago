extends SceneTree
## Gera a aparência dos menus e do HUD, em pixels do mesmo tamanho dos da interface (que é
## desenhada numa imagem de 640x360 e ampliada 2x, veja scripts/render/ui_pixels.gdshader):
## - assets/ui/parchment.png: pergaminho velho, sujo e queimado nas bordas;
## - assets/ui/wood_frame.png: moldura de madeira escura (Mesa de Pesquisa);
## - assets/ui/icons/: chave liga/desliga, seta, bolinha de opção e marcador do controle deslizante;
## - assets/ui/parchment_theme.tres: tema dos menus (tinta escura no pergaminho);
## - assets/ui/hud_theme.tres: tema do HUD (texto claro com contorno, sobre o jogo).
## Rodar a partir da pasta do projeto (duas vezes, com --import no meio, na primeira vez que as
## texturas forem criadas, para o tema poder usá-las):
##   godot --headless --path . -s tools/generate_ui_theme.gd
## Os temas também podem ser ajustados à mão no editor (abrir o .tres mostra o editor de temas).

# Cores: tons apagados, como papel visto à luz de vela, para combinar com o mundo escuro.
const PAPER := Color(0.56, 0.46, 0.31)
const BURNT := Color(0.16, 0.1, 0.06)
const INK := Color(0.11, 0.07, 0.04)
const INK_SOFT := Color(0.26, 0.18, 0.11)
const TITLE_INK := Color(0.36, 0.07, 0.04)
const LIGHT_ON_WOOD := Color(0.82, 0.72, 0.53)
const HUD_TEXT := Color(0.86, 0.8, 0.68)
const BRASS := Color(0.69, 0.54, 0.24)

## Tamanho das letras: a fonte Pixelify Sans é desenhada numa grade de cerca de 92 unidades (de
## 1000) por ponto, e 11 px dá um pixel da tela por ponto do desenho; 22 px dobra. Em 10 px os
## pontos ficam menores que um pixel, e detalhes somem (o C vira O, o 2 parece um 8).
const FONT_SMALL := 11
const FONT_BIG := 22

const PARCHMENT_SIZE := 176
const PARCHMENT_MARGIN := 12
const TILE := PARCHMENT_SIZE - 2 * PARCHMENT_MARGIN
const ICON_DIR := "res://assets/ui/icons"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ICON_DIR)
	_parchment().save_png("res://assets/ui/parchment.png")
	_wood().save_png("res://assets/ui/wood_frame.png")
	_toggle(true).save_png(ICON_DIR.path_join("toggle_on.png"))
	_toggle(false).save_png(ICON_DIR.path_join("toggle_off.png"))
	_arrow().save_png(ICON_DIR.path_join("arrow_down.png"))
	_radio(true).save_png(ICON_DIR.path_join("radio_on.png"))
	_radio(false).save_png(ICON_DIR.path_join("radio_off.png"))
	_grabber().save_png(ICON_DIR.path_join("grabber.png"))
	print("Texturas geradas.")
	print("Fonte: ", error_string(ResourceSaver.save(_font(), "res://assets/ui/ui_font.tres")))
	if FileAccess.file_exists("res://assets/ui/icons/grabber.png.import"):
		print("Tema dos menus: ", error_string(ResourceSaver.save(_menu_theme(), "res://assets/ui/parchment_theme.tres")))
		print("Tema do HUD: ", error_string(ResourceSaver.save(_hud_theme(), "res://assets/ui/hud_theme.tres")))
	else:
		print("Rode --import e esta ferramenta de novo para gerar os temas com as texturas novas.")
	quit()


# --- Texturas ---------------------------------------------------------------------

## Pergaminho: miolo que se repete sem emenda (ladrilho de TILE pixels que dá a volta), borda
## escurecida e rasgada (pixels transparentes irregulares).
func _parchment() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var paper := _paper_tile(rng)
	var size := PARCHMENT_SIZE
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var tear := []
	for i in size:
		tear.append(rng.randi_range(0, 2))
	for y in size:
		for x in size:
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var torn: int = maxi(tear[x], tear[y]) if edge < 3 else 0
			if edge < torn:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var color: Color = paper[posmod(y - PARCHMENT_MARGIN, TILE)][posmod(x - PARCHMENT_MARGIN, TILE)]
			# Queimado: escurece forte perto da borda, com pontos soltos de fuligem.
			if edge < 9:
				color = color.lerp(BURNT, pow((9 - edge) / 9.0, 1.6) * 0.85)
			if edge < 6 and rng.randf() < 0.18:
				color = color.lerp(BURNT, 0.6)
			if edge <= torn:
				color = BURNT.darkened(0.3)
			image.set_pixel(x, y, color)
	return image


## O desenho do papel num ladrilho TILE x TILE que se repete sem emenda.
func _paper_tile(rng: RandomNumberGenerator) -> Array:
	var rows := []
	for v in TILE:
		var row := []
		for u in TILE:
			var wave := sin(TAU * (u * 2.0 + v) / TILE) + 0.6 * sin(TAU * (v * 3.0 - u) / TILE)
			row.append(PAPER.darkened(0.03 * (wave + 1.6) + rng.randf_range(0.0, 0.09)))
		rows.append(row)
	# Fibras: risquinhos horizontais mais escuros.
	for fiber in 30:
		var u0 := rng.randi_range(0, TILE - 1)
		var v0 := rng.randi_range(0, TILE - 1)
		for step in rng.randi_range(2, 6):
			var u := posmod(u0 + step, TILE)
			rows[v0][u] = (rows[v0][u] as Color).darkened(0.12)
	# Manchas de umidade (a distância também dá a volta no ladrilho).
	for stain in 7:
		var center := Vector2(rng.randf_range(0, TILE), rng.randf_range(0, TILE))
		var radius := rng.randf_range(6, 16)
		for v in TILE:
			for u in TILE:
				var d := Vector2(u, v) - center
				d.x = d.x - TILE * round(d.x / TILE)
				d.y = d.y - TILE * round(d.y / TILE)
				if d.length() < radius:
					rows[v][u] = (rows[v][u] as Color).darkened(0.07 * (1.0 - d.length() / radius))
	return rows


## Madeira escura 48x48 em tábuas verticais, com moldura mais escura e um friso claro.
func _wood() -> Image:
	var size := 48
	var rng := RandomNumberGenerator.new()
	rng.seed = 2424
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var base := Color(0.19, 0.12, 0.07)
	for y in size:
		for x in size:
			var plank := x / 12
			var color := base.lightened(0.04 * (plank % 2)).darkened(rng.randf_range(0.0, 0.12))
			color = color.lightened(0.05 * maxf(sin(y * 0.5 + plank * 2.0 + x * 0.15), 0.0))
			if x % 12 == 0:
				color = color.darkened(0.5)
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			if edge < 3:
				color = Color(0.08, 0.05, 0.03) if edge != 1 else Color(0.33, 0.23, 0.13)
			image.set_pixel(x, y, color)
	return image


## Chave liga/desliga 14x8: trilho de tinta com um botão de latão.
func _toggle(on: bool) -> Image:
	var image := Image.create_empty(14, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 14:
			var inside := x > 0 and x < 13 and y > 0 and y < 7
			var border := not inside and not ((x == 0 or x == 13) and (y == 0 or y == 7))
			if border:
				image.set_pixel(x, y, INK)
			elif inside:
				image.set_pixel(x, y, TITLE_INK.lightened(0.15) if on else Color(0.3, 0.24, 0.17))
	var knob_x := 7 if on else 1
	for y in range(1, 7):
		for x in range(knob_x, knob_x + 6):
			var shade := BRASS.lightened(0.25) if y < 3 else BRASS
			image.set_pixel(x, y, shade if x != knob_x + 5 else BRASS.darkened(0.3))
	return image


## Seta para baixo 7x4 (lista de opções).
func _arrow() -> Image:
	var image := Image.create_empty(7, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in range(y, 7 - y):
			image.set_pixel(x, y, INK)
	return image


## Bolinha de opção 7x7 (marcada ou não), para as listas.
func _radio(on: bool) -> Image:
	var image := Image.create_empty(7, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 7:
			var d := Vector2(x - 3, y - 3).length()
			if d <= 3.2 and d > 2.0:
				image.set_pixel(x, y, INK)
			elif on and d <= 1.5:
				image.set_pixel(x, y, TITLE_INK)
	return image


## Marcador do controle deslizante 5x9, de latão.
func _grabber() -> Image:
	var image := Image.create_empty(5, 9, false, Image.FORMAT_RGBA8)
	for y in 9:
		for x in 5:
			var edge := x == 0 or x == 4 or y == 0 or y == 8
			image.set_pixel(x, y, INK if edge else (BRASS.lightened(0.2) if x == 1 else BRASS))
	return image


# --- Temas --------------------------------------------------------------------------

## A fonte da interface: Pixelify Sans com um pixel a mais nos espaços entre palavras e os
## algarismos desenhados à mão. Também é a fonte padrão do projeto.
func _font() -> FontVariation:
	var font := FontVariation.new()
	# Os algarismos vêm de tools/generate_digit_font.gd; o resto, da Pixelify Sans (fallback).
	font.base_font = load("res://assets/ui/digits_font.tres")
	font.spacing_space = 1
	# Sem ligaduras: o "fi" da Pixelify vira um desenho só, difícil de ler em tamanho pequeno.
	font.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("liga"): 0}
	return font


func _menu_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = load("res://assets/ui/ui_font.tres")
	theme.default_font_size = FONT_SMALL

	# Pergaminho: o painel padrão dos menus.
	var parchment := StyleBoxTexture.new()
	parchment.texture = load("res://assets/ui/parchment.png")
	parchment.set_texture_margin_all(PARCHMENT_MARGIN)
	parchment.set_content_margin_all(12)
	parchment.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	parchment.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	theme.set_stylebox("panel", "PanelContainer", parchment)
	var small_parchment := parchment.duplicate() as StyleBoxTexture
	small_parchment.set_content_margin_all(6)
	theme.set_stylebox("panel", "PopupMenu", small_parchment)
	theme.set_stylebox("panel", "TooltipPanel", small_parchment)

	# Moldura de madeira (variação "WoodPanel" de PanelContainer).
	var wood := StyleBoxTexture.new()
	wood.texture = load("res://assets/ui/wood_frame.png")
	wood.set_texture_margin_all(4)
	wood.set_content_margin_all(7)
	wood.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	wood.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	theme.set_type_variation("WoodPanel", "PanelContainer")
	theme.set_stylebox("panel", "WoodPanel", wood)

	# Texto: tinta no pergaminho; claro sobre a madeira (WoodLabel); títulos em tinta vermelha.
	theme.set_color("font_color", "Label", INK)
	theme.set_color("default_color", "RichTextLabel", INK)
	for size_name in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		theme.set_font_size(size_name, "RichTextLabel", FONT_SMALL)
	theme.set_type_variation("WoodLabel", "Label")
	theme.set_color("font_color", "WoodLabel", LIGHT_ON_WOOD)
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_color("font_color", "TitleLabel", TITLE_INK)
	theme.set_font_size("font_size", "TitleLabel", FONT_BIG)
	theme.set_type_variation("HeaderLabel", "Label")
	theme.set_color("font_color", "HeaderLabel", TITLE_INK)
	theme.set_type_variation("WoodTitleLabel", "Label")
	theme.set_color("font_color", "WoodTitleLabel", LIGHT_ON_WOOD)
	theme.set_font_size("font_size", "WoodTitleLabel", FONT_BIG)
	theme.set_color("font_color", "TooltipLabel", INK)
	theme.set_font_size("font_size", "TooltipLabel", FONT_SMALL)

	# Botões de papel mais escuro, com borda de tinta de 1 pixel.
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.set_border_width_all(1)
		box.border_color = INK_SOFT
		box.content_margin_left = 6
		box.content_margin_right = 6
		box.content_margin_top = 2
		box.content_margin_bottom = 3
		match state:
			"normal":
				box.bg_color = PAPER.darkened(0.12)
			"hover":
				box.bg_color = PAPER.lightened(0.06)
			"pressed":
				box.bg_color = PAPER.darkened(0.28)
			"disabled":
				box.bg_color = PAPER.darkened(0.2)
				box.border_color = Color(INK_SOFT, 0.5)
			"focus":
				box.draw_center = false
				box.border_color = TITLE_INK
		for type in ["Button", "OptionButton"]:
			theme.set_stylebox(state, type, box)
	for type in ["Button", "OptionButton", "CheckButton"]:
		theme.set_color("font_color", type, INK)
		theme.set_color("font_hover_color", type, Color.BLACK)
		theme.set_color("font_pressed_color", type, Color.BLACK)
		theme.set_color("font_focus_color", type, INK)
		theme.set_color("font_hover_pressed_color", type, Color.BLACK)
		theme.set_color("font_disabled_color", type, Color(INK_SOFT, 0.7))
	var nothing := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		theme.set_stylebox(state, "CheckButton", nothing)
	var focus_line := StyleBoxFlat.new()
	focus_line.draw_center = false
	focus_line.set_border_width_all(1)
	focus_line.border_color = TITLE_INK
	theme.set_stylebox("focus", "CheckButton", focus_line)
	var toggle_on: Texture2D = load(ICON_DIR.path_join("toggle_on.png"))
	var toggle_off: Texture2D = load(ICON_DIR.path_join("toggle_off.png"))
	for icon in ["checked", "checked_mirrored", "checked_disabled", "checked_disabled_mirrored"]:
		theme.set_icon(icon, "CheckButton", toggle_on)
	for icon in ["unchecked", "unchecked_mirrored", "unchecked_disabled", "unchecked_disabled_mirrored"]:
		theme.set_icon(icon, "CheckButton", toggle_off)
	theme.set_icon("arrow", "OptionButton", load(ICON_DIR.path_join("arrow_down.png")))
	theme.set_constant("arrow_margin", "OptionButton", 4)

	# Lista que abre nas opções.
	var hover := StyleBoxFlat.new()
	hover.bg_color = PAPER.darkened(0.25)
	theme.set_stylebox("hover", "PopupMenu", hover)
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", Color.BLACK)
	theme.set_font_size("font_size", "PopupMenu", FONT_SMALL)
	theme.set_constant("v_separation", "PopupMenu", 2)
	theme.set_constant("h_separation", "PopupMenu", 4)
	for icon in ["radio_checked", "checked"]:
		theme.set_icon(icon, "PopupMenu", load(ICON_DIR.path_join("radio_on.png")))
	for icon in ["radio_unchecked", "unchecked"]:
		theme.set_icon(icon, "PopupMenu", load(ICON_DIR.path_join("radio_off.png")))

	var line := StyleBoxLine.new()
	line.color = INK_SOFT
	line.thickness = 1
	theme.set_stylebox("separator", "HSeparator", line)
	theme.set_constant("separation", "HSeparator", 3)

	# Controle deslizante: trilho fino de tinta, parte cheia em vermelho, marcador de latão.
	var track := StyleBoxFlat.new()
	track.bg_color = INK_SOFT
	track.content_margin_top = 1
	track.content_margin_bottom = 1
	theme.set_stylebox("slider", "HSlider", track)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = TITLE_INK.lightened(0.15)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grabber: Texture2D = load(ICON_DIR.path_join("grabber.png"))
	for icon in ["grabber", "grabber_highlight", "grabber_disabled"]:
		theme.set_icon(icon, "HSlider", grabber)

	# Barra de rolagem fina.
	var scroll := StyleBoxFlat.new()
	scroll.bg_color = Color(INK, 0.25)
	scroll.content_margin_left = 2
	scroll.content_margin_right = 2
	theme.set_stylebox("scroll", "VScrollBar", scroll)
	var scroll_grabber := StyleBoxFlat.new()
	scroll_grabber.bg_color = INK_SOFT
	scroll_grabber.content_margin_left = 2
	scroll_grabber.content_margin_right = 2
	for style in ["grabber", "grabber_highlight", "grabber_pressed"]:
		theme.set_stylebox(style, "VScrollBar", scroll_grabber)
	return theme


## Tema do HUD: letras claras com contorno de 1 pixel, para ler sobre o jogo escuro.
func _hud_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = load("res://assets/ui/ui_font.tres")
	theme.default_font_size = FONT_SMALL
	theme.set_color("font_color", "Label", HUD_TEXT)
	theme.set_color("font_outline_color", "Label", Color.BLACK)
	theme.set_constant("outline_size", "Label", 2)
	theme.set_color("default_color", "RichTextLabel", HUD_TEXT)
	theme.set_color("font_outline_color", "RichTextLabel", Color.BLACK)
	theme.set_constant("outline_size", "RichTextLabel", 2)
	theme.set_font_size("normal_font_size", "RichTextLabel", FONT_SMALL)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.03, 0.02, 0.02, 0.85)
	background.border_color = Color(0.0, 0.0, 0.0)
	background.set_border_width_all(1)
	theme.set_stylebox("background", "ProgressBar", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.55, 0.62, 0.6)
	theme.set_stylebox("fill", "ProgressBar", fill)
	return theme
