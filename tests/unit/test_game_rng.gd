extends GutTest
## Testes do gerador aleatório com semente.


func _sequence(rng: GameRng, count: int) -> Array[float]:
	var values: Array[float] = []
	for i in count:
		values.append(rng.next_float())
	return values


func test_same_seed_gives_same_sequence() -> void:
	assert_eq(_sequence(GameRng.new(42), 10), _sequence(GameRng.new(42), 10))


func test_different_seeds_give_different_sequences() -> void:
	assert_ne(_sequence(GameRng.new(1), 10), _sequence(GameRng.new(2), 10))


func test_range_int_stays_inside_limits() -> void:
	var rng := GameRng.new(7)
	for i in 200:
		var value := rng.range_int(3, 5)
		assert_between(value, 3, 5)


func test_seed_read_from_command_line() -> void:
	assert_eq(GameRng.seed_from_args(PackedStringArray(["--outra", "--seed=123"]), 0), 123)


func test_seed_fallback_when_missing_or_invalid() -> void:
	assert_eq(GameRng.seed_from_args(PackedStringArray([]), 99), 99)
	assert_eq(GameRng.seed_from_args(PackedStringArray(["--seed=abc"]), 99), 99)
