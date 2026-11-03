class_name ScanResult
extends RefCounted
## O que um escaneamento completo revelou.

var target: ScannableData
## Primeira vez que este alvo foi escaneado.
var new_target := false
## Aspectos descobertos agora.
var new_aspects: Array[StringName] = []
## Pontos de pesquisa ganhos.
var points := 0


func discovered_something() -> bool:
	return new_target or not new_aspects.is_empty()
