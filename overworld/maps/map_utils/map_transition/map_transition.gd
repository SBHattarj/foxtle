extends CanvasLayer
@onready 
var polygon_2d: Polygon2D = $Polygon2D
@onready 
var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready 
var animation_player: AnimationPlayer = $AnimationPlayer

@export
var random_pich_scale_range: RangeValue = RangeValue.new()

func _ready() -> void:
	Signals.register_map_transition_start(map_exit_start)
	Signals.register_map_transition_end(map_exit_end)

func get_start_scale() -> float:
	return randf_range(random_pich_scale_range.low, random_pich_scale_range.high)

func map_exit_start():
	var exit_start_scale := get_start_scale()
	audio_stream_player.pitch_scale = exit_start_scale
	animation_player.speed_scale = exit_start_scale
	animation_player.play("start")
	await animation_player.animation_finished
	animation_player.speed_scale = 1.0

func map_exit_end():
	animation_player.play("end")
	await animation_player.animation_finished
	
