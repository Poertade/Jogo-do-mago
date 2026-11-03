class_name ResearchTableScreen
extends MenuLayer
## Tela da Mesa de Pesquisa: lista as páginas de pesquisa e permite estudá-las com pontos.

@onready var points_label: Label = %PointsLabel
@onready var pages_list: VBoxContainer = %PagesList
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(close)
	Game.page_studied.connect(_on_page_studied)


func _on_page_studied(_page: ResearchPageData) -> void:
	if visible:
		_refresh()


func _on_opened() -> void:
	_refresh()
	close_button.grab_focus()


func _refresh() -> void:
	points_label.text = tr("UI_RESEARCH_POINTS") % Game.knowledge.research_points
	for child in pages_list.get_children():
		child.queue_free()
	for page in Content.db.sorted_pages():
		pages_list.add_child(_page_entry(page))


## Um bloco por página: nome, descrição, custo, situação e botão de estudar.
func _page_entry(page: ResearchPageData) -> Control:
	var box := VBoxContainer.new()
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.text = "[b]%s[/b]\n%s\n[color=#a0a0a0]%s[/color]" % [
		Text.expand(page.name_key), Text.expand(page.description_key), tr("UI_PAGE_COST") % page.cost]
	box.add_child(title)

	var row := HBoxContainer.new()
	var status := Label.new()
	var check := Game.knowledge.check_study(page)
	status.text = _status_text(page, check)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status)
	var button := Button.new()
	button.text = tr("UI_STUDY")
	button.disabled = check != Knowledge.StudyCheck.OK
	button.pressed.connect(Game.study.bind(page))
	row.add_child(button)
	box.add_child(row)
	box.add_child(HSeparator.new())
	return box


func _status_text(page: ResearchPageData, check: Knowledge.StudyCheck) -> String:
	match check:
		Knowledge.StudyCheck.OK:
			return tr("UI_STUDY_OK")
		Knowledge.StudyCheck.ALREADY_STUDIED:
			return tr("UI_STUDY_ALREADY")
		Knowledge.StudyCheck.NOT_ENOUGH_POINTS:
			return tr("UI_STUDY_NO_POINTS")
		Knowledge.StudyCheck.MISSING_PAGE:
			return tr("UI_STUDY_MISSING_PAGE")
		Knowledge.StudyCheck.MISSING_ASPECT:
			var missing: PackedStringArray = []
			for aspect_id in page.required_aspects:
				if not Game.knowledge.knows_aspect(aspect_id):
					missing.append(Text.aspect_name(aspect_id))
			return tr("UI_STUDY_MISSING_ASPECT") % ", ".join(missing)
	return ""
