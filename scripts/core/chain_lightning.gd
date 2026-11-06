class_name ChainLightning
extends RefCounted
## A corrente do Focus de Choque (como o Focus de Choque do Thaumcraft): o raio acerta o primeiro
## alvo e salta para o alvo mais próximo que ainda não foi atingido, até `jumps` saltos, sem
## passar de `jump_range` metros por salto. Cada salto causa uma fração (`falloff`) do dano do
## anterior. Só calcula; quem desenha o raio e aplica o dano é a varinha (WandView).


## Ordem dos alvos atingidos (índices em `positions`), começando por `first`.
## `positions`: onde está cada alvo possível.
static func pick_targets(first: int, positions: Array[Vector3], jumps: int, jump_range: float) -> Array[int]:
	var chain: Array[int] = [first]
	if first < 0 or first >= positions.size():
		return [] as Array[int]
	for i in jumps:
		var from := positions[chain.back()]
		var best := -1
		var best_distance := jump_range
		for candidate in positions.size():
			if candidate in chain:
				continue
			var distance := from.distance_to(positions[candidate])
			if distance <= best_distance:
				best = candidate
				best_distance = distance
		if best < 0:
			break
		chain.append(best)
	return chain


## Dano de cada alvo da corrente: o primeiro leva `damage`, e cada salto, `falloff` do anterior.
static func damages(damage: float, count: int, falloff: float) -> Array[float]:
	var result: Array[float] = []
	var current := damage
	for i in count:
		result.append(current)
		current *= falloff
	return result
