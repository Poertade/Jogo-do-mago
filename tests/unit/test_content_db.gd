extends GutTest
## Testes do carregamento e da verificação do conteúdo de data/.


func test_real_content_loads_without_errors() -> void:
	var db := ContentDB.new()
	db.load_all()
	assert_eq(db.errors, PackedStringArray(), "Erros no conteúdo de data/")
	assert_not_null(db.player)
	assert_not_null(db.settings_defaults)
	assert_gt(db.presets.size(), 0)
	assert_has(db.rooms, &"test_room")


func _room(id: StringName, scene_path: String) -> RoomData:
	var room := RoomData.new()
	room.id = id
	room.scene_path = scene_path
	return room


func test_duplicate_room_id_is_reported() -> void:
	var db := ContentDB.new()
	db.add_room(_room(&"sala", "res://scenes/rooms/test_room.tscn"))
	db.add_room(_room(&"sala", "res://scenes/rooms/test_room.tscn"))
	assert_eq(db.errors.size(), 1)
	assert_string_contains(db.errors[0], "repetido")


func test_missing_room_scene_is_reported() -> void:
	var db := ContentDB.new()
	db.add_room(_room(&"perdida", "res://scenes/rooms/nao_existe.tscn"))
	db.validate()
	var found := false
	for message in db.errors:
		if "perdida" in message and "cena" in message:
			found = true
	assert_true(found, "Deveria avisar da cena inexistente")


func test_missing_default_preset_is_reported() -> void:
	var db := ContentDB.new()
	db.load_all()
	db.errors.clear()
	db.settings_defaults = db.settings_defaults.duplicate()
	db.settings_defaults.default_preset_id = &"nao_existe"
	db.validate()
	var found := false
	for message in db.errors:
		if "nao_existe" in message:
			found = true
	assert_true(found, "Deveria avisar do filtro padrão inexistente")
