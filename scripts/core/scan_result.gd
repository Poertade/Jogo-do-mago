class_name ScanResult
extends RefCounted
## O que um escaneamento completo revelou (ou por que falhou).

var target: ScannableData
## O escaneamento falhou: o alvo tem aspectos compostos que ainda não foram descobertos
## na Mesa de Pesquisa (estão em `missing`).
var blocked := false
var missing: Array[StringName] = []
## Primeira vez que este alvo foi escaneado.
var new_target := false
## Aspectos primais descobertos agora.
var new_aspects: Array[StringName] = []
## Pontos de pesquisa ganhos, por aspecto.
var points: Dictionary[StringName, int] = {}


func discovered_something() -> bool:
	return new_target or not new_aspects.is_empty()


func total_points() -> int:
	var total := 0
	for aspect_id in points:
		total += points[aspect_id]
	return total
