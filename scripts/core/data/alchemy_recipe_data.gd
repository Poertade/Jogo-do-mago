class_name AlchemyRecipeData
extends Resource
## Uma receita alquímica do cadinho: gasta essência de aspectos e dá um elixir ou enche um pote
## vazio do cinto com Vis destilado. Para prepará-la, o jogador precisa ter descoberto todos os
## aspectos que ela pede. Cada receita é um arquivo em data/alchemy/recipes/.

@export var id: StringName
## Nome e descrição (em locales/content.csv; a descrição pode citar aspectos como {life}).
@export var name_key: String
@export var description_key: String
## Ordem na tela do cadinho.
@export var order: int = 0
## Essência gasta: {aspecto: quanto}.
@export var cost: Dictionary[StringName, int] = {}
## Resultado: um elixir...
@export var elixir: ElixirData
## ...ou Vis destilado num pote vazio do cinto (aspecto primal e quanto).
@export var jar_aspect: StringName
@export var jar_amount: int = 0
