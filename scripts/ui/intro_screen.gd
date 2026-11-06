class_name IntroScreen
extends MenuLayer
## Introdução curta, no começo de um jogo novo: algumas linhas sobre a escola, as ruínas e o
## portal (INTRO_1, INTRO_2… em locales/content.csv), uma de cada vez, sobre fundo preto.
## Clique, E ou Esc pulam.

## Segundos de cada linha (entrando, parada e saindo).
const FADE := 0.9
const HOLD := 3.2

signal finished

@onready var line_label: Label = %LineLabel

var _tween: Tween


## Começa a introdução.
func play() -> void:
	open()
	var lines: PackedStringArray = []
	var index := 1
	while true:
		var key := "INTRO_%d" % index
		var text := Text.expand(key)
		if text == key or text == "":
			break
		lines.append(text)
		index += 1
	line_label.modulate.a = 0.0
	_tween = create_tween()
	for line in lines:
		_tween.tween_callback(func(): line_label.text = line)
		_tween.tween_property(line_label, "modulate:a", 1.0, FADE)
		_tween.tween_interval(HOLD)
		_tween.tween_property(line_label, "modulate:a", 0.0, FADE)
	_tween.tween_callback(_end)


## Em _input (antes da interface), para o clique pular mesmo sobre a tela.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var skip: bool = event.is_action_pressed("pause") or event.is_action_pressed("interact") \
		or (event is InputEventMouseButton and event.pressed)
	if skip:
		get_viewport().set_input_as_handled()
		_end()


func _end() -> void:
	if not visible:
		return
	if _tween != null:
		_tween.kill()
	close()
	finished.emit()
