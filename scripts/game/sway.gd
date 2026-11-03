class_name Sway
extends Node3D
## Balanço suave e contínuo (carrilhão, correntes, lanternas penduradas).

## Inclinação máxima, em graus.
@export var amplitude_degrees := 4.0
## Oscilações por segundo.
@export var frequency := 0.35

var _time := 0.0
var _phase := 0.0


func _ready() -> void:
	_phase = global_position.x * 1.7 + global_position.z * 0.9


func _process(delta: float) -> void:
	_time += delta
	var t := _time * TAU * frequency + _phase
	rotation.x = deg_to_rad(amplitude_degrees) * sin(t)
	rotation.z = deg_to_rad(amplitude_degrees * 0.6) * sin(t * 1.3 + 1.1)
