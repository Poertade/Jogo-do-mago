class_name GameRng
extends RefCounted
## Gerador de números aleatórios com semente.
## A mesma semente produz sempre a mesma sequência: serve para testes e para reproduzir erros.
## Para escolher a semente ao abrir o jogo: godot --path . -- --seed=123

var seed_value: int
var _rng := RandomNumberGenerator.new()


func _init(new_seed: int) -> void:
	seed_value = new_seed
	_rng.seed = new_seed


## Número decimal entre 0 e 1.
func next_float() -> float:
	return _rng.randf()


## Número decimal entre `from` e `to`.
func range_float(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


## Número inteiro entre `from` e `to`, incluindo os dois.
func range_int(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


## Procura "--seed=N" nos argumentos da linha de comando.
## Devolve `fallback` se não houver semente ou se ela não for um número inteiro.
static func seed_from_args(args: PackedStringArray, fallback: int) -> int:
	for arg in args:
		if arg.begins_with("--seed="):
			var value := arg.trim_prefix("--seed=")
			if value.is_valid_int():
				return value.to_int()
	return fallback
