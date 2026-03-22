@tool
extends CharacterBase
class_name Player

var event_block_handler := Signals.make_event_block_handler()
@onready
var bump_audio: AudioStreamPlayer = $BumpAudio

@onready
var camera: Camera2D = $Camera2D

@export
var bump_audio_range: RangeValue = RangeValue.new()

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
).add_part(
	BinaryConverter.Float.new(
		Core.get_volume.bind("Master"),
		func(val): Core.set_volume("Master", val)
	)
).add_part(
	BinaryConverter.Float.new(
		Core.get_volume.bind("Music"),
		func(val): Core.set_volume("Music", val)
	)
).add_part(
	BinaryConverter.Float.new(
		Core.get_volume.bind("SFX"),
		func(val): Core.set_volume("SFX", val)
	)
).add_part(
	BinaryConverter.U8.new(
		Core.get_viewport_size_ratio,
		Core.set_viewport_ratio
	)
)

func _ready():
	if Engine.is_editor_hint():
		return
	Core.ready_player(self)
	camera.reset_smoothing()
	event_block_handler.full_unblock.connect(save)
	bump.connect(_on_bump)

func _on_bump():
	if bump_audio.playing:
		return
	bump_audio.pitch_scale = randf_range(bump_audio_range.low, bump_audio_range.high)
	bump_audio.play()

func teleport(position: Vector2, smooth := false):
	global_position = position
	if smooth: return
	camera.reset_smoothing()

func save():
	if event_block_handler.is_blocked:
		return
	Core.save_player()
