extends SceneTree
## Gera os algarismos da interface (assets/ui/digits_font.tres): uma fonte de bitmap só com 0–9 (e o espaço),
## desenhados à mão em 5 x 7 pixels. Na Pixelify Sans, em tamanho pequeno, o 2 e o 5 ficavam
## parecidos com o 8; aqui cada algarismo é inconfundível. O resto do texto vem da Pixelify
## Sans (fallback), e a fonte da interface (assets/ui/ui_font.tres) usa esta como base.
## Rodar a partir da pasta do projeto:
##   godot --headless --path . -s tools/generate_digit_font.gd

const OUTPUT := "res://assets/ui/digits_font.tres"
const BASE_FONT := "res://assets/fonts/PixelifySans.ttf"
## Tamanho em que os algarismos são desenhados 1:1 (o tamanho da interface); 22 amplia 2x.
const SIZE := 11
const WIDTH := 5
const HEIGHT := 7
const ADVANCE := 6
## Folga à esquerda de cada algarismo, como a das letras da Pixelify (sem ela, o espaço antes de
## um número parece mais estreito que o espaço entre palavras).
const LEFT_BEARING := 1

const GLYPHS := {
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
}


func _initialize() -> void:
	var base: Font = load(BASE_FONT)
	var font := FontFile.new()
	font.fixed_size = SIZE
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	var cache_size := Vector2i(SIZE, 0)
	font.set_cache_ascent(0, SIZE, base.get_ascent(SIZE))
	font.set_cache_descent(0, SIZE, base.get_descent(SIZE))
	var chars: Array = GLYPHS.keys()
	var image := Image.create_empty(chars.size() * (WIDTH + 1), HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	for i in chars.size():
		var rows: Array = GLYPHS[chars[i]]
		for y in HEIGHT:
			for x in WIDTH:
				if rows[y][x] == "#":
					image.set_pixel(i * (WIDTH + 1) + x, y, Color.WHITE)
	font.set_texture_image(0, cache_size, 0, image)
	for i in chars.size():
		var glyph: int = String(chars[i]).unicode_at(0)
		font.set_glyph_advance(0, SIZE, glyph, Vector2(ADVANCE, 0))
		font.set_glyph_offset(0, cache_size, glyph, Vector2(LEFT_BEARING, -HEIGHT))
		font.set_glyph_size(0, cache_size, glyph, Vector2(WIDTH, HEIGHT))
		font.set_glyph_uv_rect(0, cache_size, glyph, Rect2(i * (WIDTH + 1), 0, WIDTH, HEIGHT))
		font.set_glyph_texture_idx(0, cache_size, glyph, 0)
	# O espaço também mora aqui: o texto é dividido por fonte, e um espaço logo antes de um
	# algarismo cai no trecho desta fonte; sem ele, "encontrou 12" ficava "encontrou12".
	var space := " ".unicode_at(0)
	font.set_glyph_advance(0, SIZE, space, Vector2(base.get_char_size(space, SIZE).x, 0))
	font.set_glyph_size(0, cache_size, space, Vector2.ZERO)
	font.set_glyph_texture_idx(0, cache_size, space, -1)
	# Tudo o que não é algarismo nem espaço vem da Pixelify Sans.
	font.fallbacks = [base]
	print("Fonte dos algarismos: ", error_string(ResourceSaver.save(font, OUTPUT)))
	quit()
