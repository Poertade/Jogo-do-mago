class_name Merchant
extends Interactable
## O Almoxarife da escola: vende potes de Vis vazios por prata achada na Dungeon.
## O preço fica em data/economy/rules.tres (jar_price).

## O vulto atrás do balcão (balança devagar, como quem respira).
@export var figure: Node3D

var _time := 0.0


func is_available() -> bool:
	return not Game.belt_full() and Game.stash.can_afford(Content.db.economy.jar_price)


func current_prompt() -> String:
	var price := Content.db.economy.jar_price
	if Game.belt_full():
		return Text.tr_key("PROMPT_MERCHANT_FULL")
	if is_available():
		return Text.tr_key("PROMPT_MERCHANT_BUY") % Game.items_text(price)
	return Text.tr_key("PROMPT_MERCHANT_POOR") % [Game.items_text(price), Game.items_text(_owned(price))]


func interact(_player: Node3D) -> void:
	if Game.buy_jar():
		Audio.play(&"coin")


## Quanto o jogador tem dos materiais do preço (para mostrar ao lado do preço).
func _owned(cost: Dictionary) -> Dictionary:
	var result := {}
	for item_id in cost:
		result[item_id] = Game.stash.count(item_id)
	return result


func _process(delta: float) -> void:
	if figure == null:
		return
	_time += delta
	figure.scale.y = 1.0 + 0.012 * sin(_time * 1.3)
