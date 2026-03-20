extends Node
signal change_player

@onready
var current_player: AudioStreamPlayer = $Player1
@onready
var other_player: AudioStreamPlayer = $Player2

var run_queue := Signals.RegisterableAsyncQueue.new()
var queued_run := run_queue.register(_run)

func _ready() -> void:
	Signals.change_bgm_signal.connect(run)

func run(stream: AudioStream, ease_duration: float):
	await queued_run.call(stream, ease_duration)

func _run(stream: AudioStream, ease_duration: float):
	if stream == current_player.stream:
		return
	if ease_duration < 0:
		ease_duration = 0
	var next_current_player := other_player
	other_player = current_player
	current_player = next_current_player
	next_current_player.volume_linear = 0
	next_current_player.stream = stream
	change_player.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	if not next_current_player.finished.is_connected(next_current_player.play):
		next_current_player.finished.connect(next_current_player.play)
	var tween := get_tree().create_tween()
	tween.tween_property(next_current_player, "volume_linear", 1, ease_duration)
	next_current_player.play()
	tween.play()
	fade_out(tween, next_current_player, ease_duration)

func fade_out(tween: Tween, next_current_player: AudioStreamPlayer, ease_duration):
	await change_player
	if tween.is_running():
		tween.stop()
	tween = get_tree().create_tween()
	tween.tween_property(next_current_player, "volume_linear", 0, ease_duration)
	tween.play()
	await AsyncUtils.wait_any([
		func(): await tween.finished,
		func(): await change_player
	])
	if tween.is_running():
		tween.stop()
	if next_current_player.finished.is_connected(next_current_player.play):
		next_current_player.finished.disconnect(next_current_player.play)
	next_current_player.stop()
