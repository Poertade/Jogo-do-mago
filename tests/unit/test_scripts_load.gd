extends GutTest
## Todo script do jogo e das ferramentas precisa compilar. (Um erro de sintaxe num script de
## interface só aparecia ao abrir o jogo; aqui ele aparece nos testes.)


func test_every_script_compiles() -> void:
	var paths: Array[String] = []
	for folder in ["res://scripts", "res://tools"]:
		_collect(folder, paths)
	assert_gt(paths.size(), 40)
	for path in paths:
		var script := load(path) as Script
		assert_not_null(script, "Não compilou: %s" % path)
		if script != null:
			assert_true(script.can_instantiate(), "Não compilou: %s" % path)


func _collect(folder: String, paths: Array[String]) -> void:
	for file_name in DirAccess.get_files_at(folder):
		if file_name.ends_with(".gd"):
			paths.append(folder.path_join(file_name))
	for sub in DirAccess.get_directories_at(folder):
		_collect(folder.path_join(sub), paths)
