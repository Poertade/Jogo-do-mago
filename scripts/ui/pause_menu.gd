class_name PauseMenu
extends CanvasLayer
## Menu de pausa (Esc): continuar, opções e sair. Pausa o jogo enquanto está aberto.

signal resumed

@onready var main_panel: Control = %MainPanel
@onready var options_menu: OptionsMenu = %OptionsMenu
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	# O menu precisa funcionar com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	options_button.pressed.connect(_show_options)
	quit_button.pressed.connect(get_tree().quit)
	options_menu.back_pressed.connect(_show_main)


func open() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_main()


func close() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("pause"):
		return
	# Esc volta um nível: das opções para o menu, e do menu para o jogo.
	if options_menu.visible:
		_show_main()
	else:
		close()
	get_viewport().set_input_as_handled()


func _show_main() -> void:
	options_menu.visible = false
	main_panel.visible = true
	resume_button.grab_focus()


func _show_options() -> void:
	main_panel.visible = false
	options_menu.visible = true
