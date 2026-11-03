class_name ResearchNote
extends RefCounted
## Nota de pesquisa, no estilo do Thaumcraft 4: uma grade de hexágonos com alguns aspectos já
## escritos (os alvos). O jogador escreve aspectos nos hexágonos vazios. Dois hexágonos vizinhos
## se ligam quando um aspecto é pai do outro (ex.: Ignis e Potentia, porque Potentia = Ordo +
## Ignis). A nota está completa quando todos os alvos estão ligados entre si por correntes.
##
## Os hexágonos usam coordenadas axiais (q, r); o centro da grade é (0, 0).

## Os seis vizinhos de um hexágono.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

## Quantos anéis de hexágonos em volta do centro (raio 2 = 19 hexágonos).
var radius: int
## Aspectos que já vêm escritos na nota.
var targets: Dictionary[Vector2i, StringName] = {}
## Aspectos escritos pelo jogador.
var placed: Dictionary[Vector2i, StringName] = {}


## Monta a nota de uma página: os alvos ficam espalhados pela borda da grade.
static func for_page(page: ResearchPageData) -> ResearchNote:
	var note := ResearchNote.new()
	note.radius = maxi(page.note_radius, 1)
	var ring := note.ring(note.radius)
	var count := page.note_aspects.size()
	for i in count:
		var index := int(round(float(i) * ring.size() / count))
		note.targets[ring[index % ring.size()]] = page.note_aspects[i]
	return note


## Distância em hexágonos entre duas células.
static func distance(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


## Dois aspectos se ligam quando um é pai do outro.
static func related(a: StringName, b: StringName, aspects: Dictionary) -> bool:
	if a == &"" or b == &"" or a == b:
		return false
	var aspect_a: AspectData = aspects.get(a)
	var aspect_b: AspectData = aspects.get(b)
	return (aspect_a != null and b in aspect_a.parents) or (aspect_b != null and a in aspect_b.parents)


## Células do anel a `distance` do centro, em ordem (volta completa).
func ring(ring_radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var cell := DIRECTIONS[4] * ring_radius
	for side in 6:
		for step in ring_radius:
			result.append(cell)
			cell += DIRECTIONS[side]
	return result


## Todas as células da nota.
func cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = [Vector2i.ZERO]
	for r in range(1, radius + 1):
		result.append_array(ring(r))
	return result


func contains(cell: Vector2i) -> bool:
	return distance(cell, Vector2i.ZERO) <= radius


func is_target(cell: Vector2i) -> bool:
	return cell in targets


func aspect_at(cell: Vector2i) -> StringName:
	if cell in targets:
		return targets[cell]
	return placed.get(cell, &"")


## Dá para escrever nesta célula? (Dentro da grade, vazia e não é um alvo.)
func can_write(cell: Vector2i) -> bool:
	return contains(cell) and not is_target(cell) and not cell in placed


## Pares de células vizinhas que estão ligadas (cada par aparece uma vez).
func links(aspects: Dictionary) -> Array[Array]:
	var result: Array[Array] = []
	for cell in cells():
		var aspect := aspect_at(cell)
		if aspect == &"":
			continue
		# Só metade das direções, para cada par aparecer uma vez.
		for i in 3:
			var other: Vector2i = cell + DIRECTIONS[i]
			if contains(other) and related(aspect, aspect_at(other), aspects):
				result.append([cell, other])
	return result


## Todos os alvos estão ligados entre si?
func is_complete(aspects: Dictionary) -> bool:
	if targets.is_empty():
		return false
	var reached := connected_cells(targets.keys()[0], aspects)
	for cell in targets:
		if not cell in reached:
			return false
	return true


## Células alcançáveis a partir de `start` seguindo as ligações.
func connected_cells(start: Vector2i, aspects: Dictionary) -> Dictionary[Vector2i, bool]:
	var reached: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction in DIRECTIONS:
			var other := cell + direction
			if contains(other) and not other in reached and related(aspect_at(cell), aspect_at(other), aspects):
				reached[other] = true
				queue.append(other)
	return reached


## Procura a corrente mais curta de aspectos a escrever, partindo de `start`, até encostar numa
## das células de `goals` (com uma ligação válida). Só usa os aspectos de `allowed`.
## Devolve {célula: aspecto} com o que precisa ser escrito, ou um dicionário vazio se não houver.
## (Usado nos testes de economia; serve também para dicas no futuro.)
func find_chain(start: Vector2i, goals: Array[Vector2i], allowed: Array[StringName], aspects: Dictionary) -> Dictionary:
	var start_state := [start, aspect_at(start)]
	var previous := {start_state: null}
	var queue: Array = [start_state]
	while not queue.is_empty():
		var state: Array = queue.pop_front()
		var cell: Vector2i = state[0]
		var aspect: StringName = state[1]
		for direction in DIRECTIONS:
			var other := cell + direction
			if not contains(other):
				continue
			if other in goals and related(aspect, aspect_at(other), aspects):
				return _rebuild_chain(previous, state)
			if not can_write(other):
				continue
			for candidate in allowed:
				var next := [other, candidate]
				if related(aspect, candidate, aspects) and not next in previous:
					previous[next] = state
					queue.append(next)
	return {}


func _rebuild_chain(previous: Dictionary, last: Array) -> Dictionary:
	var chain := {}
	var state = last
	while state != null and previous[state] != null:
		chain[state[0]] = state[1]
		state = previous[state]
	return chain
