extends GutTest
## Confere os arquivos de cena e de material. Um parâmetro de shader do tipo float gravado
## como inteiro (ex.: "emission_energy = 3") é ignorado pelo Godot: a chama ou o cristal
## aparece preto. Grave sempre com casa decimal ("3.0").

const FOLDERS := ["res://scenes", "res://assets/materials"]


func _files(dir: String) -> PackedStringArray:
	var result := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir):
		if file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
			result.append(dir.path_join(file_name))
	for sub_dir in DirAccess.get_directories_at(dir):
		result.append_array(_files(dir.path_join(sub_dir)))
	return result


func test_float_shader_parameters_have_decimals() -> void:
	var integer_value := RegEx.create_from_string("^shader_parameter/(emission_energy|texture_size_m) = -?[0-9]+$")
	var problems := PackedStringArray()
	for folder in FOLDERS:
		for path in _files(folder):
			var lines := FileAccess.get_file_as_string(path).split("\n")
			for i in lines.size():
				if integer_value.search(lines[i]) != null:
					problems.append("%s:%d  %s" % [path, i + 1, lines[i]])
	assert_eq(problems, PackedStringArray(), "Parâmetros float gravados como inteiro")
