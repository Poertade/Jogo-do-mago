class_name Hud
extends CanvasLayer
## Interface sobre o jogo. Neste marco: a mira no centro e o aviso "Clique para jogar"
## quando o mouse não está preso à janela.

@onready var click_hint: Label = %ClickHint
@onready var crosshair: Control = %Crosshair


func _process(_delta: float) -> void:
	var playing := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	crosshair.visible = playing
	click_hint.visible = not playing and not get_tree().paused
