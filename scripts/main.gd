extends Node
## Cena principal: junta a tela do jogo (mundo 3D em baixa resolução), o HUD e as telas de
## menu. Também conduz o ciclo do jogo: viagem entre salas (portal, saída) com transição,
## e a morte, que leva de volta ao Salão de Estudos.
##
## Argumentos de desenvolvimento, depois de "--" na linha de comando:
##   --seed=123             semente do gerador aleatório
##   --room=school          sala inicial (padrão: start_room)
##   --entrance=default     entrada da sala inicial
##   --screenshot=foto.png  salva uma captura da janela depois de alguns quadros e fecha o jogo

## Sala onde o jogo começa e onde o jogador renasce (identificador de data/rooms/).
@export var start_room: StringName = &"school"
@export var start_entrance: StringName = &"default"
## Sala onde a vida é restaurada ao chegar (a escola é segura).
@export var safe_room: StringName = &"school"
## Cores e duração das transições.
@export var travel_color := Color(0.1, 0.06, 0.18)
@export var death_color := Color(0.25, 0.02, 0.02)
@export var fade_seconds := 0.6

var rng: GameRng
var _transitioning := false

@onready var game_viewport: SubViewport = %GameViewport
@onready var game_screen: GameScreen = %GameScreen
@onready var world: World = %World
@onready var player: Player = %Player
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var research_book: ResearchBook = %ResearchBook
@onready var research_table_screen: ResearchTableScreen = %ResearchTableScreen
@onready var note_screen: NoteScreen = %NoteScreen
@onready var portal_screen: PortalScreen = %PortalScreen
@onready var wand_screen: WandScreen = %WandScreen


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	rng = GameRng.new(GameRng.seed_from_args(args, randi()))
	print("Semente: %d" % rng.seed_value)
	# As incursões são sorteadas a partir desta semente: --seed=N repete as mesmas.
	Game.rng = rng

	Settings.changed.connect(_apply_settings)
	_apply_settings()
	for menu: MenuLayer in [pause_menu, research_book, research_table_screen, note_screen, portal_screen, wand_screen]:
		menu.closed.connect(_capture_mouse)
	Game.screen_requested.connect(_on_screen_requested)
	Game.note_requested.connect(note_screen.show_note)
	Game.text_requested.connect(note_screen.show_text)
	Game.travel_requested.connect(_on_travel_requested)
	Game.dungeon_requested.connect(_on_dungeon_requested)
	Game.player_died.connect(_on_player_died)
	pause_menu.quit_requested.connect(quit_game)
	# Fechar a janela passa por quit_game(), para parar os sons antes de sair.
	get_tree().auto_accept_quit = false

	world.load_room(_arg_value(args, "--room=", start_room), _arg_value(args, "--entrance=", start_entrance))

	var screenshot_path := _arg_value(args, "--screenshot=", "")
	if screenshot_path != "":
		_take_screenshot_and_quit(screenshot_path)


func _apply_settings() -> void:
	game_screen.apply_settings(Settings.current, Content.db.settings_defaults)
	player.mouse_sensitivity = Settings.current.mouse_sensitivity
	Audio.set_master_volume(Settings.current.master_volume)


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event.is_action_pressed("pause"):
		pause_menu.open()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("research_book"):
		research_book.open()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse()
		get_viewport().set_input_as_handled()
		return
	# O mundo 3D fica num SubViewport, que não recebe eventos sozinho: repassamos.
	game_viewport.push_input(event)


func _on_screen_requested(screen: StringName) -> void:
	match screen:
		&"research_table":
			research_table_screen.open()
		&"portal":
			portal_screen.open()
		&"arcane_workbench":
			wand_screen.open()


## Portal ou saída: dissolve, troca a sala e volta.
func _on_travel_requested(room_id: StringName, entrance_id: StringName) -> void:
	if _transitioning:
		return
	await _transition(travel_color, _arrive.bind(room_id, entrance_id))


## Portal: dissolve, monta o mapa da Dungeon (e a malha de navegação) e volta.
func _on_dungeon_requested(incursion_seed: int, anchor_id: StringName) -> void:
	if _transitioning:
		return
	await _transition(travel_color, world.load_dungeon.bind(incursion_seed, anchor_id))


func _arrive(room_id: StringName, entrance_id: StringName) -> void:
	world.load_room(room_id, entrance_id)
	# Chegar vivo à escola guarda o que foi achado na incursão.
	if room_id == safe_room:
		Game.arrive_at_school()


## Morte: a incursão recomeça no Salão de Estudos; o conhecimento já está salvo.
func _on_player_died() -> void:
	if _transitioning:
		return
	await _transition(death_color, _respawn)
	Game.message(Text.tr_key("MSG_AWAKEN"), Color(0.85, 0.75, 0.6))


func _respawn() -> void:
	Game.run.reset()
	world.load_room(start_room, start_entrance)


## Pausa, dissolve até a cor, executa `change` e dissolve de volta.
func _transition(color: Color, change: Callable) -> void:
	_transitioning = true
	get_tree().paused = true
	await game_screen.fade_to(1.0, color, fade_seconds).finished
	change.call()
	await get_tree().process_frame
	await game_screen.fade_to(0.0, color, fade_seconds).finished
	get_tree().paused = false
	_transitioning = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


## Fecha o jogo: para os sons e espera um instante (o áudio roda em outra thread),
## para nada ficar tocando na saída.
func quit_game() -> void:
	Audio.stop_all()
	await get_tree().create_timer(0.15, true).timeout
	get_tree().quit()


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _arg_value(args: PackedStringArray, prefix: String, fallback: String) -> String:
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback


func _take_screenshot_and_quit(path: String) -> void:
	for i in 30:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("Captura salva em %s (erro %d)" % [path, error])
	quit_game()
