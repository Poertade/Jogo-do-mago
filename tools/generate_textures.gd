extends SceneTree
## Gera as texturas provisórias do greybox (pequenas, 32x32, como no PS1) em assets/textures/.
## Rodar uma vez, pelo terminal, a partir da pasta do projeto:
##   godot --headless --path . -s tools/generate_textures.gd
## A semente é fixa: rodar de novo produz exatamente as mesmas imagens.
## Para trocar uma textura por arte própria, basta substituir o PNG mantendo o nome.

const SIZE := 32
const OUTPUT_DIR := "res://assets/textures"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	_save(_stone_floor(), "stone_floor.png")
	_save(_stone_wall(), "stone_wall.png")
	_save(_wood(), "wood.png")
	_save(_wood_floor(), "wood_floor.png")
	_save(_rug(), "rug.png")
	_save(_portal_swirl(), "portal_swirl.png")
	_save(_bone(), "bone.png")
	_save(_robe(), "robe.png")
	_save(_cloth(909, Color(0.3, 0.34, 0.4), Color(0.72, 0.7, 0.62)), "uniform.png")
	_save(_skull_face(), "skull_face.png")
	_save(_iron(), "iron.png")
	_save(_ink(), "ink.png")
	_save(_rock(), "rock.png")
	_save(_flesh(), "flesh.png")
	quit()


func _save(image: Image, file_name: String) -> void:
	var path := OUTPUT_DIR.path_join(file_name)
	image.save_png(path)
	print("Gerada: ", path)


## Lajes de pedra fria: 2x2 lajes por textura, com rejunte escuro.
func _stone_floor() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var base := Color(0.33, 0.34, 0.37)
	var slab_tints := [rng.randf_range(-0.04, 0.04), rng.randf_range(-0.04, 0.04),
		rng.randf_range(-0.04, 0.04), rng.randf_range(-0.04, 0.04)]
	for y in SIZE:
		for x in SIZE:
			var slab := int(x >= 16) + 2 * int(y >= 16)
			var color := base.lightened(slab_tints[slab]) if slab_tints[slab] > 0 else base.darkened(-slab_tints[slab])
			color = _noise(color, rng, 0.06)
			if x % 16 == 0 or y % 16 == 0:
				color = color.darkened(0.55)
			elif x % 16 == 1 or y % 16 == 1:
				color = color.lightened(0.08)
			image.set_pixel(x, y, color)
	return image


## Tijolos de pedra: fileiras de 8 pixels, tijolos de 16, desencontrados.
func _stone_wall() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 202
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var base := Color(0.36, 0.34, 0.33)
	for y in SIZE:
		var row := y / 8
		var offset := 8 if row % 2 == 1 else 0
		for x in SIZE:
			var brick_x := (x + offset) % 16
			var brick_id := row * 4 + (x + offset) / 16
			var tint := 0.9 + 0.2 * fmod(brick_id * 0.6180339, 1.0)
			var color := Color(base.r * tint, base.g * tint, base.b * tint)
			color = _noise(color, rng, 0.05)
			if y % 8 == 0 or brick_x == 0:
				color = color.darkened(0.6)
			image.set_pixel(x, y, color)
	return image


## Tábuas de madeira escura na vertical, com veios.
func _wood() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 303
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var base := Color(0.30, 0.22, 0.15)
	for x in SIZE:
		var plank := x / 8
		var tint := 0.85 + 0.1 * (plank % 3)
		for y in SIZE:
			var grain := 0.06 * sin((y + plank * 5) * 0.9 + x * 0.3)
			var color := Color(base.r * tint, base.g * tint, base.b * tint).lightened(maxf(grain, 0.0))
			color = _noise(color, rng, 0.04)
			if x % 8 == 0:
				color = color.darkened(0.6)
			image.set_pixel(x, y, color)
	return image


## Piso de tábuas na horizontal, com emendas desencontradas.
func _wood_floor() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var base := Color(0.34, 0.25, 0.17)
	for y in SIZE:
		var board := y / 8
		var seam := (board * 13) % SIZE
		var tint := 0.85 + 0.08 * (board % 3)
		for x in SIZE:
			var grain := 0.05 * sin(x * 0.7 + board * 3.0 + y * 0.2)
			var color := Color(base.r * tint, base.g * tint, base.b * tint).lightened(maxf(grain, 0.0))
			color = _noise(color, rng, 0.035)
			if y % 8 == 0 or x == seam:
				color = color.darkened(0.6)
			image.set_pixel(x, y, color)
	return image


## Tapete gasto: borda escura e losangos vermelho-escuros.
func _rug() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 505
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var field := Color(0.36, 0.12, 0.10)
	var pattern := Color(0.55, 0.38, 0.18)
	for y in SIZE:
		for x in SIZE:
			var color := field
			var diamond := absi(x % 16 - 8) + absi(y % 16 - 8)
			if diamond == 6 or diamond == 2:
				color = pattern
			color = _noise(color, rng, 0.05)
			image.set_pixel(x, y, color)
	return image


## Redemoinho do portal: faixas onduladas violeta e verde-água (a textura desliza no shader).
func _portal_swirl() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 606
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var violet := Color(0.45, 0.25, 0.85)
	var teal := Color(0.25, 0.75, 0.75)
	for y in SIZE:
		for x in SIZE:
			# Ondas que fecham a cada 32 pixels: a textura repete sem emenda.
			var wave := sin((x + 4.0 * sin(y * TAU / SIZE * 2.0)) * TAU / SIZE * 3.0)
			var color := violet.lerp(teal, wave * 0.5 + 0.5)
			color = color.darkened(rng.randf_range(0.0, 0.25))
			image.set_pixel(x, y, color)
	return image


## Osso: marfim encardido com veios, rachaduras e pontas mais escuras (as juntas).
func _bone() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var base := Color(0.76, 0.72, 0.6)
	for y in SIZE:
		for x in SIZE:
			var streak := 0.05 * sin(x * 1.3 + sin(y * 0.4) * 2.0)
			var color := base.darkened(0.08 - streak)
			if y < 3 or y > SIZE - 4:
				color = color.darkened(0.3)
			image.set_pixel(x, y, _noise(color, rng, 0.04))
	# Rachaduras: linhas tortas e escuras.
	for crack in 4:
		var x := rng.randi_range(2, SIZE - 3)
		var y := rng.randi_range(0, SIZE - 12)
		for step in rng.randi_range(6, 12):
			image.set_pixel(x, y, Color(0.3, 0.26, 0.2))
			y += 1
			x = clampi(x + rng.randi_range(-1, 1), 0, SIZE - 1)
			if y >= SIZE:
				break
	return image


## Manto do bedel (32x64, com transparência): pano quase preto com dobras verticais, uma faixa
## de acabamento gasta no alto, manchas e furos, e a barra rasgada em pontas irregulares.
func _robe() -> Image:
	return _cloth(808, Color(0.12, 0.13, 0.12), Color(0.32, 0.12, 0.16))


## Pano rasgado (com transparência na barra e furos): `base` é o tecido, `trim` a faixa de cima.
## O manto do Bedel usa preto e vinho; o uniforme dos aprendizes, cinza-azulado e gola clara.
func _cloth(seed_value: int, base: Color, trim: Color) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var height := SIZE * 2
	var image := Image.create_empty(SIZE, height, false, Image.FORMAT_RGBA8)
	# Altura da barra rasgada em cada coluna: pontas compridas e curtas alternadas.
	var hem: Array[int] = []
	for x in SIZE:
		hem.append(height - rng.randi_range(2, 14) if x % 3 != 0 else height - rng.randi_range(0, 4))
	for y in height:
		for x in SIZE:
			var fold := 0.06 * sin(x * 0.8 + sin(y * 0.15) * 1.5)
			var color := base.lightened(maxf(fold, 0.0)).darkened(maxf(-fold, 0.0))
			if y >= 4 and y < 7:
				color = trim.darkened(rng.randf_range(0.0, 0.3))
			if rng.randf() < 0.02:
				color = color.darkened(0.4)
			color = _noise(color, rng, 0.03)
			var alpha := 1.0
			if y >= hem[x]:
				alpha = 0.0
			# Alguns furos no meio do pano.
			for hole in [Vector2(9, 40), Vector2(24, 30), Vector2(17, 50)]:
				if Vector2(x, y).distance_to(hole) < 1.6:
					alpha = 0.0
			image.set_pixel(x, y, Color(color, alpha))
	return image


## Rosto de caveira (com transparência): crânio alongado, órbitas fundas e inclinadas sob a
## sobrancelha, maçãs do rosto afundadas, cavidade do nariz e dentes tortos, com falhas.
## Vai num quadrado na frente da cabeça; os olhos que brilham ficam dentro das órbitas.
func _skull_face() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var bone := Color(0.74, 0.7, 0.58)
	var missing_teeth := [12, 19]
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			# Contorno: crânio oval em cima, maxilar estreito embaixo.
			var inside := false
			if y < 19:
				inside = Vector2((p.x - 16) / 12.5, (p.y - 12) / 12.0).length() < 1.0
			else:
				inside = absf(p.x - 16) < 9.5 - (y - 19) * 0.5
			if not inside:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var color := bone.darkened(clampf((p - Vector2(16, 10)).length() / 34.0, 0.0, 0.4))
			# Órbitas: ovais inclinadas (canto de dentro mais alto), com sombra em volta.
			for side in [-1.0, 1.0]:
				var center := Vector2(16 + side * 5.5, 14.5)
				var local := p - center
				local.y += local.x * side * 0.35
				var d := Vector2(local.x / 3.4, local.y / 2.6).length()
				if d < 1.0:
					color = Color(0.02, 0.02, 0.02)
				elif d < 1.6:
					color = color.darkened(0.5 * (1.6 - d) / 0.6 + 0.15)
			# Sobrancelha (borda superior das órbitas) e maçãs do rosto afundadas.
			if y >= 10 and y <= 11 and absf(p.x - 16) > 2 and absf(p.x - 16) < 10:
				color = color.lightened(0.1)
			if y >= 18 and y <= 22 and absf(p.x - 16) > 6:
				color = color.darkened(0.35)
			# Nariz: dois buracos que se encontram.
			if y >= 18 and y <= 22 and absf(p.x - 16) < (22.5 - y) * 0.5 + 0.4:
				color = Color(0.04, 0.03, 0.03)
			# Dentes: blocos claros desiguais; dois faltando.
			if y >= 24 and y <= 27:
				var tooth := x / 2
				if x % 2 == 0 or tooth in missing_teeth:
					color = Color(0.08, 0.06, 0.05)
				else:
					color = Color(0.82, 0.78, 0.62).darkened(0.1 * (tooth % 3))
					if y == 27 and tooth % 2 == 0:
						color = Color(0.08, 0.06, 0.05)
			if y >= 28:
				color = color.darkened(0.3)
			image.set_pixel(x, y, Color(_noise(color, rng, 0.04), 1.0))
	return image


## Ferro escuro com pontos de ferrugem (chaves, ponteira do bastão).
func _iron() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1010
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var color := Color(0.28, 0.28, 0.3)
			if rng.randf() < 0.12:
				color = Color(0.36, 0.2, 0.1)
			image.set_pixel(x, y, _noise(color, rng, 0.05))
	return image


## Pequena variação aleatória de brilho, pixel a pixel.
## Rocha das grutas: manchas irregulares, rachaduras escuras e veios claros, sem padrão de
## tijolo (pedra natural).
func _rock() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1313
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var base := Color(0.34, 0.31, 0.28)
	for y in SIZE:
		for x in SIZE:
			# Ondas com período que cabe na textura, para repetir sem emenda.
			var blob := sin(TAU * x / SIZE * 2.0 + sin(TAU * y / SIZE) * 1.5) * cos(TAU * y / SIZE * 3.0)
			var color := base.lightened(maxf(blob, 0.0) * 0.12).darkened(maxf(-blob, 0.0) * 0.18)
			image.set_pixel(x, y, _noise(color, rng, 0.06))
	for crack in 5:
		var px := rng.randi_range(0, SIZE - 1)
		var py := rng.randi_range(0, SIZE - 1)
		for step in rng.randi_range(5, 12):
			image.set_pixel(px % SIZE, py % SIZE, base.darkened(0.6))
			px += rng.randi_range(0, 1)
			py += rng.randi_range(-1, 1) + 1
	return image


## Carne de pedra (o Avesso): roxo escuro com veias claras que pulsam na luz.
func _flesh() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1414
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var base := Color(0.3, 0.16, 0.26)
	for y in SIZE:
		for x in SIZE:
			var vein := absf(sin(TAU * (x + sin(TAU * y / SIZE) * 4.0) / SIZE * 3.0))
			var color := base.darkened(0.15 * vein)
			if vein < 0.12:
				color = Color(0.62, 0.36, 0.5)
			image.set_pixel(x, y, _noise(color, rng, 0.04))
	return image


## Tinta viva (Lodo de Tinta): preto-azulado com veios brilhantes e restos de letras claras.
func _ink() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1212
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var base := Color(0.05, 0.06, 0.1)
	for y in SIZE:
		for x in SIZE:
			var vein := sin(x * 0.45 + sin(y * 0.3) * 2.0) * sin(y * 0.2 + x * 0.1)
			var color := base.lightened(maxf(vein, 0.0) * 0.18)
			image.set_pixel(x, y, _noise(color, rng, 0.02))
	# Letras soltas, como se a tinta ainda guardasse o texto que borrou.
	var ink_letter := Color(0.55, 0.52, 0.4)
	for letter in 7:
		var lx := rng.randi_range(1, SIZE - 5)
		var ly := rng.randi_range(1, SIZE - 5)
		for i in 5:
			var px := lx + rng.randi_range(0, 3)
			var py := ly + rng.randi_range(0, 3)
			image.set_pixel(px, py, ink_letter.darkened(rng.randf_range(0.0, 0.4)))
	return image


func _noise(color: Color, rng: RandomNumberGenerator, amount: float) -> Color:
	var delta := rng.randf_range(-amount, amount)
	return Color(clampf(color.r + delta, 0, 1), clampf(color.g + delta, 0, 1), clampf(color.b + delta, 0, 1))
