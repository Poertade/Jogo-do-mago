class_name TitleScreen
extends MenuLayer
## Menu inicial: aparece ao abrir o jogo, sobre a escola. Continuar (ou Começar, sem save),
## Novo jogo (apaga o progresso, depois de confirmar), Opções e Sair.

## O jogador quer jogar; `new_game`: começar do zero (o progresso já foi apagado).
signal start_requested(new_game: bool)
signal quit_requested

@onready var main_panel: Control = %MainPanel
@onready var confirm_panel: Control = %ConfirmPanel
@onready var options_menu: OptionsMenu = %OptionsMenu
@onready var continue_button: Button = %ContinueButton
@onready var new_button: Button = %NewButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton


func _ready() -> void:
	super._ready()
	continue_button.pressed.connect(_on_continue)
	new_button.pressed.connect(_show.bind(confirm_panel))
	options_button.pressed.connect(_show.bind(options_menu))
	quit_button.pressed.connect(quit_requested.emit)
	yes_button.pressed.connect(_on_new_game)
	no_button.pressed.connect(_show.bind(main_panel))
	options_menu.back_pressed.connect(_show.bind(main_panel))


func _on_opened() -> void:
	# Sem save, o primeiro botão começa um jogo novo (com a introdução) e "Novo jogo" some.
	var has_save := Game.has_save()
	continue_button.text = tr("UI_TITLE_CONTINUE") if has_save else tr("UI_TITLE_START")
	new_button.visible = has_save
	_show(main_panel)


## Esc volta ao menu principal (no menu principal, não faz nada: é preciso escolher).
func _on_back() -> void:
	if not main_panel.visible:
		_show(main_panel)


func _show(panel: Control) -> void:
	for each in [main_panel, confirm_panel, options_menu]:
		each.visible = each == panel
	if panel == main_panel:
		continue_button.grab_focus()
	elif panel == confirm_panel:
		no_button.grab_focus()


func _on_continue() -> void:
	var new_game := not Game.has_save()
	close()
	start_requested.emit(new_game)


func _on_new_game() -> void:
	Game.reset_progress()
	close()
	start_requested.emit(true)
