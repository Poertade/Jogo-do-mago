class_name ItemData
extends Resource
## Um material que o jogador junta na Dungeon e gasta na escola (prata, cacos de vidro, osso…).
## Cada material é um arquivo em data/items/.

@export var id: StringName
## Nome mostrado (em locales/content.csv).
@export var name_key: String
## Cor do ícone no HUD.
@export var color: Color = Color.WHITE
## Aspectos em que o material se desfaz no cadinho (vazio: não se dissolve).
@export var aspects: Dictionary[StringName, int] = {}
## Cena do achado na Dungeon (o que aparece num LootSpot com `kind` igual ao id do material).
@export_file("*.tscn") var pickup_scene: String
