extends CanvasLayer

@onready 
var animation_player: AnimationPlayer = $AnimationPlayer
@onready 
var label: Label = $Label

func _ready() -> void:
	Signals.show_map_name_signal.connect(run)

func run():
	label.text = ""
	label.size = Vector2.ZERO
	label.text = Core.get_map_name()
	animation_player.play("name_display_animation")
