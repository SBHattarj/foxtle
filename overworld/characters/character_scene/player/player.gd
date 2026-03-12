@tool
extends CharacterBase
class_name Player

var event_block_handler := Signals.make_event_block_handler()

@onready
var camera: Camera2D = $Camera2D

@export
var current_map: String

var binary_converter := BinaryConverter.new().add_part(
	BinaryConverter.Float.new(
		func(): return global_position.x,
		func(val): global_position.x=val
	)
).add_part(
	BinaryConverter.Float.new(
		func(): return global_position.y,
		func(val): global_position.y=val
	)
).add_part(
	BinaryConverter.U8.new(
		func(): return direction,
		func(val): direction = val
	)
).add_part(
	BinaryConverter.UTF8String.new(
		func(): return current_map,
		func(val): current_map = val,
		20
	)
)

func _ready():
	if Engine.is_editor_hint():
		return
	Core.ready_player(self)
	camera.reset_smoothing()
	event_block_handler.full_unblock.connect(save)

func teleport(position: Vector2, smooth := false):
	global_position = position
	if smooth: return
	camera.reset_smoothing()

func save():
	if event_block_handler.is_blocked:
		return
	Core.save_player()
