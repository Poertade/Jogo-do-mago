class_name GlassWorkbench
extends Interactable
## Bancada de vidraria da escola: funde cacos de vidro achados na Dungeon e sela um pote de Vis
## com o Vis da varinha (como a Bancada Arcana do Thaumcraft, que gasta Vis da varinha).
## Os custos ficam em data/economy/rules.tres (jar_materials e jar_vis).


func is_available() -> bool:
	var economy := Content.db.economy
	return not Game.belt_full() and Game.stash.can_afford(economy.jar_materials) and Game.missing_jar_vis().is_empty()


func current_prompt() -> String:
	var economy := Content.db.economy
	if Game.belt_full():
		return Text.tr_key("PROMPT_MERCHANT_FULL")
	var cost := "%s, %s" % [Game.items_text(economy.jar_materials), _vis_text(economy.jar_vis)]
	if is_available():
		return Text.tr_key("PROMPT_WORKBENCH_CRAFT") % cost
	var lacking := Game.stash.missing(economy.jar_materials)
	var parts: PackedStringArray = []
	if not lacking.is_empty():
		parts.append(Game.items_text(lacking))
	var vis := Game.missing_jar_vis()
	if not vis.is_empty():
		parts.append(_vis_text(vis))
	return Text.tr_key("PROMPT_WORKBENCH_MISSING") % [cost, ", ".join(parts)]


func interact(_player: Node3D) -> void:
	if Game.craft_jar():
		Audio.play(&"glass")


## "Ignis 3, Ordo 3".
func _vis_text(amounts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for aspect_id in amounts:
		parts.append("%s %d" % [Text.aspect_name(aspect_id), amounts[aspect_id]])
	return ", ".join(parts)
