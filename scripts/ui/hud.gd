class_name Hud
extends CanvasLayer
## Interface sobre o jogo: mira, aviso "Clique para jogar", texto de interação (E),
## informações do alvo da Lente com a barra de escaneamento, e avisos curtos.

## Segundos que cada aviso fica na tela.
const MESSAGE_SECONDS := 4.0

@export var player: Player

@onready var click_hint: Label = %ClickHint
@onready var crosshair: Control = %Crosshair
@onready var prompt_label: Label = %PromptLabel
@onready var scan_panel: Control = %ScanPanel
@onready var target_label: RichTextLabel = %TargetLabel
@onready var scan_bar: ProgressBar = %ScanBar
@onready var messages: VBoxContainer = %Messages


func _ready() -> void:
	# Continua atualizando durante a pausa, para esconder a mira e os textos atrás dos menus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.scan_completed.connect(_on_scan_completed)
	Game.page_studied.connect(func(page): show_message(tr("UI_MSG_PAGE_STUDIED") % Text.expand(page.name_key)))


func _process(_delta: float) -> void:
	var playing := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	crosshair.visible = playing
	click_hint.visible = not playing and not get_tree().paused
	_update_prompt(playing)
	_update_scan(playing)


func _update_prompt(playing: bool) -> void:
	var target := player.aimed_interactable
	prompt_label.visible = playing and target != null and target.is_available()
	if prompt_label.visible:
		prompt_label.text = tr("UI_PROMPT_INTERACT") % Text.expand(target.prompt_key)


## Mostra o nome e os aspectos do alvo (ou "???" se ainda não foi escaneado).
func _update_scan(playing: bool) -> void:
	var target := player.aimed_scannable
	scan_panel.visible = playing and target != null
	if target == null:
		return
	if Game.knowledge.has_scanned(target.id):
		target_label.text = "[center]%s\n%s[/center]" % [tr(target.name_key), Text.aspect_amounts_bbcode(target.aspects)]
	else:
		target_label.text = "[center]%s\n[color=#8a8a8a]%s[/color][/center]" % [tr("UI_SCAN_UNKNOWN"), tr("UI_SCAN_HINT")]
	var progress := player.scanner.progress
	scan_bar.visible = progress.is_active()
	scan_bar.value = progress.ratio()


func _on_scan_completed(result: ScanResult) -> void:
	var target_name := tr(result.target.name_key)
	if not result.discovered_something():
		show_message(tr("UI_MSG_ALREADY_SCANNED") % target_name)
		return
	show_message(tr("UI_MSG_SCANNED") % target_name)
	for aspect_id in result.new_aspects:
		show_message(tr("UI_MSG_NEW_ASPECT") % Text.aspect_name(aspect_id), Content.db.aspects[aspect_id].color)
	if result.points > 0:
		show_message(tr("UI_MSG_POINTS") % result.points)


## Mostra um aviso no canto da tela, que some sozinho.
func show_message(text: String, color := Color(0.9, 0.86, 0.78)) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", 20)
	messages.add_child(label)
	var tween := label.create_tween()
	tween.tween_interval(MESSAGE_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)
