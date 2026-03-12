extends Node2D

@export
var direction: CharacterBase.Direction
@export
var in_world_name: String
@export
var appearance: int
@export
var dialogue_index: int

var binary_converter := FileCharacter.make_binary_converter(
	func(): return global_position.x,
	func(val): global_position.x = val,
	func(): return global_position.y,
	func(val): global_position.y = val,
	func(): return direction,
	func(val): direction = val,
	func(): return in_world_name,
	func(val): in_world_name = val,
	func(): return appearance,
	func(val): appearance = val,
	func(): return dialogue_index,
	func(val): dialogue_index = val
)

func _enter_tree() -> void:
	Core.set_file_character(name, binary_converter.to_bytes())
	delete_self.call_deferred()
func delete_self() -> void:
	queue_free()
