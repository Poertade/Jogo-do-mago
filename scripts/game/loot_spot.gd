class_name LootSpot
extends Marker3D
## Lugar onde a incursão pode deixar um achado: um livro perdido ou um pote selado de Vis.
## Quem decide o que aparece é o DungeonBuilder, com a semente da incursão.

## O que pode aparecer aqui: &"book" (livro perdido) ou &"jar" (pote selado).
@export var kind: StringName = &"jar"
## Chance de aparecer um pote (os livros são sorteados entre os lugares de livro da região).
@export_range(0.0, 1.0) var chance := 0.5
## Aspectos possíveis do Vis do pote e quanto ele tem.
@export var jar_aspects: Array[StringName] = [&"fire", &"water", &"order"]
@export var jar_amount_min := 5
@export var jar_amount_max := 10
