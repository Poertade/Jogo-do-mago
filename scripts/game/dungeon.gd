class_name Dungeon
extends NavigationRegion3D
## A Dungeon de uma incursão, montada inteira de uma vez e percorrida a pé: as salas sorteadas
## (DungeonPlan) em fila, ligadas por corredores que descem em rampa (DungeonLayout), com o
## círculo de chegada no começo e a volta à escola na última sala.
## Também espalha os achados (livros e potes) e gera a malha de navegação, por onde os
## inimigos andam contornando obstáculos.

const CORRIDOR_WIDTH := 2.4
const CORRIDOR_HEIGHT := 2.8
const WALL := 0.4
const BOOK_SCENE := "res://scenes/props/lost_book.tscn"
const JAR_SCENE := "res://scenes/props/sealed_jar.tscn"

var plan: DungeonPlan
var layout: DungeonLayout
## As salas, na ordem do roteiro.
var rooms: Array[Room] = []
## Onde o jogador aparece ao chegar.
var arrival: Marker3D


## Monta tudo. Chame depois de pôr o nó na árvore (`add_child`): as salas precisam estar na
## árvore para a malha de navegação ser gerada.
func build(new_plan: DungeonPlan) -> void:
	plan = new_plan
	var db := Content.db
	var data: Array = []
	for id in plan.rooms:
		data.append(db.rooms[id])
	layout = DungeonLayout.build(plan, data)
	for i in plan.size():
		var room_data: RoomData = data[i]
		var zone: DungeonZone = db.zones.get(room_data.zone)
		var room: Room = (load(room_data.scene_path) as PackedScene).instantiate()
		room.rng = GameRng.new(plan.room_seed(i))
		room.position = layout.room_origins[i]
		add_child(room)
		rooms.append(room)
		_build_corridor(layout.corridors[i], zone, "Corridor%d" % i, i == 0)
		_set_up_exit(room, i == plan.size() - 1)
	_place_loot()
	_bake_navigation()


## Índice da sala (com o corredor que leva a ela) em que o ponto está, ou -1.
func room_index_at(point: Vector3) -> int:
	return layout.room_at(point - global_position)


# --- Corredores ---------------------------------------------------------------------

## Corredor reto de `corridor.from` a `corridor.to`, descendo em rampa se precisar. O primeiro
## começa num beco com o círculo de chegada do portal.
func _build_corridor(corridor: DungeonLayout.Corridor, zone: DungeonZone, label: String, first: bool) -> void:
	var node := Node3D.new()
	node.name = label
	add_child(node)
	var length := corridor.length()
	var drop := corridor.drop()
	var middle := (corridor.from + corridor.to) / 2.0
	var slope := atan2(drop, length)
	var ramp := sqrt(length * length + drop * drop)
	var half_width := CORRIDOR_WIDTH / 2.0
	# Chão e teto acompanham a rampa (giram no eixo X); paredes cobrem a altura toda.
	# O chão fica 2 cm abaixo do das salas: onde os dois se encontram, não piscam um sobre o outro.
	_block(node, Vector3(CORRIDOR_WIDTH + 2 * WALL, 0.2, ramp), middle + Vector3(0, -0.12, 0),
		Vector3(-slope, 0, 0), zone.floor_material, zone.floor_scannable)
	_block(node, Vector3(CORRIDOR_WIDTH + 2 * WALL, 0.2, ramp), middle + Vector3(0, CORRIDOR_HEIGHT + 0.1, 0),
		Vector3(-slope, 0, 0), zone.ceiling_material, null)
	var wall_height := CORRIDOR_HEIGHT + drop + 0.4
	for side in [-1.0, 1.0]:
		_block(node, Vector3(WALL, wall_height, length), Vector3(side * (half_width + WALL / 2.0), middle.y + CORRIDOR_HEIGHT / 2.0, middle.z),
			Vector3.ZERO, zone.wall_material, zone.wall_scannable)
	_corridor_lights(node, corridor, zone)
	if first:
		_build_arrival(node, corridor.from, zone)


## Luzes ao longo do corredor: tochas nas paredes ou brilhos soltos, conforme a região.
func _corridor_lights(node: Node3D, corridor: DungeonLayout.Corridor, zone: DungeonZone) -> void:
	if zone.light_spacing <= 0.0:
		return
	var count := maxi(1, floori(corridor.length() / zone.light_spacing))
	for i in count:
		var t := (i + 0.5) / count
		var point := corridor.from.lerp(corridor.to, t)
		var side := -1.0 if i % 2 == 0 else 1.0
		var at := point + Vector3(side * (CORRIDOR_WIDTH / 2.0 - 0.1), 1.9, 0)
		var light := OmniLight3D.new()
		light.light_color = zone.light_color
		light.light_energy = zone.light_energy
		light.omni_range = 5.5
		light.omni_attenuation = 1.2
		light.position = at - Vector3(side * 0.35, -0.3, 0)
		node.add_child(light)
		var glow := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, 0.14, 0.08) if zone.torches else Vector3(0.18, 0.18, 0.18)
		glow.mesh = mesh
		glow.material_override = _glow_material(Color(1.0, 0.69, 0.44) if zone.torches else zone.light_color)
		glow.position = at + Vector3(0, 0.27 if zone.torches else 0.0, 0)
		glow.rotation.y = PI / 4.0
		node.add_child(glow)
		if zone.torches:
			var holder := MeshInstance3D.new()
			var holder_mesh := BoxMesh.new()
			holder_mesh.size = Vector3(0.12, 0.4, 0.12)
			holder.mesh = holder_mesh
			holder.material_override = load("res://assets/materials/dark_wood.tres")
			holder.position = at
			node.add_child(holder)


## O começo do caminho: um beco fechado atrás, com o círculo de chegada do portal.
func _build_arrival(node: Node3D, start: Vector3, zone: DungeonZone) -> void:
	_block(node, Vector3(CORRIDOR_WIDTH + 2 * WALL, CORRIDOR_HEIGHT + 0.4, WALL), start + Vector3(0, CORRIDOR_HEIGHT / 2.0, WALL / 2.0),
		Vector3.ZERO, zone.wall_material, zone.wall_scannable)
	var glyph := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.6, 0.02, 1.6)
	glyph.mesh = mesh
	var material := _glow_material(Color(0.54, 0.38, 1.0), 0.7)
	material.set_shader_parameter(&"albedo_color", Color(0.04, 0.02, 0.08))
	glyph.material_override = material
	glyph.position = start + Vector3(0, 0.01, -1.4)
	glyph.rotation.y = PI / 4.0
	node.add_child(glyph)
	var light := OmniLight3D.new()
	light.light_color = Color(0.54, 0.44, 1.0)
	light.light_energy = 0.6
	light.omni_range = 3.5
	light.position = start + Vector3(0, 0.8, -1.4)
	node.add_child(light)
	arrival = Marker3D.new()
	arrival.position = start + Vector3(0, 0, -1.4)
	node.add_child(arrival)


func _block(parent: Node3D, block_size: Vector3, at: Vector3, rotation_radians: Vector3, material: Material, data: ScannableData) -> void:
	var block := GreyboxBlock.new()
	block.size = block_size
	block.material = material
	block.scannable = data
	block.position = at
	block.rotation = rotation_radians
	parent.add_child(block)


func _glow_material(color: Color, energy := 2.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/render/ps1.gdshader")
	material.set_shader_parameter(&"albedo_color", Color.BLACK)
	material.set_shader_parameter(&"emission_color", color)
	material.set_shader_parameter(&"emission_energy", energy)
	return material


# --- Saídas e achados ---------------------------------------------------------------

## Nas salas do meio, a saída é só uma grade que abre quando a sala é limpa (e a passagem de
## volta à escola sai). Na última, ela leva de volta à escola.
func _set_up_exit(room: Room, last: bool) -> void:
	for node in room.find_children("*", "ExitPoint", true, false):
		var exit := node as ExitPoint
		if last:
			exit.prompt_key = "PROMPT_EXIT_FINAL"
			continue
		exit.prompt_key = ""
		var passage := exit.get_node_or_null("ExitPassage")
		if passage != null:
			passage.free()


## Um livro ainda não lido por região (num dos lugares de livro das salas dela) e potes
## selados nos lugares de pote, com a chance de cada um.
func _place_loot() -> void:
	var rng := GameRng.new(hash([plan.seed_value, "achados"]))
	var book_spots: Dictionary = {}
	for i in rooms.size():
		var zone: StringName = Content.db.rooms[plan.rooms[i]].zone
		for node in rooms[i].find_children("*", "LootSpot", true, false):
			var spot := node as LootSpot
			if spot.kind == &"book":
				if not zone in book_spots:
					book_spots[zone] = []
				book_spots[zone].append(spot)
			elif rng.next_float() < spot.chance:
				var jar: Node3D = (load(JAR_SCENE) as PackedScene).instantiate()
				jar.set(&"aspect", spot.jar_aspects[rng.range_int(0, spot.jar_aspects.size() - 1)])
				jar.set(&"amount", rng.range_int(spot.jar_amount_min, spot.jar_amount_max))
				spot.add_child(jar)
	for zone: StringName in book_spots:
		var book := _unread_book(zone)
		if book == null:
			continue
		var spots: Array = book_spots[zone]
		var spot: LootSpot = spots[rng.range_int(0, spots.size() - 1)]
		var pickup: Node3D = (load(BOOK_SCENE) as PackedScene).instantiate()
		pickup.set(&"book", book)
		spot.add_child(pickup)


## Um livro da região que o jogador ainda não leu nem carrega (o de menor identificador).
func _unread_book(zone: StringName) -> BookData:
	var candidates: Array[BookData] = []
	for book: BookData in Content.db.books.values():
		if book.zone == zone and not Game.knowledge.has_read(book.id) and not book in Game.run.carried_books:
			candidates.append(book)
	candidates.sort_custom(func(a, b): return a.id < b.id)
	return candidates[0] if not candidates.is_empty() else null


# --- Navegação ----------------------------------------------------------------------

## Gera a malha de navegação a partir das colisões fixas (paredes, chão, móveis), na hora,
## para os inimigos acharem caminho em volta dos obstáculos.
func _bake_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.75
	mesh.agent_max_climb = 0.5
	mesh.agent_max_slope = 40.0
	navigation_mesh = mesh
	# As grades das saídas abrem quando a sala é limpa: a malha passa por elas (os inimigos de
	# trás esperam na grade até ela abrir).
	var bars: Array[CollisionObject3D] = []
	for exit in find_children("*", "ExitPoint", true, false):
		var barrier := exit.get_node_or_null("Bars")
		if barrier != null:
			for block in barrier.find_children("*", "CollisionObject3D", true, false):
				bars.append(block)
				block.collision_layer = 0
	bake_navigation_mesh(false)
	for block in bars:
		block.collision_layer = 1
