extends Node

@export
var ui_audio_streams: Dictionary[String, AudioStreamPlayer] = {}

@export
var ui_audio_stream_pitch_randomize_ranges: Dictionary[String, RangeValue]

func _ready() -> void:
	Signals.run_ui_audio_signal.connect(play_audio)

func apply_pitch_randomization(player: AudioStreamPlayer, name: String):
	if name not in ui_audio_stream_pitch_randomize_ranges:
		return
	var pitch_randomize_range := ui_audio_stream_pitch_randomize_ranges[name]
	player.pitch_scale = randf_range(pitch_randomize_range.low, pitch_randomize_range.high)

func play_audio(name: String):
	if name not in ui_audio_streams: return
	var player := ui_audio_streams[name]
	apply_pitch_randomization(player, name)
	player.play()
	
