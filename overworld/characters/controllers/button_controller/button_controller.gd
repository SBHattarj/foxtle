@tool
extends ControllerBase
class_name ButtonController

var event_block_handler = Signals.make_event_block_handler()
var current_direction := Vector2.ZERO

func _ready() -> void:
	Signals.player_direction_button_pressed.connect(direction_button_changed)
	Signals.player_direction_button_released.connect(direction_button_changed)
	Signals.player_interact.connect(_handle_interact)
	event_block_handler.on_block.connect(on_event_block)
	event_block_handler.full_unblock.connect(on_event_unblock)

func direction_button_changed(_button: Signals.DirectionButtons) -> void:
	current_direction = Input.get_vector("left", "right", "up", "down")
	if event_block_handler.is_blocked: return
	change_joystick(current_direction)

func on_event_block():
	change_joystick(Vector2.ZERO)

func on_event_unblock():
	change_joystick(current_direction)

func _handle_interact():
	if event_block_handler.is_blocked: return
	interact()
