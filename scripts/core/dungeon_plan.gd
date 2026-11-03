class_name DungeonPlan
extends RefCounted
## O roteiro de uma incursão: as salas sorteadas e os corredores entre elas (comprimento e
## descida), a partir da semente. A mesma semente e o mesmo conteúdo dão sempre o mesmo
## roteiro (bom para testar e para reproduzir um erro: rode o jogo com --seed=N).

var seed_value: int
var rooms: Array[StringName] = []
## Corredor que chega a cada sala (o primeiro sai do círculo de chegada).
var corridor_lengths: Array[float] = []
var corridor_drops: Array[float] = []


## Sorteia uma sala para cada passo de `rules.steps`.
## `rooms_by_slot`: "região/tipo" → lista de identificadores de sala (veja `slot_key`).
## Evita repetir sala na mesma incursão; se a região não tiver salas suficientes daquele tipo,
## repete, mas nunca a mesma sala duas vezes seguidas (quando há outra opção).
static func generate(rules: DungeonRules, rooms_by_slot: Dictionary, new_seed: int) -> DungeonPlan:
	var plan := DungeonPlan.new()
	plan.seed_value = new_seed
	var rng := GameRng.new(new_seed)
	for step in rules.steps:
		var pool: Array[StringName] = []
		pool.assign(rooms_by_slot.get(slot_key(step.zone, step.kind), []))
		# Ordem fixa (alfabética): o sorteio não pode depender da ordem em que os arquivos foram lidos.
		pool.sort_custom(ContentDB.by_name)
		# Os números do corredor são sorteados sempre, para não mudar o resto da incursão.
		var drop := rng.range_float(step.drop_min, step.drop_max)
		# A rampa não passa de uns 25 graus: corredor pelo menos 2,2 vezes mais comprido que a descida.
		var length := maxf(rng.range_float(rules.corridor_length_min, rules.corridor_length_max), drop * 2.2)
		var pick := rng.next_float()
		if pool.is_empty():
			continue
		var candidates := pool.filter(func(id): return not id in plan.rooms)
		if candidates.is_empty():
			candidates = pool.filter(func(id): return plan.rooms.is_empty() or id != plan.rooms.back())
		if candidates.is_empty():
			candidates = pool
		plan.rooms.append(candidates[mini(int(pick * candidates.size()), candidates.size() - 1)])
		plan.corridor_lengths.append(snappedf(length, 0.5))
		plan.corridor_drops.append(snappedf(drop, 0.25))
	return plan


## Chave das salas por região e tipo (ex.: "caves/rest").
static func slot_key(zone: StringName, kind: StringName) -> String:
	return "%s/%s" % [zone, kind]


## Semente própria de cada sala (para sortear os inimigos e objetos dela).
func room_seed(index: int) -> int:
	return hash([seed_value, index])


func size() -> int:
	return rooms.size()
