class_name DungeonZone
extends Resource
## Uma região da Dungeon (ruínas da escola, grutas, o Avesso): o nome que aparece ao entrar nela
## e a aparência dos corredores que levam até as salas dela.
## Cada região é um arquivo em data/dungeon/zones/.

@export var id: StringName
## Nome mostrado ao entrar na região (em locales/content.csv).
@export var name_key: String

@export_group("Corredores")
@export var wall_material: Material
@export var floor_material: Material
@export var ceiling_material: Material
## O que a Lente revela nas paredes e no chão dos corredores.
@export var wall_scannable: ScannableData
@export var floor_scannable: ScannableData
## Luzes ao longo dos corredores: cor, força, distância entre elas e se são tochas (com
## suporte e chama) ou brilhos soltos (fungos, olhos).
@export var light_color: Color = Color.WHITE
@export var light_energy: float = 0.0
@export var light_spacing: float = 0.0
@export var torches := false
