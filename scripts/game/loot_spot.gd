class_name LootSpot
extends Marker3D
## Lugar onde a incursão pode deixar um achado. Quem decide o que aparece é a Dungeon, com a
## semente da incursão:
## - &"book": livro perdido (um por região, entre os lugares de livro dela, enquanto houver
##   receitas a aprender);
## - &"jar": pote selado com Vis;
## - &"chest": lugar de baú (um baú por incursão, num dos lugares de baú do mapa);
## - o id de um material de data/items/ (&"silver", &"glass", &"bone", &"crystal", &"brass"): o
##   achado daquele material, com a cena dele (`pickup_scene`).

## O que pode aparecer aqui (veja acima).
@export var kind: StringName = &"jar"
## Chance de aparecer algo aqui (os livros são sorteados à parte, entre os lugares de livro).
@export_range(0.0, 1.0) var chance := 0.5
## Quanto: Vis do pote selado, moedas de prata ou cacos de vidro (sorteado entre os dois).
@export var amount_min := 5
@export var amount_max := 10
## Aspectos possíveis do Vis do pote selado.
@export var jar_aspects: Array[StringName] = [&"fire", &"water", &"order"]
