extends GutTest
## Testes do andamento do escaneamento (barra que enche segurando o botão).


func test_completes_after_duration() -> void:
	var progress := ScanProgress.new(1.5)
	assert_false(progress.update(&"candle", true, 1.0))
	assert_almost_eq(progress.ratio(), 1.0 / 1.5, 0.001)
	assert_true(progress.update(&"candle", true, 0.6))


func test_completes_only_once_while_holding() -> void:
	var progress := ScanProgress.new(1.0)
	assert_true(progress.update(&"candle", true, 1.2))
	assert_false(progress.update(&"candle", true, 1.2))
	assert_eq(progress.ratio(), 1.0)


func test_releasing_resets() -> void:
	var progress := ScanProgress.new(1.0)
	progress.update(&"candle", true, 0.8)
	progress.update(&"candle", false, 0.1)
	assert_eq(progress.ratio(), 0.0)
	assert_false(progress.update(&"candle", true, 0.5))


func test_changing_target_restarts() -> void:
	var progress := ScanProgress.new(1.0)
	progress.update(&"candle", true, 0.8)
	assert_false(progress.update(&"feather", true, 0.3))
	assert_almost_eq(progress.ratio(), 0.3, 0.001)


func test_no_target_does_nothing() -> void:
	var progress := ScanProgress.new(1.0)
	assert_false(progress.update(&"", true, 5.0))
	assert_false(progress.is_active())
