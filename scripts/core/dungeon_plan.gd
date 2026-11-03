class_name DungeonPlan
extends RefCounted
## O roteiro de uma incursão: a lista de salas, sorteada a partir da semente.
## A mesma semente e o mesmo conteúdo dão sempre o mesmo roteiro (bom para testar e para
## reproduzir um erro: rode o jogo com --seed=N).

var seed_value: int
var rooms: Array[StringName] = []


## Sorteia uma sala para cada tipo de `layout`.
## `rooms_by_kind`: tipo → lista de identificadores de sala daquele tipo.
## Evita repetir sala na mesma incursão; se o tipo não tiver salas suficientes, repete, mas
## nunca a mesma sala duas vezes seguidas (quando há outra opção).
static func generate(layout: Array[StringName], rooms_by_kind: Dictionary, new_seed: int) -> DungeonPlan:
	var plan := DungeonPlan.new()
	plan.seed_value = new_seed
	var rng := GameRng.new(new_seed)
	for kind in layout:
		var pool: Array[StringName] = []
		pool.assign(rooms_by_kind.get(kind, []))
		# Ordem fixa: o sorteio não pode depender da ordem em que os arquivos foram lidos.
		pool.sort()
		if pool.is_empty():
			continue
		var candidates := pool.filter(func(id): return not id in plan.rooms)
		if candidates.is_empty():
			candidates = pool.filter(func(id): return plan.rooms.is_empty() or id != plan.rooms.back())
		if candidates.is_empty():
			candidates = pool
		plan.rooms.append(candidates[rng.range_int(0, candidates.size() - 1)])
	return plan


## Semente própria de cada sala (para sortear os inimigos dela), derivada da semente da incursão.
func room_seed(index: int) -> int:
	return hash([seed_value, index])


func size() -> int:
	return rooms.size()
