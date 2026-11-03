extends GutTest
## Garante a regra de camadas: scripts/core é lógica pura, testável sem abrir o jogo.
## Só pode estender RefCounted, Resource ou outra classe do próprio núcleo, e não pode usar
## nós, cena, entrada ou tela.

const CORE_DIR := "res://scripts/core"
const ALLOWED_BASES := ["RefCounted", "Resource"]
const FORBIDDEN := [
	"get_tree(", "get_node(", "Input.", "RenderingServer", "DisplayServer",
	"res://scripts/game", "res://scripts/ui", "res://scripts/render", "res://scenes",
]


func _core_scripts(dir: String) -> PackedStringArray:
	var result := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir):
		if file_name.ends_with(".gd"):
			result.append(dir.path_join(file_name))
	for sub_dir in DirAccess.get_directories_at(dir):
		result.append_array(_core_scripts(dir.path_join(sub_dir)))
	return result


func test_core_has_scripts() -> void:
	assert_gt(_core_scripts(CORE_DIR).size(), 0)


## Classes declaradas dentro de scripts/core (podem servir de base para outras do núcleo).
func _core_class_names() -> Array[String]:
	var names: Array[String] = []
	for path in _core_scripts(CORE_DIR):
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("class_name "):
				names.append(line.trim_prefix("class_name ").strip_edges())
	return names


func test_core_scripts_only_extend_pure_classes() -> void:
	var allowed: Array = ALLOWED_BASES.duplicate()
	allowed.append_array(_core_class_names())
	for path in _core_scripts(CORE_DIR):
		var source := FileAccess.get_file_as_string(path)
		var base := ""
		for line in source.split("\n"):
			if line.begins_with("extends "):
				base = line.trim_prefix("extends ").strip_edges()
				break
		assert_has(allowed, base, "%s estende '%s'" % [path, base])


func test_core_scripts_do_not_touch_scene_or_screen() -> void:
	for path in _core_scripts(CORE_DIR):
		var source := FileAccess.get_file_as_string(path)
		for word in FORBIDDEN:
			assert_false(word in source, "%s usa '%s'" % [path, word])
