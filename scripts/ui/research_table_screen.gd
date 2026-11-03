class_name ResearchTableScreen
extends MenuLayer
## Tela da Mesa de Pesquisa, no estilo do Thaumcraft 4:
## - seus pontos de pesquisa, por aspecto;
## - combinar dois aspectos conhecidos para descobrir (ou ganhar pontos de) um composto;
## - estudar páginas de pesquisa, pagando com pontos de aspectos.

@onready var points_label: Label = %PointsLabel
@onready var points_list: VBoxContainer = %PointsList
@onready var combine_list: VBoxContainer = %CombineList
@onready var pages_list: VBoxContainer = %PagesList
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(close)
	Game.page_studied.connect(_on_research_changed)
	Game.aspect_combined.connect(_on_research_changed)


func _on_research_changed(_a = null, _b = null) -> void:
	if visible:
		_refresh()


func _on_opened() -> void:
	_refresh()
	close_button.grab_focus()


func _refresh() -> void:
	var rules := Content.db.research_rules
	points_label.text = tr("UI_TABLE_COMBINE_HINT") % [rules.combine_cost, rules.combine_yield]
	_fill_points()
	_fill_combinations()
	_fill_pages()


func _clear(list: Container) -> void:
	for child in list.get_children():
		child.queue_free()


func _rich(bbcode: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = bbcode
	return label


## Coluna 1: pontos de cada aspecto descoberto.
func _fill_points() -> void:
	_clear(points_list)
	var ordered: Array[StringName] = []
	for aspect_id in Game.knowledge.discovered_aspects:
		ordered.append(aspect_id)
	ordered.sort_custom(func(a, b): return Content.db.tier(a) < Content.db.tier(b))
	for aspect_id in ordered:
		points_list.add_child(_rich("%s  [color=#c8b070]%d[/color]" % [
			Text.aspect_bbcode(aspect_id, Text.aspect_name(aspect_id)), Game.knowledge.points(aspect_id)]))
	if ordered.is_empty():
		points_list.add_child(_rich("[color=#6a6a6a]%s[/color]" % tr("UI_NO_POINTS_YET")))


## Coluna 2: compostos cujos dois pais já foram descobertos. Os ainda desconhecidos aparecem
## como "?" até a primeira combinação.
func _fill_combinations() -> void:
	_clear(combine_list)
	var rules := Content.db.research_rules
	for compound in Content.db.compounds_by_tier():
		var check := Game.knowledge.check_combine(compound, rules)
		if check == Knowledge.CombineCheck.NOT_COMPOUND or check == Knowledge.CombineCheck.UNKNOWN_PARENT:
			continue
		var known := Game.knowledge.knows_aspect(compound.id)
		var result := Text.aspect_bbcode(compound.id, Text.aspect_name(compound.id)) if known else "[color=#c0c0c0]%s[/color]" % tr("UI_COMBINE_UNKNOWN")
		var row := HBoxContainer.new()
		var label := _rich("%s + %s → %s" % [
			Text.aspect_bbcode(compound.parents[0], Text.aspect_name(compound.parents[0])),
			Text.aspect_bbcode(compound.parents[1], Text.aspect_name(compound.parents[1])), result])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button := Button.new()
		button.text = tr("UI_COMBINE")
		button.disabled = check != Knowledge.CombineCheck.OK
		button.pressed.connect(Game.combine.bind(compound))
		row.add_child(button)
		combine_list.add_child(row)
	if combine_list.get_child_count() == 0:
		combine_list.add_child(_rich("[color=#6a6a6a]%s[/color]" % tr("UI_COMBINE_NOTHING")))


## Coluna 3: páginas de pesquisa.
func _fill_pages() -> void:
	_clear(pages_list)
	for page in Content.db.sorted_pages():
		pages_list.add_child(_page_entry(page))


func _page_entry(page: ResearchPageData) -> Control:
	var box := VBoxContainer.new()
	box.add_child(_rich("[b]%s[/b]\n%s\n[color=#a0a0a0]%s[/color]" % [
		Text.expand(page.name_key), Text.expand(page.description_key), tr("UI_STUDY_COST") % _cost_text(page.cost)]))
	var row := HBoxContainer.new()
	var status := Label.new()
	var check := Game.knowledge.check_study(page)
	status.text = _status_text(page, check)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD
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


## "Ignis 4, Potentia 2" com os pontos que você tem entre parênteses.
func _cost_text(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for aspect_id: StringName in cost:
		var aspect_label := Text.aspect_name(aspect_id) if Game.knowledge.knows_aspect(aspect_id) else tr("UI_COMBINE_UNKNOWN")
		parts.append("%s %d (%d)" % [aspect_label, cost[aspect_id], Game.knowledge.points(aspect_id)])
	return ", ".join(parts)


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
			var needed: Array[StringName] = page.required_aspects.duplicate()
			for aspect_id in page.cost:
				if not aspect_id in needed:
					needed.append(aspect_id)
			for aspect_id in needed:
				if not Game.knowledge.knows_aspect(aspect_id):
					var aspect: AspectData = Content.db.aspects.get(aspect_id)
					missing.append(tr("UI_COMBINE_UNKNOWN") if aspect != null and aspect.is_compound() else Text.aspect_name(aspect_id))
			return tr("UI_STUDY_MISSING_ASPECT") % ", ".join(missing)
	return ""
