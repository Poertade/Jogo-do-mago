class_name NoteScreen
extends MenuLayer
## Tela para ler um texto (placa, anotação): título e corpo vêm de locales/content.csv.

@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(close)


## Mostra um texto já pronto (ex.: um livro, com as receitas aprendidas no fim).
func show_text(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	open()
	close_button.grab_focus()


func show_note(title_key: String, body_key: String) -> void:
	title_label.text = Text.expand(title_key)
	body_label.text = Text.expand(body_key)
	open()
	close_button.grab_focus()
