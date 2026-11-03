extends Node
## Autoload "Settings": as opções do jogador, lidas de user://settings.cfg ao abrir o jogo
## e gravadas a cada mudança. Quem altera uma opção chama `notify_changed()`.

signal changed

const FILE_PATH := "user://settings.cfg"

var current: GameSettings


func _ready() -> void:
	current = GameSettings.new(Content.db.settings_defaults, Content.db.presets)
	var config := ConfigFile.new()
	if config.load(FILE_PATH) == OK:
		current.load_from(config)


## Avisa quem desenha a tela (e o jogador) e grava o arquivo.
func notify_changed() -> void:
	changed.emit()
	save()


func save() -> void:
	var config := ConfigFile.new()
	current.save_to(config)
	var error := config.save(FILE_PATH)
	if error != OK:
		push_error("Não foi possível gravar %s (erro %d)." % [FILE_PATH, error])
