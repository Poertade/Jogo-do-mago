class_name ResearchBook
extends MenuLayer
## Livro de Pesquisa (Tab): aspectos descobertos, alvos escaneados e páginas estudadas.

## Cores de tinta sobre o pergaminho.
const POINTS_COLOR := "#7a3a14"
const SOFT_COLOR := "#6b5a44"

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
			Text.aspect_icon_bbcode(aspect_id, 24), Text.aspect_bbcode(aspect_id, Text.aspect_name(aspect_id), true),
			POINTS_COLOR, knowledge.points(aspect_id), SOFT_COLOR, tr(aspect.meaning_key)]
		if aspect.is_compound():
			line += "\n      [color=%s]= %s%s + %s%s[/color]" % [SOFT_COLOR,
				Text.aspect_icon_bbcode(aspect.parents[0], 16), Text.aspect_name(aspect.parents[0]),
				Text.aspect_icon_bbcode(aspect.parents[1], 16), Text.aspect_name(aspect.parents[1])]
		_add_line(aspects_list, line)

	_clear(scanned_list)
	for target_id in knowledge.scanned_targets:
		var target := Content.db.find_scannable(target_id)
		if target != null:
			_add_line(scanned_list, "%s\n   %s" % [Text.target_name(target), Text.aspect_amounts_bbcode(target.aspects, true)])

	_clear(pages_list)
	for page in Content.db.pages_by_id(knowledge.studied_pages):
		_add_line(pages_list, "[b]%s[/b]\n   %s" % [Text.expand(page.name_key), Text.expand(page.description_key)])

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
