class_name ResearchTableScreen
extends MenuLayer
## Mesa de Pesquisa, no estilo do Thaumcraft 4:
## - à esquerda, a grade de aspectos descobertos, com os pontos de cada um;
## - embaixo, dois espaços para combinar aspectos e descobrir (ou ganhar pontos de) compostos;
## - à direita, no pergaminho, a nota de pesquisa da página escolhida: escolha um aspecto na
##   grade e clique num hexágono para escrevê-lo (gasta pontos; botão direito apaga e devolve).
##   Quando todos os aspectos marcados da nota estão ligados, a página é estudada.

@onready var aspect_grid: GridContainer = %AspectGrid
@onready var selected_label: RichTextLabel = %SelectedLabel
@onready var slot_a: AspectCell = %SlotA
@onready var slot_b: AspectCell = %SlotB
@onready var result_cell: AspectCell = %ResultCell
@onready var combine_button: Button = %CombineButton
@onready var combine_info: Label = %CombineInfo
@onready var page_tabs: HFlowContainer = %PageTabs
@onready var page_title: Label = %PageTitle
@onready var page_description: RichTextLabel = %PageDescription
@onready var note_view: ResearchNoteView = %NoteView
@onready var status_label: RichTextLabel = %StatusLabel
@onready var close_button: Button = %CloseButton

var _selected: StringName = &""
var _page: ResearchPageData


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(close)
	combine_button.pressed.connect(_on_combine)
	slot_a.gui_input.connect(_on_slot_input.bind(slot_a))
	slot_b.gui_input.connect(_on_slot_input.bind(slot_b))
	result_cell.disabled = true
	note_view.cell_clicked.connect(_on_cell_clicked)
	Game.knowledge.changed.connect(_on_knowledge_changed)
	Game.progress_reset.connect(_on_progress_reset)


func _on_opened() -> void:
	if _page == null and not Content.db.pages.is_empty():
		_page = Content.db.sorted_pages()[0]
	_refresh()
	close_button.grab_focus()


## Novo jogo: o conhecimento é outro objeto.
func _on_progress_reset() -> void:
	_page = null
	Game.knowledge.changed.connect(_on_knowledge_changed)


func _on_knowledge_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	_fill_aspects()
	_update_selection()
	_update_combination()
	_fill_pages()
	_update_note()


# --- Grade de aspectos ---------------------------------------------------------

func _fill_aspects() -> void:
	for child in aspect_grid.get_children():
		child.queue_free()
	var ordered: Array[StringName] = []
	ordered.assign(Game.knowledge.discovered_aspects)
	ordered.sort_custom(func(a, b): return Content.db.tier(a) < Content.db.tier(b) or (Content.db.tier(a) == Content.db.tier(b) and String(a) < String(b)))
	for aspect_id in ordered:
		var cell := AspectCell.new()
		cell.aspect_id = aspect_id
		cell.count = Game.knowledge.points(aspect_id)
		cell.selected = aspect_id == _selected
		cell.pressed.connect(_select.bind(aspect_id))
		aspect_grid.add_child(cell)


func _select(aspect_id: StringName) -> void:
	_selected = aspect_id
	for cell: AspectCell in aspect_grid.get_children():
		cell.selected = cell.aspect_id == aspect_id
	_update_selection()


func _update_selection() -> void:
	if _selected == &"":
		selected_label.text = "[color=#c8b48a]%s[/color]" % tr("UI_TABLE_PICK_ASPECT")
		return
	var aspect: AspectData = Content.db.aspects.get(_selected)
	var recipe := ""
	if aspect.is_compound():
		recipe = "  = %s + %s" % [Text.aspect_name(aspect.parents[0]), Text.aspect_name(aspect.parents[1])]
	selected_label.text = "%s [color=#c8b48a](%s) — %d %s%s[/color]" % [
		Text.aspect_bbcode(_selected, Text.aspect_name(_selected)), tr(aspect.meaning_key),
		Game.knowledge.points(_selected), tr("UI_BOOK_POINTS_COLUMN"), recipe]


# --- Combinação ----------------------------------------------------------------

## Clique esquerdo num espaço coloca o aspecto escolhido; o direito esvazia.
func _on_slot_input(event: InputEvent, slot: AspectCell) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT and _selected != &"":
		slot.aspect_id = _selected
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		slot.aspect_id = &""
	_update_combination()


func _update_combination() -> void:
	var rules := Content.db.research_rules
	slot_a.placeholder = "+" if slot_a.aspect_id == &"" else ""
	slot_b.placeholder = "+" if slot_b.aspect_id == &"" else ""
	slot_a.count = Game.knowledge.points(slot_a.aspect_id) if slot_a.aspect_id != &"" else -1
	slot_b.count = Game.knowledge.points(slot_b.aspect_id) if slot_b.aspect_id != &"" else -1
	var compound := Content.db.compound_of(slot_a.aspect_id, slot_b.aspect_id)
	result_cell.aspect_id = &""
	result_cell.placeholder = ""
	result_cell.count = -1
	combine_button.disabled = true
	if slot_a.aspect_id == &"" or slot_b.aspect_id == &"":
		combine_info.text = tr("UI_TABLE_COMBINE_HINT") % [rules.combine_cost, rules.combine_yield]
	elif compound == null or not Game.knowledge.knows_recipe(compound.id):
		# Sem a receita, a Mesa não diz se o par forma algo: as receitas vêm dos livros.
		result_cell.placeholder = "×"
		combine_info.text = tr("UI_COMBINE_UNKNOWN_PAIR")
	else:
		if Game.knowledge.knows_aspect(compound.id):
			result_cell.aspect_id = compound.id
			result_cell.count = Game.knowledge.points(compound.id)
		else:
			result_cell.placeholder = "?"
		var check := Game.knowledge.check_combine(compound, rules)
		combine_button.disabled = check != Knowledge.CombineCheck.OK
		match check:
			Knowledge.CombineCheck.OK:
				combine_info.text = tr("UI_COMBINE_READY")
			Knowledge.CombineCheck.UNKNOWN_RECIPE:
				combine_info.text = tr("UI_COMBINE_NEEDS_BOOK")
			_:
				combine_info.text = tr("UI_STUDY_NO_POINTS")


func _on_combine() -> void:
	var compound := Content.db.compound_of(slot_a.aspect_id, slot_b.aspect_id)
	if compound != null:
		Game.combine(compound)


# --- Nota de pesquisa ------------------------------------------------------------

func _fill_pages() -> void:
	for child in page_tabs.get_children():
		child.queue_free()
	for page in Content.db.sorted_pages():
		var tab := Button.new()
		tab.text = Text.expand(page.name_key)
		tab.toggle_mode = true
		tab.button_pressed = page == _page
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(_show_page.bind(page))
		page_tabs.add_child(tab)


func _show_page(page: ResearchPageData) -> void:
	_page = page
	_refresh()


func _update_note() -> void:
	if _page == null:
		return
	page_title.text = Text.expand(_page.name_key)
	page_description.text = Text.expand(_page.description_key)
	var knowledge := Game.knowledge
	var studied := knowledge.has_studied(_page.id)
	note_view.show_note(knowledge.note_for(_page), knowledge.knows_aspect, studied)
	var check := knowledge.check_study(_page, Content.db.aspects)
	match check:
		Knowledge.StudyCheck.ALREADY_STUDIED:
			status_label.text = "[center][color=#1d4a17]%s[/color][/center]" % tr("UI_NOTE_DONE")
		Knowledge.StudyCheck.MISSING_ASPECT:
			status_label.text = "[center]%s[/center]" % tr("UI_NOTE_MISSING_ASPECT")
		Knowledge.StudyCheck.MISSING_PAGE:
			status_label.text = "[center]%s[/center]" % tr("UI_STUDY_MISSING_PAGE")
		_:
			status_label.text = "[center]%s[/center]" % (tr("UI_NOTE_HINT") % Content.db.research_rules.note_write_cost)


func _on_cell_clicked(cell: Vector2i, button: MouseButton) -> void:
	if _page == null or Game.knowledge.has_studied(_page.id):
		return
	if button == MOUSE_BUTTON_RIGHT:
		Game.erase_from_note(_page, cell)
	elif button == MOUSE_BUTTON_LEFT and _selected != &"":
		Game.write_on_note(_page, cell, _selected)
	# Nota completa: a página é estudada na hora.
	if Game.knowledge.check_study(_page, Content.db.aspects) == Knowledge.StudyCheck.OK:
		Game.study(_page)
