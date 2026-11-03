class_name ResearchBook
extends MenuLayer
## Livro de Pesquisa (Tab): aspectos descobertos, alvos escaneados e páginas estudadas.

## Cores de tinta sobre o pergaminho.
const POINTS_COLOR := "#5c1a0a"
const SOFT_COLOR := "#3d2c1c"

@onready var points_label: Label = %PointsLabel
@onready var aspects_list: VBoxContainer = %AspectsList
@onready var scanned_list: VBoxContainer = %ScannedList
@onready var pages_list: VBoxContainer = %PagesList


func _on_opened() -> void:
	var knowledge := Game.knowledge
	points_label.text = tr("UI_BOOK_DISCOVERED_COUNT") % [knowledge.discovered_aspects.size(), Content.db.aspects.size()]

	# Aspectos: primeiro os primais, depois os compostos por nível, com pontos e receita.
	_clear(aspects_list)
	var ordered: Array[StringName] = []
	for aspect_id in knowledge.discovered_aspects:
		ordered.append(aspect_id)
	ordered.sort_custom(func(a, b): return Content.db.tier(a) < Content.db.tier(b))
	for aspect_id in ordered:
		var aspect: AspectData = Content.db.aspects.get(aspect_id)
		if aspect == null:
			continue
		var line := "%s%s  [color=%s]%d[/color]  [color=%s](%s)[/color]" % [
			Text.aspect_icon_bbcode(aspect_id), Text.aspect_bbcode(aspect_id, Text.aspect_name(aspect_id), true),
			POINTS_COLOR, knowledge.points(aspect_id), SOFT_COLOR, tr(aspect.meaning_key)]
		if aspect.is_compound():
			line += "\n      [color=%s]= %s%s + %s%s[/color]" % [SOFT_COLOR,
				Text.aspect_icon_bbcode(aspect.parents[0]), Text.aspect_name(aspect.parents[0]),
				Text.aspect_icon_bbcode(aspect.parents[1]), Text.aspect_name(aspect.parents[1])]
		_add_line(aspects_list, line)

	# Receitas que o jogador conhece de compostos que ainda não fez (para saber o que combinar).
	var pending: PackedStringArray = []
	for aspect: AspectData in Content.db.aspects.values():
		if aspect.is_compound() and not knowledge.knows_aspect(aspect.id) and knowledge.knows_recipe(aspect.id):
			pending.append("%s%s = %s + %s" % [Text.aspect_icon_bbcode(aspect.id), Text.aspect_bbcode(aspect.id, Text.aspect_name(aspect.id), true),
				Text.aspect_name(aspect.parents[0]), Text.aspect_name(aspect.parents[1])])
	if not pending.is_empty():
		_add_line(aspects_list, "[color=%s]%s[/color]" % [POINTS_COLOR, tr("UI_BOOK_RECIPES")])
		for line in pending:
			_add_line(aspects_list, line)

	_clear(scanned_list)
	for target_id in knowledge.scanned_targets:
		var target := Content.db.find_scannable(target_id)
		if target != null:
			_add_line(scanned_list, "%s\n   %s" % [Text.target_name(target), Text.aspect_amounts_bbcode(target.aspects, true)])

	_clear(pages_list)
	for page in Content.db.pages_by_id(knowledge.studied_pages):
		_add_line(pages_list, "[b]%s[/b]\n   %s" % [Text.expand(page.name_key), Text.expand(page.description_key)])

	if not knowledge.books_read.is_empty():
		var names: PackedStringArray = []
		for book_id in knowledge.books_read:
			var book: BookData = Content.db.books.get(book_id)
			if book != null:
				names.append(tr(book.name_key))
		_add_line(pages_list, "[color=%s]%s[/color]
   %s" % [POINTS_COLOR, tr("UI_BOOK_BOOKS"), ", ".join(names)])

	for list in [aspects_list, scanned_list, pages_list]:
		if list.get_child_count() == 0:
			_add_line(list, "[color=%s]%s[/color]" % [SOFT_COLOR, tr("UI_BOOK_EMPTY")])


func _clear(list: Container) -> void:
	for child in list.get_children():
		child.queue_free()


func _add_line(list: Container, bbcode: String) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = bbcode
	list.add_child(label)
