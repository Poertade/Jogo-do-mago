class_name Hud
extends CanvasLayer
## Interface sobre o jogo: vida e reserva da varinha, mira (que acende com a carga da magia),
## aviso "Clique para jogar", texto de interação (E), informações do alvo da Lente com a
## barra de escaneamento, e avisos curtos.

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
@onready var stats: VBoxContainer = %Stats
@onready var damage_flash: ColorRect = %DamageFlash

## Uma linha (barra e número) para a vida e uma para cada aspecto que o Focus gasta.
var _health_bar: ProgressBar
var _health_value: Label
var _reserve_rows: Dictionary[StringName, Array] = {}


func _ready() -> void:
	# Continua atualizando durante a pausa, para esconder a mira e os textos atrás dos menus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.scan_completed.connect(_on_scan_completed)
	Game.message_requested.connect(show_message)
	Game.player_damaged.connect(_on_player_damaged)
	_build_stats()
	Game.page_studied.connect(func(page): show_message(tr("UI_MSG_PAGE_STUDIED") % Text.expand(page.name_key)))


func _process(_delta: float) -> void:
	var playing := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	crosshair.visible = playing
	click_hint.visible = not playing and not get_tree().paused
	_update_prompt(playing)
	_update_scan(playing)
	_update_stats()
	var charge := Game.run.caster.charge_ratio()
	crosshair.color = Color(0.85, 0.8, 0.7, 0.8).lerp(Color(1.0, 0.55, 0.2, 1.0), charge)
	crosshair.scale = Vector2.ONE * (1.0 + charge)


func _build_stats() -> void:
	var row := _stat_row(tr("UI_HEALTH"), Color(0.7, 0.15, 0.12))
	_health_bar = row[0]
	_health_value = row[1]
	for aspect_id in Game.run.caster.focus.cost:
		_reserve_rows[aspect_id] = _stat_row(Text.aspect_name(aspect_id), Content.db.aspects[aspect_id].color)


## Cria uma linha "Nome [barra] valor" e devolve [barra, rótulo do valor].
func _stat_row(title: String, color: Color) -> Array:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := _outlined_label(title)
	name_label.custom_minimum_size.x = 70
	row.add_child(name_label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(160, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.05, 0.05, 0.06, 0.8)
	bar.add_theme_stylebox_override("background", background)
	row.add_child(bar)
	var value := _outlined_label("")
	row.add_child(value)
	stats.add_child(row)
	return [bar, value]


func _outlined_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", 18)
	return label


func _update_stats() -> void:
	var health := Game.run.health
	_health_bar.max_value = health.max_health
	_health_bar.value = health.current
	_health_value.text = "%d/%d" % [ceili(health.current), health.max_health]
	var wand := Game.run.wand
	for aspect_id in _reserve_rows:
		var bar: ProgressBar = _reserve_rows[aspect_id][0]
		var value: Label = _reserve_rows[aspect_id][1]
		bar.max_value = wand.capacity(aspect_id)
		bar.value = wand.reserve(aspect_id)
		value.text = "%d/%d" % [wand.reserve(aspect_id), wand.capacity(aspect_id)]


func _update_prompt(playing: bool) -> void:
	var target := player.aimed_interactable
	var key := target.current_prompt_key() if target != null else ""
	prompt_label.visible = playing and key != ""
	if not prompt_label.visible:
		return
	if target.is_available():
		prompt_label.text = tr("UI_PROMPT_INTERACT") % Text.expand(key)
	else:
		prompt_label.text = Text.expand(key)


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


## Tela fica vermelha por um instante quando o jogador apanha.
func _on_player_damaged(_amount: float) -> void:
	var tween := damage_flash.create_tween()
	tween.tween_property(damage_flash, "color:a", 0.0, 0.5).from(0.45)


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
