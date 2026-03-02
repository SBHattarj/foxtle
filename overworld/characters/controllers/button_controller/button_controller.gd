@tool
extends ControllerBase
class_name ButtonController

func _input(event: InputEvent) -> void:
	change_joystick(Input.get_vector("left", "right", "up", "down"))
