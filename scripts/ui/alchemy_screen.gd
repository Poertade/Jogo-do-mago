class_name AlchemyScreen
extends MenuLayer
## Tela do cadinho (alquimia, como no Thaumcraft 4), em três colunas:
## - Materiais: o que está guardado na escola; cada clique joga uma unidade no cadinho, e ela
##   vira essência dos aspectos dela;
## - No cadinho: a essência de cada aspecto; "anotar" a transforma em pontos de pesquisa
##   (aspectos ainda não descobertos aparecem como "?" e não podem ser anotados);
## - Receitas: elixires e Vis destilado em potes, pagos com a essência.

@onready var items_box: VBoxContainer = %Items
@onready var essence_box: VBoxContainer = %Essence
@onready var recipes_box: VBoxContainer = %Recipes
@onready var detail_label: RichTextLabel = %DetailLabel
@onready var status_label: RichTextLabel = %StatusLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(close)


func _on_opened() -> void:
	_refresh()
	close_button.grab_focus()
	detail_label.text = Text.tr_key("UI_ALCHEMY_HELP")


func _refresh() -> void:
	_clear(items_box)
	var ids: Array = Content.db.items.keys()
	ids.sort_custom(ContentDB.by_name)
	for item_id in ids:
		var item: ItemData = Content.db.items[item_id]
		var count := Game.stash.count(item_id)
		if count <= 0 or item.aspects.is_empty():
			continue
		var button := _button("%s ×%d" % [Text.tr_key(item.name_key), count])
		button.pressed.connect(_dissolve.bind(item))
		_on_hover(button, Text.tr_key("UI_ALCHEMY_DISSOLVE_DETAIL") % [Text.tr_key(item.name_key), _aspects_text(item.aspects)])
		items_box.add_child(button)
	if items_box.get_child_count() == 0:
		items_box.add_child(_note(Text.tr_key("UI_ALCHEMY_NO_ITEMS")))

	_clear(essence_box)
	var aspects: Array = Game.crucible.essentia.keys()
	aspects.sort_custom(func(a, b): return Content.db.tier(a) < Content.db.tier(b) or (Content.db.tier(a) == Content.db.tier(b) and String(a) < String(b)))
	for aspect_id in aspects:
		var amount := Game.crucible.amount(aspect_id)
		var known := Game.knowledge.knows_aspect(aspect_id)
		var label := "%s %d" % [Text.aspect_name(aspect_id) if known else "?", amount]
		var button := _button(label + " — " + Text.tr_key("UI_ALCHEMY_NOTE") if known else label)
		button.disabled = not known
		button.pressed.connect(_note_essence.bind(aspect_id))
		_on_hover(button, Text.tr_key("UI_ALCHEMY_NOTE_DETAIL") % [amount, Text.aspect_name(aspect_id)] if known else Text.tr_key("UI_ALCHEMY_UNKNOWN_DETAIL"))
		essence_box.add_child(button)
	if essence_box.get_child_count() == 0:
		essence_box.add_child(_note(Text.tr_key("UI_ALCHEMY_EMPTY")))

	_clear(recipes_box)
	var recipes: Array = Content.db.recipes.values()
	recipes.sort_custom(func(a, b): return a.order < b.order)
	for recipe: AlchemyRecipeData in recipes:
		var problem := Game.brew_problem(recipe)
		var button := _button("%s — %s" % [Text.expand(recipe.name_key), Text.tr_key("UI_ALCHEMY_BREW") if problem == "" else Text.tr_key(problem)])
		button.disabled = problem != ""
		button.pressed.connect(_brew.bind(recipe))
		_on_hover(button, "%s\n%s" % [Text.expand(recipe.description_key), Text.tr_key("UI_ALCHEMY_COST") % _aspects_text(recipe.cost)])
		recipes_box.add_child(button)

	status_label.text = Text.tr_key("UI_ALCHEMY_STATUS") % [Game.stash.elixir_total(), Content.db.player.max_elixirs,
		Game.run.jars.jars.filter(func(jar): return jar.is_empty()).size()]


func _dissolve(item: ItemData) -> void:
	Game.dissolve(item)
	_refresh()


func _note_essence(aspect_id: StringName) -> void:
	Game.note_essence(aspect_id)
	_refresh()


func _brew(recipe: AlchemyRecipeData) -> void:
	Game.brew(recipe)
	_refresh()


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.add_theme_color_override(&"font_disabled_color", Color(0.24, 0.16, 0.1))
	return button


func _note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label


## Mostra a explicação embaixo ao passar o mouse (ou o foco do teclado) sobre o botão.
func _on_hover(button: Button, text: String) -> void:
	button.mouse_entered.connect(func(): detail_label.text = text)
	button.focus_entered.connect(func(): detail_label.text = text)


## "Mortuus 1, Terra 2" (com "?" nos aspectos ainda não descobertos).
func _aspects_text(amounts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for aspect_id in amounts:
		var known := Game.knowledge.knows_aspect(aspect_id)
		parts.append("%s %d" % [Text.aspect_name(aspect_id) if known else "?", amounts[aspect_id]])
	return ", ".join(parts)


func _clear(box: Container) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
