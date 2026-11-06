extends GutTest
## Testes do M12 (acabamento): volume da música nas opções, sons próprios de cada inimigo e
## Focus, música em toda sala, a fonte dos algarismos e os textos do menu inicial e da introdução.

const ENEMY_SOUND_KINDS: Array[StringName] = [&"alert", &"swing", &"hurt", &"death"]

var db: ContentDB


func before_all() -> void:
	db = ContentDB.new()
	db.load_all()


func test_content_still_loads() -> void:
	assert_eq(db.errors.size(), 0, "\n".join(db.errors))


func test_music_volume_is_saved_and_clamped() -> void:
	var defaults := SettingsDefaults.new()
	defaults.default_preset_id = &"crunchy"
	defaults.internal_heights = [240] as Array[int]
	defaults.music_volume = 0.6
	var preset := GraphicsPreset.new()
	preset.id = &"crunchy"
	preset.internal_height = 240
	var presets: Array[GraphicsPreset] = [preset]

	var saved := GameSettings.new(defaults, presets)
	assert_eq(saved.music_volume, 0.6, "Começa no valor de data/settings")
	saved.set_music_volume(1.8)
	assert_eq(saved.music_volume, 1.0, "Não passa de 1")
	saved.set_music_volume(0.25)
	var config := ConfigFile.new()
	saved.save_to(config)

	var loaded := GameSettings.new(defaults, presets)
	loaded.load_from(config)
	assert_almost_eq(loaded.music_volume, 0.25, 0.0001)


func test_every_enemy_sound_set_is_complete() -> void:
	for enemy: EnemyData in db.enemies.values():
		assert_ne(enemy.sound_set, &"", "%s tem sons próprios" % enemy.id)
		for kind in ENEMY_SOUND_KINDS:
			var event := StringName("%s_%s" % [enemy.sound_set, kind])
			assert_true(db.sound_bank.sounds.has(event), "Falta o som %s" % event)


func test_every_focus_sound_is_in_the_bank() -> void:
	for focus: FocusData in db.foci.values():
		assert_true(db.sound_bank.sounds.has(focus.cast_sound), "%s: falta %s" % [focus.id, focus.cast_sound])
		assert_true(db.sound_bank.sounds.has(focus.impact_sound), "%s: falta %s" % [focus.id, focus.impact_sound])


func test_every_room_has_looping_music() -> void:
	for room: RoomData in db.rooms.values():
		assert_not_null(room.music, "%s tem música" % room.id)
		var wav := room.music as AudioStreamWAV
		if wav != null:
			assert_ne(wav.loop_mode, AudioStreamWAV.LOOP_DISABLED, "%s: a música repete" % room.id)


func test_digit_font_has_every_digit_and_falls_back_for_letters() -> void:
	var font := load("res://assets/ui/digits_font.tres") as FontFile
	assert_not_null(font)
	for digit in "0123456789":
		assert_true(font.has_char(digit.unicode_at(0)), "Algarismo %s desenhado" % digit)
	assert_eq(font.fallbacks.size(), 1, "As letras caem na fonte principal")
	assert_eq(font.fallbacks[0].resource_path, "res://assets/fonts/PixelifySans.ttf")


func test_title_and_intro_texts_exist() -> void:
	var ui := _keys("res://locales/ui.csv")
	for key in ["UI_TITLE_GAME", "UI_TITLE_CONTINUE", "UI_TITLE_START", "UI_TITLE_NEW", "UI_TITLE_CONFIRM",
			"UI_TITLE_CONFIRM_YES", "UI_TITLE_CONFIRM_NO", "UI_INTRO_SKIP", "UI_OPT_MUSIC"]:
		assert_true(ui.has(key), "Falta %s em locales/ui.csv" % key)
	var content := _keys("res://locales/content.csv")
	assert_true(content.has("INTRO_1"), "A introdução tem ao menos uma linha")


func _keys(path: String) -> Dictionary:
	var keys := {}
	var file := FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 0:
			keys[row[0]] = true
	return keys
