class_name ResearchBook
extends MenuLayer
## Livro de Pesquisa (Tab): aspectos descobertos, alvos escaneados e páginas estudadas.

@onready var points_label: Label = %PointsLabel
@onready var aspects_list: VBoxContainer = %AspectsList
@onready var scanned_list: VBoxContainer = %ScannedList
@onready var pages_list: VBoxContainer = %PagesList


func _on_opened() -> void:
	var knowledge := Game.knowledge
	points_label.text = tr("UI_RESEARCH_POINTS") % knowledge.research_points

	_clear(aspects_list)
	for aspect_id in knowledge.discovered_aspects:
		var aspect: AspectData = Content.db.aspects.get(aspect_id)
		if aspect == null:
			continue
		var kind := tr("UI_ASPECT_KIND_COMPOUND") if aspect.is_compound() else tr("UI_ASPECT_KIND_PRIMAL")
		_add_line(aspects_list, "%s  [color=#8a8a8a](%s, %s)[/color]" % [
			Text.aspect_bbcode(aspect_id, Text.aspect_name(aspect_id)), tr(aspect.meaning_key), kind])

	_clear(scanned_list)
	for target_id in knowledge.scanned_targets:
		var target := Content.db.find_scannable(target_id)
		if target != null:
			_add_line(scanned_list, "%s\n   %s" % [tr(target.name_key), Text.aspect_amounts_bbcode(target.aspects)])

	_clear(pages_list)
	for page in Content.db.pages_by_id(knowledge.studied_pages):
		_add_line(pages_list, "[b]%s[/b]\n   %s" % [Text.expand(page.name_key), Text.expand(page.description_key)])

	for list in [aspects_list, scanned_list, pages_list]:
		if list.get_child_count() == 0:
			_add_line(list, "[color=#6a6a6a]%s[/color]" % tr("UI_BOOK_EMPTY"))


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
