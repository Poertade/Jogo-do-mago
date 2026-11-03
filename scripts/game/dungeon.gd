class_name Dungeon
extends NavigationRegion3D
## Raiz do mapa fixo da Dungeon (scenes/dungeon/dungeon.tscn), feito à mão no estilo dos mapas
## do Lunacid: as mesmas salas a cada incursão, ligadas por corredores (CorridorPath), com um
## átrio central, caminhos que voltam a lugares já vistos, atalhos de um lado só e portas
## trancadas (Gate), paredes falsas (SecretWall), chaves (KeyPickup), âncoras do portal
## (PortalAnchor) e desníveis (o poço, a ponte sobre a fenda).
##
## A cada incursão mudam só os inimigos (EnemySpawn, com a semente) e os achados (LootSpot):
## livros, potes selados, prata e cacos de vidro. O que o jogador abriu, pegou ou sintonizou fica
## para sempre (DungeonProgress, no save).
## Também gera a malha de navegação, por onde os inimigos andam contornando obstáculos.

const BOOK_SCENE := "res://scenes/props/lost_book.tscn"
const JAR_SCENE := "res://scenes/props/sealed_jar.tscn"
const ITEM_SCENES := {
	&"silver": "res://scenes/props/silver_pouch.tscn",
	&"glass": "res://scenes/props/glass_shards.tscn",
}

## As salas do mapa e a caixa (no espaço do mundo) que cada uma ocupa.
var rooms: Array[Room] = []
var _boxes: Array[AABB] = []


## Sorteia o que muda nesta incursão. Chame antes de pôr o mapa na árvore (`add_child`): as
## salas criam os inimigos ao entrar nela, com o gerador definido aqui.
func prepare(incursion_seed: int) -> void:
	for node in find_children("*", "Room", true, false):
		var room := node as Room
		room.rng = GameRng.new(hash([incursion_seed, String(room.name)]))
	_place_loot(GameRng.new(hash([incursion_seed, "achados"])))


func _ready() -> void:
	for node in find_children("*", "Room", true, false):
		var room := node as Room
		var data: RoomData = Content.db.rooms.get(room.room_id)
		if data == null:
			push_error("Sala '%s' do mapa sem room_id válido ('%s')." % [room.name, room.room_id])
			continue
		rooms.append(room)
		# Salas giradas 90° trocam largura e profundidade.
		var turned := absf(room.global_basis.z.x) > 0.5
		var footprint := Vector3(data.depth if turned else data.width, data.height, data.width if turned else data.depth)
		_boxes.append(AABB(room.global_position - Vector3(footprint.x / 2.0, 0.5, footprint.z / 2.0),
			footprint + Vector3(0.0, 1.0, 0.0)))


## Índice da sala em que o ponto está, ou -1 (nos corredores).
func room_index_at(point: Vector3) -> int:
	for i in _boxes.size():
		if _boxes[i].has_point(point):
			return i
	return -1


## A âncora do portal com esse identificador (null se não existir).
func anchor(anchor_id: StringName) -> PortalAnchor:
	for node in find_children("*", "PortalAnchor", true, false):
		if (node as PortalAnchor).anchor_id == anchor_id:
			return node
	return null


## Gera a malha de navegação a partir das colisões fixas (paredes, chão, móveis), para os
## inimigos acharem caminho em volta dos obstáculos. Chame depois de pôr o mapa na árvore.
func bake_navigation() -> void:
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
	bake_navigation_mesh(false)


# --- Achados ------------------------------------------------------------------------

## Um livro por região (num dos lugares de livro dela), enquanto houver receitas que o jogador
## ainda não conhece; nos outros lugares, potes selados, prata e cacos, com a chance de cada um.
func _place_loot(rng: GameRng) -> void:
	var book_spots: Dictionary = {}
	for node in find_children("*", "LootSpot", true, false):
		var spot := node as LootSpot
		if spot.kind == &"book":
			var zone := _zone_of(spot)
			if not zone in book_spots:
				book_spots[zone] = []
			book_spots[zone].append(spot)
			continue
		# Os sorteios acontecem sempre, para um lugar não mudar o resultado dos seguintes.
		var roll := rng.next_float()
		var amount := rng.range_int(spot.amount_min, spot.amount_max)
		var pick := rng.range_int(0, maxi(spot.jar_aspects.size() - 1, 0))
		if roll >= spot.chance or amount <= 0:
			continue
		if spot.kind == &"jar" and not spot.jar_aspects.is_empty():
			var jar: Node3D = (load(JAR_SCENE) as PackedScene).instantiate()
			jar.set(&"aspect", spot.jar_aspects[pick])
			jar.set(&"amount", amount)
			spot.add_child(jar)
		elif spot.kind in ITEM_SCENES:
			var pickup: Node3D = (load(ITEM_SCENES[spot.kind]) as PackedScene).instantiate()
			pickup.set(&"item", spot.kind)
			pickup.set(&"amount", amount)
			spot.add_child(pickup)
	# Cada livro ensina uma receita: não adianta haver mais livros que receitas a aprender.
	var to_learn := Game.knowledge.unknown_recipes(Content.db.aspects).size() - Game.run.carried_books.size()
	var zones: Array = book_spots.keys()
	zones.sort_custom(ContentDB.by_name)
	for zone: StringName in zones:
		var titles := Content.db.books_in(zone)
		if to_learn <= 0 or titles.is_empty():
			continue
		to_learn -= 1
		var book := titles[rng.range_int(0, titles.size() - 1)]
		var spots: Array = book_spots[zone]
		var spot: LootSpot = spots[rng.range_int(0, spots.size() - 1)]
		var pickup: Node3D = (load(BOOK_SCENE) as PackedScene).instantiate()
		pickup.set(&"book", book)
		spot.add_child(pickup)


## Região da sala onde o nó está.
func _zone_of(node: Node) -> StringName:
	while node != null and not node is Room:
		node = node.get_parent()
	if node == null:
		return &""
	var data: RoomData = Content.db.rooms.get((node as Room).room_id)
	return data.zone if data != null else &""
