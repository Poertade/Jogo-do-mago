class_name GameSettings
extends RefCounted
## Opções escolhidas pelo jogador: efeitos PS1, resolução interna, sensibilidade do mouse e volume.
## Não sabe desenhar nada: só guarda os valores, aplica filtros e lê/grava num ConfigFile.
## Quem aplica os valores na tela é o autoload Settings e a GameScreen.

## Versão do formato do arquivo de opções. Aumente quando mudar o formato.
const FORMAT_VERSION := 1
## Valor de `preset_id` quando a combinação de efeitos não corresponde a nenhum filtro.
const CUSTOM_PRESET := &"custom"
## Nomes dos efeitos que podem ser ligados e desligados (iguais aos campos de GraphicsPreset).
const EFFECTS: Array[StringName] = [
	&"vertex_snap", &"affine_mapping", &"fog", &"color_limit", &"dithering",
]

var preset_id: StringName = CUSTOM_PRESET
var vertex_snap := true
var affine_mapping := true
var fog := true
var color_limit := true
var dithering := true
var internal_height := 240
var mouse_sensitivity := 0.15
## Volume geral, de 0 a 1.
var master_volume := 1.0

var _defaults: SettingsDefaults
var _presets: Array[GraphicsPreset] = []


## Cria as opções com os valores iniciais: o filtro padrão e a sensibilidade padrão.
func _init(defaults: SettingsDefaults, presets: Array[GraphicsPreset]) -> void:
	_defaults = defaults
	_presets = presets
	mouse_sensitivity = defaults.mouse_sensitivity
	master_volume = defaults.master_volume
	var preset := find_preset(defaults.default_preset_id)
	if preset != null:
		apply_preset(preset)


func find_preset(id: StringName) -> GraphicsPreset:
	for preset in _presets:
		if preset.id == id:
			return preset
	return null


## Copia os efeitos e a resolução de um filtro.
func apply_preset(preset: GraphicsPreset) -> void:
	for effect in EFFECTS:
		set(effect, preset.get(effect))
	internal_height = preset.internal_height
	preset_id = preset.id


## Liga ou desliga um efeito. O filtro passa a ser o que corresponder à nova combinação,
## ou "personalizado" se nenhum corresponder.
func set_effect(effect: StringName, enabled: bool) -> void:
	assert(effect in EFFECTS, "Efeito desconhecido: %s" % effect)
	set(effect, enabled)
	preset_id = _matching_preset_id()


## Muda a resolução interna, se for uma das alturas permitidas.
func set_internal_height(height: int) -> void:
	if height in _defaults.internal_heights:
		internal_height = height
		preset_id = _matching_preset_id()


## Muda a sensibilidade do mouse, respeitando os limites dos dados.
func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, _defaults.mouse_sensitivity_min, _defaults.mouse_sensitivity_max)


## Muda o volume geral (de 0 a 1).
func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)


## Quantos níveis de cor por canal o pós-processamento usa (2 elevado aos bits).
func color_levels() -> int:
	return 1 << _defaults.color_depth_bits


func save_to(config: ConfigFile) -> void:
	config.set_value("meta", "format_version", FORMAT_VERSION)
	config.set_value("graphics", "preset", String(preset_id))
	for effect in EFFECTS:
		config.set_value("graphics", String(effect), get(effect))
	config.set_value("graphics", "internal_height", internal_height)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("audio", "master_volume", master_volume)


## Lê as opções de um ConfigFile. Valores ausentes ou inválidos mantêm o valor atual.
func load_from(config: ConfigFile) -> void:
	for effect in EFFECTS:
		var value = config.get_value("graphics", String(effect), get(effect))
		if value is bool:
			set(effect, value)
	var height = config.get_value("graphics", "internal_height", internal_height)
	if height is int:
		set_internal_height(height)
	var sensitivity = config.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	if sensitivity is float or sensitivity is int:
		set_mouse_sensitivity(float(sensitivity))
	var volume = config.get_value("audio", "master_volume", master_volume)
	if volume is float or volume is int:
		set_master_volume(float(volume))
	preset_id = _matching_preset_id()


func _matching_preset_id() -> StringName:
	for preset in _presets:
		if _matches(preset):
			return preset.id
	return CUSTOM_PRESET


func _matches(preset: GraphicsPreset) -> bool:
	for effect in EFFECTS:
		if get(effect) != preset.get(effect):
			return false
	return internal_height == preset.internal_height
