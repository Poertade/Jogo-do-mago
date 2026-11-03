class_name FlickerLight
extends OmniLight3D
## Luz de vela ou tocha que tremula em torno da intensidade definida no inspetor.

## Quanto a intensidade varia (0,25 = até 25% para cima ou para baixo).
@export_range(0.0, 1.0) var flicker_amount := 0.25
## Rapidez do tremor.
@export var flicker_speed := 7.0

var _base_energy: float
var _time := 0.0
var _phase := 0.0


func _ready() -> void:
	_base_energy = light_energy
	# Fase tirada da posição: cada luz tremula de um jeito, sempre igual entre execuções.
	_phase = global_position.x * 1.3 + global_position.z * 2.1


func _process(delta: float) -> void:
	_time += delta
	var t := _time * flicker_speed + _phase
	# Soma de ondas de frequências diferentes: parece irregular, sem precisar de aleatoriedade.
	var wave := 0.5 * sin(t) + 0.3 * sin(t * 2.3 + 1.7) + 0.2 * sin(t * 5.1 + 0.4)
	light_energy = _base_energy * (1.0 + wave * flicker_amount)
