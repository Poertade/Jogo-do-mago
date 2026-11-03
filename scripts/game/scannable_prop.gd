class_name ScannableProp
extends StaticBody3D
## Objeto do cenário que a Lente consegue escanear. Os aspectos ficam no recurso `data`
## (data/scannables/). A colisão é o que recebe a mira: deixe-a um pouco maior que o
## objeto, para objetos pequenos (pena, vela) serem fáceis de mirar.

@export var data: ScannableData


func get_scannable() -> ScannableData:
	return data


## Procura em `node` ou nos seus pais algo escaneável (objeto ou criatura).
static func find_on(node: Node) -> ScannableData:
	while node != null:
		if node.has_method(&"get_scannable"):
			return node.get_scannable()
		node = node.get_parent()
	return null
