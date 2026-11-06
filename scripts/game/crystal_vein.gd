class_name CrystalVein
extends Interactable
## Veio de cristal na rocha das grutas: o Focus de Escavação arranca as lascas, que caem no chão
## para serem pegas. O veio volta a cada incursão.

## Quantas lascas de cristal o veio dá.
@export var amount := 2

var _mined := false

@onready var shards: Node3D = $Shards


func _ready() -> void:
	locked_prompt_key = "PROMPT_CRYSTAL_VEIN"


func is_available() -> bool:
	return false


func current_prompt_key() -> String:
	return "" if _mined else locked_prompt_key


func dig() -> void:
	if _mined:
		return
	_mined = true
	shards.queue_free()
	Audio.play_at(&"glass", global_position, get_parent())
	var item: ItemData = Content.db.items.get(&"crystal")
	if item == null or item.pickup_scene == "":
		return
	var pickup: Node3D = (load(item.pickup_scene) as PackedScene).instantiate()
	pickup.set(&"item", &"crystal")
	pickup.set(&"amount", amount)
	get_parent().add_child(pickup)
	# As lascas caem no chão, à frente do veio.
	pickup.global_position = global_position + global_basis.z * 0.6
	pickup.global_position.y = global_position.y
