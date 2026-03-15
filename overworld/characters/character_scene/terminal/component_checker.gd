extends Resource
class_name ComponentChecker

@export
var character_name: String

@export
var appearance: int

@export
var expected_file_name: String = ""

func is_file_name_correct(file_name: String):
	if expected_file_name == "": return true
	return file_name == expected_file_name

class ValidFieldsExtractor:
	var in_world_name: String
	var appearance: int
	var binary_converter := FileCharacter.make_binary_converter(
		FileCharacter.dummy_getter,
		FileCharacter.dummy_setter,
		FileCharacter.dummy_getter,
		FileCharacter.dummy_setter,
		FileCharacter.dummy_getter,
		FileCharacter.dummy_setter,
		FileCharacter.dummy_getter,
		func(val): in_world_name = val,
		FileCharacter.dummy_getter,
		func(val): appearance = val
	)
	func _init(file: FS.LoadSaveFileReturn):
		binary_converter.from_bytes(file.get_buffer(0, binary_converter.length))

class FileVarifier:
	var name: String
	var file_name: String
	var original_file_name: String
	var verified: bool
	var file_name_match: bool:
		get():
			return file_name == original_file_name
	static func invalid() -> FileVarifier:
		var result := FileVarifier.new()
		result.verified = false
		return result
	static func semi_valid(name: String, file_name: String, original_file_name: String) -> FileVarifier:
		var result := FileVarifier.new()
		result.verified = true
		result.name = name
		result.file_name = file_name
		result.original_file_name = original_file_name
		return result
	static func valid(name: String, file_name: String) -> FileVarifier:
		var result := FileVarifier.new()
		result.verified = true
		result.name = name
		result.file_name = file_name
		result.original_file_name = file_name
		return result

func extract_valid_file(terminal_name: String, files: PackedStringArray) -> FileVarifier:
	for file_name in files:
		var file := Core.get_terminal_file(terminal_name, file_name)
		var valid_fields := ValidFieldsExtractor.new(file)
		Core.unload_terminal_file(terminal_name, file_name)
		if valid_fields.appearance != appearance: continue
		if valid_fields.in_world_name != character_name: continue
		if not is_file_name_correct(file_name):
			return FileVarifier.semi_valid(character_name, expected_file_name, file_name)
		return FileVarifier.valid(character_name, file_name)
	return FileVarifier.invalid()
