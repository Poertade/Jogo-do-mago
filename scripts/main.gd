extends Node
## Cena principal: junta a tela do jogo (mundo 3D em baixa resolução), o HUD e o menu de pausa.
##
## Argumentos de desenvolvimento, depois de "--" na linha de comando:
##   --seed=123             semente do gerador aleatório
##   --room=test_room       sala inicial (padrão: start_room)
##   --entrance=default     entrada da sala inicial
##   --screenshot=foto.png  salva uma captura da janela depois de alguns quadros e fecha o jogo

## Sala onde o jogo começa (identificador de data/rooms/).
@export var start_room: StringName = &"test_room"
@export var start_entrance: StringName = &"default"

var rng: GameRng

@onready var game_viewport: SubViewport = %GameViewport
@onready var game_screen: GameScreen = %GameScreen
@onready var world: World = %World
@onready var player: Player = %Player
@onready var pause_menu: PauseMenu = %PauseMenu


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	rng = GameRng.new(GameRng.seed_from_args(args, randi()))
	print("Semente: %d" % rng.seed_value)

	Settings.changed.connect(_apply_settings)
	_apply_settings()
	pause_menu.resumed.connect(_capture_mouse)

	world.load_room(_arg_value(args, "--room=", start_room), _arg_value(args, "--entrance=", start_entrance))

	var screenshot_path := _arg_value(args, "--screenshot=", "")
	if screenshot_path != "":
		_take_screenshot_and_quit(screenshot_path)


func _apply_settings() -> void:
	game_screen.apply_settings(Settings.current, Content.db.settings_defaults)
	player.mouse_sensitivity = Settings.current.mouse_sensitivity


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.open()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse()
		get_viewport().set_input_as_handled()
		return
	# O mundo 3D fica num SubViewport, que não recebe eventos sozinho: repassamos.
	game_viewport.push_input(event)


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
	get_tree().quit()
