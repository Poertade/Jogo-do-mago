extends GutTest
## Testes das opções do jogador: filtros, efeitos, limites e gravação.

var defaults: SettingsDefaults
var crunchy: GraphicsPreset
var clean: GraphicsPreset


func before_each() -> void:
	defaults = SettingsDefaults.new()
	defaults.default_preset_id = &"crunchy"
	defaults.internal_heights = PackedInt32Array([180, 240, 480])
	defaults.mouse_sensitivity = 0.2
	defaults.mouse_sensitivity_min = 0.1
	defaults.mouse_sensitivity_max = 0.5
	defaults.color_depth_bits = 5

	crunchy = GraphicsPreset.new()
	crunchy.id = &"crunchy"
	crunchy.vertex_snap = true
	crunchy.affine_mapping = true
	crunchy.fog = true
	crunchy.color_limit = true
	crunchy.dithering = true
	crunchy.internal_height = 240

	clean = GraphicsPreset.new()
	clean.id = &"clean"
	clean.fog = true
	clean.internal_height = 480


func _new_settings() -> GameSettings:
	var presets: Array[GraphicsPreset] = [crunchy, clean]
	return GameSettings.new(defaults, presets)


func test_starts_with_default_preset_and_sensitivity() -> void:
	var settings := _new_settings()
	assert_eq(settings.preset_id, &"crunchy")
	assert_true(settings.vertex_snap)
	assert_eq(settings.internal_height, 240)
	assert_eq(settings.mouse_sensitivity, 0.2)


func test_apply_preset_copies_effects_and_resolution() -> void:
	var settings := _new_settings()
	settings.apply_preset(clean)
	assert_eq(settings.preset_id, &"clean")
	assert_false(settings.vertex_snap)
	assert_false(settings.affine_mapping)
	assert_true(settings.fog)
	assert_eq(settings.internal_height, 480)


func test_changing_an_effect_becomes_custom() -> void:
	var settings := _new_settings()
	settings.set_effect(&"fog", false)
	assert_false(settings.fog)
	assert_eq(settings.preset_id, GameSettings.CUSTOM_PRESET)


func test_returning_to_a_preset_combination_recognizes_it() -> void:
	var settings := _new_settings()
	settings.set_effect(&"fog", false)
	settings.set_effect(&"fog", true)
	assert_eq(settings.preset_id, &"crunchy")


func test_resolution_outside_list_is_ignored() -> void:
	var settings := _new_settings()
	settings.set_internal_height(1000)
	assert_eq(settings.internal_height, 240)
	settings.set_internal_height(180)
	assert_eq(settings.internal_height, 180)
	assert_eq(settings.preset_id, GameSettings.CUSTOM_PRESET)


func test_sensitivity_is_clamped_to_limits() -> void:
	var settings := _new_settings()
	settings.set_mouse_sensitivity(9.0)
	assert_eq(settings.mouse_sensitivity, 0.5)
	settings.set_mouse_sensitivity(0.0)
	assert_eq(settings.mouse_sensitivity, 0.1)


func test_color_levels_follow_bits() -> void:
	assert_eq(_new_settings().color_levels(), 32)


func test_save_and_load_round_trip() -> void:
	var saved := _new_settings()
	saved.set_effect(&"dithering", false)
	saved.set_internal_height(480)
	saved.set_mouse_sensitivity(0.33)
	var config := ConfigFile.new()
	saved.save_to(config)
	assert_eq(config.get_value("meta", "format_version"), GameSettings.FORMAT_VERSION)

	var loaded := _new_settings()
	loaded.load_from(config)
	assert_false(loaded.dithering)
	assert_eq(loaded.internal_height, 480)
	assert_almost_eq(loaded.mouse_sensitivity, 0.33, 0.0001)
	assert_eq(loaded.preset_id, GameSettings.CUSTOM_PRESET)


func test_load_ignores_invalid_values() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "fog", "talvez")
	config.set_value("graphics", "internal_height", 999)
	config.set_value("controls", "mouse_sensitivity", "rápido")
	var settings := _new_settings()
	settings.load_from(config)
	assert_true(settings.fog)
	assert_eq(settings.internal_height, 240)
	assert_eq(settings.mouse_sensitivity, 0.2)
	assert_eq(settings.preset_id, &"crunchy")
