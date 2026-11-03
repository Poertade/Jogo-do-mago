class_name PauseMenu
extends MenuLayer
## Menu de pausa (Esc): continuar, opções e sair.

## O jogador pediu para fechar o jogo (quem fecha é a cena principal).
signal quit_requested

@onready var main_panel: Control = %MainPanel
@onready var options_menu: OptionsMenu = %OptionsMenu
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	super._ready()
	resume_button.pressed.connect(close)
	options_button.pressed.connect(_show_options)
	quit_button.pressed.connect(quit_requested.emit)
	options_menu.back_pressed.connect(_show_main)


func _on_opened() -> void:
	_show_main()


## Esc volta um nível: das opções para o menu, e do menu para o jogo.
func _on_back() -> void:
	if options_menu.visible:
		_show_main()
	else:
		close()


func _show_main() -> void:
	options_menu.visible = false
	main_panel.visible = true
	resume_button.grab_focus()


func _show_options() -> void:
	main_panel.visible = false
	options_menu.visible = true
