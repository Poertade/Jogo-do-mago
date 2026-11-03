class_name WandScreen
extends MenuLayer
## Tela da Bancada Arcana: a varinha montada agora, os núcleos (quanto Vis cabe) e as ponteiras
## (quanto as magias custam). Cada peça mostra o que faz e, conforme o caso:
## - "Montada": é a que está na varinha;
## - "Montar": o jogador já a tem; montar é de graça;
## - "Fazer": liberada por uma página estudada; gasta materiais e Vis da varinha;
## - "Falta…" ou "Estude a página…": ainda não dá.
## Embaixo, os materiais guardados na escola.

@onready var wand_label: RichTextLabel = %WandLabel
@onready var cores_box: VBoxContainer = %Cores
@onready var caps_box: VBoxContainer = %Caps
@onready var detail_label: RichTextLabel = %DetailLabel
@onready var materials_label: RichTextLabel = %MaterialsLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(close)


func _on_opened() -> void:
	_refresh()
	close_button.grab_focus()


func _refresh() -> void:
	var core := Game.equipped_core()
	var cap := Game.equipped_cap()
	wand_label.text = Text.tr_key("UI_WAND_CURRENT") % [Text.tr_key(core.name_key), Text.tr_key(cap.name_key),
		core.aspect_capacity, core.capacity, _cost_percent(cap)]
	_fill(cores_box, Content.db.cores.values())
	_fill(caps_box, Content.db.caps.values())
	var owned := {}
	for item_id in Content.db.items:
		if Game.stash.count(item_id) > 0:
			owned[item_id] = Game.stash.count(item_id)
	materials_label.text = Text.tr_key("UI_WAND_MATERIALS") % (Game.items_text(owned) if not owned.is_empty() else Text.tr_key("UI_WAND_NO_MATERIALS"))
	# Abre mostrando a peça que dá para fazer agora (ou o núcleo montado).
	var shown: Resource = core
	for part in Content.db.cores.values() + Content.db.caps.values():
		if _can_build(part):
			shown = part
			break
	_show_detail(shown)


## Uma linha por peça, das mais simples às melhores.
func _fill(box: VBoxContainer, parts: Array) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	parts.sort_custom(func(a, b): return a.tier < b.tier)
	for part in parts:
		var button := Button.new()
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s · %s" % [Text.tr_key(part.name_key), _stats(part)]
		var state := _state(part)
		button.text += " — " + state
		button.disabled = not (_can_build(part) or (Game.owns_part(part) and not _is_equipped(part)))
		# Peças que ainda não dá para usar continuam legíveis (só um pouco mais claras).
		button.add_theme_color_override(&"font_disabled_color", Color(0.24, 0.16, 0.1))
		button.pressed.connect(_use.bind(part))
		button.mouse_entered.connect(_show_detail.bind(part))
		button.focus_entered.connect(_show_detail.bind(part))
		box.add_child(button)


func _use(part: Resource) -> void:
	if Game.owns_part(part):
		Game.equip_part(part)
	else:
		Game.build_part(part)
	_refresh()


func _show_detail(part: Resource) -> void:
	var text := Text.expand(part.description_key)
	if not Game.owns_part(part):
		text += "\n" + Text.tr_key("UI_WAND_COST") % _cost_text(part)
	detail_label.text = text


func _state(part: Resource) -> String:
	if _is_equipped(part):
		return Text.tr_key("UI_WAND_EQUIPPED")
	if Game.owns_part(part):
		return Text.tr_key("UI_WAND_EQUIP")
	if not Game.part_unlocked(part):
		return Text.tr_key("UI_WAND_LOCKED")
	if _can_build(part):
		return Text.tr_key("UI_WAND_BUILD")
	var lacking := Game.stash.missing(part.cost)
	var parts: PackedStringArray = []
	if not lacking.is_empty():
		parts.append(Game.items_text(lacking))
	var vis := Game.missing_vis(part.vis_cost)
	for aspect_id in vis:
		parts.append("%s %d" % [Text.aspect_name(aspect_id), vis[aspect_id]])
	return Text.tr_key("UI_WAND_MISSING") % ", ".join(parts)


func _can_build(part: Resource) -> bool:
	return not Game.owns_part(part) and Game.part_unlocked(part) and Game.stash.can_afford(part.cost) and Game.missing_vis(part.vis_cost).is_empty()


func _is_equipped(part: Resource) -> bool:
	return part == Game.equipped_core() or part == Game.equipped_cap()


## O que a peça faz, em poucas palavras.
func _stats(part: Resource) -> String:
	if part is WandCoreData:
		return Text.tr_key("UI_WAND_CORE_STATS") % [part.aspect_capacity, part.capacity]
	return Text.tr_key("UI_WAND_CAP_STATS") % _cost_percent(part)


## Quanto as magias custam com a ponteira, em porcentagem do normal (ex.: 80).
func _cost_percent(cap: WandCapData) -> int:
	return roundi(100.0 / maxf(cap.efficiency, 0.01))


func _cost_text(part: Resource) -> String:
	var parts: PackedStringArray = [Game.items_text(part.cost)]
	for aspect_id in part.vis_cost:
		parts.append("%s %d" % [Text.aspect_name(aspect_id), part.vis_cost[aspect_id]])
	return ", ".join(parts)
