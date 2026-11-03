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


## Pequena variação aleatória de brilho, pixel a pixel.
func _noise(color: Color, rng: RandomNumberGenerator, amount: float) -> Color:
	var delta := rng.randf_range(-amount, amount)
	return Color(clampf(color.r + delta, 0, 1), clampf(color.g + delta, 0, 1), clampf(color.b + delta, 0, 1))
