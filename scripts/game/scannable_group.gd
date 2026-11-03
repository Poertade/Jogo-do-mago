class_name ScannableGroup
extends Node3D
## Objeto feito de várias peças com colisão (por exemplo, uma estante montada com blocos):
## escanear qualquer peça revela os dados deste nó.

@export var data: ScannableData


func get_scannable() -> ScannableData:
	return data
