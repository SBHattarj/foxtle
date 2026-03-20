extends Node
class_name Map

const file_character_scene := preload("res://overworld/characters/character_scene/file_character/file_character.tscn")
const DEFAULT_BGM = preload("uid://cqprtfp1js20s")

@export
var bgm: AudioStream
@export
var in_gates: Array[InGate]

@export
var file_character_spawn_location: Node2D

var characters: Array[FileCharacter] = []

func _ready():
	if bgm == null:
		bgm = DEFAULT_BGM
	characters.clear()
	get_viewport().focus_exited.connect(_focus_exited)
	get_viewport().focus_entered.connect(_focus_entered)
	var character_names := Core.get_file_characters_in_map()
	spawn_characters_from_names(character_names)
	Signals.change_bgm(bgm)

func spawn_characters_from_names(character_names: PackedStringArray, make_sound := false):
	for character_name in character_names:
		Core.load_file_character(character_name)
		var character: FileCharacter = file_character_scene.instantiate()
		character.name = character_name
		character.is_spawner = false
		file_character_spawn_location.add_child(character)
		characters.append(character)
	if len(character_names) > 0 and make_sound:
		Signals.run_ui_audio("ReverseObjectMoveAudio")

func _focus_exited():
	for character in characters:
		Core.unload_file_character(character.name)
func _focus_entered():
	var character_names := Core.get_file_characters_in_map()
	for character_index in range(len(characters)):
		var character := characters[len(characters)-character_index-1]
		if character.name not in character_names:
			character.delete_self()
			characters.erase(character)
			Signals.run_ui_audio("ObjectMoveAudio")
			continue
		Core.load_file_character(character.name)
		character.load_from_file()
		character_names.erase(character.name)
	spawn_characters_from_names(character_names, true)
