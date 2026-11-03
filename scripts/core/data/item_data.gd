class_name ItemData
extends Resource
## Um material que o jogador junta na Dungeon e gasta na escola (prata, cacos de vidro).
## Cada material é um arquivo em data/items/.

@export var id: StringName
## Nome mostrado (em locales/content.csv).
@export var name_key: String
## Cor do ícone no HUD.
@export var color: Color = Color.WHITE
