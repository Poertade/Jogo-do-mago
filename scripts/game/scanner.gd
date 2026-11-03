class_name Scanner
extends Node3D
## A Lente Taxonômica, na mão esquerda: segure o botão direito mirando um objeto ou
## criatura e, quando a barra enche, os aspectos são revelados e vão para o Livro de Pesquisa.
## Este nó é o modelo da lente (filho da câmera); ele sobe para a frente do olho durante o uso.

@export var player: Player
## Posição da lente abaixada e erguida, em relação à câmera.
@export var rest_position := Vector3(-0.3, -0.4, -0.34)
@export var raised_position := Vector3(-0.1, -0.07, -0.3)

var progress: ScanProgress
var _hum: AudioStreamPlayer


func _ready() -> void:
	progress = ScanProgress.new(Content.db.research_rules.scan_duration)
	position = rest_position


## A lente está erguida (o botão está seguro e as mãos estão livres)?
func is_raised() -> bool:
	return Input.is_action_pressed("scan") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
		and player.can_use_lens()


func _physics_process(delta: float) -> void:
	var target := player.aimed_scannable
	var target_id: StringName = target.id if target != null else &""
	if progress.update(target_id, is_raised(), delta):
		Game.complete_scan(target)
	_update_hum(progress.is_active() and not progress.completed)
	# A lente desliza até a posição desejada (suavização exponencial).
	var goal := raised_position if is_raised() else rest_position
	position = position.lerp(goal, 1.0 - exp(-14.0 * delta))


## Zumbido da Lente enquanto a barra enche.
func _update_hum(scanning: bool) -> void:
	if scanning and not is_instance_valid(_hum):
		_hum = Audio.play(&"scan_hum")
	elif not scanning and is_instance_valid(_hum):
		Audio.fade_out(_hum)
		_hum = null
