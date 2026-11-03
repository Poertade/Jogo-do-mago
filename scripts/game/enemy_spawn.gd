class_name EnemySpawn
extends Marker3D
## Ponto onde um inimigo pode aparecer quando a sala é carregada. O tipo vem de data/enemies/.
## A seta azul (eixo -Z) indica para onde ele começa olhando.
## Para variar a sala a cada incursão: preencha `enemy_pool` (um deles é sorteado) e/ou
## baixe `chance` (a chance de aparecer alguém aqui).

## Inimigo fixo (usado quando `enemy_pool` está vazio).
@export var enemy: EnemyData
## Inimigos possíveis: um deles é sorteado com a semente da sala.
@export var enemy_pool: Array[EnemyData] = []
## Chance de aparecer um inimigo neste ponto (1 = sempre).
@export_range(0.0, 1.0) var chance := 1.0


## Sorteia o inimigo deste ponto (ou null, se não aparecer ninguém).
func pick(rng: GameRng) -> EnemyData:
	# Os dois sorteios acontecem sempre, para os pontos seguintes não mudarem de resultado.
	var roll := rng.next_float()
	var index := rng.range_int(0, maxi(enemy_pool.size() - 1, 0))
	if roll >= chance:
		return null
	if not enemy_pool.is_empty():
		return enemy_pool[index]
	if enemy == null:
		push_warning("EnemySpawn '%s' sem inimigo definido." % name)
	return enemy
