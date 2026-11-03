class_name MenuLayer
extends CanvasLayer
## Base das telas que pausam o jogo (pausa, Livro de Pesquisa, Mesa de Pesquisa).
## Abrir: pausa e solta o mouse. Esc (ou `extra_close_action`) volta/fecha.

signal closed

## Outra ação que também fecha a tela (ex.: Tab fecha o Livro de Pesquisa).
@export var extra_close_action: StringName = &""


func _ready() -> void:
	# A tela precisa funcionar com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_on_opened()


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or (extra_close_action != &"" and event.is_action_pressed(extra_close_action)):
		_on_back()
		get_viewport().set_input_as_handled()


## Chamado ao abrir: preencha a tela aqui.
func _on_opened() -> void:
	pass


## Chamado com Esc: por padrão fecha a tela.
func _on_back() -> void:
	close()
