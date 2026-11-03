class_name OptionsMenu
extends Control
## Menu de opções: filtro visual, resolução interna, cada efeito PS1 e sensibilidade do mouse.
## Lê e altera Settings.current; cada mudança é aplicada na hora e gravada.

signal back_pressed

@onready var preset_option: OptionButton = %PresetOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var back_button: Button = %BackButton
## Um botão de liga/desliga para cada efeito, na mesma ordem de GameSettings.EFFECTS.
@onready var effect_checks: Dictionary[StringName, CheckButton] = {
	&"vertex_snap": %VertexSnapCheck,
	&"affine_mapping": %AffineCheck,
	&"fog": %FogCheck,
	&"color_limit": %ColorLimitCheck,
	&"dithering": %DitheringCheck,
}

## Evita que, ao preencher os controles por código, eles disparem mudanças.
var _refreshing := false


func _ready() -> void:
	_fill_lists()
	preset_option.item_selected.connect(_on_preset_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	back_button.pressed.connect(back_pressed.emit)
	for effect in effect_checks:
		effect_checks[effect].toggled.connect(_on_effect_toggled.bind(effect))
	visibility_changed.connect(_on_visibility_changed)


## Coloca o foco no primeiro controle (para navegar pelo teclado) e mostra os valores atuais.
func _on_visibility_changed() -> void:
	if visible:
		refresh()
		preset_option.grab_focus()


func _fill_lists() -> void:
	preset_option.clear()
	for preset in Content.db.presets:
		preset_option.add_item(tr(preset.name_key))
		preset_option.set_item_metadata(-1, preset.id)
	preset_option.add_item(tr("PRESET_CUSTOM"))
	preset_option.set_item_metadata(-1, GameSettings.CUSTOM_PRESET)
	# "Personalizado" aparece quando os efeitos não batem com nenhum filtro, mas não é escolhível.
	preset_option.set_item_disabled(-1, true)

	resolution_option.clear()
	for height in Content.db.settings_defaults.internal_heights:
		resolution_option.add_item(tr("UI_RESOLUTION_LINES") % height)
		resolution_option.set_item_metadata(-1, height)

	var defaults := Content.db.settings_defaults
	sensitivity_slider.min_value = defaults.mouse_sensitivity_min
	sensitivity_slider.max_value = defaults.mouse_sensitivity_max
	sensitivity_slider.step = 0.01


## Mostra nos controles os valores atuais das opções.
func refresh() -> void:
	var settings: GameSettings = Settings.current
	_refreshing = true
	_select_by_metadata(preset_option, settings.preset_id)
	_select_by_metadata(resolution_option, settings.internal_height)
	for effect in effect_checks:
		effect_checks[effect].button_pressed = settings.get(effect)
	# Dithering só faz sentido com a cor limitada.
	effect_checks[&"dithering"].disabled = not settings.color_limit
	sensitivity_slider.value = settings.mouse_sensitivity
	_refreshing = false


func _select_by_metadata(option: OptionButton, value: Variant) -> void:
	for index in option.item_count:
		if option.get_item_metadata(index) == value:
			option.select(index)
			return


func _on_preset_selected(index: int) -> void:
	if _refreshing:
		return
	var preset: GraphicsPreset = Settings.current.find_preset(preset_option.get_item_metadata(index))
	if preset != null:
		Settings.current.apply_preset(preset)
		_changed()


func _on_resolution_selected(index: int) -> void:
	if not _refreshing:
		Settings.current.set_internal_height(resolution_option.get_item_metadata(index))
		_changed()


func _on_effect_toggled(enabled: bool, effect: StringName) -> void:
	if not _refreshing:
		Settings.current.set_effect(effect, enabled)
		_changed()


func _on_sensitivity_changed(value: float) -> void:
	if not _refreshing:
		Settings.current.set_mouse_sensitivity(value)
		_changed()


func _changed() -> void:
	Settings.notify_changed()
	refresh()
