class_name Hud
extends CanvasLayer
## Interface sobre o jogo: vida, mostrador de Vis da varinha, mira (que acende com a carga da
## magia), aviso "Clique para jogar", texto de interação (E), informações do alvo da Lente com
## a barra de escaneamento, e avisos curtos.
## Tudo é desenhado na imagem pequena da interface (640x360, ampliada 2x); a aparência vem de
## assets/ui/hud_theme.tres.

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
@onready var vis_gauge: VisGauge = %VisGauge
@onready var depth_label: Label = %DepthLabel
@onready var boss_panel: Control = %BossPanel
@onready var boss_name: Label = %BossName
@onready var boss_bar: ProgressBar = %BossBar

var _health_bar: ProgressBar
var _health_value: Label
## Chefe que está lutando com o jogador (barra de vida no alto da tela).
var _boss: Node3D


func _ready() -> void:
	# Continua atualizando durante a pausa, para esconder a mira e os textos atrás dos menus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.scan_completed.connect(_on_scan_completed)
	Game.message_requested.connect(show_message)
	Game.player_damaged.connect(_on_player_damaged)
	_build_stats()
	Game.page_studied.connect(func(page): show_message(tr("UI_MSG_PAGE_STUDIED") % Text.expand(page.name_key)))
	Game.aspect_combined.connect(_on_aspect_combined)
	Game.boss_engaged.connect(_on_boss_engaged)


func _process(_delta: float) -> void:
	var playing := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	crosshair.visible = playing
	click_hint.visible = not playing and not get_tree().paused
	_update_prompt(playing)
	_update_scan(playing)
	_update_stats()
	_update_depth()
	_update_boss()
	var charge := Game.run.caster.charge_ratio()
	crosshair.color = Color(0.85, 0.8, 0.7, 0.8).lerp(Color(1.0, 0.55, 0.2, 1.0), charge)
	crosshair.scale = Vector2.ONE * (1.0 + charge)


func _build_stats() -> void:
	var row := _stat_row(tr("UI_HEALTH"), Color(0.6, 0.12, 0.1))
	_health_bar = row[0]
	_health_value = row[1]


## Cria uma linha "Nome [barra] valor" e devolve [barra, rótulo do valor].
func _stat_row(title: String, color: Color) -> Array:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := _outlined_label(title)
	name_label.custom_minimum_size.x = 30
	row.add_child(name_label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(80, 6)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	var value := _outlined_label("")
	row.add_child(value)
	stats.add_child(row)
	return [bar, value]


func _outlined_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	return label


func _update_stats() -> void:
	var health := Game.run.health
	_health_bar.max_value = health.max_health
	_health_bar.value = health.current
	_health_value.text = "%d/%d" % [ceili(health.current), health.max_health]
	var focus := Game.run.caster.focus
	var focus_aspect: AspectData = Content.db.aspects.get(focus.element)
	vis_gauge.show_wand(Game.run.wand, focus_aspect.color if focus_aspect != null else Color.WHITE)


func _on_boss_engaged(enemy: Node3D) -> void:
	_boss = enemy
	boss_name.text = Text.expand(enemy.data.name_key)


## A barra some quando o chefe cai ou a sala é trocada.
func _update_boss() -> void:
	var active: bool = is_instance_valid(_boss) and not _boss.health.is_dead()
	boss_panel.visible = active
	if active:
		boss_bar.max_value = _boss.health.max_health
		boss_bar.value = _boss.health.current


## Na Dungeon, mostra em que sala da incursão o jogador está.
func _update_depth() -> void:
	var run := Game.run
	depth_label.visible = run.in_dungeon()
	if depth_label.visible:
		depth_label.text = tr("UI_DEPTH") % [run.room_index + 1, run.dungeon.size()]


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


## Mostra o nome e os aspectos do alvo. Antes do escaneamento: "???". Se a Lente já tentou e
## faltou conhecimento: os aspectos conhecidos e "?" nos compostos ainda não descobertos.
func _update_scan(playing: bool) -> void:
	var target := player.aimed_scannable
	scan_panel.visible = playing and target != null
	if target == null:
		return
	if Game.knowledge.has_scanned(target.id):
		target_label.text = "[center]%s\n%s[/center]" % [Text.target_name(target), Text.aspect_amounts_bbcode(target.aspects)]
	elif target.id in Game.analyzed_targets:
		target_label.text = "[center]%s\n%s\n[color=#c08060]%s[/color][/center]" % [
			Text.target_name(target), _partial_aspects(target), tr("UI_SCAN_NEEDS_RESEARCH")]
	else:
		target_label.text = "[center]%s\n[color=#8a8a8a]%s[/color][/center]" % [tr("UI_SCAN_UNKNOWN"), tr("UI_SCAN_HINT")]
	var progress := player.scanner.progress
	scan_bar.visible = progress.is_active()
	scan_bar.value = progress.ratio()


## Aspectos do alvo: os já descobertos com nome e quantidade; os compostos que faltam, como "?".
func _partial_aspects(target: ScannableData) -> String:
	var parts: PackedStringArray = []
	for aspect_id: StringName in target.aspects:
		var aspect: AspectData = Content.db.aspects.get(aspect_id)
		if aspect != null and aspect.is_compound() and not Game.knowledge.knows_aspect(aspect_id):
			parts.append("[color=#8a8a8a]?[/color]")
		else:
			parts.append(Text.aspect_icon_bbcode(aspect_id) + Text.aspect_bbcode(aspect_id, tr("UI_ASPECT_AMOUNT") % [Text.aspect_name(aspect_id), target.aspects[aspect_id]]))
	return "  ".join(parts)


func _on_scan_completed(result: ScanResult) -> void:
	var target_name := Text.target_name(result.target)
	if result.blocked:
		show_message(tr("UI_MSG_SCAN_BLOCKED") % [target_name, result.missing.size()], Color(0.85, 0.55, 0.4))
		return
	if not result.discovered_something():
		show_message(tr("UI_MSG_ALREADY_SCANNED") % target_name)
		return
	show_message(tr("UI_MSG_SCANNED") % target_name)
	for aspect_id in result.new_aspects:
		show_message(tr("UI_MSG_NEW_ASPECT") % Text.aspect_name(aspect_id), Content.db.aspects[aspect_id].color)
	for aspect_id in result.points:
		if result.points[aspect_id] > 0:
			show_message(tr("UI_MSG_ASPECT_POINTS") % [result.points[aspect_id], Text.aspect_name(aspect_id)],
				Content.db.aspects[aspect_id].color.lerp(Color.WHITE, 0.3))


## Tela fica vermelha por um instante quando o jogador apanha.
func _on_player_damaged(_amount: float) -> void:
	var tween := damage_flash.create_tween()
	tween.tween_property(damage_flash, "color:a", 0.0, 0.5).from(0.45)


## Mostra um aviso no canto da tela, que some sozinho.
func show_message(text: String, color := Color(0.9, 0.86, 0.78)) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	messages.add_child(label)
	var tween := label.create_tween()
	tween.tween_interval(MESSAGE_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)


func _on_aspect_combined(compound: AspectData, discovered: bool) -> void:
	if discovered:
		show_message(tr("UI_MSG_COMPOUND_DISCOVERED") % Text.aspect_name(compound.id), compound.color)
