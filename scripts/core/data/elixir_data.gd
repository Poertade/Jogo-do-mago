class_name ElixirData
extends Resource
## Um elixir preparado no cadinho e levado para a Dungeon (F bebe). Cada elixir é um arquivo em
## data/alchemy/elixirs/.

@export var id: StringName
## Nome (em locales/content.csv).
@export var name_key: String
## Vida que o elixir devolve.
@export var heal: float = 0.0
## Cor do frasco no HUD.
@export var color: Color = Color.WHITE
