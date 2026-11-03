class_name PortalScreen
extends MenuLayer
## Tela do portal da escola: com mais de uma âncora sintonizada, pergunta para onde ir.
## Um botão por âncora (na ordem de data/dungeon/rules.tres), mais "Ficar na escola".

@onready var choices: VBoxContainer = %Choices
@onready var stay_button: Button = %StayButton


func _ready() -> void:
	super._ready()
	stay_button.pressed.connect(close)


func _on_opened() -> void:
	for child in choices.get_children():
		child.queue_free()
	var names := Content.db.dungeon_rules.anchor_names
	var first: Button = null
	for anchor_id in Game.attuned_anchors():
		var button := Button.new()
		button.text = Text.tr_key(names.get(anchor_id, String(anchor_id)))
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.pressed.connect(_travel.bind(anchor_id))
		choices.add_child(button)
		if first == null:
			first = button
	if first != null:
		first.grab_focus.call_deferred()


func _travel(anchor_id: StringName) -> void:
	close()
	Game.start_dungeon(anchor_id)
